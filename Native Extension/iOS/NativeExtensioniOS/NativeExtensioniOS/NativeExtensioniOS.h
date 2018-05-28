#import "FlashRuntimeExtensions.h"

void NativeExtensionContextInitializer(void* extData, const uint8_t* ctxType, FREContext ctx, uint32_t* numFunctionsToTest, const FRENamedFunction** functionsToSet);
void NativeExtensionContextFinalizer(FREContext ctx);
void NativeExtensionInitializer(void** extDataToSet, FREContextInitializer* ctxInitializerToSet, FREContextFinalizer* ctxFinalizerToSet);
void NativeExtensionFinalizer(void *extData);
