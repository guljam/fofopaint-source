package
{
    import Modules.ReplayDataCodec;
    import flash.desktop.NativeApplication;
    import flash.display.Sprite;
    import flash.events.InvokeEvent;
    import flash.filesystem.File;
    import flash.filesystem.FileMode;
    import flash.filesystem.FileStream;
    import flash.utils.ByteArray;
    import flash.utils.getTimer;

    public class CodecBenchmark extends Sprite
    {
        public function CodecBenchmark()
        {
            NativeApplication.nativeApplication.addEventListener(InvokeEvent.INVOKE, run);
        }

        private function run(event:InvokeEvent):void
        {
            try
            {
                var emitPath:String = null;
                for each (var path:String in event.arguments)
                {
                    if (path.indexOf("--emit=") == 0)
                        emitPath = path.substr(7);
                    else
                    {
                        measure(new File(path), emitPath);
                        emitPath = null;
                    }
                }
                measureSynthetic();
                NativeApplication.nativeApplication.exit(0);
            }
            catch (error:Error)
            {
                trace("ERROR " + error + "\n" + error.getStackTrace());
                NativeApplication.nativeApplication.exit(1);
            }
        }

        private function measure(file:File, emitPath:String):void
        {
            const original:ByteArray = file.extension == "txt" ? fromText(file) : fromFile(file);
            const baseline:ByteArray = copy(original);
            var begin:int = getTimer();
            baseline.compress();
            const baselineTime:int = getTimer() - begin;
            begin = getTimer();
            const relative:ByteArray = toRelativeStream(original, false);
            const relativeTransformTime:int = getTimer() - begin;
            const relativePacked:ByteArray = copy(relative);
            begin = getTimer();
            relativePacked.compress();
            const relativeZlibTime:int = getTimer() - begin;
            const relativeRestored:ByteArray = fromRelativeStream(relative);
            const relativeDrift:Object = measureDrift(original, relativeRestored);
            const exactRelative:ByteArray = toRelativeStream(original, true);
            const exactRelativePacked:ByteArray = copy(exactRelative);
            exactRelativePacked.compress();
            const exactRelativeRestored:ByteArray = fromRelativeStream(exactRelative);
            assertEqual(original, exactRelativeRestored);
            begin = getTimer();
            const transformed:ByteArray = ReplayDataCodec.encode(original);
            const transformTime:int = getTimer() - begin;
            const packed:ByteArray = copy(transformed);
            begin = getTimer();
            packed.compress();
            const packedTime:int = getTimer() - begin;
            const compressedLength:uint = packed.length;
            const doubleBaseline:ByteArray = copy(baseline);
            doubleBaseline.compress();
            const doublePacked:ByteArray = copy(packed);
            doublePacked.compress();
            if (emitPath != null)
            {
                const container:FileStream = new FileStream();
                container.open(new File(emitPath), FileMode.WRITE);
                container.writeUTFBytes("FOFOPAINT");
                container.writeUnsignedInt(packed.length);
                container.writeBytes(packed);
                container.close();
                emitPath = null;
            }
            packed.uncompress();
            begin = getTimer();
            const restored:ByteArray = ReplayDataCodec.decode(packed);
            const decodeTime:int = getTimer() - begin;
            assertEqual(original, restored);
            trace(file.name + " objects=" + countObjects(original)
                    + " raw=" + original.length + " zlib=" + baseline.length
                    + " relativeRaw=" + relative.length + " relativeZlib=" + relativePacked.length
                    + " relativeExactZlib=" + exactRelativePacked.length
                    + " relativeDrift=" + relativeDrift.mismatches + "/" + relativeDrift.coordinates
                    + " maxError=" + relativeDrift.maxError
                    + " codec=" + transformed.length + " codec+zlib=" + compressedLength
                    + " doubleZlib=" + doubleBaseline.length + "/" + doublePacked.length
                    + " zlibMs=" + baselineTime + " transformMs=" + transformTime
                    + " relativeTransformMs=" + relativeTransformTime + " relativeZlibMs=" + relativeZlibTime
                    + " codecZlibMs=" + packedTime + " decodeMs=" + decodeTime + " roundtrip=OK");
        }

        // lineStyle5[5:6] is the saved moveTo position. The parser's synthetic
        // moveTo is deliberately absent from the source AMF object stream.
        private function toRelativeStream(input:ByteArray, exactOnly:Boolean):ByteArray
        {
            input.position = 0;
            const output:ByteArray = new ByteArray();
            while (input.bytesAvailable > 0)
            {
                const group:Array = input.readObject() as Array;
                const result:Array = [];
                var hasPosition:Boolean = false;
                var previousX:Number = 0;
                var previousY:Number = 0;
                for each (var command:Array in group)
                {
                    const name:String = String(command[0]);
                    if (name == "lineStyle5" && command.length > 6)
                    {
                        previousX = Number(command[5]);
                        previousY = Number(command[6]);
                        hasPosition = true;
                        result.push(command);
                    }
                    else if (name == "moveTo" && command.length >= 3)
                    {
                        previousX = Number(command[1]);
                        previousY = Number(command[2]);
                        hasPosition = true;
                        result.push(command);
                    }
                    else if (name == "lineTo" && command.length == 3)
                    {
                        const x:Number = Number(command[1]);
                        const y:Number = Number(command[2]);
                        const dx:Number = x - previousX;
                        const dy:Number = y - previousY;
                        if (hasPosition && (!exactOnly || (sameNumber(previousX + dx, x) && sameNumber(previousY + dy, y))))
                            result.push(["lineTo2", dx, dy]);
                        else
                            result.push(command);
                        previousX = x;
                        previousY = y;
                        hasPosition = true;
                    }
                    else
                    {
                        result.push(command);
                        if (name == "drawDone5" || name == "tempDone4")
                            hasPosition = false;
                    }
                }
                output.writeObject(result);
            }
            output.position = 0;
            return output;
        }

        private function fromRelativeStream(input:ByteArray):ByteArray
        {
            input.position = 0;
            const output:ByteArray = new ByteArray();
            while (input.bytesAvailable > 0)
            {
                const group:Array = input.readObject() as Array;
                const result:Array = [];
                var previousX:Number = 0;
                var previousY:Number = 0;
                for each (var command:Array in group)
                {
                    const name:String = String(command[0]);
                    if (name == "lineStyle5" && command.length > 6)
                    {
                        previousX = Number(command[5]);
                        previousY = Number(command[6]);
                        result.push(command);
                    }
                    else if (name == "moveTo" && command.length >= 3)
                    {
                        previousX = Number(command[1]);
                        previousY = Number(command[2]);
                        result.push(command);
                    }
                    else if (name == "lineTo2" && command.length == 3)
                    {
                        previousX += Number(command[1]);
                        previousY += Number(command[2]);
                        result.push(["lineTo", previousX, previousY]);
                    }
                    else
                    {
                        result.push(command);
                        if (name == "lineTo" && command.length == 3)
                        {
                            previousX = Number(command[1]);
                            previousY = Number(command[2]);
                        }
                    }
                }
                output.writeObject(result);
            }
            output.position = 0;
            return output;
        }

        private function measureDrift(original:ByteArray, restored:ByteArray):Object
        {
            original.position = 0;
            restored.position = 0;
            var coordinates:uint = 0;
            var mismatches:uint = 0;
            var maxError:Number = 0;
            while (original.bytesAvailable > 0 && restored.bytesAvailable > 0)
            {
                const groupA:Array = original.readObject() as Array;
                const groupB:Array = restored.readObject() as Array;
                if (groupA.length != groupB.length)
                    throw new Error("Relative stream changed command count");
                for (var i:uint = 0; i < groupA.length; i++)
                {
                    if (groupA[i][0] != groupB[i][0])
                        throw new Error("Relative stream changed command name");
                    if (groupA[i][0] == "lineTo")
                    {
                        for (var j:uint = 1; j <= 2; j++)
                        {
                            coordinates++;
                            if (!sameNumber(Number(groupA[i][j]), Number(groupB[i][j])))
                            {
                                mismatches++;
                                maxError = Math.max(maxError, Math.abs(Number(groupA[i][j]) - Number(groupB[i][j])));
                            }
                        }
                    }
                }
            }
            original.position = 0;
            restored.position = 0;
            return {coordinates:coordinates, mismatches:mismatches, maxError:maxError};
        }

        private function sameNumber(a:Number, b:Number):Boolean
        {
            return a == b && (a != 0 || 1 / a == 1 / b);
        }

        private function measureSynthetic():void
        {
            const original:ByteArray = new ByteArray();
            original.writeObject([]);
            original.writeObject([["lineStyle5", false, 1, 0, 1, -17.25, 8.01, null, false, false, 0],
                    ["lineTo", -17.24, 8.02], ["lineTo", 1.23456789, -2.718281828],
                    ["lineTo", -0.0, 0.0], ["lineTo", 1073741824, -1073741824],
                    ["lasso2", [1, 2], {x:3, y:4}], ["drawDone5", false]]);
            original.position = 0;
            assertEqual(original, ReplayDataCodec.decode(ReplayDataCodec.encode(original)));
            assertEqual(original, fromRelativeStream(toRelativeStream(original, true)));
            trace("synthetic edge cases roundtrip=OK");
        }

        private function fromFile(file:File):ByteArray
        {
            const stream:FileStream = new FileStream();
            const bytes:ByteArray = new ByteArray();
            stream.open(file, FileMode.READ);
            stream.readBytes(bytes);
            stream.close();
            return bytes;
        }

        private function fromText(file:File):ByteArray
        {
            const stream:FileStream = new FileStream();
            stream.open(file, FileMode.READ);
            const lines:Array = stream.readUTFBytes(stream.bytesAvailable).split(/\r?\n/);
            stream.close();
            const bytes:ByteArray = new ByteArray();
            for each (var line:String in lines)
            {
                const split:int = line.indexOf(": ");
                if (split < 0) continue;
                const groups:Array = JSON.parse(line.substr(split + 2)) as Array;
                const commands:Array = [];
                for each (var group:Object in groups)
                {
                    for each (var command:Array in group.commands)
                    {
                        if (command[0] == "moveTo" && command.length > 3
                                && String(command[3]).indexOf("implicit from ") == 0)
                            continue;
                        commands.push(command);
                    }
                }
                bytes.writeObject(commands);
            }
            bytes.position = 0;
            return bytes;
        }

        private function copy(input:ByteArray):ByteArray
        {
            const value:ByteArray = new ByteArray();
            value.writeBytes(input);
            value.position = 0;
            return value;
        }

        private function countObjects(input:ByteArray):uint
        {
            input.position = 0;
            var count:uint = 0;
            while (input.bytesAvailable > 0)
            {
                input.readObject();
                count++;
            }
            input.position = 0;
            return count;
        }

        private function assertEqual(a:ByteArray, b:ByteArray):void
        {
            a.position = 0;
            b.position = 0;
            var objectIndex:uint = 0;
            while (a.bytesAvailable > 0 && b.bytesAvailable > 0)
            {
                compare(a.readObject(), b.readObject(), String(objectIndex));
                objectIndex++;
            }
            if (a.bytesAvailable != b.bytesAvailable)
                throw new Error("Object stream length differs");
            a.position = 0;
            b.position = 0;
        }

        private function compare(a:*, b:*, path:String):void
        {
            if (a is Array && b is Array)
            {
                if (a.length != b.length) throw new Error(path + " length differs");
                for (var i:uint = 0; i < a.length; i++)
                    compare(a[i], b[i], path + "/" + i);
            }
            else if (a is Number && b is Number)
            {
                if (isNaN(a) ? !isNaN(b) : Number(a) != Number(b))
                    throw new Error(path + " number differs: " + a + "/" + b);
                if (Number(a) == 0 && 1 / Number(a) != 1 / Number(b))
                    throw new Error(path + " signed zero differs");
            }
            else if (a is Object && b is Object)
            {
                if (JSON.stringify(a) != JSON.stringify(b))
                    throw new Error(path + " object differs");
            }
            else if (a !== b)
                throw new Error(path + " differs: " + a + "/" + b);
        }
    }
}
