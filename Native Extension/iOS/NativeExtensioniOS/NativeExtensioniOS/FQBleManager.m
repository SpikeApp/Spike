#import "FQBleManager.h"
#import "FQHeaderDefine.h"
#import "FQApiObject.h"
#import "FQToolsUtil.h"
#import "Context.h"

@interface FQBleManager()
{
	NSDate *_startDate;
}
@property (strong ,nonatomic) CBCharacteristic *writeCharacteristic;
@property (strong ,nonatomic) CBCharacteristic *notifyCharacteristic;

@property (strong ,nonatomic) NSMutableString *bufStr;
@property (assign ,nonatomic) NSInteger bufLen;
@property (assign ,nonatomic) BOOL receivedEnoughPackets;

@end

@implementation FQBleManager

+ (FQBleManager *)shared
{
    static FQBleManager *shared = nil;
    static dispatch_once_t oneToken;
    dispatch_once(&oneToken, ^{
        shared = [[FQBleManager alloc] init];
    });
    return shared;
}

- (void)startScanDevice{
    if (!self.manager) {
        FPANE_Log(@"spiketrace ANE FQBLEManager.m in startScanDevice");
        self.manager = [[CBCentralManager alloc]initWithDelegate:self queue:dispatch_get_main_queue()];
        self.bufStr =  [NSMutableString string];
    } else {
        FPANE_Log(@"spiketrace ANE FQBLEManager.m in startScanDevice, but manager already exists");
    }
}

- (void)startScanning{
    if (self.manager) {
        FPANE_Log(@"spiketrace ANE FQBLEManager.m in startScanning, start scanning");
        [self.manager scanForPeripheralsWithServices:nil options:@{CBCentralManagerScanOptionAllowDuplicatesKey:@YES}];
    } else {
        FPANE_Log(@"spiketrace ANE FQBLEManager.m in startScanning, but manager does not exist");
    }
}

- (void)disCoverServiceWith:(CBPeripheral *)peripheral{
    [peripheral discoverServices:nil];
}

- (void)stopScanDevice
{
    if (self.manager) {
        [self.manager stopScan];
        FPANE_Log(@"spiketrace ANE FQBLEManager.m stop ScanDevice");
        self.manager = nil;
    }
}

- (void)stopScanning
{
    if (self.manager) {
        if ([self.manager isScanning]) {
            [self.manager stopScan];
            FPANE_Log(@"spiketrace ANE FQBLEManager.m stopScanning");
        }
    }
}

