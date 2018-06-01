#import <Foundation/Foundation.h>
#import "FQApiObject.h"

@interface FQApi : NSObject


+ (void)setSelectMAC:(NSString *)newMAC;
    
+(void)startScaning;

+(void)stopScaning;

+(void)connectWithMAC:(NSString *)MAC; //you can connect peripheral directly by MAC

+(void)connectAfterUpdateWithMAC:(NSString *)MAC;

+(void)cancelConnectWithMAC:(NSString *)MAC; //cancel your connected peripheral

+(void)confirmChange;	//when miaomiao read new sensor ,your App need confirm change.

+(void)forgetPeripheral;

+(void)sendStartReadingCommand;

+(void)startScanDevice;

+(void)stopScanDevice;

@end
