// com.fofo.nativecore 공통 정의
// Windows 7 호환: Win8 이상 전용 API와 STL 스레드 기능(std::thread, std::mutex 등)을 쓰지 않고 Win32 API를 직접 씀
#pragma once

#ifndef WIN32_LEAN_AND_MEAN
#define WIN32_LEAN_AND_MEAN
#endif
#ifndef NOMINMAX
#define NOMINMAX
#endif
#include <windows.h>
#include <stdint.h>
#include <string.h>
#include "FlashRuntimeExtensions.h"

#define FOFO_EXPORT extern "C" __declspec(dllexport)

// AS3에 돌려주는 결과 코드 (int), 1이 성공
enum
{
    RESULT_OK = 1,
    RESULT_NO_TABLE = -1,
    RESULT_BAD_ARGUMENT = -2,
    RESULT_BITMAP_ACQUIRE_FAILED = -3,
    RESULT_UNSUPPORTED_FORMAT = -4,
    RESULT_BYTES_ACQUIRE_FAILED = -5,
    RESULT_NOT_ENOUGH_BYTES = -6,
    RESULT_OUT_OF_MEMORY = -7,
    RESULT_INTERNAL_ERROR = -8,
    RESULT_BUSY = -9,
    RESULT_IO_ERROR = -10
};

FREObject newInt(int32_t value);
FREObject newUint(uint32_t value);
FREObject newDouble(double value);
FREObject newBool(bool value);
FREObject newString(const char* text);
bool getInt(FREObject object, int32_t* value);
bool getUint(FREObject object, uint32_t* value);
bool getDouble(FREObject object, double* value);
bool getBool(FREObject object, bool* value);
// UTF-8 문자열을 복사해서 돌려줌, 실패하면 빈 문자열과 false
bool getString(FREObject object, char* buffer, size_t bufferSize);

// 함수 등록용
struct NamedFunction
{
    const char* name;
    FREFunction function;
};

// 모듈마다 자기 함수 목록을 돌려줌
const NamedFunction* pixelFunctions(uint32_t* count);
