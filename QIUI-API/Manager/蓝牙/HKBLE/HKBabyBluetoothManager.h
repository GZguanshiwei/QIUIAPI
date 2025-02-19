//
//  HKBabyBluetoothManager.h
//  HKBabyBluetooth
//
//  Created by 刘华坤 on 2019/3/15.
//  Copyright © 2018年 liuhuakun. All rights reserved.
//


#import <Foundation/Foundation.h>
#import "HKPeripheralInfo.h"

// 设置蓝牙的前缀【开发者必须改为自己的蓝牙设备前缀】
#define kMyDevicePrefix (@"FEE7")
#define kMyDevilPrefix (@"qiui")
#define kMyDevilsPrefix (@"QIUI")
#define kMyDevilsOKUPrefix (@"OKU")
#define kMyDevilsKeyPrefix (@"FFF0")
#define kMyDevilsSPPrefix (@"A6ED0201")
#define kMyIIKEYSPPrefix (@"FDAA")
#define kMyTAILSSPPrefix (@"FEE5")


// 设置蓝牙的channel值【开发者可不做修改】
#define channelOnPeropheralView @"peripheralView"

@protocol HKBabyBluetoothManageDelegate <NSObject>

@optional

/**
 蓝牙被关闭
 */
- (void)systemBluetoothClose;


/**
 蓝牙已开启
 */
- (void)sysytemBluetoothOpen;


/**
 扫描到的设备回调
 
 @param peripheralInfoArr 扫描到的蓝牙设备数组
 */
- (void)getScanResultPeripherals:(NSArray *)peripheralInfoArr;


/**
 连接成功
 */
- (void)connectSuccess;


/**
 连接失败
 */
- (void)connectFailed;


/**
 当前断开的设备
 
 @param peripheral 断开的peripheral信息
 */
- (void)disconnectPeripheral:(CBPeripheral *)peripheral;


/**
 读取蓝牙数据
 
 @param valueData 蓝牙设备发送过来的data数据
 */
- (void)readData:(NSData *)valueData;

@end


@interface HKBabyBluetoothManager : NSObject

//外设的服务UUID值
@property (nonatomic, copy) NSString *serverUUIDString;
//外设的写入UUID值
@property (nonatomic, copy) NSString *writeUUIDString;
//外设的读取UUID值
@property (nonatomic, copy) NSString *readUUIDString;
//尾巴
@property (nonatomic, assign) bool isTAILS;

/**
 单例
 
 @return 单例对象
 */
+ (HKBabyBluetoothManager *)sharedManager;


@property (nonatomic, weak) id<HKBabyBluetoothManageDelegate> delegate;


/**
 开始扫描周边蓝牙设备
 */
- (void)startScanPeripheral;


/**
 停止扫描
 */
- (void)stopScanPeripheral;


/**
 连接所选取的蓝牙外设
 
 @param peripheral 所选择蓝牙外设的perioheral
 */
-(void)connectPeripheral:(CBPeripheral *)peripheral;


/**
 获取当前连接成功的蓝牙设备数组
 
 @return 返回当前所连接成功蓝牙设备数组
 */
- (NSArray *)getCurrentPeripherals;


/**
 获取设备的服务跟特征值
 当已连接成功时调用有效
 */
- (void)searchServerAndCharacteristicUUID;


/**
 断开当前连接的所有蓝牙设备
 */
- (void)disconnectAllPeripherals;


/**
 断开所选择的蓝牙设备
 
 @param peripheral 所选择蓝牙外设的perioheral
 */
- (void)disconnectLastPeripheral:(CBPeripheral *)peripheral;

/**
 向蓝牙设备发送数据
 
 @param msgData 数据data值
 */
- (void)write:(NSData *)msgData;

@end
