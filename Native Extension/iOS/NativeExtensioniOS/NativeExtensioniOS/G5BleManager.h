#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import "G5Api.h"
#import "G5ApiObject.h"


@protocol G5BleManagerDelegate <NSObject>

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
- (void)fqResp:(G5BaseResp*)resp;


@end

@interface G5BleManager : NSObject<CBCentralManagerDelegate,CBPeripheralDelegate>

@property (weak ,nonatomic) id<G5BleManagerDelegate> delegate;
@property (strong ,nonatomic) CBCentralManager *manager;
@property (strong ,nonatomic) CBPeripheral *peripheral;
@property (strong, nonatomic) NSString * transmitterID;
@property (strong, nonatomic) NSString * cryptKey;
@property (strong, nonatomic) NSData * testdata;
@property (assign, nonatomic) BOOL G5Reset;

@property (copy,nonatomic)NSString *selectMAC;

//instance
+ (G5BleManager *)shared;

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

- (void)disconnect;

//get servicies
- (void)disCoverServiceWith:(CBPeripheral *)peripheral;

- (void)stopScanning;

- (NSString *)hexStringFromData:(NSData *)mD;

- (void) doG5FirmwareVersionRequest;

- (void) doG5BatteryInfoRequest;
@end
