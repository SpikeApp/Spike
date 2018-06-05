#import "Trace.h"
#import <Foundation/Foundation.h>
#import "Context.h"

@interface Trace ()
@property (nonatomic, copy) NSString * filepath;

@end

@implementation Trace

static Trace * instance;
NSString * _filepath;

+ (Trace*) getInstance {
    if (instance == nil) {
        instance = [[Trace alloc] init];
    }
    return instance;
}

+ (void) setFilepath:(NSString*) newFilePath {
    _filepath = newFilePath;
}

+ (void) writeTraceToFile:(NSString *) text {
    if (!_filepath) {
        //NSLog(@"spiketrace ANE Trace.m in writeStringToFile, _filepath = nil");
        return;
    }
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:_filepath]) {
        //NSString* message = [NSString stringWithFormat:@"spiketrace ANE Trace.m Context.m  writeStringToFile, %@ does not exist, creating it now", _filepath];
        
        //NSLog(@"%@",message);
        
        [[text dataUsingEncoding:NSUTF8StringEncoding] writeToFile:_filepath atomically:YES];
    } else {
        //NSLog(@"spiketrace ANE Trace.m Context.m  writeStringToFile, %@ exists trying to write to it the message %@", _filepath, text);
        
        NSFileHandle *fileHandler = [NSFileHandle fileHandleForUpdatingAtPath:_filepath];
        [fileHandler seekToEndOfFile];
        [fileHandler writeData:[text dataUsingEncoding:NSUTF8StringEncoding]];
        [fileHandler closeFile];
    }
}

+ (void) writeStringToFile:(NSString *) string withFilePath:(NSString *) path {
    if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
        [[string dataUsingEncoding:NSUTF8StringEncoding] writeToFile:path atomically:YES];
    } else {
        NSFileHandle *fileHandler = [NSFileHandle fileHandleForUpdatingAtPath:path];
        [fileHandler seekToEndOfFile];
        [fileHandler writeData:[string dataUsingEncoding:NSUTF8StringEncoding]];
        [fileHandler closeFile];
    }
}

@end