- (BOOL)retrievePeripherals:(CBCentralManager *)central{
    FPANE_Log(@"spiketrace ANE FQBLEManager.m in retrievePeripherals");
    if(self.selectMAC){
        FPANE_Log(@"spiketrace ANE FQBLEManager.m in retrievePeripherals, self.selectMAC not null");
        NSString *sUUID = [FQToolsUtil userDefaults:self.selectMAC];
        if (sUUID.length!=0) {
            FPANE_Log(@"spiketrace ANE FQBLEManager.m in retrievePeripherals, sUUID.length!=0");
            NSUUID *uuid0 = [[NSUUID UUID] initWithUUIDString:sUUID];
            NSArray *peripheralArr = [central retrievePeripheralsWithIdentifiers:@[uuid0]];
            if (peripheralArr.count>0) {
                FPANE_Log(@"spiketrace ANE FQBLEManager.m in retrievePeripherals, peripheralArr.count>0");
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
        FPANE_Log(@"spiketrace ANE FQBLEManager.m in centralManagerDidUpdateState, power on");
        [self retrievePeripherals:central];
    }else if (central.state == CBCentralManagerStatePoweredOff){
		FPANE_Log(@"spiketrace ANE FQBLEManager.m in centralManagerDidUpdateState, power off");
    }else{
        FPANE_Log(@"spiketrace ANE FQBLEManager.m in centralManagerDidUpdateState, status seems not on and not off ?");
    }
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI{
    FPANE_Log([NSString stringWithFormat:@"spiketrace ANE FQBLEManager.m in didDiscoverPeripheral peripheral.name %@",peripheral.name]);
    if ([peripheral.name hasPrefix:@"miaomiao"]){
        NSData *data = advertisementData[@"kCBAdvDataManufacturerData"];
        NSString *dataStr = [self hexStringFromData:data];
        
        NSString *MAC = @"";
        if (dataStr.length == 16) {
            NSString *firmVersion = [dataStr substringToIndex:4];
            FPANE_Log([NSString stringWithFormat:@"spiketrace ANE FQBLEManager.m in didDiscoverPeripheral firmVersion =  %@",firmVersion]);

            MAC = [[dataStr substringFromIndex:4]uppercaseString];
            FPANE_Log([NSString stringWithFormat:@"spiketrace ANE FQBLEManager.m in didDiscoverPeripheral MAC =  %@",MAC]);

            if (self.selectMAC ==  NULL) {
                _selectMAC = MAC;
                FREDispatchStatusEventAsync([Context getContext], (const uint8_t*) "StatusEvent_newMiaoMiaoMac", (const uint8_t*) FPANE_ConvertNSString_TO_uint8([NSString stringWithFormat:@"%@%@", MAC, @"JJ§§((hhd"]));
            } else {
                if (![self.selectMAC hasSuffix:MAC]) {
                    FPANE_Log(@"spiketrace ANE FQBLEManager.m in didDiscoverPeripheral peripheral address does not matches stored address");
                    return;
                }
            }

            //stop scanning because we will try to connect to this device
            [self.manager stopScan];
            
            self.peripheral = peripheral;
            
            if(peripheral.state == CBPeripheralStateDisconnected ){
                FPANE_Log(@"spiketrace ANE FQBLEManager.m in didDiscoverPeripheral connecting peripheral");
                [central connectPeripheral:peripheral options:nil];
            } else {
                FPANE_Log(@"spiketrace ANE FQBLEManager.m in didDiscoverPeripheral calling didConnectPeripheral");
                [self centralManager:central didConnectPeripheral:peripheral];
            }
        } else {
            FPANE_Log(@"spiketrace ANE FQBLEManager.m in didDiscoverPeripheral dataStr.length != 16");
        }
    }
    if ([peripheral.name hasPrefix:@"miaomiaoA"]){
        self.peripheral = peripheral;
        FPANE_Log([NSString stringWithFormat:@"spiketrace ANE FQBLEManager.m %@",peripheral]);
    }
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    NSUUID *uuid = peripheral.identifier;
    [FQToolsUtil saveUserDefaults:uuid.UUIDString key:self.selectMAC];
    FPANE_Log([NSString stringWithFormat:@"spiketrace ANE FQBLEManager.m in didConnectPeripheral, connected peripheral name:%@ MAC: %@, uuid:%@", peripheral.name, self.selectMAC, uuid]);
    self.peripheral = peripheral;
    [self.peripheral setDelegate:self];
    [self.peripheral discoverServices:@[[CBUUID UUIDWithString:FQ_MM_SERVICE_UUID]]];
    FREDispatchStatusEventAsync([Context getContext], (const uint8_t*) "StatusEvent_connectedMiaoMiao", (const uint8_t*) "");
}

-(void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    FPANE_Log([NSString stringWithFormat:@"spiketrace ANE FQBLEManager.m in didFailToConnectPeripheral, peripheral name:（%@）failed reason:%@",[peripheral name],[error localizedDescription]]);
    if (self.peripheral) {
        FPANE_Log(@"spiketrace ANE FQBLEManager.m in didFailToConnectPeripheral, self.peripheral not nil, trying to reconnect");
        [self.manager connectPeripheral:self.peripheral options:nil];
    }
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error{
    
    FPANE_Log([NSString stringWithFormat:@"spiketrace ANE FQBLEManager.m >>>peripheral didDisconnect %@: %@\n", [peripheral name], [error localizedDescription]]);
    FREDispatchStatusEventAsync([Context getContext], (const uint8_t*) "StatusEvent_disconnectedMiaoMiao", (const uint8_t*) "");
    if (self.peripheral) {
        FPANE_Log(@"spiketrace ANE FQBLEManager.m in didDisconnectPeripheral, trying to reconnect");
        [self.manager connectPeripheral:self.peripheral options:nil];
    } else if (!self.peripheral) {
        FPANE_Log(@"spiketrace ANE FQBLEManager.m in didDisconnectPeripheral, self.peripheral = nil");
    }
    
}

-(void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error{
    FPANE_Log([NSString stringWithFormat:@"spiketrace ANE FQBLEManager.m >>>scanned services：%@",peripheral.services]);
    if (error){
        FPANE_Log([NSString stringWithFormat:@"spiketrace ANE FQBLEManager.m >>>Discovered services for %@ with error: %@", peripheral.name, [error localizedDescription]]);
        return;
    }
    for (CBService *service in peripheral.services) {
        FPANE_Log([NSString stringWithFormat:@"spiketrace ANE FQBLEManager.m in didDiscoverServices , service.UUID =   %@",service.UUID]);
        [peripheral discoverCharacteristics:nil forService:service];
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error{
    FPANE_Log([NSString stringWithFormat:@"spiketrace ANE FQBLEManager.m in didDiscoverCharacteristicsForService, discovered characteristics"]);
    if (error) {
        FPANE_Log([NSString stringWithFormat:@"spiketrace ANE FQBLEManager.m error Discovered characteristics for %@ with error: %@", service.UUID, [error localizedDescription]]);
        return;
    }
    
    for (CBCharacteristic *characteristic in service.characteristics){
        if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:FQ_MM_WRITE_CHARACTER_UUID]]) {
            FPANE_Log([NSString stringWithFormat:@"spiketrace ANE FQBLEManager.m in didDiscoverCharacteristicsForService, found writeCharacteristic"]);
            self.writeCharacteristic = characteristic;
        }
        if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:FQ_MM_NOTIFY_CHARACTER_UUID]]) {
            FPANE_Log([NSString stringWithFormat:@"spiketrace ANE FQBLEManager.m in didDiscoverCharacteristicsForService, found notifyCharacteristic"]);
            self.notifyCharacteristic = characteristic;
            [peripheral setNotifyValue:YES forCharacteristic:characteristic];
        }
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    if (characteristic.isNotifying == YES) {
        FPANE_Log([NSString stringWithFormat:@"spiketrace ANE FQBLEManager.m in didUpdateNotificationStateForCharacteristic, characteristic.isNotifying == YES"]);
        [self sendStartReadingCommand];
    }
}

- (void) sendStartReadingCommand {
    FPANE_Log([NSString stringWithFormat:@"spiketrace ANE FQBLEManager.m in sendStartReadingCommand"]);
        [self reset];
        Byte value[1] = {0xF0};
        NSData * data = [NSData dataWithBytes:&value length:sizeof(value)];
        [self writeFileData:data];
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error{
    NSData *data = characteristic.value;
    NSString *data_s = [self hexStringFromData:data];
    //unread or need change sensor
    if(data.length == 1 || data.length == 2){
        FPANE_Log([NSString stringWithFormat:@"spiketrace ANE FQBLEManager.m in didUpdateValueForCharacteristic data_s = %@", data_s]);

        if ([data_s isEqualToString:@"32"]) {
            FPANE_Log(@"spiketrace ANE FQBLEManager.m in didUpdateValueForCharacteristic, sensor changed message received from miaomiao");
            FREDispatchStatusEventAsync([Context getContext], (const uint8_t*) "StatusEvent_sensorChangeMessageReceived", (const uint8_t*) "");
        }
        if ([data_s isEqualToString:@"34"]) {
            FPANE_Log(@"spiketrace ANE FQBLEManager.m in didUpdateValueForCharacteristic, sensor not detected message received from miaomiao");
            FREDispatchStatusEventAsync([Context getContext], (const uint8_t*) "StatusEvent_sensorNotDetectedMessageReceived", (const uint8_t*) "");
        }
		if ([data_s isEqualToString:@"D101"]) {
			FPANE_Log(@"spiketrace ANE FQBLEManager.m in didUpdateValueForCharacteristic, change time interval success");
            FREDispatchStatusEventAsync([Context getContext], (const uint8_t*) "StatusEvent_miaoMiaoChangeTimeIntervalChangedSuccess", (const uint8_t*) "");
		}
		if ([data_s isEqualToString:@"D100"]) {
			FPANE_Log(@"spiketrace ANE FQBLEManager.m in didUpdateValueForCharacteristic, change time interval failed");
            FREDispatchStatusEventAsync([Context getContext], (const uint8_t*) "StatusEvent_miaoMiaoChangeTimeIntervalChangedFailure", (const uint8_t*) "");
		}
        return;
    }
    
    if (_startDate) {
        NSTimeInterval timer = [[NSDate date]timeIntervalSinceDate:_startDate];
        if (timer > 10) {
            FPANE_Log([NSString stringWithFormat:@"spiketrace ANE FQBLEManager.m in didUpdateValueForCharacteristic, more than 10 seconds since last packet, resetting buffer"]);
            [self reset];
        }
    }
    
    //sensor hex data
    if (data.length) {
        NSString *pre_s = [data_s substringToIndex:2];
        if ([pre_s isEqualToString:@"28"] && self.bufStr.length == 0) {
            NSString *len_s = [data_s substringWithRange:NSMakeRange(2, 4)];
            //344 is the useful packet. 18 is the header (with info about packet type, length, battery level, ...).
            //344 +18 = 362. One packet is 20 bytes, 362/20 = 18,2
            //Means minimum 19 packets are required.
            //19 * 20 = 380 bytes.
            self.bufLen = MIN(380, strtoul([len_s UTF8String],0,16));
            [self.bufStr appendString:data_s];
			_startDate = [NSDate date];
            FREDispatchStatusEventAsync([Context getContext], (const uint8_t*) "StatusEvent_didRecieveInitialUpdateValueForCharacteristic", (const uint8_t*) "");
        } else {
            [self.bufStr appendString:data_s];
        }
    }
    
    if ((self.bufStr.length == self.bufLen * 2) && !_receivedEnoughPackets) {
        _receivedEnoughPackets = true;
        FPANE_Log([NSString stringWithFormat:@"spiketrace ANE FQBLEManager.m hexStr = %@",self.bufStr]);
        if (error) {
            FPANE_Log([NSString stringWithFormat:@"spiketrace ANE FQBLEManager.m error = %@",error.localizedDescription]);
            FPANE_Log([NSString stringWithFormat:@"spiketrace ANE FQBLEManager.m error = %ld",(long)error.code]);
        } else {
            FREDispatchStatusEventAsync([Context getContext], (const uint8_t*) "StatusEvent_miaomiaoData", (const uint8_t*) FPANE_ConvertNSString_TO_uint8([NSString stringWithFormat:@"%@%@", self.bufStr, @"JJ§§((hhd"]));
        }
    } else {
        //received enough packets, no further processing
    }
}

-(void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    FPANE_Log([NSString stringWithFormat:@"spiketrace ANE FQBLEManager.m %@,%@",peripheral,characteristic]);
    if (error) {
        FPANE_Log([NSString stringWithFormat:@"spiketrace ANE FQBLEManager.m write error:=======%@",error]);
    }else{
        FPANE_Log([NSString stringWithFormat:@"spiketrace ANE FQBLEManager.m write success"]);
        if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:FQ_MM_WRITE_CHARACTER_UUID]]) {
            FPANE_Log([NSString stringWithFormat:@"spiketrace ANE FQBLEManager.m characteristic value is:%@",characteristic.value]);
        }
    }
}

- (void)writeFileData:(NSData *)data{
	FPANE_Log(@"spiketrace ANE FQBLEManager.m writeFileData, request data");
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


- (void)readValue{
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
- (void)reset{
    self.bufLen = 0;
    _startDate = [NSDate date];
    [self.bufStr setString:@""];
    _receivedEnoughPackets = false;
}

@end
