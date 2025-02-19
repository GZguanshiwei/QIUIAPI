//
//  HKBabyBluetoothManager.m
//  HKBabyBluetooth
//
//  Created by 刘华坤 on 2019/3/15.
//  Copyright © 2018年 liuhuakun. All rights reserved.
//

#import "HKBabyBluetoothManager.h"

@interface HKBabyBluetoothManager ()

@property (nonatomic, strong) BabyBluetooth    *babyBluetooth;
//扫描到的外设设备数组
@property (nonatomic, strong) NSMutableArray   *peripheralArr;
//写数据特征值
@property (nonatomic, strong) CBCharacteristic *writeCharacteristic;
//读数据特征值
@property (nonatomic, strong) CBCharacteristic *readCharacteristic;
//当前连接的外设设备
@property (nonatomic, strong) CBPeripheral     *currentPeripheral;

@end

@implementation HKBabyBluetoothManager


///lazy
- (NSMutableArray *)peripheralArr {
    if (!_peripheralArr) {
        _peripheralArr = [NSMutableArray new];
    }
    return _peripheralArr;
}


+ (HKBabyBluetoothManager *)sharedManager {
    static HKBabyBluetoothManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[HKBabyBluetoothManager alloc] init];
    });
    return instance;
}


- (instancetype)init {
    self = [super init];
    if (self) {
        [self initBabyBluetooth];
    }
    return self;
}


- (void)initBabyBluetooth {
    self.babyBluetooth = [BabyBluetooth shareBabyBluetooth];
    [self babyBluetoothDelegate];
}


