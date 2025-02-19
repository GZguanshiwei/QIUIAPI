//
//  NSMutableDictionary+JMJson.h
//  JMBaseProject
//
//  Created by liuny on 2018/7/14.
//  Copyright © 2018年 liuny. All rights reserved.
//

/*
 *主要用于网络请求，阻拦空值设置
 */

#import <Foundation/Foundation.h>

@interface NSMutableDictionary (JMJson)
-(void)setJsonValue:(NSString *)value key:(NSString *)key;
@end
