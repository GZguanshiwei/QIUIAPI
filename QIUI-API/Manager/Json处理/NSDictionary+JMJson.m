//
//  NSDictionary+JMJson.m
//  JMBaseProject
//
//  Created by liuny on 2018/7/14.
//  Copyright © 2018年 liuny. All rights reserved.
//

#import "NSDictionary+JMJson.h"

@implementation NSDictionary (JMJson)
-(NSString *)getJsonValue:(NSString *)key{
    NSString *value = self[key];
    if(value == nil || [value isEqual:[NSNull null]]){
        value = @"";
    }else{
        value = [NSString stringWithFormat:@"%@",value];
        if([self isPureDouble:value]){
            NSArray *array = [value componentsSeparatedByString:@"."];
            //有小数
            if(array.count == 2)
            {
                double pointNum = [value doubleValue];
                value = [NSString stringWithFormat:@"%.2f",pointNum];
            }
        }
    }
    return value;
}

//判断是否为整形
-(BOOL)isPureInt:(NSString *)string{
    NSScanner *scan = [NSScanner scannerWithString:string];
    int val;
    return [scan scanInt:&val] && [scan isAtEnd];
}

//判断是否为double
-(BOOL)isPureDouble:(NSString *)string{
    NSScanner *scan = [NSScanner scannerWithString:string];
    double val;
    return [scan scanDouble:&val] && [scan isAtEnd];
}

//判断是否为浮点型
-(BOOL)isPureFloat:(NSString *)string{
    NSScanner *scan = [NSScanner scannerWithString:string];
    float val;
    return [scan scanFloat:&val] && [scan isAtEnd];
}
@end