#pragma mark 蓝牙配置
- (void)babyBluetoothDelegate {
    __weak typeof(self) weakSelf = self;
    
    // 1-系统蓝牙状态
    [self.babyBluetooth setBlockOnCentralManagerDidUpdateState:^(CBCentralManager *central) {
        dispatch_async(dispatch_get_main_queue(), ^{
            // 从block中取到值，再回到主线程
            if ([weakSelf respondsToSelector:@selector(systemBluetoothState:)]) {
                [weakSelf systemBluetoothState:central.state];
            }
        });
    }];
    
    // 2-设置查找设备的过滤器
    [self.babyBluetooth setFilterOnDiscoverPeripherals:^BOOL(NSString *peripheralName, NSDictionary *advertisementData, NSNumber *RSSI) {
        // 最常用的场景是查找某一个前缀开头的设备
        NSLog(@"advertisementData%@",advertisementData);
        

//        if ([peripheralName hasPrefix:kMyDevilPrefix] || [peripheralName hasPrefix:kMyDevilsPrefix] || [peripheralName hasPrefix:kMyDevilsOKUPrefix]) {
//                    return YES;
//        }

            
            if ([peripheralName hasPrefix:kMyDevilPrefix] || [peripheralName hasPrefix:kMyDevilsPrefix] || [peripheralName hasPrefix:kMyDevilsOKUPrefix] || [peripheralName hasPrefix:kMyTAILSSPPrefix]) {
                        return YES;
            }
        if ([advertisementData objectForKey:@"kCBAdvDataServiceUUIDs"]) {  //objectForKey will return nil if a key doesn't exists.

            NSArray * ary = [advertisementData objectForKey:@"kCBAdvDataServiceUUIDs"];
            for (CBUUID * cbuuid in ary) {
                if ([cbuuid isEqual:[CBUUID UUIDWithString:kMyDevicePrefix]] || [cbuuid isEqual:[CBUUID UUIDWithString:kMyDevilsKeyPrefix]] || [cbuuid isEqual:[CBUUID UUIDWithString:kMyDevilsSPPrefix]] || [cbuuid isEqual:[CBUUID UUIDWithString:kMyTAILSSPPrefix]]) {
                    return YES;
                }

            }

        }
        return NO;
    }];
    
    // 查找的规则
    [self.babyBluetooth setFilterOnDiscoverPeripheralsAtChannel:channelOnPeropheralView
                                                         filter:^BOOL(NSString *peripheralName, NSDictionary *advertisementData, NSNumber *RSSI) {
                                                             // 最常用的场景是查找某一个前缀开头的设备
//                                                            if ([peripheralName hasPrefix:kMyDevicePrefix] || [peripheralName hasPrefix:kMyDevilPrefix]|| [peripheralName hasPrefix:kMyDevilsPrefix]) {
//                                                                 return YES;
//                                                             }
//                                                                    if ([peripheralName hasPrefix:kMyDevilsOKUPrefix]) {
//                                                                        return YES;
//                                                                    }

                                                                      //objectForKey will return nil if a key doesn't exists.
                                                            //            if ([peripheralName hasPrefix:kMyDevicePrefix] || [peripheralName hasPrefix:kMyDevilPrefix]|| [peripheralName hasPrefix:kMyDevilsPrefix]) {
                                                            //                return YES;
                                                            //            }
                                                                        if ([peripheralName hasPrefix:kMyDevilPrefix]|| [peripheralName hasPrefix:kMyDevilsPrefix] || [peripheralName hasPrefix:kMyDevilsOKUPrefix] || [peripheralName hasPrefix:kMyTAILSSPPrefix]) {
                                                                                    return YES;
                                                                        }
                                                                if ([advertisementData objectForKey:@"kCBAdvDataServiceUUIDs"]) {
                                                                        NSArray * ary = [advertisementData objectForKey:@"kCBAdvDataServiceUUIDs"];
                                                                        for (CBUUID * cbuuid in ary) {
                                                                            if ([cbuuid isEqual:[CBUUID UUIDWithString:kMyDevicePrefix]] || [cbuuid isEqual:[CBUUID UUIDWithString:kMyDevilsKeyPrefix]] || [cbuuid isEqual:[CBUUID UUIDWithString:kMyDevilsSPPrefix]]|| [cbuuid isEqual:[CBUUID UUIDWithString:kMyTAILSSPPrefix]]) {
                                                                                return YES;
                                                                            }

                                                                        }

                                                                    }

                                                             return NO;
                                                         }];
    
    //设置连接规则
    [self.babyBluetooth setFilterOnConnectToPeripheralsAtChannel:channelOnPeropheralView
                                                          filter:^BOOL(NSString *peripheralName, NSDictionary *advertisementData, NSNumber *RSSI) {
                                                              return NO;
                                                          }];
    
    //2.1-设备连接过滤器
    [self.babyBluetooth setFilterOnConnectToPeripherals:^BOOL(NSString *peripheralName, NSDictionary *advertisementData, NSNumber *RSSI) {
        //不自动连接
        return NO;
    }];
    
    //3-设置扫描到设备的委托
    [self.babyBluetooth setBlockOnDiscoverToPeripherals:^(CBCentralManager *central, CBPeripheral *peripheral, NSDictionary *advertisementData, NSNumber *RSSI) {
        dispatch_async(dispatch_get_main_queue(), ^{
            // 从block中取到值，再回到主线程
            if ([weakSelf respondsToSelector:@selector(scanResultPeripheral: advertisementData: rssi:)]) {
                [weakSelf scanResultPeripheral:peripheral advertisementData:advertisementData rssi:RSSI];
            }
        });
    }];
    
    BabyRhythm *rhythm = [[BabyRhythm alloc]init];
    //4-设置设备连接成功的委托,同一个baby对象，使用不同的channel切换委托回调
    [self.babyBluetooth setBlockOnConnectedAtChannel:channelOnPeropheralView
                                               block:^(CBCentralManager *central, CBPeripheral *peripheral) {
                                                   NSLog(@"【HKBabyBluetooth】->连接成功");
                                                   dispatch_async(dispatch_get_main_queue(), ^{
                                                       // 从block中取到值，再回到主线程
                                                       if ([weakSelf respondsToSelector:@selector(connectSuccess)]) {
                                                           [weakSelf connectSuccess];
                                                       }
                                                   });
                                               }];
    
    // 5-设置设备连接失败的委托
    [self.babyBluetooth setBlockOnFailToConnectAtChannel:channelOnPeropheralView
                                                   block:^(CBCentralManager *central, CBPeripheral *peripheral, NSError *error) {
                                                       NSLog(@"【HKBabyBluetooth】->连接失败");
                                                       dispatch_async(dispatch_get_main_queue(), ^{
                                                           // 从block中取到值，再回到主线程
                                                           if ([weakSelf respondsToSelector:@selector(connectFailed)]) {
                                                               [weakSelf connectFailed];
                                                           }
                                                       });
                                                   }];
    
    // 6-设置设备断开连接的委托
    [self.babyBluetooth setBlockOnDisconnectAtChannel:channelOnPeropheralView
                                                block:^(CBCentralManager *central, CBPeripheral *peripheral, NSError *error) {
                                                    NSLog(@"【HKBabyBluetooth】->设备：%@断开连接",peripheral.name);
                                                    dispatch_async(dispatch_get_main_queue(), ^{
                                                        // 从block中取到值，再回到主线程
                                                        if ([weakSelf respondsToSelector:@selector(disconnectPeripheral:)]) {
                                                            [weakSelf disconnectPeripheral:peripheral];
                                                        }
                                                    });
                                                }];
    
    // 7-设置发现设备的Services的委托
    [self.babyBluetooth setBlockOnDiscoverServicesAtChannel:channelOnPeropheralView
                                                      block:^(CBPeripheral *peripheral, NSError *error) {
                                                          [rhythm beats];
                                                      }];
    
    // 8-设置发现设service的Characteristics的委托
    [self.babyBluetooth setBlockOnDiscoverCharacteristicsAtChannel:channelOnPeropheralView
                                                             block:^(CBPeripheral *peripheral, CBService *service, NSError *error) {
                                                                 NSString *serviceUUID = [NSString stringWithFormat:@"%@",service.UUID];
                                                                 if ([serviceUUID isEqualToString:weakSelf.serverUUIDString]) {
                                                                     for (CBCharacteristic *ch in service.characteristics) {
                                                                         // 写数据的特征值
                                                                         NSLog(@"CBCharacteristic%@",ch);
                                                                         NSString *chUUID = [NSString stringWithFormat:@"%@",ch.UUID];
                                                                         if(ch.properties & 0xC){
                                                                             if (weakSelf.isTAILS) {
                                                                                 if ([chUUID isEqualToString:weakSelf.writeUUIDString]) {
                                                                                     weakSelf.writeCharacteristic = ch;
                                                                                 }
                                                                             }else
                                                                             {
                                                                                 weakSelf.writeCharacteristic = ch;
                                                                             }
                                                                         }
                                                                         
                                                                         // 读数据的特征值
                                                                         if(ch.properties & 0x10){
                                                                             weakSelf.readCharacteristic = ch;
                                                                             [weakSelf.currentPeripheral setNotifyValue:YES
                                                                                                      forCharacteristic:weakSelf.readCharacteristic];
                                                                         }
                                                                     }
                                                                 }
                                                             }];
    
    // 9-设置读取characteristics的委托
    [self.babyBluetooth setBlockOnReadValueForCharacteristicAtChannel:channelOnPeropheralView
                                                                block:^(CBPeripheral *peripheral, CBCharacteristic *characteristics, NSError *error) {
                                                                    dispatch_async(dispatch_get_main_queue(), ^{
                                                                        // 从block中取到值，再回到主线程
                                                                        if ([weakSelf respondsToSelector:@selector(readData:)]) {
                                                                            [weakSelf readData:characteristics.value];
                                                                        }
                                                                    });
                                                                }];
    
    // 设置发现characteristics的descriptors的委托
    [self.babyBluetooth setBlockOnDiscoverDescriptorsForCharacteristicAtChannel:channelOnPeropheralView
                                                                          block:^(CBPeripheral *peripheral, CBCharacteristic *characteristic, NSError *error) { }];
    
    // 设置读取Descriptor的委托
    [self.babyBluetooth setBlockOnReadValueForDescriptorsAtChannel:channelOnPeropheralView
                                                             block:^(CBPeripheral *peripheral, CBDescriptor *descriptor, NSError *error) { }];
    
    // 读取rssi的委托
    [self.babyBluetooth setBlockOnDidReadRSSI:^(NSNumber *RSSI, NSError *error) { }];
    
    // 设置beats break委托
    [rhythm setBlockOnBeatsBreak:^(BabyRhythm *bry) { }];
    
    // 设置beats over委托
    [rhythm setBlockOnBeatsOver:^(BabyRhythm *bry) { }];
    
    // 扫描选项->CBCentralManagerScanOptionAllowDuplicatesKey:忽略同一个Peripheral端的多个发现事件被聚合成一个发现事件
    NSDictionary *scanForPeripheralsWithOptions = @{CBCentralManagerScanOptionAllowDuplicatesKey:@YES};
    /*连接选项->
     CBConnectPeripheralOptionNotifyOnConnectionKey :当应用挂起时，如果有一个连接成功时，如果我们想要系统为指定的peripheral显示一个提示时，就使用这个key值。
     CBConnectPeripheralOptionNotifyOnDisconnectionKey :当应用挂起时，如果连接断开时，如果我们想要系统为指定的peripheral显示一个断开连接的提示时，就使用这个key值。
     CBConnectPeripheralOptionNotifyOnNotificationKey:
     当应用挂起时，使用该key值表示只要接收到给定peripheral端的通知就显示一个提
     */
    NSDictionary *connectOptions = @{CBConnectPeripheralOptionNotifyOnConnectionKey:@YES,
                                     CBConnectPeripheralOptionNotifyOnDisconnectionKey:@YES,
                                     CBConnectPeripheralOptionNotifyOnNotificationKey:@YES};
    
    [self.babyBluetooth setBabyOptionsAtChannel:channelOnPeropheralView
                  scanForPeripheralsWithOptions:scanForPeripheralsWithOptions
                   connectPeripheralWithOptions:connectOptions
                 scanForPeripheralsWithServices:nil
                           discoverWithServices:nil
                    discoverWithCharacteristics:nil];
    
    // 连接设备
    [self.babyBluetooth setBabyOptionsWithScanForPeripheralsWithOptions:scanForPeripheralsWithOptions
                                           connectPeripheralWithOptions:nil
                                         scanForPeripheralsWithServices:nil
                                                   discoverWithServices:nil
                                            discoverWithCharacteristics:nil];
}

