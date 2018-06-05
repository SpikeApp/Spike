//////////////////////////////////////////////////////////////////////////////////////
//
//  Copyright 2012 Freshplanet (http://freshplanet.com | opensource@freshplanet.com)
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//
//////////////////////////////////////////////////////////////////////////////////////

#import <Foundation/Foundation.h>
#import "FlashRuntimeExtensions.h"

#define DEFINE_ANE_FUNCTION(fn) FREObject fn(FREContext context, void* functionData, uint32_t argc, FREObject argv[])

#define MAP_FUNCTION(fn, data) { (const uint8_t*)(#fn), (data), &(fn) }

#define ROOT_VIEW_CONTROLLER [[[UIApplication sharedApplication] keyWindow] rootViewController]

void FPANE_DispatchEvent(FREContext context, NSString *eventName);
void FPANE_DispatchEventWithInfo(FREContext context, NSString *eventName, NSString *eventInfo);
void FPANE_Log(NSString *message);

NSString * FPANE_FREObjectToNSString(FREObject object);
NSArray * FPANE_FREObjectToNSArrayOfNSString(FREObject object);
NSDictionary * FPANE_FREObjectsToNSDictionaryOfNSString(FREObject keys, FREObject values);
BOOL FPANE_FREObjectToBool(FREObject object);
NSInteger FPANE_FREObjectToInt(FREObject object);
int32_t FPANE_FREObjectToInt32t(FREObject object);
double FPANE_FREObjectToDouble(FREObject object);

FREObject FPANE_BOOLToFREObject(BOOL boolean);
FREObject FPANE_IntToFREObject(NSInteger i);
FREObject FPANE_DoubleToFREObject(double d);
FREObject FPANE_NSStringToFREObject(NSString *string);

FREObject FPANE_CreateError( NSString* error, NSInteger* id );

uint8_t * FPANE_ConvertNSString_TO_uint8(NSString * toConvert);
