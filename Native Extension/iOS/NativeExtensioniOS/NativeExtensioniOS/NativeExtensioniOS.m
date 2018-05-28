//
//  NativeExtensionTemplateiOS.m
//  NativeExtensionTemplateiOS
//
//  Created by Johan Degraeve on 24/05/2018.
//  Copyright © 2018 Johan Degraeve. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FlashRuntimeExtensions.h"
#import "NativeExtensioniOS.h"
#include "FPANEUtils.h"

static FREContext _context;

FREObject traceNSLog( FREContext ctx, void* funcData, uint32_t argc, FREObject argv[] ) {
   NSLog(@"%@", FPANE_FREObjectToNSString(argv[0]));
    return NULL;
}

FREObject init( FREContext ctx, void* funcData, uint32_t argc, FREObject argv[] ) {
    NSLog(@"Initializing context");
    _context = ctx;
    return NULL;
}

void NativeExtensionInitializer( void** extDataToSet, FREContextInitializer* ctxInitializerToSet, FREContextFinalizer* ctxFinalizerToSet ) {
    extDataToSet = NULL;
    *ctxInitializerToSet = &NativeExtensionContextInitializer;
    *ctxFinalizerToSet = &NativeExtensionContextFinalizer;
    
}

void NativeExtensionContextInitializer(void* extData, const uint8_t* ctxType, FREContext ctx, uint32_t* numFunctionsToTest, const FRENamedFunction** functionsToSet) {
    
    *numFunctionsToTest = 2;
    
    FRENamedFunction * func = (FRENamedFunction *) malloc(sizeof(FRENamedFunction) * *numFunctionsToTest);
    
    func[0].name = (const uint8_t*) "traceNSLog";
    func[0].functionData = NULL;
    func[0].function = &traceNSLog;

    func[1].name = (const uint8_t*) "init";
    func[1].functionData = NULL;
    func[1].function = &init;

    *functionsToSet = func;
}

void NativeExtensionContextFinalizer( FREContext ctx )
{
    return;
}

void NativeExtensionFinalizer( FREContext ctx )
{
    return;
}

