// ADOBE CONFIDENTIAL
//
// Copyright 2011 Adobe Systems Incorporated All Rights Reserved.
//
// NOTICE: All information contained herein is, and remains the property of
// Adobe Systems Incorporated and its suppliers, if any. The intellectual and
// technical concepts contained herein are proprietary to Adobe Systems
// Incorporated and its suppliers and may be covered by U.S. and Foreign
// Patents, patents in process, and are protected by trade secret or copyright
// law. Dissemination of this information or reproduction of this material
// is strictly forbidden unless prior written permission is obtained from
// Adobe Systems Incorporated.

// AdobePatentID="P969E1"

#ifdef WIN32
	typedef unsigned __int32	uint32_t;
	typedef unsigned __int8		uint8_t;
	typedef          __int32	int32_t;
#else
	#include <stdint.h>
#endif

#ifndef FRNATIVEEXTENSIONS_H_
#define FRNATIVEEXTENSIONS_H_

#ifdef __cplusplus
extern "C" {
#endif

typedef void *      FREContext;
typedef void *      FREObject;

/* Initialization *************************************************************/

/**
 * Defines the signature for native calls that can be invoked via an
 * instance of the AS ExtensionContext class.
 *
 * @return    The return value corresponds to the return value
 *            from the AS ExtensionContext class call() method. It defaults to
 *            FRE_INVALID_OBJECT, which is reported as null in AS.
 */

typedef FREObject (*FREFunction)(
        FREContext ctx,
		void*      functionData,
        uint32_t   argc,
        FREObject  argv[]
);

typedef struct FRENamedFunction_ {
    const uint8_t* name;
	void*          functionData;
    FREFunction    function;
} FRENamedFunction;

/**
 * Defines the signature for the initializer that is called each time
 * a new AS ExtensionContext object is created.
 *
 * @param extData The extension client data provided to the FREInitializer function as extDataToSet.
 *
 * @param ctxType Pointer to the contextType string (UTF8) as provided to the AS createExtensionContext call.
 *
 * @param ctx The FREContext being initialized.
 *
 * @param numFunctionsToSet The number of elements in the functionsToSet array.
 *
 * @param functionsToSet A pointer to an array of FRENamedFunction elements.
 */

typedef void (*FREContextInitializer)(
        void*                    extData          ,
        const uint8_t*           ctxType          ,
        FREContext               ctx              ,
        uint32_t*                numFunctionsToSet,
        const FRENamedFunction** functionsToSet
);

/**
 * Defines the signature for the finalizer that is called each time
 * an ExtensionContext instance is disposed.
 */

typedef void (*FREContextFinalizer)(
        FREContext ctx
);

/**
 * The initialization function provided by each extension must conform
 * to the following signature.
 *
 * @param extDataToSet Provided for the extension to store per-extension instance data. 
 *            For example, if the extension creates
 *            globals per-instance, it can store a pointer to them here.
 *
 * @param ctxInitializerToSet Must be set to a pointer to a function
 *            of type FREContextInitializer. Will be invoked whenever
 *            the ActionScript code creates a new context for this extension.
 *
 * @param ctxFinalizerToSet Must be set to a pointer to a function
 *            of type FREContextFinalizer.
 */

typedef void (*FREInitializer)(
        void**                 extDataToSet       ,
        FREContextInitializer* ctxInitializerToSet,
        FREContextFinalizer*   ctxFinalizerToSet
);

/** 
 * Called iff the extension is unloaded from the process. Extensions
 * are not guaranteed to be unloaded; the runtime process may exit without
 * doing so.
 */

typedef void (*FREFinalizer)(
        void* extData
);

/* Result Codes ***************************************************************/
/** 
 * These values must not be changed.
 */

typedef enum {
    FRE_OK                  = 0,
    FRE_NO_SUCH_NAME        = 1,
    FRE_INVALID_OBJECT      = 2,
    FRE_TYPE_MISMATCH       = 3,
    FRE_ACTIONSCRIPT_ERROR  = 4,
    FRE_INVALID_ARGUMENT    = 5,
    FRE_READ_ONLY           = 6,
    FRE_WRONG_THREAD        = 7,
    FRE_ILLEGAL_STATE       = 8,
    FRE_INSUFFICIENT_MEMORY = 9,
	FREResult_ENUMPADDING   = 0xfffff /* will ensure that C and C++ treat this enum as the same size. */
} FREResult;

/* Context Data ************************************************************/

/**
 * @returns FRE_OK
 *          FRE_WRONG_THREAD
 *          FRE_INVALID_ARGUMENT If nativeData is null.
 */

FREResult FREGetContextNativeData( FREContext ctx, void** nativeData );

/**
 * @returns FRE_OK
 *          FRE_INVALID_ARGUMENT
 *          FRE_WRONG_THREAD
 */

FREResult FRESetContextNativeData( FREContext ctx, void*  nativeData );

/**
 * @returns FRE_OK
 *          FRE_WRONG_THREAD
 *          FRE_INVALID_ARGUMENT If actionScriptData is null.
 */

FREResult FREGetContextActionScriptData( FREContext ctx, FREObject *actionScriptData );

/**
 * @returns FRE_OK
 *          FRE_WRONG_THREAD
 */

FREResult FRESetContextActionScriptData( FREContext ctx, FREObject  actionScriptData );

/* Primitive Types ************************************************************/
/**
 * These values must not be changed.
 */

typedef enum {
    FRE_TYPE_OBJECT           = 0,
    FRE_TYPE_NUMBER           = 1,
    FRE_TYPE_STRING           = 2,
    FRE_TYPE_BYTEARRAY        = 3,
    FRE_TYPE_ARRAY            = 4,
    FRE_TYPE_VECTOR           = 5,
    FRE_TYPE_BITMAPDATA       = 6,
	FRE_TYPE_BOOLEAN          = 7,
	FRE_TYPE_NULL             = 8,
	FREObjectType_ENUMPADDING = 0xfffff /* will ensure that C and C++ treat this enum as the same size. */
} FREObjectType;

/**
 * @returns FRE_OK
 *          FRE_INVALID_OBJECT
 *          FRE_WRONG_THREAD
 *          FRE_INVALID_ARGUMENT If objectType is null.
 */

FREResult FREGetObjectType( FREObject object, FREObjectType *objectType );

/**
 * @return  FRE_OK
 *          FRE_TYPE_MISMATCH
 *          FRE_INVALID_OBJECT
 *          FRE_INVALID_ARGUMENT
 *          FRE_WRONG_THREAD
 */

FREResult FREGetObjectAsInt32 ( FREObject object, int32_t  *value );
FREResult FREGetObjectAsUint32( FREObject object, uint32_t *value );
FREResult FREGetObjectAsDouble( FREObject object, double   *value );
FREResult FREGetObjectAsBool  ( FREObject object, uint32_t *value );

/**
 * @return  FRE_OK
 *          FRE_INVALID_ARGUMENT
 *          FRE_WRONG_THREAD
 */

FREResult FRENewObjectFromInt32 ( int32_t  value, FREObject *object );
FREResult FRENewObjectFromUint32( uint32_t value, FREObject *object );
FREResult FRENewObjectFromDouble( double   value, FREObject *object );
FREResult FRENewObjectFromBool  ( uint32_t value, FREObject *object );

/**
 * Retrieves a string representation of the object referred to by
 * the given object. The referenced string is immutable and valid 
 * only for duration of the call to a registered function. If the 
 * caller wishes to keep the the string, they must keep a copy of it.
 *
 * @param object The string to be retrieved.
 *
 * @param length The size, in bytes, of the string. Includes the
 *               null terminator.
 *
 * @param value  A pointer to a possibly temporary copy of the string.
 *
 * @return  FRE_OK
 *          FRE_TYPE_MISMATCH
 *          FRE_INVALID_OBJECT
 *          FRE_INVALID_ARGUMENT
 *          FRE_WRONG_THREAD
 */

FREResult FREGetObjectAsUTF8(
        FREObject       object,
        uint32_t*       length,
        const uint8_t** value
);

/** 
 * Creates a new String object that contains a copy of the specified
 * string.
 *
 * @param length The length, in bytes, of the original string. Must include
 *               the null terminator.
 *
 * @param value  A pointer to the original string.
 *
 * @param object Receives a reference to the new string object.
 * 
 * @return  FRE_OK
 *          FRE_INVALID_ARGUMENT
 *          FRE_WRONG_THREAD
 */

FREResult FRENewObjectFromUTF8(
        uint32_t        length,
        const uint8_t*  value ,
        FREObject*      object
);

/* Object Access **************************************************************/

/**
 * @param className UTF8-encoded name of the class being constructed.
 *
 * @param thrownException A pointer to a handle that can receive the handle of any ActionScript 
 *            Error thrown during execution. May be null if the caller does not
 *            want to receive this handle. If not null and no error occurs, is set an
 *            invalid handle value.
 *
 * @return  FRE_OK
 *          FRE_TYPE_MISMATCH
 *          FRE_INVALID_OBJECT
 *          FRE_INVALID_ARGUMENT
 *          FRE_ACTIONSCRIPT_ERROR If an ActionScript exception results from calling this method.
 *              In this case, thrownException will be set to the handle of the thrown value. 
 *          FRE_ILLEGAL_STATE If a ByteArray or BitmapData has been acquired and not yet released.
 *          FRE_NO_SUCH_NAME
 *          FRE_WRONG_THREAD
 */

FREResult FRENewObject(
        const uint8_t* className      ,
        uint32_t       argc           ,
        FREObject      argv[]         ,
        FREObject*     object         ,
        FREObject*     thrownException
);

/**
 * @param propertyName UTF8-encoded name of the property being fetched.
 *
 * @param thrownException A pointer to a handle that can receive the handle of any ActionScript 
 *            Error thrown during getting the property. May be null if the caller does not
 *            want to receive this handle. If not null and no error occurs, is set an
 *            invalid handle value.
 *
 * @return  FRE_OK
 *          FRE_TYPE_MISMATCH
 *          FRE_INVALID_OBJECT
 *          FRE_INVALID_ARGUMENT
 *
 *          FRE_ACTIONSCRIPT_ERROR If an ActionScript exception results from getting this property.
 *              In this case, thrownException will be set to the handle of the thrown value. 
 *
 *          FRE_NO_SUCH_NAME If the named property doesn't exist, or if the reference is ambiguous
 *              because the property exists in more than one namespace.
 *
 *          FRE_ILLEGAL_STATE If a ByteArray or BitmapData has been acquired and not yet released.
 *
 *          FRE_WRONG_THREAD
 */

FREResult FREGetObjectProperty(
        FREObject       object         ,
        const uint8_t*  propertyName   ,
        FREObject*      propertyValue  ,
        FREObject*      thrownException
);

/**
 * @param propertyName UTF8-encoded name of the property being set.
 *
 * @param thrownException A pointer to a handle that can receive the handle of any ActionScript 
 *            Error thrown during method execution. May be null if the caller does not
 *            want to receive this handle. If not null and no error occurs, is set an
 *            invalid handle value.
 *
 *
 * @return  FRE_OK
 *          FRE_TYPE_MISMATCH
 *          FRE_INVALID_OBJECT
 *          FRE_INVALID_ARGUMENT
 *          FRE_ACTIONSCRIPT_ERROR If an ActionScript exception results from getting this property.
 *              In this case, thrownException will be set to the handle of the thrown value. 
 *
 *          FRE_NO_SUCH_NAME If the named property doesn't exist, or if the reference is ambiguous
 *              because the property exists in more than one namespace.
 *
 *          FRE_ILLEGAL_STATE If a ByteArray or BitmapData has been acquired and not yet released.
 *
 *          FRE_READ_ONLY
 *          FRE_WRONG_THREAD
 */

FREResult FRESetObjectProperty(
        FREObject       object         ,
        const uint8_t*  propertyName   ,
        FREObject       propertyValue  ,
        FREObject*      thrownException
);

/**
 * @param methodName UTF8-encoded null-terminated name of the method being invoked.
 *
 * @param thrownException A pointer to a handle that can receive the handle of any ActionScript 
 *            Error thrown during method execution. May be null if the caller does not
 *            want to receive this handle. If not null and no error occurs, is set an
 *            invalid handle value.
 *
 * @return  FRE_OK
 *          FRE_TYPE_MISMATCH
 *          FRE_INVALID_OBJECT
 *          FRE_INVALID_ARGUMENT
 *          FRE_ACTIONSCRIPT_ERROR If an ActionScript exception results from calling this method.
 *              In this case, thrownException will be set to the handle of the thrown value. 
 *
 *          FRE_NO_SUCH_NAME If the named method doesn't exist, or if the reference is ambiguous
 *              because the method exists in more than one namespace.
 *
 *          FRE_ILLEGAL_STATE If a ByteArray or BitmapData has been acquired and not yet released.
 *
 *          FRE_WRONG_THREAD
 */

FREResult FRECallObjectMethod (
        FREObject      object         ,
        const uint8_t* methodName     ,
        uint32_t       argc           ,
        FREObject      argv[]         ,
        FREObject*     result         ,
        FREObject*     thrownException
);

/* BitmapData Access **********************************************************/

typedef struct {
    uint32_t  width;           /* width of the BitmapData bitmap */
    uint32_t  height;          /* height of the BitmapData bitmap */
    uint32_t  hasAlpha;        /* if non-zero, pixel format is ARGB32, otherwise pixel format is _RGB32, host endianness */
    uint32_t  isPremultiplied; /* pixel color values are premultiplied with alpha if non-zero, un-multiplied if zero */
    uint32_t  lineStride32;    /* line stride in number of 32 bit values, typically the same as width */
    uint32_t* bits32;          /* pointer to the first 32-bit pixel of the bitmap data */
} FREBitmapData;

typedef struct {
    uint32_t  width;           /* width of the BitmapData bitmap */
    uint32_t  height;          /* height of the BitmapData bitmap */
    uint32_t  hasAlpha;        /* if non-zero, pixel format is ARGB32, otherwise pixel format is _RGB32, host endianness */
    uint32_t  isPremultiplied; /* pixel color values are premultiplied with alpha if non-zero, un-multiplied if zero */
    uint32_t  lineStride32;    /* line stride in number of 32 bit values, typically the same as width */
    uint32_t  isInvertedY;     /* if non-zero, last row of pixels starts at bits32, otherwise, first row of pixels starts at bits32. */
    uint32_t* bits32;          /* pointer to the first 32-bit pixel of the bitmap data */
} FREBitmapData2;

/**
 * Referenced data is valid only for duration of the call
 * to a registered function.
 *
 * @return  FRE_OK
 *          FRE_TYPE_MISMATCH
 *          FRE_INVALID_OBJECT
 *          FRE_INVALID_ARGUMENT
 *          FRE_WRONG_THREAD
 *          FRE_ILLEGAL_STATE
 */

FREResult FREAcquireBitmapData(
        FREObject      object         , 
        FREBitmapData* descriptorToSet
);

/**
 * Referenced data is valid only for duration of the call
 * to a registered function.
 *
 * Use of this API requires that the extension and application must be packaged for 
 * the 3.1 namespace or later.
 *
 * @return  FRE_OK
 *          FRE_TYPE_MISMATCH
 *          FRE_INVALID_OBJECT
 *          FRE_INVALID_ARGUMENT
 *          FRE_WRONG_THREAD
 *          FRE_ILLEGAL_STATE
 */

FREResult FREAcquireBitmapData2(
        FREObject      object         , 
        FREBitmapData2* descriptorToSet
);

/**
 * BitmapData must be acquired to call this. Clients must invalidate any region
 * they modify in order to notify AIR of the changes. Only invalidated regions
 * are redrawn.
 *
 * @return  FRE_OK
 *          FRE_INVALID_OBJECT
 *          FRE_WRONG_THREAD
 *          FRE_ILLEGAL_STATE
 *          FRE_TYPE_MISMATCH
 */

FREResult FREInvalidateBitmapDataRect(
        FREObject object,
        uint32_t x      ,
        uint32_t y      ,
        uint32_t width  ,
        uint32_t height
);
/**
 * @return  FRE_OK
 *          FRE_WRONG_THREAD
 *          FRE_ILLEGAL_STATE
 *          FRE_TYPE_MISMATCH
 */

FREResult FREReleaseBitmapData( FREObject object );

/**
 * Referenced data is valid only for duration of the call
 * to a registered function.
 *
 * @return  FRE_OK
 *          FRE_TYPE_MISMATCH
 *          FRE_INVALID_OBJECT
 *          FRE_WRONG_THREAD
 */

/* ByteArray Access ***********************************************************/

typedef struct {
    uint32_t length;
    uint8_t* bytes;
} FREByteArray;

/**
 * Referenced data is valid only for duration of the call
 * to a registered function.
 *
 * @return  FRE_OK
 *          FRE_TYPE_MISMATCH
 *          FRE_INVALID_OBJECT
 *          FRE_INVALID_ARGUMENT
 *          FRE_WRONG_THREAD
 *          FRE_ILLEGAL_STATE
 */

FREResult FREAcquireByteArray(
    FREObject     object        ,
    FREByteArray* byteArrayToSet
);

/**
 * @return  FRE_OK
 *          FRE_INVALID_OBJECT
 *          FRE_ILLEGAL_STATE
 *          FRE_WRONG_THREAD
 */

FREResult FREReleaseByteArray( FREObject object );

/* Array and Vector Access ****************************************************/

/**
 * @return  FRE_OK
 *          FRE_INVALID_OBJECT
 *          FRE_INVALID_ARGUMENT
 *          FRE_ILLEGAL_STATE
 *          FRE_TYPE_MISMATCH
 *          FRE_WRONG_THREAD
 */

FREResult FREGetArrayLength(
        FREObject  arrayOrVector,
        uint32_t*  length
);

/**
 * @return  FRE_OK
 *          FRE_INVALID_OBJECT
 *          FRE_TYPE_MISMATCH
 *          FRE_ILLEGAL_STATE
 *          FRE_INVALID_ARGUMENT If length is greater than 2^32.
 *
 *          FRE_READ_ONLY   If the handle refers to a Vector
 *              of fixed size.
 *
 *          FRE_WRONG_THREAD
 *          FRE_INSUFFICIENT_MEMORY
 */

FREResult FRESetArrayLength(
        FREObject  arrayOrVector,
        uint32_t   length
);

/**
 * If an Array is sparse and an element that isn't defined is requested, the
 * return value will be FRE_OK but the handle value will be invalid.
 *
 * @return  FRE_OK
 *          FRE_ILLEGAL_STATE
 *
 *          FRE_INVALID_ARGUMENT If the handle refers to a vector and the index is
 *              greater than the size of the array.
 *
 *          FRE_INVALID_OBJECT
 *          FRE_TYPE_MISMATCH
 *          FRE_WRONG_THREAD
 */

FREResult FREGetArrayElementAt(
        FREObject  arrayOrVector,
        uint32_t   index        ,
        FREObject* value
);

/**
 *
 * @return  FRE_OK
 *          FRE_INVALID_OBJECT
 *          FRE_ILLEGAL_STATE
 *
 *          FRE_TYPE_MISMATCH If an attempt to made to set a value in a Vector
 *              when the type of the value doesn't match the Vector's item type.
 *
 *          FRE_WRONG_THREAD
 */

FREResult FRESetArrayElementAt(
        FREObject  arrayOrVector,
        uint32_t   index        ,
        FREObject  value
);

/* Callbacks ******************************************************************/

/** 
 * Causes a StatusEvent to be dispatched from the associated
 * ExtensionContext object.
 *
 * Dispatch happens asynchronously, even if this is called during
 * a call to a registered function.
 *
 * The ActionScript portion of this extension can listen for that event
 * and, upon receipt, query the native portion for details of the event
 * that occurred.
 *
 * This call is thread-safe and may be invoked from any thread. The string
 * values are copied before the call returns.
 *
 * @return  FRE_OK In all circumstances, as the referenced object cannot
 *              necessarily be checked for validity on the invoking thread.
 *              However, no event will be dispatched if the object is
 *              invalid or not an EventDispatcher.
 *          FRE_INVALID_ARGUMENT If code or level is NULL
 */

FREResult FREDispatchStatusEventAsync(
        FREContext     ctx  ,
        const uint8_t* code ,
        const uint8_t* level
);

#ifdef __cplusplus
}
#endif

#endif /* #ifndef _FLASH_RUNTIME_EXTENSIONS_H_ */
