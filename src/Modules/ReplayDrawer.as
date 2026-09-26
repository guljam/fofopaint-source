package Modules
{
    public class ReplayDrawer
    {
        public static const JUMP_FRAME_PLAY:int = (1 << 0); // 그냥 재생할때
        public static const JUMP_FRAME_MANUAL:int = (1 << 1); // 탐색바에서 마우스 특정 프레임 클릭
        public static const JUMP_FRAME_PREV:int = (1 << 2); // 이전 프레임으로 이동 (프레임 감소)
        public static const JUMP_FRAME_NEXT:int = (1 << 3); // 이후 프레임으로 이동 (프레임 증가)

        public static var rNowFrame:Number = 0; // dodraw에서 현재까지 플레이된 프레임수 누적, jump frame이 가동됐을때 프레임 누적갯수를 세서 썸네일 이미지 만들어줌
        public static var rPrevFrame:Number = 0; // jump one frame 에서 이전 프레임 탐색할때 이 프레임으로 탐색해줌 tickdraw에서 data 끝의 프레임을 저장함

        private static var readCount:Number = 0;
        private static var rMemoryDataLen:uint;
        public static var rMemoryDataReadON:Boolean = true; // rData읽을때는 true, rfile 읽을때는 false
        public static var rMemoryDataStartIndex:int = 0; // 리플레이에서 프레임 스캡을 앞부분으로 해줄때 rdata를 읽는 부분이면 현재 undoindex부분 부터 읽게 인덱스를 올려줌
        public static var rMemoryDataIndex:int = 0; // rData에서만씀 rData 스크로크 뭉치 인덱스
        public static var rFileLastBytePosition:Number = 0; // fs position 저장
        private static var rFileCutBytePosition:Number = 0; // super undo에서 파일 잘라줄때 필요함

        public static function makeMemoryCacheImage(completedStepStartFrame:Number):void
        {
            ReplayController.createRFrameTempCache(completedStepStartFrame, rFileCutBytePosition);
        }

        public static function readyToReadMemoryData(jumpFlag:int):void
        {
            rMemoryDataReadON = true;
            rMemoryDataIndex = rMemoryDataStartIndex;
            rMemoryDataStartIndex = 0;
            rMemoryDataLen = ReplayController.rMemoryData.length;

            if (jumpFlag === JUMP_FRAME_PLAY)
            {
                 ReplayController.rFileStream.close();
            }

            if ( ReplayController.rMemoryData.length > 0)
            {
                rPrevFrame = rNowFrame;
                ReplayDrawCommands.setData(ReplayController.rMemoryData[rMemoryDataIndex]);
            }
            else
            {
                ReplayDrawCommands.clearData();
            }
        }

        public static function readNextFileData():Boolean
        {
            if (ReplayController.rFileStream.bytesAvailable > 0)
            {
                const obj:Array = ReplayController.rFileStream.readObject() as Array;

                if (!obj)
                    return true;
                ReplayDrawCommands.setData(obj);
                rFileCutBytePosition = rFileLastBytePosition;
                rFileLastBytePosition = ReplayController.rFileStream.position;
                rPrevFrame = rNowFrame;
                return true;
            }

            return false;
        }

        public static function checkFinish(jumpFlag:int):Boolean
        {
            if (rMemoryDataIndex >= rMemoryDataLen || rMemoryDataLen === 0) // 자연적으로 끝났을때
            {
                ReplayController.rReplayFOFOCursor.visible = false;
                ReplayController.isReplayFinished = true;

                if (jumpFlag === JUMP_FRAME_PLAY || ReplayController.isReplaySlideShowMode === true) // 1프레임 이상일때만 재시작 타이머 가동
                {
                    // reset replay time해주지 말고 그냥 end플래그만 올려줌
                    // 왜냐하면 리플레이 자연적으로 끝나고도 스킵프레임이나 oneframe jump을 해줄수가 있기 때문
                    ReplayController.stopReplay();
                    return true;
                }
            }

            return false;
        }

        public static function drawFromMemoryData(len:Number, jumpFlag:int):void
        {
            for (var i:Number = 0;i < len;i++)
            {
                if (ReplayDrawCommands.isReadFinished())
                {
                    rMemoryDataIndex++;

                    if (checkFinish(jumpFlag))
                    {
                        return;
                    }

                    rPrevFrame = rNowFrame;
                    ReplayDrawCommands.setData(ReplayController.rMemoryData[rMemoryDataIndex]);
                }

                ReplayDrawCommands.drawNext();
                rNowFrame++;
            }
        }

        public static function drawFromFileData(len:Number, jumpFlag:int):void
        {
            for (var i:Number = 0;i < len;i++)
            {
                if (ReplayDrawCommands.isReadFinished())
                {
                    const completedStepStartFrame:Number = rPrevFrame;
                    if (readNextFileData() === false)
                    {
                        // 더이상 읽을 데이터가 없을때 메모리읽기로 넘겨줌
                        readyToReadMemoryData(jumpFlag);
                        return;
                    }

                    if (ReplayController.isReplayStarted === false && (jumpFlag === JUMP_FRAME_MANUAL || jumpFlag === JUMP_FRAME_PREV))
                    {
                        if (rNowFrame > ReplayController.getRFrameTempCacheLastFrame() + ReplayController.REPLAY_MEMORY_CACHE_FRAME_INTERVAL)
                        {
                            makeMemoryCacheImage(completedStepStartFrame);
                        }
                    }
                }

                ReplayDrawCommands.drawNext();
                rNowFrame++;
                readCount--;
            }
        }

        public static function start(commandCount:Number, jumpFlag:int):void
        {
            if (commandCount > 0)
            {
                readCount = commandCount;

                if (!rMemoryDataReadON)
                {
                    // readcount 감소
                    drawFromFileData(commandCount, jumpFlag);
                }

                if (readCount > 0)
                {
                    // readcount를 읽어줌
                    drawFromMemoryData(readCount, jumpFlag);
                }
            }
        }
    }
}
