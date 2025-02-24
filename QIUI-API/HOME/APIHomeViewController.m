//
//  APIHomeViewController.m
//  QIUI-API
//
//  Created by mac on 2025/2/12.
//
#define  XP_StatusBarAndNavigationBarHeight  (XP_iPhoneX ? 92.f : 64.f)
// 判断是否为iPhone X 系列  这样写消除了在Xcode10上的警告。
#define XP_iPhoneX \
({BOOL isPhoneX = NO;\
if (@available(iOS 11.0, *)) {\
isPhoneX = [[UIApplication sharedApplication] delegate].window.safeAreaInsets.bottom > 0.0;\
}\
(isPhoneX);})

#import "APIHomeViewController.h"
#import <AFNetworking.h>
#import <MBProgressHUD.h>
#import <SBJson5Writer.h>
#import "NSMutableDictionary+JMJson.h"
//蓝牙
#import "HKBabyBluetoothManager.h"
#import "AESCipher.h"

#import "APIBuletoothListViewController.h"

@interface APIHomeViewController ()<HKBabyBluetoothManageDelegate>
@property (weak, nonatomic) IBOutlet UIView *mainView;

@property (weak, nonatomic) IBOutlet UIButton * btn1;//获取API TOKEN
@property (weak, nonatomic) IBOutlet UIButton * btn2;//连接设备
@property (weak, nonatomic) IBOutlet UIButton * btn3;//绑定设备
@property (weak, nonatomic) IBOutlet UIButton * btn4;//获取TOKEN
@property (weak, nonatomic) IBOutlet UIButton * btn5;//开锁
@property (weak, nonatomic) IBOutlet UIButton * btn6;//关锁
@property (weak, nonatomic) IBOutlet UIButton * btn7;//断开连接

@property (copy, nonatomic) NSString * platformApiToken;//平台Api Token
@property (copy, nonatomic) NSString * expiresTime;//平台Api Token到期时间
//蓝牙模块
@property (strong, nonatomic) HKBabyBluetoothManager * babyMgr;
@property (nonatomic, strong) CBPeripheral *peripheral;

@property (copy, nonatomic) NSString * bluetoothAddress;//设备蓝牙地址
@property (copy, nonatomic) NSString * serialNumber;//设备编码
@property (nonatomic, copy) NSString * typeId;
@property (copy, nonatomic) NSString * deviceToken;//设备Token


@end

@implementation APIHomeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    CGRect mianframe = self.mainView.frame;
    mianframe.origin.y = XP_StatusBarAndNavigationBarHeight;
    mianframe.size.height -= XP_StatusBarAndNavigationBarHeight;
    self.mainView.frame = mianframe;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(connectToySynchronize:) name:@"connectToySynchronize" object:nil];

}

-(void)connectToySynchronize:(NSNotification*)notification
{
    NSDictionary *theData = [notification userInfo];
    _bluetoothAddress = [theData objectForKey:@"bluetoothAddress"];
    HKPeripheralInfo * info = [theData objectForKey:@"peripheralInfo"];
    _peripheral = info.peripheral;
    
}

- (void)connectSuccess {
    // 连接成功 写入UUID值【替换成自己的蓝牙设备UUID值】
    _babyMgr.serverUUIDString = @"FFF0";
    _babyMgr.writeUUIDString = @"FFF1";
    _babyMgr.readUUIDString = @"FFF2";

    [self functionUnsend:_deviceToken];

    NSLog(@"连接成功");
}
//将获取到到token写入设备
-(void)functionUnsend:(NSString *)message
{
    NSData *data = [self hexToBytes:message];
    [_babyMgr write:data];
}
//str转nsdata
-(NSData*)hexToBytes:(NSString*)str {
    
    NSString *string = str;
    const char *buf = [string UTF8String];
    NSMutableData *data = [NSMutableData data];
    if (buf){
        long len = strlen(buf);
        
        char singleNumberString[3] = {'\0', '\0', '\0'};
        uint32_t singleNumber = 0;
        for(uint32_t i = 0 ; i < len; i+=2) {
            if ( ((i+1) < len) && isxdigit(buf[i]) && (isxdigit(buf[i+1]))) {
                singleNumberString[0] = buf[i];
                singleNumberString[1] = buf[i + 1];
                sscanf(singleNumberString, "%x", &singleNumber);
                uint8_t tmp = (uint8_t)(singleNumber & 0x000000FF);
                [data appendBytes:(void *)(&tmp)length:1];
            } else {
                break;
            }
        }
        
    }
    
    return data;
}

