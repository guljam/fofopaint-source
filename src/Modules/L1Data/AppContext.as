package Modules.L1Data
{
    import flash.display.Stage;

    // 층: L1 데이터 - 앱 전역에서 쓰는 stage와 버전 정보. Main이 시작할 때 한 번 채우고, 아래층은 Main 타입을 알 필요 없이 여기서 읽음
    public class AppContext
    {
        public static var stage:Stage;
        public static var appVersion:String;
        public static var appStateVersion:String;
        public static var titleString:String;
    }
}
