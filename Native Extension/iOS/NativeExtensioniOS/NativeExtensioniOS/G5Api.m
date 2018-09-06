#import "G5Api.h"
#import "G5HeaderDefine.h"
#import "G5BleManager.h"
#import <UIKit/UIKit.h>
#import "FQToolsUtil.h"



@interface G5Api()
@end

@implementation G5Api

+(void)startScaning{
    id d = UIApplication.sharedApplication.delegate;
	G5BleManager *manager = [G5BleManager shared];
	manager.delegate = (id)d;
	[manager startScanning];
}

+(void)startScanDevice{
    id d = UIApplication.sharedApplication.delegate;
    G5BleManager *manager = [G5BleManager shared];
    manager.delegate = (id)d;
    [manager startScanDevice];
}

+(void)stopScanDevice{
    G5BleManager *manager = [G5BleManager shared];
    [manager stopScanDevice];
}

+ (void)setSelectMAC:(NSString *)newMAC {
    G5BleManager *manager = [G5BleManager shared];
    [manager setSelectMAC:newMAC];
}

+(void)connectWithMAC:(NSString *)MAC{
    
    [G5Api stopScaning];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        id d = UIApplication.sharedApplication.delegate;
		G5BleManager *manager = [G5BleManager shared];
		manager.delegate = (id)d;
		manager.selectMAC = MAC;
    });
}

+(void)stopScaning{
    G5BleManager *manager = [G5BleManager shared];
    [manager stopScanning];
}

+(void)connectAfterUpdateWithMAC:(NSString *)MAC{
	[G5Api stopScaning];
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
		id d = UIApplication.sharedApplication.delegate;
		G5BleManager *manager = [G5BleManager shared];
		manager.delegate = (id)d;
		manager.manager = nil;
		manager.peripheral = nil;
		manager.selectMAC = MAC;
	});
}

+(void)cancelConnectWithMAC:(NSString *)MAC{
    if (MAC.length > 0) {
        FPANE_Log(@"spiketrace ANE G5Api.m in cancelConnectWithMAC");
        G5BleManager *manager = [G5BleManager shared];
        [FQToolsUtil saveUserDefaults:nil key:MAC];
        [manager setSelectMAC:@""];
        [manager cancelConnectDevice];
    }
}

+(void)disconnect{
    FPANE_Log(@"spiketrace ANE G5Api.m in disconnect");
    G5BleManager *manager = [G5BleManager shared];
    [manager disconnect];
}

+(void)forgetPeripheral{
    FPANE_Log(@"spiketrace ANE G5Api.m in forgetPeripheral");
        G5BleManager *manager = [G5BleManager shared];
        manager.peripheral = nil;
}

+(void)setTransmitterIdWithId:(NSString *)transmitterId withCryptKey:(NSString*)cryptKey{
    G5BleManager *manager = [G5BleManager shared];
    manager.transmitterID = transmitterId;
    manager.cryptKey = cryptKey;
}

+(void)setTestData:(NSData*)testData{
    G5BleManager *manager = [G5BleManager shared];
    manager.testdata = testData;
}

+(void)setG5Reset:(BOOL)value{
    G5BleManager *manager = [G5BleManager shared];
    manager.G5Reset = value;
}

+(void)doG5FirmwareVersionRequest{
    G5BleManager *manager = [G5BleManager shared];
    [manager doG5FirmwareVersionRequest];
}

+(void)doG5BatteryInfoRequest{
    G5BleManager *manager = [G5BleManager shared];
    [manager doG5BatteryInfoRequest];
}

@end
