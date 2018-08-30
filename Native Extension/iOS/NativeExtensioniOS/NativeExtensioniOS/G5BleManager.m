#import "FQToolsUtil.h"
#import "G5BleManager.h"
#import "G5HeaderDefine.h"
#import "Context.h"
#import "FQAESUitil.h"

@interface G5BleManager()
{
	NSDate *_startDate;
}
@property (strong ,nonatomic) CBCharacteristic *writeCharacteristic;
@property (strong ,nonatomic) CBCharacteristic *notifyCharacteristic;

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
    } else {
        FPANE_Log(@"spiketrace ANE G5BLEManager.m in startScanDevice, but manager already exists");
    }
    _G5Reset = false;
}

- (void)startScanning{
    if ([_transmitterID length] < 6) {
        FPANE_Log([NSString stringWithFormat:@"spiketrace ANE G5BLEManager.m in startScanning but transmitter id in settings has not length 6 - not starting scan"]);
        return;
    }

    if (self.manager) {
        NSArray *services = [NSArray arrayWithObjects:[CBUUID UUIDWithString:G5_MM_ADVERTISEMENT_UUID], nil];
        FPANE_Log(@"spiketrace ANE G5BLEManager.m in startScanning, start scanning");
        [self.manager scanForPeripheralsWithServices:services options:nil];
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
        NSString *sUUID = [FQToolsUtil userDefaults:self.selectMAC];
        if (sUUID.length!=0) {
            NSUUID *uuid0 = [[NSUUID UUID] initWithUUIDString:sUUID];
            NSArray *peripheralArr = [central retrievePeripheralsWithIdentifiers:@[uuid0]];
            if (peripheralArr.count>0) {
                FPANE_Log(@"spiketrace ANE G5BLEManager.m in retrievePeripherals, found known peripherals, trying to connect");
                self.peripheral = [peripheralArr firstObject];
                self.peripheral.delegate = self;
                [central connectPeripheral:self.peripheral options:nil];
                return YES;
            }
        }
    }
    FPANE_Log(@"spiketrace ANE G5BLEManager.m in retrievePeripherals, no peripherals retrieved");
    return NO;
}

- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    if (central.state == CBCentralManagerStatePoweredOn) {
        FPANE_Log(@"spiketrace ANE G5BLEManager.m in centralManagerDidUpdateState, power on");
        if (![self retrievePeripherals:central]) {
            [self startScanning];
        }
    }else if (central.state == CBCentralManagerStatePoweredOff){
		FPANE_Log(@"spiketrace ANE G5BLEManager.m in centralManagerDidUpdateState, power off");
    }else{
        FPANE_Log(@"spiketrace ANE G5BLEManager.m in centralManagerDidUpdateState, status seems not on and not off ?");
    }
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI{
    FPANE_Log([NSString stringWithFormat:@"spiketrace ANE G5BLEManager.m in didDiscoverPeripheral peripheral.name %@",peripheral.name]);
    NSString * expectedPeripheralName = [[NSString stringWithFormat:@"DEXCOM%@", [_transmitterID substringFromIndex:4]] uppercaseString];
    if ([[peripheral.name uppercaseString] isEqualToString:expectedPeripheralName]){
        if ([[NSDate date]timeIntervalSinceDate:_timeStampOfLastG5Reading] < 60) {
            FPANE_Log([NSString stringWithFormat:@"spiketrace ANE G5BLEManager.m in didDiscoverPeripheral G5 but last reading was less than 1 minute ago, ignoring this peripheral discovery. continue scan"]);
            return;
        };
        NSString* UUIDString = [peripheral.identifier UUIDString];
        
        FPANE_Log([NSString stringWithFormat:@"spiketrace ANE G5BLEManager.m in didDiscoverPeripheral UUIDString =  %@",UUIDString]);

        if (self.selectMAC ==  NULL || [[FQToolsUtil userDefaults:@"databaseResetted"]  isEqual: @"true"]) {
            _selectMAC = UUIDString;
            [FQToolsUtil saveUserDefaults:@"false" key:@"databaseResetted"];
            FREDispatchStatusEventAsync([Context getContext], (const uint8_t*) "StatusEvent_newG5Mac", (const uint8_t*) FPANE_ConvertNSString_TO_uint8([NSString stringWithFormat:@"%@%@", UUIDString, @"JJ§§((hhd"]));
        } else {
            if ([[self.selectMAC uppercaseString] rangeOfString:[UUIDString uppercaseString]].location == NSNotFound) {
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
        FPANE_Log(@"spiketrace ANE G5BLEManager.m in didDisconnectPeripheral, self.peripheral not nil, trying to reconnect");
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
        FPANE_Log([NSString stringWithFormat:@"spiketrace ANE G5BLEManager.m in didUpdateNotificationStateForCharacteristic, characteristic is notify"]);
        [self sendAuthRequestTxMessage];
        _awaitingAuthStatusRxMessage = true;
    } else {
        FPANE_Log([NSString stringWithFormat:@"spiketrace ANE G5BLEManager.m in didUpdateNotificationStateForCharacteristic, characteristic uuid not notify"]);
        if (_G5Reset) {
            [self doG5Reset];
            _G5Reset = false;
         } else {
             [self getSensorData];
         }
    }
}

- (void) sendAuthRequestTxMessage {
    NSMutableData* authMessage = [NSMutableData dataWithCapacity:10];
    uint8_t number = 1;
    [authMessage appendBytes:&number length:1];
    [authMessage appendBytes:[[self create8BytesRandomNSData] bytes] length:8];
    number = 2;
    [authMessage appendBytes:&number length:1];
    FPANE_Log([NSString stringWithFormat:@"spiketrace ANE G5BLEManager.m sendAuthRequestTxMessage authMessage = %@",[self hexStringFromData:authMessage]]);

    [self.peripheral writeValue:authMessage forCharacteristic:self.notifyCharacteristic type:CBCharacteristicWriteWithResponse];
}
    
- (NSData*) create8BytesRandomNSData
{
    int EightBytes           = 8;
    NSMutableData* theData = [NSMutableData dataWithCapacity:EightBytes];
    for( unsigned int i = 0 ; i < EightBytes ; ++i )
    {
        NSInteger randomBits = arc4random();
        [theData appendBytes:(void*)&randomBits length:1];
    }
    return theData;
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error{

    _awaitingAuthStatusRxMessage = false;

    NSData *data = characteristic.value;
    NSString *dataAsString = [self hexStringFromData:data];
    FPANE_Log([NSString stringWithFormat:@"spiketrace ANE G5BLEManager.m didUpdateValueForCharacteristic data = %@", dataAsString]);
    const char *bytes = (const char *)[data bytes];

    FPANE_Log([NSString stringWithFormat:@"spiketrace ANE G5BLEManager.m didUpdateValueForCharacteristic bytes[0] = %i",(int)bytes[0]]);

    if ((int)bytes[0] == 5) {
        if ([data length] >= 3) {
            int bonded = (int)bytes[2];
            if (bonded != 2) {
            } else {
                FPANE_Log(@"spiketrace ANE G5BLEManager.m in didUpdateValueForCharacteristic, not bonded sending device not paired message");
                FREDispatchStatusEventAsync([Context getContext], (const uint8_t*) "StatusEvent_G5DeviceNotPaired", (const uint8_t*) "");
            }
            FPANE_Log(@"spiketrace ANE G5BLEManager.m in didUpdateValueForCharacteristic, Subscribing to WriteCharacteristic");
            [peripheral setNotifyValue:YES forCharacteristic:self.writeCharacteristic];
        }
    } else if ((int)bytes[0] == 3) {
        if ([data length] >= 17) {
            NSMutableData* challenge = [NSMutableData dataWithCapacity:8];
            [challenge appendBytes:bytes + 9 length:8];
            NSData* challengeHash = [FQAESUitil calculateHash:challenge withCryptKey:_cryptKey];
            NSMutableData* dataToWrite =[NSMutableData dataWithCapacity:9];
            uint8_t number = 4;
            [dataToWrite appendBytes:&number length:1];
            [dataToWrite appendBytes:[challengeHash bytes] length:8];
            [self.peripheral writeValue:dataToWrite forCharacteristic:self.notifyCharacteristic type:CBCharacteristicWriteWithResponse];
        }
    } else {
        
        FREDispatchStatusEventAsync([Context getContext], (const uint8_t*) "StatusEvent_G5DataPacketReceived", (const uint8_t*) FPANE_ConvertNSString_TO_uint8([NSString stringWithFormat:@"%@%@", dataAsString, @"JJ§§((hhd"]));
    }
}

-(void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if (error) {
        FPANE_Log([NSString stringWithFormat:@"spiketrace ANE G5BLEManager.m write error = %@",error]);
    } else {
        FPANE_Log([NSString stringWithFormat:@"spiketrace ANE G5BLEManager.m write success"]);
        if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:G5_MM_NOTIFY_CHARACTER_UUID]]) {
            _awaitingAuthStatusRxMessage = true;
        }
    }
}

