#import <Foundation/Foundation.h>

@interface G5Api : NSObject


+(void)setSelectMAC:(NSString *)newMAC;
    
+(void)startScaning;

+(void)stopScaning;

+(void)connectWithMAC:(NSString *)MAC; //you can connect peripheral directly by MAC

+(void)connectAfterUpdateWithMAC:(NSString *)MAC;

+(void)cancelConnectWithMAC:(NSString *)MAC; //cancel your connected peripheral

+(void)disconnect;

+(void)forgetPeripheral;

+(void)startScanDevice;

+(void)stopScanDevice;

+(void)setTransmitterIdWithId:(NSString *)transmitterId withCryptKey:(NSString*)cryptKey;

+(void)setTestData:(NSData*)testData;

+(void)setG5Reset:(BOOL)value;

+(void)doG5FirmwareVersionRequest;

+(void)doG5BatteryInfoRequest;

@end
