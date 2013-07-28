//
//  TaskForSafari.h
//  RecDesktop
//
//  Created by AirMyac on 7/19/13.
//  Copyright (c) 2013 com.katzlifehack. All rights reserved.
//

#import "Task.h"
#import <WebKit/WebKit.h>

@interface TaskForSafari : Task

@property (retain) TaskSource *source;

@property (assign) BOOL canAddNote;

@property (strong) WebView *webView;

@property (retain) NSMutableDictionary *serviceQueue;

- (void)polling:(NSTimer*)timer;

/*
 * サービスキューを削除し、空になった場合はロックを解除する
 */
-(void)deleteServiceQueue:(int)queueId;

@end