- (void)readData:(NSData *)data {
    // 获取到蓝牙设备发来的数据
    NSLog(@"蓝牙发来的数据 = %@",[NSString stringWithFormat:@"%@",data]);
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
        hexString = [hexString uppercaseStringWithLocale:[NSLocale currentLocale]];
        [bytesAry addObject:hexString];
    }
    NSString * bytesStr = [bytesAry componentsJoinedByString:@""];;
    NSLog(@"bytesStr%@",bytesStr);

    
    if(bytesStr.length == 32){
        [self functionDecryptToy:bytesStr];
    }

}

//获取API TOKEN
-(IBAction)selectorBtn1:(id)sender
{
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    [params setJsonValue:@"Client_C11BAFF8287A495BB339BFF79E18A03E" key:@"clientId"];//平台的clientId
    [params setJsonValue:@"client_credentials" key:@"grantType"];//授权方式，该参数为固定字符串'client_credentials',即客户端凭证模式

    //http://192.168.31.163:8115
    NSString *getPlatformApiToken = @"http://192.168.31.163:8115/system/api/device/common/getPlatformApiToken";
    SBJson5Writer *writer = [[SBJson5Writer alloc] init];
    NSString *jsonStr = [writer stringWithObject:params];

    NSURL *url = [NSURL URLWithString:getPlatformApiToken];
    //创建请求request
    NSMutableURLRequest *request =[NSMutableURLRequest requestWithURL:url cachePolicy:0 timeoutInterval:60];
    //设置请求方式为POST
    request.HTTPMethod = @"POST";
    //设置请求内容格式
    request.HTTPBody = [jsonStr dataUsingEncoding:NSUTF8StringEncoding];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:@"TEST" forHTTPHeaderField:@"Environment"];

    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    manager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json", @"text/json", @"text/javascript", @"text/html",@"image/jpeg",@"text/plain", nil];
    
    [[manager dataTaskWithRequest:request uploadProgress:nil downloadProgress:nil completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
        
        NSString * str  =[[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
        NSData *data = [str dataUsingEncoding:NSUTF8StringEncoding];
        NSDictionary *tempDictQueryDiamond = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        NSString *state = [NSString stringWithFormat:@"%@",[tempDictQueryDiamond objectForKey:@"code"]];
        if ([state isEqualToString:@"200"]) {
            NSDictionary * data = tempDictQueryDiamond[@"data"];
            _platformApiToken = [NSString stringWithFormat:@"%@",[data objectForKey:@"platformApiToken"]];
            _expiresTime = [NSString stringWithFormat:@"%@",[data objectForKey:@"expiresTime"]];
            UIAlertController *alertC = [UIAlertController alertControllerWithTitle:@"API TOKEN" message:_platformApiToken preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *actionCancle1 = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                [self.navigationController popToViewController:self.navigationController.viewControllers[0] animated:YES];
            }];

            [alertC addAction:actionCancle1];

            [self presentViewController:alertC animated:YES completion:nil];

        }else
        {
            
            NSString *message = [NSString stringWithFormat:@"%@",[tempDictQueryDiamond objectForKey:@"message"]];
            if([message isEqualToString:@"(null)"]){
                message = @"请检查网络连接是否正常";
            }
            
        }
        [MBProgressHUD hideHUDForView:self.view animated:YES];
    }] resume];

}
//连接设备
-(IBAction)selectorBtn2:(id)sender
{
    APIBuletoothListViewController * list = [[APIBuletoothListViewController alloc] init];
    [self.navigationController pushViewController:list animated:YES];
}
//绑定设备
-(IBAction)selectorBtn3:(id)sender
{
    if (!_platformApiToken || [_platformApiToken isEqualToString:@"(null)"]) {
        //请先获取APITOKEN
        return;
    }
    if (!_bluetoothAddress || [_bluetoothAddress isEqualToString:@"(null)"]) {
        //请先连接设备
        return;
    }
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    [params setJsonValue:_bluetoothAddress key:@"bluetoothAddress"];

    NSString *addDeviceInfo = @"http://192.168.31.163:8115/system/api/platform/device/addDeviceInfo";
    SBJson5Writer *writer = [[SBJson5Writer alloc] init];
    NSString *parametersStr = [writer stringWithObject:params];

    NSURL *url = [NSURL URLWithString:addDeviceInfo];
    //创建请求request
    NSMutableURLRequest *request =[NSMutableURLRequest requestWithURL:url cachePolicy:0 timeoutInterval:60];
    //设置请求方式为POST
    request.HTTPMethod = @"POST";
    //设置请求内容格式
    request.HTTPBody = [parametersStr dataUsingEncoding:NSUTF8StringEncoding];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request addValue:@"TEST" forHTTPHeaderField:@"Environment"];
    [request addValue:_platformApiToken forHTTPHeaderField:@"Authorization"];

    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    manager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json", @"text/json", @"text/javascript", @"text/html",@"image/jpeg",@"text/plain", nil];
    
    [[manager dataTaskWithRequest:request uploadProgress:nil downloadProgress:nil completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
        
        NSString * decryptedText  =[[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
        NSData *data = [decryptedText dataUsingEncoding:NSUTF8StringEncoding];
        NSDictionary *tempDictQueryDiamond = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        NSString *state = [NSString stringWithFormat:@"%@",[tempDictQueryDiamond objectForKey:@"code"]];
        if ([state isEqualToString:@"200"]) {
            NSDictionary * data = tempDictQueryDiamond[@"data"];
            NSString * message = [NSString stringWithFormat:@"createBy:%@ # createTime:%@ # environmentType:%@ # iccid:%@ # serialNumber:%@ # typeId:%@",data[@"createBy"],data[@"createTime"],data[@"environmentType"],data[@"iccid"],data[@"serialNumber"],data[@"typeId"]];
            UIAlertController *alertC = [UIAlertController alertControllerWithTitle:@"设备信息" message:message preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *actionCancle1 = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                [self.navigationController popToViewController:self.navigationController.viewControllers[0] animated:YES];
            }];

            [alertC addAction:actionCancle1];

            [self presentViewController:alertC animated:YES completion:nil];
            
            _typeId = [NSString stringWithFormat:@"%@",data[@"typeId"]];
            _serialNumber = [NSString stringWithFormat:@"%@",data[@"serialNumber"]];
        }else
        {
            NSString *message = [NSString stringWithFormat:@"%@",[tempDictQueryDiamond objectForKey:@"message"]];
            if([message isEqualToString:@"(null)"]){
                message = @"请检查网络连接是否正常";
            }
            
            UIAlertController *alertC = [UIAlertController alertControllerWithTitle:@"AddDeviceInfo" message:message preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *actionCancle1 = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                [self.navigationController popToViewController:self.navigationController.viewControllers[0] animated:YES];
            }];

            [alertC addAction:actionCancle1];

            [self presentViewController:alertC animated:YES completion:nil];

        }
        [MBProgressHUD hideHUDForView:self.view animated:YES];
    }] resume];

}
//获取设备信息
-(IBAction)selectorBtn4:(id)sender
{
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    [params setJsonValue:_bluetoothAddress key:@"bluetoothAddress"];

    NSString *addDeviceInfo = @"http://192.168.31.163:8115/system/api/platform/device/queryDeviceInfo";
    SBJson5Writer *writer = [[SBJson5Writer alloc] init];
    NSString *parametersStr = [writer stringWithObject:params];

    NSURL *url = [NSURL URLWithString:addDeviceInfo];
    //创建请求request
    NSMutableURLRequest *request =[NSMutableURLRequest requestWithURL:url cachePolicy:0 timeoutInterval:60];
    //设置请求方式为POST
    request.HTTPMethod = @"POST";
    //设置请求内容格式
    request.HTTPBody = [parametersStr dataUsingEncoding:NSUTF8StringEncoding];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request addValue:@"TEST" forHTTPHeaderField:@"Environment"];
    [request addValue:_platformApiToken forHTTPHeaderField:@"Authorization"];

    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    manager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json", @"text/json", @"text/javascript", @"text/html",@"image/jpeg",@"text/plain", nil];
    
    [[manager dataTaskWithRequest:request uploadProgress:nil downloadProgress:nil completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
        
        NSString * decryptedText  =[[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
        NSData *data = [decryptedText dataUsingEncoding:NSUTF8StringEncoding];
        NSDictionary *tempDictQueryDiamond = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        NSString *state = [NSString stringWithFormat:@"%@",[tempDictQueryDiamond objectForKey:@"code"]];
        if ([state isEqualToString:@"200"]) {
            NSDictionary * data = tempDictQueryDiamond[@"data"];
            NSString * message = [NSString stringWithFormat:@"createBy:%@ # createTime:%@ # environmentType:%@ # iccid:%@ # serialNumber:%@ # typeId:%@",data[@"createBy"],data[@"createTime"],data[@"environmentType"],data[@"iccid"],data[@"serialNumber"],data[@"typeId"]];
            UIAlertController *alertC = [UIAlertController alertControllerWithTitle:@"设备信息" message:message preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *actionCancle1 = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                [self.navigationController popToViewController:self.navigationController.viewControllers[0] animated:YES];
            }];

            [alertC addAction:actionCancle1];

            [self presentViewController:alertC animated:YES completion:nil];
            
            _typeId = [NSString stringWithFormat:@"%@",data[@"typeId"]];
            _serialNumber = [NSString stringWithFormat:@"%@",data[@"serialNumber"]];
        }else
        {
            NSString *message = [NSString stringWithFormat:@"%@",[tempDictQueryDiamond objectForKey:@"message"]];
            if([message isEqualToString:@"(null)"]){
                message = @"请检查网络连接是否正常";
            }
        }
        [MBProgressHUD hideHUDForView:self.view animated:YES];
    }] resume];

}
//获取TOKEN
-(IBAction)selectorBtn5:(id)sender
{

    
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    [params setJsonValue:_bluetoothAddress key:@"bluetoothAddress"];//平台的clientId
    [params setJsonValue:_serialNumber key:@"serialNumber"];//Device Code
    [params setJsonValue:_typeId key:@"typeId"];//设备编号

    NSString *addDeviceInfo = @"http://192.168.31.163:8115/system/api/device/common/getDeviceToken";
    SBJson5Writer *writer = [[SBJson5Writer alloc] init];
    NSString *parametersStr = [writer stringWithObject:params];

    NSURL *url = [NSURL URLWithString:addDeviceInfo];
    //创建请求request
    NSMutableURLRequest *request =[NSMutableURLRequest requestWithURL:url cachePolicy:0 timeoutInterval:60];
    //设置请求方式为POST
    request.HTTPMethod = @"POST";
    //设置请求内容格式
    request.HTTPBody = [parametersStr dataUsingEncoding:NSUTF8StringEncoding];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request addValue:@"TEST" forHTTPHeaderField:@"Environment"];
    [request addValue:_platformApiToken forHTTPHeaderField:@"Authorization"];

    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    manager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json", @"text/json", @"text/javascript", @"text/html",@"image/jpeg",@"text/plain", nil];
    
    [[manager dataTaskWithRequest:request uploadProgress:nil downloadProgress:nil completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
        
        NSString * decryptedText  =[[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
        NSData *data = [decryptedText dataUsingEncoding:NSUTF8StringEncoding];
        NSDictionary *tempDictQueryDiamond = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        NSString *state = [NSString stringWithFormat:@"%@",[tempDictQueryDiamond objectForKey:@"code"]];
        if ([state isEqualToString:@"200"]) {
            UIAlertController *alertC = [UIAlertController alertControllerWithTitle:@"设备TOKEN" message:tempDictQueryDiamond[@"data"] preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *actionCancle1 = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                [self.navigationController popToViewController:self.navigationController.viewControllers[0] animated:YES];
            }];

            [alertC addAction:actionCancle1];

            [self presentViewController:alertC animated:YES completion:nil];
            
            _deviceToken = [NSString stringWithFormat:@"%@",tempDictQueryDiamond[@"data"]];
            
            _babyMgr = [HKBabyBluetoothManager sharedManager];
            _babyMgr.delegate = self;
            [_babyMgr connectPeripheral:_peripheral];

        }else
        {
            NSString *message = [NSString stringWithFormat:@"%@",[tempDictQueryDiamond objectForKey:@"message"]];
            if([message isEqualToString:@"(null)"]){
                message = @"请检查网络连接是否正常";
            }
        }
        [MBProgressHUD hideHUDForView:self.view animated:YES];
    }] resume];

}
//开锁
-(IBAction)selectorBtn6:(id)sender
{
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    [params setJsonValue:_bluetoothAddress key:@"bluetoothAddress"];//平台的clientId
    [params setJsonValue:_serialNumber key:@"serialNumber"];//Device Code
    [params setJsonValue:_typeId key:@"typeId"];//设备编号

    NSString *addDeviceInfo = @"http://192.168.31.163:8115/system/api/device/keyPod/getKeyPodUnlockCmd";
    SBJson5Writer *writer = [[SBJson5Writer alloc] init];
    NSString *parametersStr = [writer stringWithObject:params];

    NSURL *url = [NSURL URLWithString:addDeviceInfo];
    //创建请求request
    NSMutableURLRequest *request =[NSMutableURLRequest requestWithURL:url cachePolicy:0 timeoutInterval:60];
    //设置请求方式为POST
    request.HTTPMethod = @"POST";
    //设置请求内容格式
    request.HTTPBody = [parametersStr dataUsingEncoding:NSUTF8StringEncoding];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request addValue:@"TEST" forHTTPHeaderField:@"Environment"];
    [request addValue:_platformApiToken forHTTPHeaderField:@"Authorization"];

    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    manager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json", @"text/json", @"text/javascript", @"text/html",@"image/jpeg",@"text/plain", nil];
    
    [[manager dataTaskWithRequest:request uploadProgress:nil downloadProgress:nil completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
        
        NSString * decryptedText  =[[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
        NSData *data = [decryptedText dataUsingEncoding:NSUTF8StringEncoding];
        NSDictionary *tempDictQueryDiamond = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        NSString *state = [NSString stringWithFormat:@"%@",[tempDictQueryDiamond objectForKey:@"code"]];
        if ([state isEqualToString:@"200"]) {
                [self functionUnsend:tempDictQueryDiamond[@"data"]];
        }else
        {
            NSString *message = [NSString stringWithFormat:@"%@",[tempDictQueryDiamond objectForKey:@"message"]];
            if([message isEqualToString:@"(null)"]){
                message = @"请检查网络连接是否正常";
            }
        }
        [MBProgressHUD hideHUDForView:self.view animated:YES];
    }] resume];

}
//关锁
-(IBAction)selectorBtn7:(id)sender
{
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    [params setJsonValue:_bluetoothAddress key:@"bluetoothAddress"];//平台的clientId
    [params setJsonValue:_serialNumber key:@"serialNumber"];//Device Code
    [params setJsonValue:_typeId key:@"typeId"];//设备编号

    NSString *addDeviceInfo = @"http://192.168.31.163:8115/system/api/device/keyPod/getKeyPodLockCmd";
    SBJson5Writer *writer = [[SBJson5Writer alloc] init];
    NSString *parametersStr = [writer stringWithObject:params];

    NSURL *url = [NSURL URLWithString:addDeviceInfo];
    //创建请求request
    NSMutableURLRequest *request =[NSMutableURLRequest requestWithURL:url cachePolicy:0 timeoutInterval:60];
    //设置请求方式为POST
    request.HTTPMethod = @"POST";
    //设置请求内容格式
    request.HTTPBody = [parametersStr dataUsingEncoding:NSUTF8StringEncoding];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request addValue:@"TEST" forHTTPHeaderField:@"Environment"];
    [request addValue:_platformApiToken forHTTPHeaderField:@"Authorization"];

    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    manager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json", @"text/json", @"text/javascript", @"text/html",@"image/jpeg",@"text/plain", nil];
    
    [[manager dataTaskWithRequest:request uploadProgress:nil downloadProgress:nil completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
        
        NSString * decryptedText  =[[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
        NSData *data = [decryptedText dataUsingEncoding:NSUTF8StringEncoding];
        NSDictionary *tempDictQueryDiamond = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        NSString *state = [NSString stringWithFormat:@"%@",[tempDictQueryDiamond objectForKey:@"code"]];
        if ([state isEqualToString:@"200"]) {
                [self functionUnsend:tempDictQueryDiamond[@"data"]];
        }else
        {
            NSString *message = [NSString stringWithFormat:@"%@",[tempDictQueryDiamond objectForKey:@"message"]];
            if([message isEqualToString:@"(null)"]){
                message = @"请检查网络连接是否正常";
            }
        }
        [MBProgressHUD hideHUDForView:self.view animated:YES];
    }] resume];

}
//断开连接
-(IBAction)selectorBtn8:(id)sender
{
    [_babyMgr stopScanPeripheral];
    [_babyMgr disconnectAllPeripherals];

}

