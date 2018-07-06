#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import "FQApi.h"


@protocol FQBleManagerDelegate <NSObject>

//find peripherals
@required
- (void)fqFoundPeripheral:(CBPeripheral *)peripheral
           centralManager:(CBCentralManager *)centralManager
                     RSSI:(NSNumber *)RSSI
              firmVersion:(NSString *)firmVersion
                      MAC:(NSString*)MAC;

//connect to peripheral
- (void)fqConnectSuccess:(CBPeripheral *)peripheral
		  centralManager:(CBCentralManager *)centralManager;

//connect Failed
- (void)fqConnectFailed;

//disConnected
- (void)fqDisConnected;

//return data
- (void)fqResp:(FQBaseResp*)resp;


@end

@interface FQBleManager : NSObject<CBCentralManagerDelegate,CBPeripheralDelegate>

@property (weak ,nonatomic) id<FQBleManagerDelegate> delegate;
@property (strong ,nonatomic) CBCentralManager *manager;
@property (strong ,nonatomic) CBPeripheral *peripheral;

@property (copy,nonatomic)NSString *selectMAC;

//instance
+ (FQBleManager *)shared;

//set selectMac
- (void)setSelectMAC:(NSString *)newMAC ;

//start scaning
- (void)startScanDevice;

//stop scaning
- (void)stopScanDevice;

//stop scaning
- (void)startScanning;

//cancel connect
- (void)cancelConnectDevice;

//get servicies
- (void)disCoverServiceWith:(CBPeripheral *)peripheral;

- (void)writeFileData:(NSData *)data;

- (void)writeControlData:(NSData *)data;

- (void)readValue;

- (void) sendStartReadingCommand;

- (void)stopScanning;
@end
