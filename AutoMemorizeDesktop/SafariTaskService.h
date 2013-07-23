//
//  SafariTaskService.h
//  RecDesktop
//
//  Created by AirMyac on 7/24/13.
//  Copyright (c) 2013 com.katzlifehack. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>

@interface SafariTaskService : NSObject

@property (retain) WebView *webView;

@property int serviceQueueId;

-(void)loadWebHistory:(NSString*)targetURL andQueueId:(int)queueId;


@end
