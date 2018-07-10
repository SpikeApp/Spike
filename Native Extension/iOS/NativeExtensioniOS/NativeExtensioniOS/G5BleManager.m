#import "FQToolsUtil.h"
#import "G5BleManager.h"
#import "G5HeaderDefine.h"
#import "Context.h"

@interface G5BleManager()
{
	NSDate *_startDate;
}
@property (strong ,nonatomic) CBCharacteristic *writeCharacteristic;
@property (strong ,nonatomic) CBCharacteristic *notifyCharacteristic;

@property (strong ,nonatomic) NSMutableString *bufStr;
@property (assign ,nonatomic) NSInteger bufLen;
@property (assign ,nonatomic) NSDate *timeStampOfLastG5Reading;
@property (assign, nonatomic) BOOL awaitingAuthStatusRxMessage;

@end

@implementation G5BleManager

+ (G5BleManager *)shared
{
    static G5BleManager *shared = nil;
    static dispatch_once_t oneToken;
    dispatch_once(&oneToken, ^{
        shared = [[G5BleManager alloc] init];
    });
    return shared;
}

- (void)startScanDevice{
    if (!self.manager) {
        FPANE_Log(@"spiketrace ANE G5BLEManager.m in startScanDevice");
        self.manager = [[CBCentralManager alloc]initWithDelegate:self queue:dispatch_get_main_queue()];
        self.bufStr =  [NSMutableString string];
    } else {
        FPANE_Log(@"spiketrace ANE G5BLEManager.m in startScanDevice, but manager already exists");
    }
}

- (void)startScanning{
    if ([_transmitterID length] < 6) {
        FPANE_Log([NSString stringWithFormat:@"spiketrace ANE G5BLEManager.m in startScanning but transmitter id in settings has not length 6 - not starting scan"]);
        return;
    }

    if (self.manager) {
        NSArray *services = [NSArray arrayWithObjects:[CBUUID UUIDWithString:G5_MM_ADVERTISEMENT_UUID], nil];
        FPANE_Log(@"spiketrace ANE G5BLEManager.m in startScanning, start scanning");
        [self.manager scanForPeripheralsWithServices:services options:@{CBCentralManagerScanOptionAllowDuplicatesKey:@YES}];
    } else {
        FPANE_Log(@"spiketrace ANE G5BLEManager.m in startScanning, but manager does not exist");
    }
}

- (void)disCoverServiceWith:(CBPeripheral *)peripheral{
    [peripheral discoverServices:nil];
}

- (void)stopScanDevice
{
    if (self.manager) {
        [self.manager stopScan];
        FPANE_Log(@"spiketrace ANE G5BLEManager.m stop ScanDevice");
        self.manager = nil;
    }
}

- (void)stopScanning
{
    if (self.manager) {
        if ([self.manager isScanning]) {
            [self.manager stopScan];
            FPANE_Log(@"spiketrace ANE G5BLEManager.m stopScanning");
        }
    }
}

- (BOOL)retrievePeripherals:(CBCentralManager *)central{
    FPANE_Log(@"spiketrace ANE G5BLEManager.m in retrievePeripherals");
    if(self.selectMAC){
        FPANE_Log(@"spiketrace ANE G5BLEManager.m in retrievePeripherals, self.selectMAC not null");
        NSString *sUUID = [FQToolsUtil userDefaults:self.selectMAC];
        if (sUUID.length!=0) {
            FPANE_Log(@"spiketrace ANE G5BLEManager.m in retrievePeripherals, sUUID.length!=0");
            NSUUID *uuid0 = [[NSUUID UUID] initWithUUIDString:sUUID];
            NSArray *peripheralArr = [central retrievePeripheralsWithIdentifiers:@[uuid0]];
            if (peripheralArr.count>0) {
                FPANE_Log(@"spiketrace ANE G5BLEManager.m in retrievePeripherals, peripheralArr.count>0");
                self.peripheral = [peripheralArr firstObject];
                self.peripheral.delegate = self;
                [central connectPeripheral:self.peripheral options:nil];
                return YES;
            }
        }
    }
    return NO;
}

- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    if (central.state == CBCentralManagerStatePoweredOn) {
        FPANE_Log(@"spiketrace ANE G5BLEManager.m in centralManagerDidUpdateState, power on");
        [self retrievePeripherals:central];
    }else if (central.state == CBCentralManagerStatePoweredOff){
		FPANE_Log(@"spiketrace ANE G5BLEManager.m in centralManagerDidUpdateState, power off");
    }else{
        FPANE_Log(@"spiketrace ANE G5BLEManager.m in centralManagerDidUpdateState, status seems not on and not off ?");
    }
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI{
    FPANE_Log([NSString stringWithFormat:@"spiketrace ANE G5BLEManager.m in didDiscoverPeripheral peripheral.name %@",peripheral.name]);
    NSString * expectedPeripheralName = [NSString stringWithFormat:@"DEXCOM%@", [_transmitterID substringFromIndex:5]];
    if ([peripheral.name isEqualToString:expectedPeripheralName]){
        if ([[NSDate date]timeIntervalSinceDate:_timeStampOfLastG5Reading] < 60) {
            FPANE_Log([NSString stringWithFormat:@"spiketrace ANE G5BLEManager.m in didDiscoverPeripheral G5 but last reading was less than 1 minute ago, ignoring this peripheral discovery. continue scan"]);
            return;
        };
        NSData *data = advertisementData[@"kCBAdvDataManufacturerData"];
        NSString *dataStr = [self hexStringFromData:data];
        FPANE_Log([NSString stringWithFormat:@"spiketrace ANE G5BLEManager.m in didDiscoverPeripheral datastr = %@ length is %lu", dataStr, (unsigned long)[dataStr length]]);
        
        NSString *MAC = @"";
        if (dataStr.length == 16) {
            NSString *firmVersion = [dataStr substringToIndex:4];
            FPANE_Log([NSString stringWithFormat:@"spiketrace ANE G5BLEManager.m in didDiscoverPeripheral firmVersion =  %@",firmVersion]);

            MAC = [[dataStr substringFromIndex:4]uppercaseString];
            FPANE_Log([NSString stringWithFormat:@"spiketrace ANE G5BLEManager.m in didDiscoverPeripheral MAC =  %@",MAC]);

            if (self.selectMAC ==  NULL) {
                _selectMAC = MAC;
                FREDispatchStatusEventAsync([Context getContext], (const uint8_t*) "StatusEvent_newG5Mac", (const uint8_t*) FPANE_ConvertNSString_TO_uint8(MAC));
            } else {
                if (![self.selectMAC hasSuffix:MAC]) {
                    FPANE_Log(@"spiketrace ANE G5BLEManager.m in didDiscoverPeripheral peripheral address does not matches stored address");
                    return;
                }
            }

            //stop scanning because we will try to connect to this device
            [self.manager stopScan];
            
            self.peripheral = peripheral;
            
            if(peripheral.state == CBPeripheralStateDisconnected ){
                FPANE_Log(@"spiketrace ANE G5BLEManager.m in didDiscoverPeripheral connecting peripheral");
                [central connectPeripheral:peripheral options:nil];
            } else {
                FPANE_Log(@"spiketrace ANE G5BLEManager.m in didDiscoverPeripheral calling didConnectPeripheral");
                [self centralManager:central didConnectPeripheral:peripheral];
            }
        } else {
            FPANE_Log(@"spiketrace ANE G5BLEManager.m in didDiscoverPeripheral dataStr.length != 16");
        }
    } else {
        FPANE_Log([NSString stringWithFormat:@"spiketrace ANE G5BLEManager.m in didDiscoverPeripheral expected device name = %@, but receivd device name = %@", expectedPeripheralName, peripheral.name]);
    }
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    NSUUID *uuid = peripheral.identifier;
    [FQToolsUtil saveUserDefaults:uuid.UUIDString key:self.selectMAC];
    FPANE_Log([NSString stringWithFormat:@"spiketrace ANE G5BLEManager.m in didConnectPeripheral, connected peripheral name:%@ MAC: %@, uuid:%@", peripheral.name, self.selectMAC, uuid]);
    self.peripheral = peripheral;
    [self.peripheral setDelegate:self];
    [self.peripheral discoverServices:@[[CBUUID UUIDWithString:G5_MM_SERVICE_UUID]]];
    FREDispatchStatusEventAsync([Context getContext], (const uint8_t*) "StatusEvent_connectedG5", (const uint8_t*) "");
}

