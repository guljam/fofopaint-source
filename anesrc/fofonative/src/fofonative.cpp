// com.fofo.nativecore 진입점
// 저장, 코덱, 캐시 이미지처럼 무거운 픽셀/압축 작업을 네이티브로 처리함
// 모듈별 함수 목록을 모아서 컨텍스트에 등록함
#include "common.h"
#include "pool.h"
#include "fileio.h"
#include <vector>

FREObject newInt(int32_t value)
{
    FREObject object = NULL;
    FRENewObjectFromInt32(value, &object);
    return object;
}

FREObject newUint(uint32_t value)
{
    FREObject object = NULL;
    FRENewObjectFromUint32(value, &object);
    return object;
}

FREObject newDouble(double value)
{
    FREObject object = NULL;
    FRENewObjectFromDouble(value, &object);
    return object;
}

FREObject newBool(bool value)
{
    FREObject object = NULL;
    FRENewObjectFromBool(value ? 1 : 0, &object);
    return object;
}

FREObject newString(const char* text)
{
    FREObject object = NULL;
    FRENewObjectFromUTF8((uint32_t)strlen(text), (const uint8_t*)text, &object);
    return object;
}

bool getInt(FREObject object, int32_t* value)
{
    return FREGetObjectAsInt32(object, value) == FRE_OK;
}

bool getUint(FREObject object, uint32_t* value)
{
    return FREGetObjectAsUint32(object, value) == FRE_OK;
}

bool getDouble(FREObject object, double* value)
{
    return FREGetObjectAsDouble(object, value) == FRE_OK;
}

bool getBool(FREObject object, bool* value)
{
    uint32_t flag = 0;

    if (FREGetObjectAsBool(object, &flag) != FRE_OK)
        return false;

    *value = flag != 0;
    return true;
}

bool getString(FREObject object, char* buffer, size_t bufferSize)
{
    uint32_t length = 0;
    const uint8_t* text = NULL;

    buffer[0] = 0;

    if (FREGetObjectAsUTF8(object, &length, &text) != FRE_OK || length + 1 > bufferSize)
        return false;

    memcpy(buffer, text, length);
    buffer[length] = 0;
    return true;
}

bool setByteArray(FREObject byteArray, const uint8_t* data, size_t length)
{
    if (length > 0xFFFFFFFFu)
        return false;

    if (FRESetObjectProperty(byteArray, (const uint8_t*)"length", newUint((uint32_t)length), NULL) != FRE_OK)
        return false;

    FREByteArray bytes;

    if (FREAcquireByteArray(byteArray, &bytes) != FRE_OK)
        return false;

    const bool ok = bytes.length == length;

    if (ok && length > 0)
        memcpy(bytes.bytes, data, length);

    FREReleaseByteArray(byteArray);
    FRESetObjectProperty(byteArray, (const uint8_t*)"position", newUint(0), NULL);
    return ok;
}

static std::vector<FRENamedFunction> gFunctions;

static void addFunctions(const NamedFunction* list, uint32_t count)
{
    for (uint32_t i = 0; i < count; i++)
    {
        FRENamedFunction f;
        f.name = (const uint8_t*)list[i].name;
        f.functionData = NULL;
        f.function = list[i].function;
        gFunctions.push_back(f);
    }
}

static void ContextInitializer(void* extData, const uint8_t* ctxType, FREContext ctx, uint32_t* numFunctions, const FRENamedFunction** functions)
{
    if (gFunctions.empty())
    {
        uint32_t count = 0;
        const NamedFunction* list = pixelFunctions(&count);
        addFunctions(list, count);
        list = testFunctions(&count);
        addFunctions(list, count);
        list = codecFunctions(&count);
        addFunctions(list, count);
        list = saveFunctions(&count);
        addFunctions(list, count);
        list = jobFunctions(&count);
        addFunctions(list, count);
        list = cacheFunctions(&count);
        addFunctions(list, count);
    }

    jobs::setContext(ctx);
    *numFunctions = (uint32_t)gFunctions.size();
    *functions = gFunctions.data();
}

static void ContextFinalizer(FREContext ctx)
{
    // 앱 종료: 캐시 작업은 취소 (세대를 바꾸면 블록 사이에서 멈춤, 남은 캐시는 다음 실행때 다시 만듦)
    cancelAllCacheJobs();

    // 진행 중인 저장은 끝날때까지 기다림 (AS3 쪽이 먼저 기다리므로 보통 바로 지나감), 최대 60초
    for (int waited = 0; waited < 6000 && (activeSaveCount() > 0 || activeCacheJobCount() > 0); waited++)
        Sleep(10);

    // 이 뒤로는 완료 알림(FREDispatchStatusEventAsync)을 보내지 않음
    jobs::setContext(NULL);
}

FOFO_EXPORT void NativeCoreExtInit(void** extData, FREContextInitializer* contextInitializer, FREContextFinalizer* contextFinalizer)
{
    *extData = NULL;
    *contextInitializer = &ContextInitializer;
    *contextFinalizer = &ContextFinalizer;
}

FOFO_EXPORT void NativeCoreExtFin(void* extData)
{
    pool::stop();
}
