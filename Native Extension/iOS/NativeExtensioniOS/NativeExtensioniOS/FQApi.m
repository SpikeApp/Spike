#import "FQApi.h"
#import "FQHeaderDefine.h"
#import "FQBleManager.h"
#import <UIKit/UIKit.h>
#import "FQToolsUtil.h"



@interface FQApi()
@end

@implementation FQApi

+(void)startScaning{
    id d = UIApplication.sharedApplication.delegate;
	FQBleManager *manager = [FQBleManager shared];
	manager.delegate = (id)d;
	[manager startScanning];
}

+(void)startScanDevice{
    id d = UIApplication.sharedApplication.delegate;
    FQBleManager *manager = [FQBleManager shared];
    manager.delegate = (id)d;
    [manager startScanDevice];
}

+(void)stopScanDevice{
    FQBleManager *manager = [FQBleManager shared];
    [manager stopScanDevice];
}

+ (void)setSelectMAC:(NSString *)newMAC {
    FQBleManager *manager = [FQBleManager shared];
    [manager setSelectMAC:newMAC];
}

+(void)connectWithMAC:(NSString *)MAC{
    
    [FQApi stopScaning];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        id d = UIApplication.sharedApplication.delegate;
		FQBleManager *manager = [FQBleManager shared];
		manager.delegate = (id)d;
		manager.selectMAC = MAC;
    });
}

+(void)stopScaning{
    FQBleManager *manager = [FQBleManager shared];
    [manager stopScanning];
}

+(void)connectAfterUpdateWithMAC:(NSString *)MAC{
	[FQApi stopScaning];
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
		id d = UIApplication.sharedApplication.delegate;
		FQBleManager *manager = [FQBleManager shared];
		manager.delegate = (id)d;
		manager.manager = nil;
		manager.peripheral = nil;
		manager.selectMAC = MAC;
	});
}

+(void)cancelConnectWithMAC:(NSString *)MAC{
    if (MAC.length > 0) {
        FPANE_Log(@"spiketrace ANE FQApi.m in cancelConnectWithMAC");
        FQBleManager *manager = [FQBleManager shared];
        [FQToolsUtil saveUserDefaults:nil key:MAC];
        [manager setSelectMAC:@""];
        [manager cancelConnectDevice];
    }
}

+(void)confirmChange{
    dispatch_after(0.2, dispatch_get_main_queue(), ^{
        FQBleManager *manager = [FQBleManager shared];
        Byte byte[2] = {};
        byte[0] = 0xD3;
        byte[1] = 0x01;
        NSData * data = [NSData dataWithBytes:&byte length:sizeof(byte)];
        [manager writeFileData:data];
        
        dispatch_after(0.2, dispatch_get_main_queue(), ^{
            Byte byte1 = 0xF0;
            NSData * data1 = [NSData dataWithBytes:&byte1 length:sizeof(byte)];
            [manager writeFileData:data1];
        });
    });
}

+(void)sendStartReadingCommand{
    FQBleManager *manager = [FQBleManager shared];
    [manager sendStartReadingCommand];
}

+(void)forgetPeripheral{
    FPANE_Log(@"spiketrace ANE FQApi.m in forgetPeripheral");
        FQBleManager *manager = [FQBleManager shared];
        manager.peripheral = nil;
}

@end
