//
//  HKPeripheralInfo.h
//  HKBabyBluetooth
//
//  Created by 刘华坤 on 2019/3/15.
//  Copyright © 2018年 liuhuakun. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <BabyBluetooth.h>

@interface HKPeripheralInfo : NSObject

@property (nonatomic, strong) NSNumber     *RSSI;
@property (nonatomic, strong) CBPeripheral *peripheral;
@property (nonatomic, strong) NSDictionary *advertisementData;

@end
