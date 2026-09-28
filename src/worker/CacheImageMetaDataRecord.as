package worker
{
    // main의 Modules.CacheImageMetaData와 같은 alias로 등록해서 worker도 같은 형식으로 캐시 파일을 쓰게 해줌
    // Modules.CacheImageMetaData는 ReplayDrawCommands를 참조해서 worker에 넣을 수 없음, 필드가 바뀌면 여기도 같이 바꿔야함
    public class CacheImageMetaDataRecord
    {
        public var bmpdWidth:Number;
        public var bmpdHeight:Number;
        public var bgColor:uint;
        public var lastByte:Number;
        public var lastFrame:Number;
        public var nowFrame:Number;
        public var mirrorFlag:Boolean;
        public var rCursorPosX:Number;
        public var rCursorPosY:Number;
    }
}
