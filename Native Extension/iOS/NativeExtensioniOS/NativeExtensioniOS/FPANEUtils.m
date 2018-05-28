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

#import "FPANEUtils.h"

#pragma mark - Dispatch events

NSDateFormatter *objDateformat;


void FPANE_DispatchEvent(FREContext context, NSString *eventName)
{
    FREDispatchStatusEventAsync(context, (const uint8_t *)[eventName UTF8String], (const uint8_t *)"");
}

void FPANE_DispatchEventWithInfo(FREContext context, NSString *eventName, NSString *eventInfo)
{
    FREDispatchStatusEventAsync(context, (const uint8_t *)[eventName UTF8String], (const uint8_t *)[eventInfo UTF8String]);
}

NSString * getCurrentTimeStamp()
{
    if (!objDateformat) {
        objDateformat = [[NSDateFormatter alloc] init];
        [objDateformat setDateFormat:@"yyyy-MM-dd HH:mm:ss.SSS"];//2017-09-09 15:28:11.390
    }
    NSString    *strTime = [objDateformat stringFromDate:[NSDate date]];
    return strTime;
}

NSString * FPANE_FREObjectToNSString(FREObject object)
{
    uint32_t stringLength;
    const uint8_t *string;
    FREGetObjectAsUTF8(object, &stringLength, &string);
    return [NSString stringWithUTF8String:(char*)string];
}

NSArray * FPANE_FREObjectToNSArrayOfNSString(FREObject object)
{
    uint32_t arrayLength;
    FREGetArrayLength(object, &arrayLength);
    
    uint32_t stringLength;
    NSMutableArray *mutableArray = [NSMutableArray arrayWithCapacity:arrayLength];
    for (NSInteger i = 0; i < arrayLength; i++)
    {
        FREObject itemRaw;
        FREGetArrayElementAt(object, (uint)i, &itemRaw);
        
        // Convert item to string. Skip with warning if not possible.
        const uint8_t *itemString;
        if (FREGetObjectAsUTF8(itemRaw, &stringLength, &itemString) != FRE_OK)
        {
            NSLog(@"Couldn't convert FREObject to NSString at index %ld", (long)i);
            continue;
        }
        
        NSString *item = [NSString stringWithUTF8String:(char*)itemString];
        [mutableArray addObject:item];
    }
    
    return [NSArray arrayWithArray:mutableArray];
}

NSDictionary * FPANE_FREObjectsToNSDictionaryOfNSString(FREObject keys, FREObject values)
{
    uint32_t numKeys, numValues;
    FREGetArrayLength(keys, &numKeys);
    FREGetArrayLength(values, &numValues);
    
    uint32_t stringLength;
    uint32_t numItems = MIN(numKeys, numValues);
    NSMutableDictionary *mutableDictionary = [NSMutableDictionary dictionaryWithCapacity:numItems];
    for (NSInteger i = 0; i < numItems; i++)
    {
        FREObject keyRaw, valueRaw;
        FREGetArrayElementAt(keys, (uint)i, &keyRaw);
        FREGetArrayElementAt(values, (uint)i, &valueRaw);
        
        // Convert key and value to strings. Skip with warning if not possible.
        const uint8_t *keyString, *valueString;
        if (FREGetObjectAsUTF8(keyRaw, &stringLength, &keyString) != FRE_OK || FREGetObjectAsUTF8(valueRaw, &stringLength, &valueString) != FRE_OK)
        {
            NSLog(@"Couldn't convert FREObject to NSString at index %ld", (long)i);
            continue;
        }
        
        NSString *key = [NSString stringWithUTF8String:(char*)keyString];
        NSString *value = [NSString stringWithUTF8String:(char*)valueString];
        [mutableDictionary setObject:value forKey:key];
    }
    
    return [NSDictionary dictionaryWithDictionary:mutableDictionary];
}

BOOL FPANE_FREObjectToBool(FREObject object)
{
    uint32_t b;
    FREGetObjectAsBool(object, &b);
    return b != 0;
}

NSInteger FPANE_FREObjectToInt(FREObject object)
{
    int32_t i;
    FREGetObjectAsInt32(object, &i);
    return i;
}

int32_t FPANE_FREObjectToInt32t(FREObject object)
{
    int32_t i;
    FREGetObjectAsInt32(object, &i);
    return i;
}

double FPANE_FREObjectToDouble(FREObject object)
{
    double x;
    FREGetObjectAsDouble(object, &x);
    return x;
}


#pragma mark - Obj-C -> FREObject

FREObject FPANE_BOOLToFREObject(BOOL boolean)
{
    FREObject result;
    FRENewObjectFromBool(boolean, &result);
    return result;
}

FREObject FPANE_IntToFREObject(NSInteger i)
{
    FREObject result;
    FRENewObjectFromInt32((int32_t)i, &result);
    return result;
}

FREObject FPANE_DoubleToFREObject(double d)
{
    FREObject result;
    FRENewObjectFromDouble(d, &result);
    return result;
}

FREObject FPANE_NSStringToFREObject(NSString *string)
{
    FREObject result;
    FRENewObjectFromUTF8((int)string.length, (const uint8_t *)[string UTF8String], &result);
    return result;
}

FREObject FPANE_CreateError( NSString* error, NSInteger* id )
{
    FREObject ret;
    FREObject errorThrown;
    
    FREObject freId;
    FRENewObjectFromInt32( (int32_t)*id, &freId);
    FREObject argV[] = {
        FPANE_NSStringToFREObject(error),
        freId
    };
    FRENewObject((const uint8_t*)"Error", 2, argV, &ret, &errorThrown);
    
    return ret;
}

uint8_t * FPANE_ConvertNSString_TO_uint8(NSString * toConvert)
{
    NSData *someData = [toConvert dataUsingEncoding:NSUTF8StringEncoding];
    const void *bytes = [someData bytes];
    return (uint8_t*)bytes;
}
