//
//  APIBuletoothListViewController.m
//  QIUI-API
//
//  Created by mac on 2025/2/13.
//

#import "APIBuletoothListViewController.h"
#import "BuletoothListCell.h"

//蓝牙
#import "HKBabyBluetoothManager.h"

@interface APIBuletoothListViewController ()<UITableViewDataSource,UITableViewDelegate,HKBabyBluetoothManageDelegate>
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) HKBabyBluetoothManager * babyMgr;
@property (nonatomic, strong) NSMutableArray *dataSource;
@property (nonatomic, strong) CBPeripheral *peripheral;

@end

@implementation APIBuletoothListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _dataSource = [[NSMutableArray alloc] init];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    
    //注册cell
    UINib *BuletoothListCellNib=[UINib nibWithNibName:@"BuletoothListCell" bundle:nil];
    [self.tableView registerNib:BuletoothListCellNib forCellReuseIdentifier:@"BuletoothListCell"];
    [self.tableView reloadData];

    
    _babyMgr = [HKBabyBluetoothManager sharedManager];
    _babyMgr.delegate = self;
    [_babyMgr startScanPeripheral];
}
-(void)Languagesettings
{

}
-(void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [_babyMgr stopScanPeripheral];
}
#pragma mark - UITableView
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.dataSource.count;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    
    BuletoothListCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    //解决xib复用数据混乱问题
    if (nil == cell) {
        
        cell= (BuletoothListCell *)[[[NSBundle  mainBundle]  loadNibNamed:@"BuletoothListCell" owner:self options:nil]  lastObject];
        
    }else{
        //删除cell的所有子视图
        while ([cell.contentView.subviews lastObject] != nil)
        {
            [(UIView*)[cell.contentView.subviews lastObject] removeFromSuperview];
        }
        
    }
    [cell setBlueData:self.dataSource[indexPath.row]];
    cell.checkConnectBtnBlock = ^(NSDictionary * bluetoothInfo) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"connectToySynchronize" object:nil userInfo:bluetoothInfo];
        [self.navigationController popViewControllerAnimated:YES];
    };

    

    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [_babyMgr stopScanPeripheral];
}
-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{

    return 44;
}

#pragma mark HKBabyBluetoothManageDelegate 代理回调
- (void)systemBluetoothClose {
    // 系统蓝牙被关闭、提示用户去开启蓝牙
}

- (void)sysytemBluetoothOpen {
    // 系统蓝牙已开启、开始扫描周边的蓝牙设备
    [_babyMgr startScanPeripheral];
}

- (void)getScanResultPeripherals:(NSArray *)peripheralInfoArr {
    // 这里获取到扫描到的蓝牙外设数组、添加至数据源中
    if (self.dataSource.count>0) {
        [self.dataSource removeAllObjects];
    }
    
    for (HKPeripheralInfo *info in peripheralInfoArr) {
        NSData *data = info.advertisementData[@"kCBAdvDataManufacturerData"];
        NSUInteger len = [data length];
        Byte *byteData = (Byte*)malloc(len);
        memcpy(byteData, [data bytes], len);
        
        NSMutableArray * bytesAry = [[NSMutableArray alloc] init];

        for (int i = 0; i < len; i++) {
            NSLog(@"byteData : %hhu",byteData[i]);
            NSString *hexString= [NSString stringWithFormat:@"%@",[[NSString alloc] initWithFormat:@"%1hhx",byteData[i]]];
            if(hexString.length <=1)
            {
                hexString = [NSString stringWithFormat:@"0%@",hexString];
            }
            if(_typeId == 4 || _typeId == 9)
            {
                switch (i) {
                    case 3:
                        [bytesAry addObject:hexString];
                        break;
                    case 4:
                        [bytesAry addObject:hexString];
                        break;
                    case 5:
                        [bytesAry addObject:hexString];
                        break;
                    case 6:
                        [bytesAry addObject:hexString];
                        break;
                    case 7:
                        [bytesAry addObject:hexString];
                        break;
                    case 8:
                        [bytesAry addObject:hexString];
                        break;

                    default:
                        break;
                }

            }else if(_typeId == 6)
            {
                switch (i) {
                    case 0:
                        [bytesAry addObject:hexString];
                        break;
                    case 1:
                        [bytesAry addObject:hexString];
                        break;
                    case 2:
                        [bytesAry addObject:hexString];
                        break;
                    case 3:
                        [bytesAry addObject:hexString];
                        break;
                    case 4:
                        [bytesAry addObject:hexString];
                        break;
                    case 5:
                        [bytesAry addObject:hexString];
                        break;

                    default:
                        break;
                }

            }
            else
            {
                switch (i) {
                    case 2:
                        [bytesAry addObject:hexString];
                        break;
                    case 3:
                        [bytesAry addObject:hexString];
                        break;
                    case 4:
                        [bytesAry addObject:hexString];
                        break;
                    case 5:
                        [bytesAry addObject:hexString];
                        break;
                    case 6:
                        [bytesAry addObject:hexString];
                        break;
                    case 7:
                        [bytesAry addObject:hexString];
                        break;

                    default:
                        break;
                }

            }
        }
        if(bytesAry.count >5){
        NSLog(@"%@:%@:%@:%@:%@:%@",bytesAry[0],bytesAry[1],bytesAry[2],bytesAry[3],bytesAry[4],bytesAry[5]);

        if(_typeId == 4 || _typeId == 9)
        {
            [self requestNetwork:[NSString stringWithFormat:@"%@:%@:%@:%@:%@:%@",bytesAry[5],bytesAry[4],bytesAry[3],bytesAry[2],bytesAry[1],bytesAry[0]] info:info];
        }else
        {
            [self requestNetwork:[NSString stringWithFormat:@"%@:%@:%@:%@:%@:%@",bytesAry[0],bytesAry[1],bytesAry[2],bytesAry[3],bytesAry[4],bytesAry[5]] info:info];

        }
            
        }
    }

    
}
-(void)requestNetwork:(NSString *) macAddr info:(HKPeripheralInfo*)info
{
    NSMutableDictionary * dic = [[NSMutableDictionary alloc] init];
    [dic setObject:macAddr forKey:@"bluetoothAddress"];
    [dic setObject:info forKey:@"peripheralInfo"];

    [self.dataSource addObject:dic];
    [self.tableView reloadData];

}


@end
