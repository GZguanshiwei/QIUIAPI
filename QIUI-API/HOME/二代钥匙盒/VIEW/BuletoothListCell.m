//
//  BuletoothListCell.m
//  QIUI-API
//
//  Created by mac on 2025/2/13.
//

#import "BuletoothListCell.h"
@interface BuletoothListCell ()
@property (weak, nonatomic) IBOutlet UILabel *bluetoothAddressLab;
@property (weak, nonatomic) NSDictionary *bluetoothInfo;

@end

@implementation BuletoothListCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}
-(void)setBlueData:(NSDictionary *)cellData
{
    _bluetoothInfo = cellData;
    NSString * bluetoothAddress = [NSString stringWithFormat:@"%@",cellData[@"bluetoothAddress"]];
    _bluetoothAddressLab.text = bluetoothAddress;
}
-(IBAction)selectorConnectBtn:(id)sender{
    if (self.checkConnectBtnBlock) {
        self.checkConnectBtnBlock(_bluetoothInfo);
    }
}

@end
