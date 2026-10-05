package Modules.ReplayEngine
{
    import Modules.AppStateManager;
    import flash.filesystem.File;
    import flash.filesystem.FileMode;
    import flash.filesystem.FileStream;
    import flash.utils.ByteArray;

    // repdata 파일에 들어있는 프레임(명령)마다의 시간 간격(ms)을 uint 하나씩 그대로 이어 쓴 파일
    // 프레임 i의 위치는 i * 4 바이트라서 구간만 바로 읽을수 있고, repdata에 묶음을 붙이는 때 같이 붙임
    // .fofo 파일에 저장할때는 TimingSheet로 구간별 압축해서 씀
    // 한 프레임의 값은 직전 프레임과의 간격이고 첫 프레임이나 시계가 끊긴 직후(앱 재시작, 자르기)의 값은 0
    public final class TimingJournal
    {
        private static var lastStamp:int = 0; // 마지막으로 파일에 쓴 프레임의 getTimer 값
        private static var hasLastStamp:Boolean = false;

        // 파일이 없으면 만들지 않고 비어있는 것으로 봄
        public static function get frameCount():Number
        {
            const file:File = AppStateManager.timingDataFilePath;
            return file.exists ? Math.floor(file.size / 4) : 0;
        }

        public static function reset():void
        {
            const fs:FileStream = new FileStream();
            fs.open(AppStateManager.timingDataFilePath, FileMode.WRITE);
            fs.close();
            hasLastStamp = false;
        }

        // 마지막 프레임의 시각을 잊게 해서 다음 프레임의 간격을 0으로 만듬 (시계가 끊긴 직후)
        public static function breakClock():void
        {
            hasLastStamp = false;
        }

        public static function getLastStamp():Object
        {
            return {has: hasLastStamp, stamp: lastStamp};
        }

        public static function setLastStamp(has:Boolean, stamp:int):void
        {
            hasLastStamp = has;
            lastStamp = stamp;
        }

        // 파일이 frame개의 프레임만 가지도록 모자라면 0으로 채우고 남으면 자름
        // repdata와 길이가 어긋난 채로 이어 붙이지 않게 붙이기 직전에 부름
        public static function alignTo(frame:Number):void
        {
            const file:File = AppStateManager.timingDataFilePath;
            const now:Number = frameCount;

            if (now === frame)
            {
                return;
            }

            const fs:FileStream = new FileStream();

            if (now > frame)
            {
                fs.open(file, FileMode.UPDATE);
                fs.position = frame * 4;
                fs.truncate();
                fs.close();
                return;
            }

            fs.open(file, FileMode.APPEND);

            for (var i:Number = now; i < frame; i++)
            {
                fs.writeUnsignedInt(0);
            }

            fs.close();
        }

        // 묶음 하나의 명령들의 getTimer 값을 간격으로 바꿔서 이어 붙임. 앞 프레임까지 길이를 맞춘 다음에 씀
        public static function appendGroup(stamps:Array, firstFrame:Number):void
        {
            alignTo(firstFrame);

            const fs:FileStream = new FileStream();
            fs.open(AppStateManager.timingDataFilePath, FileMode.APPEND);

            for (var i:int = 0; i < stamps.length; i++)
            {
                const stamp:int = stamps[i];
                var delta:int = 0;

                if (hasLastStamp)
                {
                    delta = (stamp - lastStamp) | 0; // 값이 넘쳐도 차이는 맞게 나옴

                    if (delta < 0)
                    {
                        delta = 0;
                    }
                }

                fs.writeUnsignedInt(uint(delta));
                lastStamp = stamp;
                hasLastStamp = true;
            }

            fs.close();
        }

        // frame개 이후를 자름 (뒤 자르기)
        public static function truncateAfter(frame:Number):void
        {
            if (frameCount > frame)
            {
                alignTo(frame);
            }

            hasLastStamp = false;
        }

        // 앞의 frame개를 자르고 남은 첫 프레임의 간격을 0으로 함 (앞 자르기)
        public static function cutBefore(frame:Number):void
        {
            const file:File = AppStateManager.timingDataFilePath;
            hasLastStamp = false;

            if (frame <= 0)
            {
                return;
            }

            if (frameCount <= frame)
            {
                reset();
                return;
            }

            const fs:FileStream = new FileStream();
            const rest:ByteArray = new ByteArray();
            fs.open(file, FileMode.READ);
            fs.position = frame * 4;
            fs.readBytes(rest, 0, fs.bytesAvailable);
            fs.close();

            rest.position = 0;
            rest.writeUnsignedInt(0);

            fs.open(file, FileMode.WRITE);
            fs.writeBytes(rest, 0, rest.length);
            fs.close();
            rest.clear();
        }

        // firstFrame부터 count개의 간격을 읽음. 파일에 모자란 부분은 0
        public static function readRange(firstFrame:Number, count:int):Vector.<uint>
        {
            const result:Vector.<uint> = new Vector.<uint>(count, true);
            const file:File = AppStateManager.timingDataFilePath;

            if (!file.exists)
            {
                return result;
            }

            const available:Number = Math.max(0, Math.min(count, frameCount - firstFrame));

            if (available === 0)
            {
                return result;
            }

            const fs:FileStream = new FileStream();
            fs.open(file, FileMode.READ);
            fs.position = firstFrame * 4;

            for (var i:int = 0; i < available; i++)
            {
                result[i] = fs.readUnsignedInt();
            }

            fs.close();
            return result;
        }
    }
}
