package worker
{
    import Modules.L1Data.ReplayDataCodec;
    import Modules.L1Data.PixelRestore;
    import Modules.L1Data.CacheImageFormat;
    import flash.display.BitmapData;
    import flash.display.PNGEncoderOptions;
    import flash.display.Sprite;
    import flash.events.Event;
    import flash.filesystem.File;
    import flash.filesystem.FileMode;
    import flash.filesystem.FileStream;
    import flash.geom.Rectangle;
    import flash.net.registerClassAlias;
    import flash.system.MessageChannel;
    import flash.system.Worker;
    import flash.utils.ByteArray;

    [SWF(frameRate="2")]
    public class BackgroundImageProcessor extends Sprite
    {
        private var bgWorker:Worker;

        protected var mainToBack:MessageChannel;

        protected var backToMain:MessageChannel;

        private var cacheGeneration:ByteArray; // main과 공유하는 현재 캐시 세대 번호

        public function BackgroundImageProcessor()
        {
            super();
            registerClassAlias("CacheImageMetaData", CacheImageMetaDataRecord);
            this.bgWorker = Worker.current;
            this.mainToBack = this.bgWorker.getSharedProperty("mainToBack");
            this.mainToBack.addEventListener(Event.CHANNEL_MESSAGE, this.onFromMain);
            this.backToMain = this.bgWorker.getSharedProperty("backToMain");
            this.cacheGeneration = this.bgWorker.getSharedProperty("cacheGeneration");
        }

        private function encodePNG(ba:ByteArray, w:Number, h:Number, bg:uint, transBGFlag:Boolean, isCaptureImage:Boolean):void
        {
            var bmpd:BitmapData = new BitmapData(w, h, true, transBGFlag ? 0 : bg);
            var bmpd2:BitmapData = new BitmapData(w, h, true, 0);
            ba.position = 0;
            bmpd2.lock();
            // setPixels를 그대로 쓰면 반투명 픽셀이 1씩 어두워져서 PNG도 어두워짐
            PixelRestore.setPixels(bmpd2, new Rectangle(0, 0, w, h), ba);
            bmpd2.unlock();
            bmpd.draw(bmpd2);
            ba.clear();
            bmpd.encode(new Rectangle(0, 0, w, h), new PNGEncoderOptions(), ba);
            if (isCaptureImage)
            {
                this.backToMain.send("encodePNGCaptureDone");
            }
            else
            {
                this.backToMain.send("encodePNGSaveDone");
            }
            this.backToMain.send(ba);
            ba.clear();
            ba = null;
        }

        // 캐시 이미지를 압축해서 main이 알려준 임시 파일에 씀
        // 성공, 취소, 실패 모두 응답해줘야 main의 작업 카운트와 대기열이 맞음
        private function compressUndoData(jobId:int, generation:int, path:String, metadata:Object, layer1:ByteArray, layer2:ByteArray):void
        {
            var result:String;

            try
            {
                result = writeCacheImage(generation, path, metadata, layer1, layer2);
            }
            catch (error:Error)
            {
                result = "error:" + error.message;
            }

            layer1.clear();
            layer2.clear();
            this.backToMain.send("compress_UndoDataDone");
            this.backToMain.send(jobId);
            this.backToMain.send(result);
        }

        private function writeCacheImage(generation:int, path:String, metadata:Object, layer1:ByteArray, layer2:ByteArray):String
        {
            if (isCacheGenerationChanged(generation))
                return "cancelled:0";

            const copy1:ByteArray = copyLayer(layer1);
            const copy2:ByteArray = copyLayer(layer2);
            // 새 캐시 형식 (Modules.CacheImageFormat, straight + zlib), 메타데이터는 alias "CacheImageMetaData"로 써서 main에서 CacheImageMetaData로 읽힘
            const metadataBytes:ByteArray = new ByteArray();
            metadataBytes.writeObject(metadata);
            const encoded:ByteArray = CacheImageFormat.encodeStraight(copy1, copy2, metadata.bmpdWidth, metadata.bmpdHeight, metadataBytes);
            copy1.clear();
            copy2.clear();

            if (isCacheGenerationChanged(generation))
            {
                encoded.clear();
                return "cancelled:1";
            }

            const fs:FileStream = new FileStream();

            try
            {
                fs.open(new File(path), FileMode.WRITE);
                fs.writeBytes(encoded);
            }
            finally
            {
                fs.close();
                encoded.clear();
            }

            return "done";
        }

        // shareable ByteArray는 compress를 못해서(Error #3735) worker 메모리로 복사, 원본은 복사 직후 바로 놓음
        private function copyLayer(source:ByteArray):ByteArray
        {
            const copy:ByteArray = new ByteArray();
            copy.writeBytes(source);
            source.clear();
            return copy;
        }

        private function isCacheGenerationChanged(generation:int):Boolean
        {
            // 값이 0일때만 0을 다시 쓰므로 main의 값은 바뀌지 않고 현재 값만 원자적으로 읽어옴
            return this.cacheGeneration.atomicCompareAndSwapIntAt(0, 0, 0) !== generation;
        }

        // replaySegmentInfo가 있으면 세그먼트 형식: repdata 조각 캐시 조각(압축 crc 확인) + ba6(캐시 뒤 부분 + 메모리 뭉치)을 조각으로 인코드해서 이어 붙임
        // 캐시 조각이 깨졌거나 ba6를 조각으로 인코드하지 못하면 "segment-cache-failed" (캐시 앞부분이 있으면 ba6가 리플레이 전체가 아니라 zlib로 대신 쓸 수 없음)
        // replaySegmentInfo가 null이면 이전 방식: ba6 전체를 한 덩어리로 인코드, 복원 결과가 원본과 다르면 기존 zlib
        private function compressReplayData(ba1:ByteArray, ba2:ByteArray, ba3:ByteArray, ba4:ByteArray, ba5:ByteArray, ba6:ByteArray, replaySegmentInfo:Object):void
        {
            ba1.compress();
            ba2.compress();
            ba3.compress();
            ba4.compress();
            ba5.compress();
            var segmentSaveStatus:String = "whole";

            if (replaySegmentInfo !== null)
            {
                const segmentedBlock:ByteArray = encodeSegmentedReplayBlock(ba6, replaySegmentInfo);
                if (segmentedBlock !== null)
                {
                    ba6.clear();
                    ba6.writeBytes(segmentedBlock);
                    ba6.position = 0;
                    segmentedBlock.clear();
                    segmentSaveStatus = "segment";
                }
                else if (replaySegmentInfo.cachedSegments.length > 0)
                {
                    ba6.clear();
                    segmentSaveStatus = "segment-cache-failed";
                }
            }

            if (segmentSaveStatus === "whole")
            {
                // 리플레이 명령은 전용 변환(LZMA 포함)으로 저장하고, 복원 결과가 원본과 다르면 기존 zlib으로 저장
                const encoded:ByteArray = ReplayDataCodec.encodeVerified(ba6);
                if (encoded != null)
                {
                    ba6.clear();
                    ba6.writeBytes(encoded);
                    ba6.position = 0;
                    encoded.clear();
                }
                else
                {
                    ba6.compress();
                }
            }
            this.backToMain.send("compress_ReplayDataDone");
            this.backToMain.send(ba1);
            this.backToMain.send(ba2);
            this.backToMain.send(ba3);
            this.backToMain.send(ba4);
            this.backToMain.send(ba5);
            this.backToMain.send(ba6);
            this.backToMain.send(segmentSaveStatus);
            ba1.clear();
            ba2.clear();
            ba3.clear();
            ba4.clear();
            ba5.clear();
            ba6.clear();
            ba1 = null;
            ba2 = null;
            ba3 = null;
            ba4 = null;
            ba5 = null;
            ba6 = null;
        }

        // repdata 조각 캐시 조각(압축 crc가 맞는지 확인) + tailReplay를 조각으로 인코드한 것을 세그먼트 형식 블록으로, 못하면 null
        private function encodeSegmentedReplayBlock(tailReplay:ByteArray, replaySegmentInfo:Object):ByteArray
        {
            const segments:Array = [];
            const cachedSegments:Array = replaySegmentInfo.cachedSegments;
            const cachedSegmentBytes:Array = replaySegmentInfo.cachedSegmentBytes;

            for (var i:int = 0; i < cachedSegments.length; i++)
            {
                const compressed:ByteArray = cachedSegmentBytes[i] as ByteArray;
                if (compressed === null || ReplayDataCodec.crc32OfBytes(compressed, 0, compressed.length) !== cachedSegments[i].compressedCrc)
                {
                    trace("Replay segment cache " + i + " is broken");
                    return null;
                }
                segments.push({ rawLength: cachedSegments[i].rawLength, rawCrc: cachedSegments[i].rawCrc, compressed: compressed, compressedCrc: cachedSegments[i].compressedCrc });
            }

            const tailSegments:Array = ReplayDataCodec.encodeReplaySegments(tailReplay, replaySegmentInfo.tailStartFrames, false);
            if (tailSegments === null)
                return null;

            const block:ByteArray = ReplayDataCodec.assembleSegmentedBlock(segments.concat(tailSegments));
            for each (var segment:Object in segments.concat(tailSegments))
                ByteArray(segment.compressed).clear();
            return block;
        }

        // repdata 조각 캐시 채우기: replayBytes를 조각으로 나눠 닫힌 조각만 인코드하고 folderPath에 조각마다 파일로 씀 (임시 파일에 쓰고 교체)
        // 결과: [{fileName, rawLength, rawCrc, compressedLength, compressedCrc, endFrames}] 또는 실패면 null (main ReplaySegmentCache.finishWorkerSegmentCacheFill)
        private function encodeReplaySegmentsToCacheFiles(jobId:int, replayBytes:ByteArray, replayStartFrames:Number, folderPath:String, segmentFileNamePrefix:String, firstSegmentNumber:int):void
        {
            const start:Number = new Date().time;
            var results:Array = null;
            var encodedTime:Number = start;
            const replay:ByteArray = new ByteArray();
            replay.writeBytes(replayBytes);
            replayBytes.clear();

            try
            {
                const segments:Array = ReplayDataCodec.encodeReplaySegments(replay, replayStartFrames, true);
                encodedTime = new Date().time;
                if (segments !== null)
                {
                    results = [];
                    for (var i:int = 0; i < segments.length; i++)
                    {
                        const fileName:String = segmentFileNamePrefix + (firstSegmentNumber + i);
                        const file:File = new File(folderPath).resolvePath(fileName);
                        const tempFile:File = new File(folderPath).resolvePath(fileName + ".tmp");
                        const fs:FileStream = new FileStream();
                        try
                        {
                            fs.open(tempFile, FileMode.WRITE);
                            fs.writeBytes(segments[i].compressed);
                        }
                        finally
                        {
                            fs.close();
                        }
                        tempFile.moveTo(file, true);
                        results.push({ fileName: fileName, rawLength: segments[i].rawLength, rawCrc: segments[i].rawCrc, compressedLength: segments[i].compressed.length,
                                compressedCrc: segments[i].compressedCrc, endFrames: segments[i].endFrames });
                        segments[i].compressed.clear();
                    }
                }
            }
            catch (error:Error)
            {
                trace("Replay segment cache fill failed: " + error);
                results = null;
            }

            replay.clear();
            this.backToMain.send("encode_ReplaySegmentsDone");
            this.backToMain.send(jobId);
            this.backToMain.send(results);
            this.backToMain.send(encodedTime - start);
            this.backToMain.send(new Date().time - encodedTime);
        }

        private function onFromMain(event:Event):void
        {
            handleCommand(this.mainToBack.receive() as String);
        }

        protected function handleCommand(command:String):void
        {
            switch (command)
            {
                case "encodePNG":
                    this.encodePNG(this.mainToBack.receive(true), this.mainToBack.receive(true), this.mainToBack.receive(true), this.mainToBack.receive(true), this.mainToBack.receive(true), this.mainToBack.receive(true));
                    break;
                case "compress_ReplayData":
                    this.compressReplayData(this.mainToBack.receive(true), this.mainToBack.receive(true), this.mainToBack.receive(true), this.mainToBack.receive(true), this.mainToBack.receive(true), this.mainToBack.receive(true), this.mainToBack.receive(true));
                    break;
                case "encode_ReplaySegments":
                    this.encodeReplaySegmentsToCacheFiles(this.mainToBack.receive(true), this.mainToBack.receive(true), this.mainToBack.receive(true), this.mainToBack.receive(true), this.mainToBack.receive(true), this.mainToBack.receive(true));
                    break;
                case "compress_UndoData":
                    this.compressUndoData(this.mainToBack.receive(true), this.mainToBack.receive(true), this.mainToBack.receive(true), this.mainToBack.receive(true), this.mainToBack.receive(true), this.mainToBack.receive(true));
            }
        }
    }
}
