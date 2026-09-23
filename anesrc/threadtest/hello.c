#include <windows.h>
#include <FlashRuntimeExtensions.h>

FREContext gCtx = NULL; // AS와 연결된 전화번호 저장용

// 알바 스레드: 2초 -> 첫문자, 1초 더 -> 두번째문자
DWORD WINAPI MyThread(LPVOID p) {
  Sleep(2000);
  FREDispatchStatusEventAsync(gCtx, (const uint8_t*)"MSG", (const uint8_t*)"hello it's me");

  Sleep(1000);
  FREDispatchStatusEventAsync(gCtx, (const uint8_t*)"MSG", (const uint8_t*)"threaded");
  return 0;
}

// AS에서 call("chello") 하면 여기로 온다
FREObject Chello(FREContext ctx, void* funcData, uint32_t argc, FREObject argv[]) {
  gCtx = ctx; // 전화번호 저장
  CreateThread(NULL, 0, MyThread, NULL, 0, NULL); // 알바 만들고
  return NULL; // 바로 리턴! 여기서 3초 기다리면 앱이 멈춤
}

// 이름 연결표: "chello"라는 말은 Chello 함수다
void MyContextInit(void* extData, const uint8_t* ctxType, FREContext ctx,
  uint32_t* numFuncs, const FRENamedFunction** funcs) {
  static FRENamedFunction f[1];
  f[0].name = (const uint8_t*)"chello";
  f[0].functionData = NULL;
  f[0].function = &Chello;
  *numFuncs = 1;
  *funcs = f;
}
void MyContextFin(FREContext ctx) { gCtx = NULL; }

__declspec(dllexport) void ExtInit(void** extData, FREContextInitializer* cInit, FREContextFinalizer* cFin) {
  *cInit = &MyContextInit;
  *cFin = &MyContextFin;
}
__declspec(dllexport) void ExtFin(void* extData) {}