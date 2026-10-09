// 파일 입출력 (UTF-8 경로 -> UTF-16, 와이드 API) 과 작업 완료 알림
#pragma once
#include "common.h"
#include "zstream.h"
#include <string>

std::wstring widePath(const std::string& utf8);
std::string utf8Path(const std::wstring& wide);
bool fileExists(const std::wstring& path);

// 실패하면 GetLastError 값
struct IoResult
{
    bool ok;
    DWORD error;
};

// 같은 폴더에 임시 파일(<최종 이름>.<번호>.tmp)을 새로 만들어 조각들을 순서대로 씀, 성공하면 tempPath에 경로
IoResult writeTempFile(const std::wstring& finalPath, const std::vector<const Pieces*>& parts, std::wstring& tempPath);
// 임시 파일을 대상으로 교체 (MOVEFILE_REPLACE_EXISTING | MOVEFILE_WRITE_THROUGH)
IoResult replaceFile(const std::wstring& tempPath, const std::wstring& finalPath);
// 덮어쓰지 않고 옮김 (이미 있으면 실패)
IoResult moveNoReplace(const std::wstring& from, const std::wstring& to);
// 대상 파일을 지금 교체할 수 있는지 미리 확인 (없으면 true): 읽기 전용이 아니고 DELETE 권한으로 열리는지
IoResult canReplace(const std::wstring& finalPath);
// 파일 앞에서 length 바이트를 읽음 (다른 곳에서 쓰는 중이어도 읽게 공유 모드로)
IoResult readFilePrefix(const std::wstring& path, uint64_t length, Bytes& out);
void deleteQuietly(const std::wstring& path);

// ---- 작업 완료 알림 ----
namespace jobs
{
    void setContext(FREContext ctx);
    // 결과를 보관하고 StatusEvent(code=kind, level=작업 번호)를 보냄. 컨텍스트가 해제된 뒤면 보내지 않음
    void finish(int32_t id, const char* kind, const std::string& result);
    // 보관한 결과를 꺼냄 (없으면 빈 문자열)
    std::string take(int32_t id);
}

const NamedFunction* jobFunctions(uint32_t* count);