- (void)connectFailed {
    // 连接失败、做连接失败的处理
}
- (void)disconnectPeripheral:(CBPeripheral *)peripheral {
    // 获取到当前断开的设备 这里可做断开UI提示处理
    
}
//解密蓝牙返回的命令
-(void)functionDecryptToy:(NSString *)str
{
    
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    [params setJsonValue:str key:@"lockCommand"];//Command Returned by Device
    [params setJsonValue:_serialNumber key:@"serialNumber"];//Device Code

    NSString *addDeviceInfo = @"http://192.168.31.163:8115/system/api/device/keyPod/decryBluetoothCommand";
    SBJson5Writer *writer = [[SBJson5Writer alloc] init];
    NSString *parametersStr = [writer stringWithObject:params];

    NSURL *url = [NSURL URLWithString:addDeviceInfo];
    //创建请求request
    NSMutableURLRequest *request =[NSMutableURLRequest requestWithURL:url cachePolicy:0 timeoutInterval:60];
    //设置请求方式为POST
    request.HTTPMethod = @"POST";
    //设置请求内容格式
    request.HTTPBody = [parametersStr dataUsingEncoding:NSUTF8StringEncoding];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request addValue:@"TEST" forHTTPHeaderField:@"Environment"];
    [request addValue:_platformApiToken forHTTPHeaderField:@"Authorization"];

    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    manager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json", @"text/json", @"text/javascript", @"text/html",@"image/jpeg",@"text/plain", nil];
    
    [[manager dataTaskWithRequest:request uploadProgress:nil downloadProgress:nil completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
        
        NSString * decryptedText  =[[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
        NSData *data = [decryptedText dataUsingEncoding:NSUTF8StringEncoding];
        NSDictionary *tempDictQueryDiamond = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        NSString *state = [NSString stringWithFormat:@"%@",[tempDictQueryDiamond objectForKey:@"code"]];
        if ([state isEqualToString:@"200"]) {
        }else
        {
            NSString *message = [NSString stringWithFormat:@"%@",[tempDictQueryDiamond objectForKey:@"message"]];
            if([message isEqualToString:@"(null)"]){
                message = @"请检查网络连接是否正常";
            }
        }
        [MBProgressHUD hideHUDForView:self.view animated:YES];
    }] resume];


}

@end
