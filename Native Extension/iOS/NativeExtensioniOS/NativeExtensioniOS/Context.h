#ifndef Context_h
#define Context_h

#import "FlashRuntimeExtensions.h"
#import "FPANEUtils.h"

@interface Context : NSObject


+ (void) setContext:(FREContext) newContext;

+ (FREContext) getContext;

+ (Context*) getInstance;

@end

#endif

