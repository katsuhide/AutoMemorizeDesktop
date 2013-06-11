//
//  NSDate+NSDate_Util_h.m
//  AutoMemorizeDesktop
//
//  Created by AirMyac on 6/2/13.
//  Copyright (c) 2013 com.katzlifehack. All rights reserved.
//

#import "NSDate+Util.h"

@implementation NSDate (Util)

- (NSDate*)toLocalTime{
    
    NSTimeZone *tz = [NSTimeZone defaultTimeZone];
    NSInteger seconds = [tz secondsFromGMTForDate: self];
    return [NSDate dateWithTimeInterval: seconds sinceDate: self];
    
}

- (NSString*)toString{
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    df.dateFormat  = @"yyyy/MM/dd HH:mm:ss";
    return [df stringFromDate:self];
}

- (NSString*)toStringWithFormat:(NSString*) format{
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    df.dateFormat  = format;
    return [df stringFromDate:self];
}

@end