- (void)cancelConnectDevice{
    if (self.peripheral.state == CBPeripheralStateConnected) {
         [self.manager cancelPeripheralConnection:self.peripheral];
         self.peripheral = nil;
    }
}

- (void) getSensorData {
    FPANE_Log(@"spiketrace ANE G5BLEManager.m in getSensorData");
    //SensorTxMessage hardcoded
    const unsigned char bytes[] = {0x2E,0xAC,0xC5};
    NSData *data = [NSData dataWithBytes:bytes length:sizeof(bytes)];

    [self.peripheral writeValue:data forCharacteristic:self.writeCharacteristic type:CBCharacteristicWriteWithResponse];
}

- (void) doG5Reset {
    FPANE_Log(@"spiketrace ANE G5BLEManager.m in doG5Reset");
    //Sensor reset message hardcoded
    const unsigned char bytes[] = {0x42,0x86,0x68};
    NSData *data = [NSData dataWithBytes:bytes length:sizeof(bytes)];
    
    [self.peripheral writeValue:data forCharacteristic:self.writeCharacteristic type:CBCharacteristicWriteWithResponse];
}

- (void) doG5FirmwareVersionRequest {
    FPANE_Log(@"spiketrace ANE G5BLEManager.m in doG5FirmwareVersionRequest");
    //FirmwareVersionRequest reset message hardcoded
    const unsigned char bytes[] = {0x4A,0x8E,0xE9};
    NSData *data = [NSData dataWithBytes:bytes length:sizeof(bytes)];
    [self.peripheral writeValue:data forCharacteristic:self.writeCharacteristic type:CBCharacteristicWriteWithResponse];
}

- (void) doG5BatteryInfoRequest {
    FPANE_Log(@"spiketrace ANE G5BLEManager.m in doG5BatteryInfoRequest");
    //BatteryInfoRequest reset message hardcoded
    const unsigned char bytes[] = {0x22,0x20,0x04};
    NSData *data = [NSData dataWithBytes:bytes length:sizeof(bytes)];
    [self.peripheral writeValue:data forCharacteristic:self.writeCharacteristic type:CBCharacteristicWriteWithResponse];
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
