//
//  NSDate+NSDate_Util_h.h
//  AutoMemorizeDesktop
//
//  Created by AirMyac on 6/2/13.
//  Copyright (c) 2013 com.katzlifehack. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDate (Util)

/*
 * ローカル時刻へ変換
 */
- (NSDate*)toLocalTime;

/*
 * yyyy/MM/dd hh:mm:ssフォーマットの文字列に変換
 */
- (NSString*)toString;

@end
