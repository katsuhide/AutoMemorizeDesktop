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

@property (assign) BOOL canAddNote;

@property (strong) WebView *webView;

- (void)polling:(NSTimer*)timer;

@end
