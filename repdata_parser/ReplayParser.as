package
{
    import Modules.ReplayDataCodec;
    import flash.desktop.NativeApplication;
    import flash.display.Sprite;
    import flash.events.InvokeEvent;
    import flash.filesystem.File;
    import flash.filesystem.FileMode;
    import flash.filesystem.FileStream;
    import flash.net.ObjectEncoding;
    import flash.utils.ByteArray;
    import flash.utils.CompressionAlgorithm;
    import flash.utils.describeType;
    import flash.utils.getQualifiedClassName;

    public class ReplayParser extends Sprite
    {
        private static const HEADER:String = "FOFOPAINT";

        public function ReplayParser()
        {
            NativeApplication.nativeApplication.addEventListener(InvokeEvent.INVOKE, start);
        }

        private function start(event:InvokeEvent):void
        {
            NativeApplication.nativeApplication.removeEventListener(InvokeEvent.INVOKE, start);
            try
            {
                const args:Array = event.arguments;
                if (args.length < 2)
                    throw new Error("Usage: ReplayParser <input.2020|repdata> <output-directory>");
                const source:File = new File(args[0]);
                const output:File = new File(args[1]);
                if (!source.exists || source.isDirectory)
                    throw new Error("Input file does not exist: " + source.nativePath);
                output.createDirectory();
                if (source.extension && source.extension.toLowerCase() == "txt")
                {
                    const existingPage:File = output.resolvePath("index.html");
                    writeText(existingPage, makeHtml(source));
                    trace("HTML " + existingPage.nativePath);
                    NativeApplication.nativeApplication.exit(0);
                    return;
                }
                const objects:Array = readReplayObjects(source);
                const textFile:File = output.resolvePath(source.name + ".txt");
                writeText(textFile, makeText(objects));
                const page:File = output.resolvePath("index.html");
                writeText(page, makeHtml(textFile)); // Read the saved text back as the sole HTML input.
                trace("OK objects=" + objects.length + " frames=" + countFrames(objects));
                trace("TXT " + textFile.nativePath);
                trace("HTML " + page.nativePath);
                NativeApplication.nativeApplication.exit(0);
            }
            catch (error:Error)
            {
                trace("ERROR " + error.message);
                NativeApplication.nativeApplication.exit(1);
            }
        }

        private static function readReplayObjects(source:File):Array
        {
            const stream:FileStream = new FileStream();
            stream.objectEncoding = ObjectEncoding.AMF3;
            stream.open(source, FileMode.READ);
            const objects:Array = [];
            try
            {
                if (source.extension && source.extension.toLowerCase() == "2020" && stream.bytesAvailable >= 13)
                {
                    if (stream.readUTFBytes(9) == HEADER)
                    {
                        const length:uint = stream.readUnsignedInt();
                        if (length > stream.bytesAvailable)
                            throw new Error("Invalid compressed data length: " + length);
                        if (length > 0)
                        {
                            const packed:ByteArray = new ByteArray();
                            stream.readBytes(packed, 0, length);
                            packed.uncompress(CompressionAlgorithm.ZLIB);
                            if (ReplayDataCodec.isEncoded(packed))
                            {
                                const decoded:ByteArray = ReplayDataCodec.decode(packed);
                                packed.clear();
                                packed.writeBytes(decoded);
                            }
                            packed.position = 0;
                            packed.objectEncoding = ObjectEncoding.AMF3;
                            readObjectStream(packed, objects, "compressed replay");
                            // Exercise AIR's matching native compressor and verify lossless round-trip.
                            const check:ByteArray = new ByteArray();
                            check.writeBytes(packed);
                            check.compress(CompressionAlgorithm.ZLIB);
                            check.uncompress(CompressionAlgorithm.ZLIB);
                            if (check.length != packed.length)
                                throw new Error("AIR compression round-trip failed");
                            for (var byteIndex:uint = 0; byteIndex < packed.length; byteIndex++)
                                if (check[byteIndex] != packed[byteIndex])
                                    throw new Error("AIR compression round-trip changed byte " + byteIndex);
                        }
                    }
                    else
                    {
                        stream.position = 0; // Headerless legacy .2020 stream.
                    }
                }
                if (stream.bytesAvailable > 0)
                    readObjectStream(stream, objects, "file");
            }
            finally
            {
                stream.close();
            }
            if (objects.length == 0)
                throw new Error("No replay command objects found");
            return objects;
        }

        private static function readObjectStream(input:*, objects:Array, label:String):void
        {
            while (input.bytesAvailable > 0)
            {
                const offset:uint = input.position;
                var value:*;
                try { value = input.readObject(); }
                catch (error:Error)
                {
                    throw new Error(label + " AMF3 read failed at byte " + offset + ": " + error.message);
                }
                if (!(value is Array))
                    throw new Error(label + " object at byte " + offset + " is not an Array");
                const array:Array = value as Array;
                if (array.length > 0 && array[0] is String && isImageRecord(String(array[0])))
                    continue;
                if (array.length == 0)
                    continue;
                for each (var command:* in array)
                {
                    if (!(command is Array) || (command as Array).length == 0 || !((command as Array)[0] is String))
                        throw new Error(label + " object at byte " + offset + " has an invalid command");
                }
                objects.push(array);
            }
        }

        private static function isImageRecord(name:String):Boolean
        {
            return name == "rFirstImage" || name == "rFinalImage" || name == "refimage" || name == "traceImage";
        }

        private static function countFrames(objects:Array):uint
        {
            var result:uint = 0;
            for each (var object:Array in objects) result += object.length;
            return result;
        }

        private static function makeText(objects:Array):String
        {
            const lines:Array = [];
            var frame:uint = 1;
            for each (var object:Array in objects)
            {
                const groups:Array = [];
                var stroke:Array = null;
                for each (var raw:Array in object)
                {
                    const command:Array = normalize(raw, [] ) as Array;
                    const name:String = String(raw[0]);
                    if (name.indexOf("lineStyle") == 0)
                    {
                        if (stroke == null)
                        {
                            stroke = [];
                            groups.push({type:"stroke", commands:stroke});
                        }
                        stroke.push(command);
                        // lineStyle contains the implicit graphics.moveTo coordinates.
                        if (raw.length > 6)
                            stroke.push(["moveTo", raw[5], raw[6], "implicit from " + name]);
                    }
                    else if (stroke != null)
                    {
                        stroke.push(command);
                        if (name.indexOf("drawDone") == 0)
                            stroke = null;
                    }
                    else
                    {
                        groups.push({type:"command", commands:[command]});
                    }
                }
                lines.push(frame + ": " + JSON.stringify(groups));
                frame += object.length;
            }
            return lines.join("\n") + "\n";
        }

        private static function normalize(value:*, parents:Array):*
        {
            if (value == null || value is String || value is Boolean)
                return value;
            if (value is Number || value is int || value is uint)
                return isFinite(Number(value)) ? value : String(value);
            if (value is ByteArray)
                return {$type:"ByteArray", length:(value as ByteArray).length, base64:base64(value as ByteArray)};
            if (parents.indexOf(value) >= 0)
                return {$ref:"circular"};
            parents.push(value);
            var result:*;
            if (value is Array || getQualifiedClassName(value).indexOf("__AS3__.vec::Vector") == 0)
            {
                result = [];
                for each (var item:* in value)
                    result.push(normalize(item, parents));
            }
            else
            {
                result = {};
                const typeName:String = getQualifiedClassName(value);
                if (typeName != "Object") result.$type = typeName;
                if (value is Date)
                {
                    result.time = (value as Date).time;
                }
                else
                {
                    const description:XML = describeType(value);
                    for each (var variable:XML in description.variable)
                    {
                        var field:String = String(variable.@name);
                        result[field] = normalize(value[field], parents);
                    }
                    for each (var accessor:XML in description.accessor)
                    {
                        if (String(accessor.@access) == "writeonly") continue;
                        field = String(accessor.@name);
                        try { result[field] = normalize(value[field], parents); }
                        catch (error:Error) { result[field] = {$error:error.message}; }
                    }
                }
                for (var key:String in value)
                    result[key] = normalize(value[key], parents);
            }
            parents.pop();
            return result;
        }

        private static function base64(bytes:ByteArray):String
        {
            const chars:String = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
            var output:String = "";
            for (var i:uint = 0; i < bytes.length; i += 3)
            {
                const a:uint = bytes[i], b:uint = i + 1 < bytes.length ? bytes[i + 1] : 0;
                const c:uint = i + 2 < bytes.length ? bytes[i + 2] : 0;
                output += chars.charAt(a >> 2) + chars.charAt(((a & 3) << 4) | (b >> 4));
                output += i + 1 < bytes.length ? chars.charAt(((b & 15) << 2) | (c >> 6)) : "=";
                output += i + 2 < bytes.length ? chars.charAt(c & 63) : "=";
            }
            return output;
        }

        private static function writeText(file:File, content:String):void
        {
            const stream:FileStream = new FileStream();
            stream.open(file, FileMode.WRITE);
            try { stream.writeUTFBytes(content); }
            finally { stream.close(); }
        }

        private static function readText(file:File):String
        {
            const stream:FileStream = new FileStream();
            stream.open(file, FileMode.READ);
            var value:String;
            try { value = stream.readUTFBytes(stream.bytesAvailable); }
            finally { stream.close(); }
            return value;
        }

        private static function makeHtml(textFile:File):String
        {
            const lines:Array = readText(textFile).split(/\r?\n/);
            const rows:Array = [];
            var total:uint = 0;
            for each (var line:String in lines)
            {
                if (line.length == 0) continue;
                var colon:int = line.indexOf(": ");
                if (colon < 0) throw new Error("Invalid text line: " + line.substr(0, 60));
                var frame:uint = uint(line.substring(0, colon));
                var groups:Array = JSON.parse(line.substr(colon + 2)) as Array;
                if (!groups) throw new Error("Invalid group JSON at frame " + frame);
                const cards:Array = [];
                var commandFrame:uint = frame;
                for each (var group:Object in groups)
                {
                    var commands:Array = [];
                    for each (var command:Array in group.commands)
                    {
                        var name:String = String(command[0]);
                        var args:String = JSON.stringify(command.slice(1));
                        var derived:Boolean = name == "moveTo" && command.length > 3 && String(command[3]).indexOf("implicit from ") == 0;
                        var displayFrame:uint = derived ? commandFrame - 1 : commandFrame;
                        commands.push('<div class="command' + (derived ? ' derived' : '') + '" data-frame="' + displayFrame + '" tabindex="0" role="button" aria-expanded="false"><span class="cmd-frame">(' + displayFrame + ')</span> <span class="cmd-name">' + escapeHtml(name) + '</span><div class="command-args" hidden><pre>' + escapeHtml(args) + '</pre></div></div>');
                        if (!derived) commandFrame++;
                        total++;
                    }
                    cards.push('<div class="group ' + (group.type == "stroke" ? "stroke" : "") + '"><div class="group-title">' + (group.type == "stroke" ? "펜 스트로크" : "개별 명령") + '</div><div class="command-list">' + commands.join("") + '</div></div>');
                }
                rows.push('<section class="frame" data-start="' + frame + '" data-end="' + (commandFrame - 1) + '"><div class="frame-label">프레임 <strong>' + frame + '</strong></div><div class="groups">' + cards.join("") + '</div></section>');
            }
            const template:File = File.applicationDirectory.resolvePath("viewer-template.html");
            if (!template.exists) throw new Error("HTML template not found: " + template.nativePath);
            return readText(template).replace("{{SOURCE}}", escapeHtml(textFile.name))
                .replace("{{OBJECT_COUNT}}", String(rows.length))
                .replace("{{ITEM_COUNT}}", String(total))
                .replace("{{ROWS}}", rows.join(""));
        }

        private static function escapeHtml(value:String):String
        {
            return value.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/"/g, "&quot;").replace(/'/g, "&#39;");
        }
    }
}
