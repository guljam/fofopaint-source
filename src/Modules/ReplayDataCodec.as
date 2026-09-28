package Modules
{
    import flash.utils.ByteArray;
    import flash.utils.CompressionAlgorithm;

    // .fofo 파일의 리플레이 블록 전용 무손실 변환. 결과는 "FRC2" + 버전 + LZMA로 압축한 본문이라 그대로 파일에 씀
    // 이 블록을 쓴 파일은 헤더가 "V2FOFOPAINT" (ReplayFileCache.writeReplayFile)
    // repdata(AMF3 명령 뭉치 스트림)를 성격이 같은 값끼리 스트림으로 나눠 저장함
    // - lineTo 좌표: 0.01 단위 정수로 정확히 되돌아오는 경우 직전 좌표와 이동량으로 예측한 값과의 차이만 기록
    //   연속된 lineTo는 한 묶음으로 기록하고, 묶음 전체가 정수 픽셀이면 차이를 픽셀 단위로 기록
    // - 그 외 명령: 명령 이름은 번호로, 필드는 같은 이름의 직전 명령과 같으면 태그 1바이트로 기록
    // 저장 쪽은 decode 결과가 원본 바이트와 같은지 확인하고 다르면 이 변환을 쓰지 않아야 함
    public final class ReplayDataCodec
    {
        private static const MAGIC:String = "FRC2";
        private static const VERSION:uint = 1;
        private static const STREAM_COUNT:int = 8;
        private static const MAX_SCALED:Number = 268435455; // 2^28 - 1, 예측값 차이가 int 범위를 넘지 않게 함
        private static const MAX_NAMES:int = 250;
        private static const MAX_FIELDS:int = 255;

        private static const OP_RUN_CENTI:uint = 0; // 연속된 lineTo 묶음, 예측 차이를 0.01 단위로 기록
        private static const OP_LINE_TO_RAW:uint = 1;
        private static const OP_NEW_NAME:uint = 2;
        private static const OP_RUN_PIXEL:uint = 3; // 연속된 lineTo 묶음, 좌표가 모두 정수 픽셀이라 예측 차이를 픽셀 단위로 기록
        private static const OP_NAME_BASE:uint = 4;

        private static const T_SAME:uint = 0;
        private static const T_NULL:uint = 1;
        private static const T_UNDEFINED:uint = 2;
        private static const T_TRUE:uint = 3;
        private static const T_FALSE:uint = 4;
        private static const T_INT:uint = 5;
        private static const T_CENTI:uint = 6;
        private static const T_DOUBLE:uint = 7;
        private static const T_STRING:uint = 8;
        private static const T_NEW_STRING:uint = 9;
        private static const T_AMF:uint = 10;
        private static const T_PEN:uint = 11;

        // 스트림 번호
        private static const S_OPS:int = 0; // 명령 종류
        private static const S_COUNT:int = 1; // 뭉치별 명령 갯수
        private static const S_XY:int = 2; // lineTo 좌표 예측 차이
        private static const S_TAG:int = 3; // 일반 명령 필드 갯수와 태그
        private static const S_VALUE:int = 4; // 일반 명령 정수 값, 문자열 번호
        private static const S_DOUBLE:int = 5; // 정수로 못 바꾸는 Number
        private static const S_OBJECT:int = 6; // 이름, 문자열, Vector/Array 등 AMF3 그대로
        private static const S_RUN:int = 7; // lineTo 묶음 길이

        public static function isEncoded(input:ByteArray):Boolean
        {
            return input.length >= 5 && input[0] == 70 && input[1] == 82 && input[2] == 67 && input[3] == 50;
        }

        // encode 후 decode 결과가 원본과 바이트 단위로 같을때만 결과를 돌려줌. 실패하거나 다르면 null
        public static function encodeVerified(input:ByteArray):ByteArray
        {
            var encoded:ByteArray = null;
            try
            {
                encoded = encode(input);
                const decoded:ByteArray = decode(encoded);
                const same:Boolean = isSameBytes(input, decoded);
                decoded.clear();
                if (same)
                    return encoded;
                trace("Replay codec verify failed");
            }
            catch (error:Error)
            {
                trace("Replay codec skipped: " + error);
            }
            if (encoded != null)
                encoded.clear();
            input.position = 0;
            return null;
        }

        public static function encode(input:ByteArray):ByteArray
        {
            const streams:Vector.<ByteArray> = new Vector.<ByteArray>(STREAM_COUNT, true);
            for (var s:int = 0; s < STREAM_COUNT; s++)
                streams[s] = new ByteArray();
            const ops:ByteArray = streams[S_OPS];
            const counts:ByteArray = streams[S_COUNT];
            const xy:ByteArray = streams[S_XY];
            const tags:ByteArray = streams[S_TAG];
            const values:ByteArray = streams[S_VALUE];
            const doubles:ByteArray = streams[S_DOUBLE];
            const objects:ByteArray = streams[S_OBJECT];
            const runs:ByteArray = streams[S_RUN];

            const nameIds:Object = {};
            var nameCount:int = 0;
            const previousByName:Object = {};
            const stringIds:Object = {};
            var stringCount:int = 0;

            // 펜 위치(0.01 단위 정수)와 직전 이동량
            var penValid:Boolean = false;
            var penX:int = 0;
            var penY:int = 0;
            var velocityX:int = 0;
            var velocityY:int = 0;

            var groupCount:uint = 0;
            input.position = 0;
            while (input.bytesAvailable > 0)
            {
                const group:Array = input.readObject() as Array;
                if (group == null)
                    throw new Error("Replay object is not an Array");
                const commandCount:int = group.length;
                writeUnsigned(counts, commandCount);
                for (var c:int = 0; c < commandCount; c++)
                {
                    const command:Array = group[c] as Array;
                    if (command == null || command.length == 0 || !(command[0] is String))
                        throw new Error("Invalid replay command");
                    const name:String = command[0];
                    const fieldCount:int = command.length - 1;

                    if (isCentiLineTo(command))
                    {
                        // 연속된 lineTo 끝을 찾고 묶음 전체가 정수 픽셀인지 확인
                        var pixel:Boolean = !penValid || (penX % 100 == 0 && penY % 100 == 0 && velocityX % 100 == 0 && velocityY % 100 == 0);
                        var runEnd:int = c;
                        while (runEnd < commandCount && isCentiLineTo(group[runEnd]))
                        {
                            if (pixel)
                                pixel = Math.round(group[runEnd][1] * 100) % 100 == 0 && Math.round(group[runEnd][2] * 100) % 100 == 0;
                            runEnd++;
                        }
                        ops.writeByte(pixel ? OP_RUN_PIXEL : OP_RUN_CENTI);
                        writeUnsigned(runs, runEnd - c);
                        const unit:int = pixel ? 100 : 1;
                        for (; c < runEnd; c++)
                        {
                            const kx:int = int(Math.round(group[c][1] * 100));
                            const ky:int = int(Math.round(group[c][2] * 100));
                            if (penValid)
                            {
                                writeSigned(xy, (kx - (penX + velocityX)) / unit);
                                writeSigned(xy, (ky - (penY + velocityY)) / unit);
                                velocityX = kx - penX;
                                velocityY = ky - penY;
                            }
                            else
                            {
                                writeSigned(xy, kx / unit);
                                writeSigned(xy, ky / unit);
                                velocityX = 0;
                                velocityY = 0;
                            }
                            penX = kx;
                            penY = ky;
                            penValid = true;
                        }
                        c--;
                        continue;
                    }

                    if (name === "lineTo" && fieldCount == 2)
                    {
                        const x:* = command[1];
                        const y:* = command[2];
                        if (x is Number && y is Number)
                        {
                            ops.writeByte(OP_LINE_TO_RAW);
                            doubles.writeDouble(x);
                            doubles.writeDouble(y);
                            penValid = false;
                            velocityX = 0;
                            velocityY = 0;
                            continue;
                        }
                    }

                    // 일반 명령
                    if (nameIds[name] === undefined)
                    {
                        if (nameCount >= MAX_NAMES)
                            throw new Error("Too many replay command names");
                        nameIds[name] = nameCount++;
                        ops.writeByte(OP_NEW_NAME);
                        objects.writeUTF(name);
                    }
                    ops.writeByte(OP_NAME_BASE + nameIds[name]);
                    if (fieldCount > MAX_FIELDS)
                        throw new Error("Too many replay command fields");
                    tags.writeByte(fieldCount);

                    const previous:Array = previousByName[name] as Array;
                    const hasPen:Boolean = hasPenFields(name, fieldCount);
                    for (var i:int = 1; i <= fieldCount; i++)
                    {
                        const v:* = command[i];
                        if (previous != null && i < previous.length && isSameValue(v, previous[i]))
                        {
                            tags.writeByte(T_SAME);
                        }
                        else if (hasPen && penValid && (i == 5 || i == 6) && isCenti(v)
                                && int(Math.round(v * 100)) == (i == 5 ? penX : penY))
                        {
                            tags.writeByte(T_PEN);
                        }
                        else if (v === null)
                        {
                            tags.writeByte(T_NULL);
                        }
                        else if (v === undefined)
                        {
                            tags.writeByte(T_UNDEFINED);
                        }
                        else if (v === true)
                        {
                            tags.writeByte(T_TRUE);
                        }
                        else if (v === false)
                        {
                            tags.writeByte(T_FALSE);
                        }
                        else if (v is Number && isWholeInt(v))
                        {
                            tags.writeByte(T_INT);
                            writeSigned(values, int(v));
                        }
                        else if (v is Number && isCenti(v))
                        {
                            tags.writeByte(T_CENTI);
                            writeSigned(values, int(Math.round(v * 100)));
                        }
                        else if (v is Number)
                        {
                            tags.writeByte(T_DOUBLE);
                            doubles.writeDouble(v);
                        }
                        else if (v is String)
                        {
                            if (stringIds[v] === undefined)
                            {
                                stringIds[v] = stringCount++;
                                tags.writeByte(T_NEW_STRING);
                                objects.writeUTF(v);
                            }
                            else
                            {
                                tags.writeByte(T_STRING);
                                writeUnsigned(values, stringIds[v]);
                            }
                        }
                        else
                        {
                            tags.writeByte(T_AMF);
                            objects.writeObject(v);
                        }
                    }
                    previousByName[name] = command;

                    if (hasPen && name.indexOf("lineStyle") == 0)
                    {
                        velocityX = 0;
                        velocityY = 0;
                        if (isCenti(command[5]) && isCenti(command[6]))
                        {
                            penX = int(Math.round(command[5] * 100));
                            penY = int(Math.round(command[6] * 100));
                            penValid = true;
                        }
                        else
                        {
                            penValid = false;
                        }
                    }
                }
                groupCount++;
            }

            const body:ByteArray = new ByteArray();
            body.writeUnsignedInt(groupCount);
            for (s = 0; s < STREAM_COUNT; s++)
                body.writeUnsignedInt(streams[s].length);
            for (s = 0; s < STREAM_COUNT; s++)
            {
                body.writeBytes(streams[s]);
                streams[s].clear();
            }
            // 이 데이터에서는 LZMA가 zlib보다 작고 압축도 빠름
            body.compress(CompressionAlgorithm.LZMA);

            const output:ByteArray = new ByteArray();
            output.writeUTFBytes(MAGIC);
            output.writeByte(VERSION);
            output.writeBytes(body);
            body.clear();
            input.position = 0;
            output.position = 0;
            return output;
        }

        public static function decode(input:ByteArray):ByteArray
        {
            input.position = 0;
            if (!isEncoded(input) || input.readUTFBytes(4) != MAGIC)
                throw new Error("Invalid replay codec header");
            if (input.readUnsignedByte() != VERSION)
                throw new Error("Unknown replay codec version");
            const body:ByteArray = new ByteArray();
            input.readBytes(body);
            input.position = 0;
            body.uncompress(CompressionAlgorithm.LZMA);
            const groupCount:uint = body.readUnsignedInt();
            if (body.bytesAvailable < STREAM_COUNT * 4)
                throw new Error("Invalid replay codec header");
            const streams:Vector.<ByteArray> = new Vector.<ByteArray>(STREAM_COUNT, true);
            const lengths:Vector.<uint> = new Vector.<uint>(STREAM_COUNT, true);
            var total:Number = 0;
            for (var s:int = 0; s < STREAM_COUNT; s++)
            {
                lengths[s] = body.readUnsignedInt();
                total += lengths[s];
            }
            if (total != body.bytesAvailable)
                throw new Error("Invalid replay codec stream length");
            for (s = 0; s < STREAM_COUNT; s++)
            {
                streams[s] = new ByteArray();
                if (lengths[s] > 0)
                    body.readBytes(streams[s], 0, lengths[s]);
            }
            body.clear();
            const ops:ByteArray = streams[S_OPS];
            const counts:ByteArray = streams[S_COUNT];
            const xy:ByteArray = streams[S_XY];
            const tags:ByteArray = streams[S_TAG];
            const values:ByteArray = streams[S_VALUE];
            const doubles:ByteArray = streams[S_DOUBLE];
            const objects:ByteArray = streams[S_OBJECT];
            const runs:ByteArray = streams[S_RUN];

            const names:Vector.<String> = new Vector.<String>();
            const previousById:Array = [];
            const strings:Vector.<String> = new Vector.<String>();

            var penValid:Boolean = false;
            var penX:int = 0;
            var penY:int = 0;
            var velocityX:int = 0;
            var velocityY:int = 0;

            const output:ByteArray = new ByteArray();
            for (var g:uint = 0; g < groupCount; g++)
            {
                const commandCount:uint = readUnsigned(counts);
                if (commandCount > ops.bytesAvailable + xy.bytesAvailable)
                    throw new Error("Invalid replay command count");
                const group:Array = new Array(commandCount);
                for (var c:uint = 0; c < commandCount; c++)
                {
                    var op:uint = ops.readUnsignedByte();
                    if (op == OP_RUN_CENTI || op == OP_RUN_PIXEL)
                    {
                        const runLength:uint = readUnsigned(runs);
                        if (runLength == 0 || runLength > commandCount - c)
                            throw new Error("Invalid replay codec run");
                        const unit:int = op == OP_RUN_PIXEL ? 100 : 1;
                        for (var r:uint = 0; r < runLength; r++)
                        {
                            var kx:int = readSigned(xy) * unit;
                            var ky:int = readSigned(xy) * unit;
                            if (penValid)
                            {
                                kx += penX + velocityX;
                                ky += penY + velocityY;
                                velocityX = kx - penX;
                                velocityY = ky - penY;
                            }
                            else
                            {
                                velocityX = 0;
                                velocityY = 0;
                            }
                            penX = kx;
                            penY = ky;
                            penValid = true;
                            group[c++] = ["lineTo", kx / 100, ky / 100];
                        }
                        c--;
                        continue;
                    }
                    if (op == OP_LINE_TO_RAW)
                    {
                        group[c] = ["lineTo", doubles.readDouble(), doubles.readDouble()];
                        penValid = false;
                        velocityX = 0;
                        velocityY = 0;
                        continue;
                    }
                    if (op == OP_NEW_NAME)
                    {
                        names.push(objects.readUTF());
                        op = ops.readUnsignedByte();
                    }
                    const id:int = int(op) - int(OP_NAME_BASE);
                    if (id < 0 || id >= names.length)
                        throw new Error("Unknown replay command id: " + op);
                    const name:String = names[id];
                    const fieldCount:int = tags.readUnsignedByte();
                    const previous:Array = previousById[id] as Array;
                    const hasPen:Boolean = hasPenFields(name, fieldCount);
                    const command:Array = new Array(fieldCount + 1);
                    command[0] = name;
                    for (var i:int = 1; i <= fieldCount; i++)
                    {
                        const tag:uint = tags.readUnsignedByte();
                        switch (tag)
                        {
                            case T_SAME:
                                if (previous == null || i >= previous.length)
                                    throw new Error("Invalid replay codec reference");
                                command[i] = previous[i];
                                break;
                            case T_PEN:
                                if (!hasPen || !penValid || (i != 5 && i != 6))
                                    throw new Error("Invalid replay codec pen reference");
                                command[i] = (i == 5 ? penX : penY) / 100;
                                break;
                            case T_NULL:
                                command[i] = null;
                                break;
                            case T_UNDEFINED:
                                command[i] = undefined;
                                break;
                            case T_TRUE:
                                command[i] = true;
                                break;
                            case T_FALSE:
                                command[i] = false;
                                break;
                            case T_INT:
                                command[i] = readSigned(values);
                                break;
                            case T_CENTI:
                                command[i] = readSigned(values) / 100;
                                break;
                            case T_DOUBLE:
                                command[i] = doubles.readDouble();
                                break;
                            case T_STRING:
                                const stringId:uint = readUnsigned(values);
                                if (stringId >= strings.length)
                                    throw new Error("Invalid replay codec string");
                                command[i] = strings[stringId];
                                break;
                            case T_NEW_STRING:
                                const str:String = objects.readUTF();
                                strings.push(str);
                                command[i] = str;
                                break;
                            case T_AMF:
                                command[i] = objects.readObject();
                                break;
                            default:
                                throw new Error("Unknown replay codec tag: " + tag);
                        }
                    }
                    previousById[id] = command;
                    group[c] = command;

                    if (hasPen && name.indexOf("lineStyle") == 0)
                    {
                        velocityX = 0;
                        velocityY = 0;
                        if (isCenti(command[5]) && isCenti(command[6]))
                        {
                            penX = int(Math.round(command[5] * 100));
                            penY = int(Math.round(command[6] * 100));
                            penValid = true;
                        }
                        else
                        {
                            penValid = false;
                        }
                    }
                }
                output.writeObject(group);
            }
            for (s = 0; s < STREAM_COUNT; s++)
            {
                if (streams[s].bytesAvailable != 0)
                    throw new Error("Trailing replay codec bytes");
                streams[s].clear();
            }
            output.position = 0;
            return output;
        }

        // 원본과 decode 결과가 바이트 단위로 같은지 비교
        public static function isSameBytes(a:ByteArray, b:ByteArray):Boolean
        {
            if (a.length != b.length)
                return false;
            a.position = 0;
            b.position = 0;
            var same:Boolean = true;
            // 4바이트씩 비교하고 남은 부분은 1바이트씩
            while (same && a.bytesAvailable >= 4)
                same = a.readUnsignedInt() == b.readUnsignedInt();
            while (same && a.bytesAvailable > 0)
                same = a.readUnsignedByte() == b.readUnsignedByte();
            a.position = 0;
            b.position = 0;
            return same;
        }

        private static function isCentiLineTo(v:*):Boolean
        {
            const command:Array = v as Array;
            return command != null && command.length == 3 && command[0] === "lineTo" && isCenti(command[1]) && isCenti(command[2]);
        }

        private static function hasPenFields(name:String, fieldCount:int):Boolean
        {
            return fieldCount >= 6 && (name.indexOf("lineStyle") == 0 || name.indexOf("dot") == 0 || name.indexOf("line") == 0);
        }

        // 0.01 단위 정수로 바꿨다가 되돌렸을때 원래 Number와 완전히 같은 값인지
        private static function isCenti(v:*):Boolean
        {
            if (!(v is Number))
                return false;
            const n:Number = v;
            if (n != n || n > MAX_SCALED / 100 || n < -MAX_SCALED / 100 || (n == 0 && 1 / n < 0))
                return false;
            return Math.round(n * 100) / 100 === n;
        }

        private static function isWholeInt(v:*):Boolean
        {
            const n:Number = v;
            return n === Math.floor(n) && n <= 1073741823 && n >= -1073741824 && !(n == 0 && 1 / n < 0);
        }

        // SAME 태그로 이전 값을 그대로 가져가도 되는지. -0과 0은 === 로 같다고 나와서 따로 구분함
        private static function isSameValue(a:*, b:*):Boolean
        {
            if (a !== b)
                return false;
            if (a is Number)
                return a != 0 || 1 / a == 1 / b;
            return a === null || a === undefined || a is Boolean || a is String;
        }

        private static function writeUnsigned(output:ByteArray, value:uint):void
        {
            while (value >= 128)
            {
                output.writeByte((value & 127) | 128);
                value >>>= 7;
            }
            output.writeByte(value);
        }

        private static function readUnsigned(input:ByteArray):uint
        {
            var result:uint = 0;
            for (var shift:int = 0; shift < 35; shift += 7)
            {
                const part:uint = input.readUnsignedByte();
                result |= (part & 127) << shift;
                if ((part & 128) == 0)
                    return result;
            }
            throw new Error("Replay codec integer is too long");
        }

        private static function writeSigned(output:ByteArray, value:int):void
        {
            writeUnsigned(output, uint((value << 1) ^ (value >> 31)));
        }

        private static function readSigned(input:ByteArray):int
        {
            const bits:uint = readUnsigned(input);
            return int((bits >>> 1) ^ uint(-(bits & 1)));
        }
    }
}
