//
//  BuletoothListCell.h
//  QIUI-API
//
//  Created by mac on 2025/2/13.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface BuletoothListCell : UITableViewCell
-(void)setBlueData:(NSDictionary *)cellData;
@property(nonatomic,copy)void(^checkConnectBtnBlock)(NSDictionary * bluetoothInfo);

@end

NS_ASSUME_NONNULL_END
