#ifndef Trace_h
#define Trace_h
#import <Foundation/Foundation.h>


@interface Trace : NSObject

+ (void) setFilepath:(NSString *) newFilePath;
+ (void) writeTraceToFile:(NSString *) text;
+ (void) writeStringToFile:(NSString *) string withFilePath:(NSString *) path;
+ (Trace*) getInstance;

@end

#endif /* Trace_h */
