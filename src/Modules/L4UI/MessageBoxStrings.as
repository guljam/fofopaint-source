package Modules.L4UI
{
    import Modules.L2Engine.ReplayEngine.ReplayFileCache;

    // 층: L4 UI - 메시지 상자(MessageBoxController) 문구 모음. 고정 문구는 상수, 값을 이어 붙이는 문구는 get~String 메서드
    public class MessageBoxStrings
    {
        public static const STRING_ALREADY_SAVED:String = "Already saved";
        public static const STRING_UNKNOWN_ERROR:String = "An unknown error occurred.";

        // 리플레이 파일 저장 완료 문구 "File saved : 파일명 (크기)" (네이티브·worker 공통), isRenamed면 원래 파일이 잡혀 있어 다른 이름으로 저장했다는 말을 덧붙임
        public static function getReplayFileSavedString(savedFileName:String, fileSize:Number, isRenamed:Boolean = false):String
        {
            const sizeText:String = (isNaN(fileSize) || fileSize <= 0) ? "" : " (" + ReplayFileCache.formatFileSize(fileSize) + ")";
            return "File saved : " + savedFileName + sizeText + (isRenamed ? " _ original file was in use" : "");
        }

        // 리플레이 파일 쓰기 실패 문구, win32 오류 코드를 이유로 바꿔 붙임
        public static function getReplayFileSaveFailedString(win32ErrorCode:int):String
        {
            return "Save failed: " + getWriteErrorReasonString(win32ErrorCode);
        }

        // 캡처 이미지 PNG 저장 완료 문구 (네이티브·worker 공통)
        public static function getCaptureImageSavedString(fileName:String, fileSize:Number):String
        {
            return "Image saved : \"" + fileName + "\"" + getFileSizeSuffixString(fileSize);
        }

        // 캡처 이미지 PNG 쓰기 실패 문구, win32 오류 코드를 이유로 바꿔 붙임
        public static function getCaptureImageSaveFailedString(win32ErrorCode:int):String
        {
            return "Capture save failed: " + getWriteErrorReasonString(win32ErrorCode);
        }

        // 문구 뒤에 붙이는 ", 크기". 크기를 모르면 쉼표까지 통째로 뺌
        private static function getFileSizeSuffixString(bytes:Number):String
        {
            return (isNaN(bytes) || bytes <= 0) ? "" : ", " + ReplayFileCache.formatFileSize(bytes);
        }

        // 네이티브 저장이 돌려준 win32 쓰기 오류 코드를 사용자에게 보여줄 이유 문구로 바꿈
        private static function getWriteErrorReasonString(win32ErrorCode:int):String
        {
            switch (win32ErrorCode)
            {
                case 2: // ERROR_FILE_NOT_FOUND
                case 3: // ERROR_PATH_NOT_FOUND
                    return "folder not found";
                case 5: // ERROR_ACCESS_DENIED
                    return "no permission";
                case 39: // ERROR_HANDLE_DISK_FULL
                case 112: // ERROR_DISK_FULL
                    return "disk is full";
                case 123: // ERROR_INVALID_NAME
                    return "invalid file name";
                default:
                    return "error " + win32ErrorCode;
            }
        }
    }
}