#pragma mark 对蓝牙操作
/// 蓝牙状态
- (void)systemBluetoothState:(CBManagerState)state  API_AVAILABLE(ios(10.0)) {
    if (state == CBManagerStatePoweredOn) {
        if ([self.delegate respondsToSelector:@selector(sysytemBluetoothOpen)]) {
            [self.delegate sysytemBluetoothOpen];
        }
    }else if (state == CBManagerStatePoweredOff) {
        if ([self.delegate respondsToSelector:@selector(systemBluetoothClose)]) {
            [self.delegate systemBluetoothClose];
        }
    }
}

/// 开始扫描
- (void)startScanPeripheral {
    self.babyBluetooth.scanForPeripherals().begin();
}

/// 扫描到的设备[由block回主线程]
- (void)scanResultPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData rssi:(NSNumber *)RSSI {
    for (HKPeripheralInfo *peripheralInfo in self.peripheralArr) {
        if ([peripheralInfo.peripheral.identifier isEqual:peripheral.identifier]) {
            return;
        }
    }
    
    HKPeripheralInfo *peripheralInfo = [[HKPeripheralInfo alloc] init];
    peripheralInfo.peripheral = peripheral;
    peripheralInfo.advertisementData = advertisementData;
    peripheralInfo.RSSI = RSSI;
    [self.peripheralArr addObject:peripheralInfo];
    
    if ([self.delegate respondsToSelector:@selector(getScanResultPeripherals:)]) {
        [self.delegate getScanResultPeripherals:self.peripheralArr];
    }
}


