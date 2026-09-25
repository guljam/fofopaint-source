package Modules
{
    import flash.utils.ByteArray;

    // Reversible command transform for the replay portion of a .2020 file.
    // The transformed bytes still need an outer ByteArray.compress() call.
    public final class ReplayDataCodec
    {
        public static const MAGIC:String = "FRC1";
        private static const MAX_SCALED:Number = 1073741823;

        public static function isEncoded(input:ByteArray):Boolean
        {
            return input.length >= 8 && input[0] == 70 && input[1] == 82
                    && input[2] == 67 && input[3] == 49;
        }

        public static function encode(input:ByteArray):ByteArray
        {
            const output:ByteArray = new ByteArray();
            input.position = 0;
            output.writeUTFBytes(MAGIC);
            output.writeUnsignedInt(0); // Object count, filled after encoding.
            var objectCount:uint = 0;
            while (input.bytesAvailable > 0)
            {
                const group:Array = input.readObject() as Array;
                if (group == null)
                    throw new Error("Replay object is not an Array");
                output.writeUnsignedInt(group.length);
                var previousX:Number = NaN;
                var previousY:Number = NaN;
                for each (var command:* in group)
                {
                    const values:Array = command as Array;
                    if (values == null || values.length == 0)
                        throw new Error("Invalid replay command");
                    if (values[0] === "lineTo" && values.length == 3
                            && values[1] is Number && values[2] is Number)
                    {
                        const x:Number = Number(values[1]);
                        const y:Number = Number(values[2]);
                        var scale:uint = 0;
                        if (canScale(x, 1) && canScale(y, 1)) scale = 1;
                        else if (canScale(x, 100) && canScale(y, 100)) scale = 100;
                        else if (canScale(x, 1000) && canScale(y, 1000)) scale = 1000;
                        if (scale != 0)
                        {
                            const delta:Boolean = canScale(previousX, scale) && canScale(previousY, scale)
                                    && Math.abs(Math.round(x * scale) - Math.round(previousX * scale)) <= MAX_SCALED
                                    && Math.abs(Math.round(y * scale) - Math.round(previousY * scale)) <= MAX_SCALED;
                            output.writeByte(scale == 1 ? (delta ? 1 : 2)
                                    : scale == 100 ? (delta ? 3 : 4) : (delta ? 5 : 6));
                            writeSigned(output, int(Math.round(x * scale) - (delta ? Math.round(previousX * scale) : 0)));
                            writeSigned(output, int(Math.round(y * scale) - (delta ? Math.round(previousY * scale) : 0)));
                        }
                        else
                        {
                            output.writeByte(7);
                            output.writeDouble(x);
                            output.writeDouble(y);
                        }
                        previousX = x;
                        previousY = y;
                    }
                    else
                    {
                        output.writeByte(0);
                        output.writeObject(values);
                        if (values[0] === "lineStyle5" && values.length > 6
                                && values[5] is Number && values[6] is Number)
                        {
                            previousX = Number(values[5]);
                            previousY = Number(values[6]);
                        }
                    }
                }
                objectCount++;
            }
            output.position = 4;
            output.writeUnsignedInt(objectCount);
            output.position = 0;
            return output;
        }

        public static function decode(input:ByteArray):ByteArray
        {
            input.position = 0;
            if (!isEncoded(input) || input.readUTFBytes(4) != MAGIC)
                throw new Error("Invalid replay codec header");
            const objectCount:uint = input.readUnsignedInt();
            if (objectCount > input.bytesAvailable / 4)
                throw new Error("Invalid replay object count");
            const output:ByteArray = new ByteArray();
            for (var objectIndex:uint = 0; objectIndex < objectCount; objectIndex++)
            {
                const count:uint = input.readUnsignedInt();
                if (count > input.bytesAvailable)
                    throw new Error("Invalid replay command count");
                const group:Array = [];
                var previousX:Number = NaN;
                var previousY:Number = NaN;
                for (var i:uint = 0; i < count; i++)
                {
                    const tag:uint = input.readUnsignedByte();
                    var command:Array;
                    if (tag == 0)
                    {
                        command = input.readObject() as Array;
                        if (command == null || command.length == 0)
                            throw new Error("Invalid replay command in codec");
                        if (command[0] === "lineStyle5" && command.length > 6
                                && command[5] is Number && command[6] is Number)
                        {
                            previousX = Number(command[5]);
                            previousY = Number(command[6]);
                        }
                    }
                    else if (tag >= 1 && tag <= 7)
                    {
                        var x:Number;
                        var y:Number;
                        if (tag == 7)
                        {
                            x = input.readDouble();
                            y = input.readDouble();
                        }
                        else
                        {
                            const scale:uint = tag <= 2 ? 1 : tag <= 4 ? 100 : 1000;
                            const delta:Boolean = (tag & 1) == 1;
                            if (delta && (!canScale(previousX, scale) || !canScale(previousY, scale)))
                                throw new Error("Invalid replay coordinate predictor");
                            x = (readSigned(input) + (delta ? Math.round(previousX * scale) : 0)) / scale;
                            y = (readSigned(input) + (delta ? Math.round(previousY * scale) : 0)) / scale;
                        }
                        command = ["lineTo", x, y];
                        previousX = x;
                        previousY = y;
                    }
                    else
                        throw new Error("Unknown replay codec tag: " + tag);
                    group.push(command);
                }
                output.writeObject(group);
            }
            if (input.bytesAvailable != 0)
                throw new Error("Trailing replay codec bytes");
            output.position = 0;
            return output;
        }

        private static function canScale(value:Number, scale:uint):Boolean
        {
            if (isNaN(value) || !isFinite(value) || Math.abs(value) * scale > MAX_SCALED
                    || (value == 0 && 1 / value < 0))
                return false;
            const scaled:Number = Math.round(value * scale);
            return scaled / scale == value;
        }

        private static function writeSigned(output:ByteArray, value:int):void
        {
            var bits:uint = uint((value << 1) ^ (value >> 31));
            while (bits >= 128)
            {
                output.writeByte((bits & 127) | 128);
                bits >>>= 7;
            }
            output.writeByte(bits);
        }

        private static function readSigned(input:ByteArray):int
        {
            var bits:uint = 0;
            for (var i:uint = 0; i < 5; i++)
            {
                const part:uint = input.readUnsignedByte();
                if (i == 4 && (part & 240) != 0)
                    throw new Error("Invalid replay integer");
                bits |= (part & 127) << (i * 7);
                if ((part & 128) == 0)
                    return int((bits >>> 1) ^ uint(-(bits & 1)));
            }
            throw new Error("Replay integer is too long");
        }
    }
}
