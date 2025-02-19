//
//  AppDelegate.m
//  QIUI-API
//
//  Created by mac on 2025/2/12.
//

#import "AppDelegate.h"
#import "APIHomeViewController.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    APIHomeViewController * home = [[APIHomeViewController alloc] init];
    home.title = @"QIUI-API";
    UINavigationController * nav = [[UINavigationController alloc] initWithRootViewController:home];

    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    
    self.window.rootViewController = nav;
    
    [self.window makeKeyAndVisible];
    
    self.window.backgroundColor = [UIColor whiteColor];
    return YES;
}

@end
