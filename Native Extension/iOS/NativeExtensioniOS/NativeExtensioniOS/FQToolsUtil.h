#import <Foundation/Foundation.h>

#ifndef FQToolsUtil_h
#define FQToolsUtil_h

@interface FQToolsUtil : NSObject

+(void)saveUserDefaults:(id)obj key:(NSString *)key;
+(id) userDefaults:(NSString *)key;
+(NSString *)checkNull:(id)aStr;
+(NSString *)dictToJsonStr:(NSDictionary *)dict;

@end
#endif
