#import <Foundation/Foundation.h>

@interface FQAESUitil : NSObject

+ (NSData *) AESEncryptWithKey:(NSString *)key withData:(NSData *) data;

@end
