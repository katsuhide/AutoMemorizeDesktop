//
//  SafariView.h
//  RecDesktop
//
//  Created by AirMyac on 7/29/13.
//  Copyright (c) 2013 com.katzlifehack. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface SafariView : NSViewController

@property (retain) IBOutlet NSTextField *safariError;

-(void)initialize:(NSMutableDictionary*)inputData;

-(NSMutableDictionary*)setViewData:(NSMutableDictionary*)inputData;

-(BOOL)validate;

@end
