//
//  NSDictionary+JMJson.h
//  JMBaseProject
//
//  Created by liuny on 2018/7/14.
//  Copyright © 2018年 liuny. All rights reserved.
//

/*
 *主要用于网络请求，JSON解析空判断，以及小数位数的保留
 */

#import <Foundation/Foundation.h>

@interface NSDictionary (JMJson)
-(NSString *)getJsonValue:(NSString *)key;
@end