/// 停止扫描
- (void)stopScanPeripheral {
    [self.peripheralArr removeAllObjects];
    [self.babyBluetooth cancelScan];
}


/// 连接设备
-(void)connectPeripheral:(CBPeripheral *)peripheral {
    // 断开之前的所有连接
    [self.babyBluetooth cancelAllPeripheralsConnection];
    self.currentPeripheral = peripheral;
    self.babyBluetooth.having(peripheral).and.channel(channelOnPeropheralView).
    then.connectToPeripherals().discoverServices().
    discoverCharacteristics().readValueForCharacteristic().
    discoverDescriptorsForCharacteristic().
    readValueForDescriptors().begin();
}


/// 连接成功[由block回主线程]
- (void)connectSuccess {
    if ([self.delegate respondsToSelector:@selector(connectSuccess)]) {
        [self.delegate connectSuccess];
    }
}


/// 连接失败[由block回主线程]
- (void)connectFailed {
    if ([self.delegate respondsToSelector:@selector(connectFailed)]) {
        [self.delegate connectFailed];
    }
}


/// 获取当前断开的设备[由block回主线程]
- (void)disconnectPeripheral:(CBPeripheral *)peripheral {
    if ([self.delegate respondsToSelector:@selector(disconnectPeripheral:)]) {
        [self.delegate disconnectPeripheral:peripheral];
    }
}


/// 获取当前连接
- (NSArray *)getCurrentPeripherals {
    return [self.babyBluetooth findConnectedPeripherals];
}


///获取设备的服务跟特征值[当已连接成功时]
- (void)searchServerAndCharacteristicUUID {
    self.babyBluetooth.having(self.currentPeripheral).and.channel(channelOnPeropheralView).
    then.connectToPeripherals().discoverServices().discoverCharacteristics()
    .readValueForCharacteristic().discoverDescriptorsForCharacteristic().
    readValueForDescriptors().begin();
}


///断开所有连接
- (void)disconnectAllPeripherals {
    [self.babyBluetooth cancelAllPeripheralsConnection];
}


///断开当前连接
- (void)disconnectLastPeripheral:(CBPeripheral *)peripheral {
    [self.babyBluetooth cancelPeripheralConnection:peripheral];
}


///发送数据
- (void)write:(NSData *)msgData {
    if (self.writeCharacteristic == nil) {
        NSLog(@"【HKBabyBluetooth】->数据发送失败");
        [[NSNotificationCenter defaultCenter] postNotificationName:@"refishWriteUUIDString" object:nil];
        return;
    }
    
    //若最后一个参数是CBCharacteristicWriteWithResponse
    //则会进入setBlockOnDidWriteValueForCharacteristic委托
    [self.currentPeripheral writeValue:msgData
                     forCharacteristic:self.writeCharacteristic
                                  type:CBCharacteristicWriteWithoutResponse];
}


///读取数据
- (void)readData:(NSData *)valueData {
    if ([self.delegate respondsToSelector:@selector(readData:)]) {
        [self.delegate readData:valueData];
    }
}


@end
