//
//  NSMutableDictionary+JMJson.m
//  JMBaseProject
//
//  Created by liuny on 2018/7/14.
//  Copyright © 2018年 liuny. All rights reserved.
//

#import "NSMutableDictionary+JMJson.h"

@implementation NSMutableDictionary (JMJson)
-(void)setJsonValue:(NSString *)value key:(NSString *)key{
    if(key != nil && key.length > 0){
        self[key] = value==nil?@"":value;
    }
}
@end