-(void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    FPANE_Log([NSString stringWithFormat:@"spiketrace ANE G5BLEManager.m in didFailToConnectPeripheral, peripheral name:（%@）failed reason:%@",[peripheral name],[error localizedDescription]]);
    if (self.peripheral) {
        FPANE_Log(@"spiketrace ANE G5BLEManager.m in didFailToConnectPeripheral, self.peripheral not nil, trying to reconnect");
        [self.manager connectPeripheral:self.peripheral options:nil];
    }
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error{
    
    FPANE_Log([NSString stringWithFormat:@"spiketrace ANE G5BLEManager.m >>>peripheral didDisconnect %@: %@\n", [peripheral name], [error localizedDescription]]);
    FREDispatchStatusEventAsync([Context getContext], (const uint8_t*) "StatusEvent_disconnectedG5", (const uint8_t*) "");
    if (self.peripheral) {
        FPANE_Log(@"spiketrace ANE G5BLEManager.m in didDisconnectPeripheral, self.peripheral not nil and _reconnectAfterDisconnect = true, trying to reconnect");
        [self.manager connectPeripheral:self.peripheral options:nil];
    } else if (!self.peripheral) {
        FPANE_Log(@"spiketrace ANE G5BLEManager.m in didDisconnectPeripheral, self.peripheral = nil");
    }
    
}

-(void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error{
    FPANE_Log([NSString stringWithFormat:@"spiketrace ANE G5BLEManager.m >>>scanned services：%@",peripheral.services]);
    if (error){
        FPANE_Log([NSString stringWithFormat:@"spiketrace ANE G5BLEManager.m >>>Discovered services for %@ with error: %@", peripheral.name, [error localizedDescription]]);
        return;
    }
    for (CBService *service in peripheral.services) {
        FPANE_Log([NSString stringWithFormat:@"spiketrace ANE G5BLEManager.m in didDiscoverServices , service.UUID =   %@",service.UUID]);
        [peripheral discoverCharacteristics:nil forService:service];
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error{
    FPANE_Log([NSString stringWithFormat:@"spiketrace ANE G5BLEManager.m in didDiscoverCharacteristicsForService, discovered characteristics"]);
    if (error) {
        FPANE_Log([NSString stringWithFormat:@"spiketrace ANE G5BLEManager.m error Discovered characteristics for %@ with error: %@", service.UUID, [error localizedDescription]]);
        return;
    }
    
    for (CBCharacteristic *characteristic in service.characteristics){
        if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:G5_MM_WRITE_CHARACTER_UUID]]) {
            FPANE_Log([NSString stringWithFormat:@"spiketrace ANE G5BLEManager.m in didDiscoverCharacteristicsForService, found writeCharacteristic"]);
            self.writeCharacteristic = characteristic;
        }
        if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:G5_MM_NOTIFY_CHARACTER_UUID]]) {
            FPANE_Log([NSString stringWithFormat:@"spiketrace ANE G5BLEManager.m in didDiscoverCharacteristicsForService, found notifyCharacteristic"]);
            self.notifyCharacteristic = characteristic;
            [peripheral setNotifyValue:YES forCharacteristic:characteristic];
        }
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    if (characteristic.isNotifying == YES) {
        FPANE_Log([NSString stringWithFormat:@"spiketrace ANE G5BLEManager.m in didUpdateNotificationStateForCharacteristic, characteristic.isNotifying == YES"]);
    }
    if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:G5_MM_NOTIFY_CHARACTER_UUID]]) {
        /*                    if (G5_RESET_REQUESTED) {
         doG5Reset();
         G5_RESET_REQUESTED = false;
         } else {
         getSensorData();
         }
*/
    } else {
       // sendAuthRequestTxMessage(readCharacteristic);
       // _awaitingAuthStatusRxMessage = true;
    }

}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error{
    NSData *data = characteristic.value;
    NSString *data_s = [self hexStringFromData:data];
}

-(void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    FPANE_Log([NSString stringWithFormat:@"spiketrace ANE G5BLEManager.m %@,%@",peripheral,characteristic]);
    if (error) {
        FPANE_Log([NSString stringWithFormat:@"spiketrace ANE G5BLEManager.m write error:=======%@",error]);
    }else{
        FPANE_Log([NSString stringWithFormat:@"spiketrace ANE G5BLEManager.m write success"]);
        if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:G5_MM_WRITE_CHARACTER_UUID]]) {
            FPANE_Log([NSString stringWithFormat:@"spiketrace ANE G5BLEManager.m characteristic value is:%@",characteristic.value]);
        }
    }
}

- (void)writeFileData:(NSData *)data{
	FPANE_Log(@"spiketrace ANE G5BLEManager.m writeFileData, request data");
    [self.peripheral writeValue:data forCharacteristic:self.writeCharacteristic type:CBCharacteristicWriteWithoutResponse];
}

- (void)writeControlData:(NSData *)data{
    [self.peripheral writeValue:data forCharacteristic:self.notifyCharacteristic type:CBCharacteristicWriteWithResponse];
}
- (void)cancelConnectDevice{
    if (self.peripheral.state == CBPeripheralStateConnected) {
         [self.manager cancelPeripheralConnection:self.peripheral];
         self.peripheral = nil;
    }
}


- (void)setSelectMAC:(NSString *)selectMAC
{
    _selectMAC = selectMAC;
}

- (NSString *)hexStringFromData:(NSData *)myD
{
    Byte *bytes = (Byte *)[myD bytes];
    NSString *hexStr=@"";
    for(int i=0;i<[myD length];i++)  {
        NSString *newHexStr = [NSString stringWithFormat:@"%x",bytes[i]&0xff];///16进制数
        if([newHexStr length] == 1)
            hexStr = [NSString stringWithFormat:@"%@0%@",hexStr,newHexStr];
        else
            hexStr = [NSString stringWithFormat:@"%@%@",hexStr,newHexStr];
    }
    return hexStr;
}

@end
