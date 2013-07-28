//
//  SafariTaskService.h
//  RecDesktop
//
//  Created by AirMyac on 7/24/13.
//  Copyright (c) 2013 com.katzlifehack. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>
#import "NSData+EvernoteSDK.h"
#import "EvernoteServiceUtil.h"

// デリゲートを定義
@protocol SafariDelegate <NSObject>

-(void)deleteServiceQueue:(int)queueId;

-(void)setEvernoteDelegate:(EvernoteServiceUtil*)enService;

@end

@interface SafariTaskService : NSObject

@property (retain) WebView *webView;

@property int serviceQueueId;

@property (nonatomic, assign) id<SafariDelegate> delegate;

// イニシャライザ
- (id)init;

/*
 * 指定されたURLのページを描画する
 */
-(void)loadWebHistory:(NSString*)targetURL andQueueId:(int)queueId;

@end
