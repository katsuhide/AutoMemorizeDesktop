//
//  SkypeView.h
//  RecDesktop
//
//  Created by AirMyac on 7/2/13.
//  Copyright (c) 2013 com.katzlifehack. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface SkypeView : NSViewController

@property (retain) IBOutlet NSTextField *skypeUserField;

@property (retain) IBOutlet NSTextField *skypeUserError;

-(void)initilize:(NSMutableDictionary*)inputData;

-(NSMutableDictionary*)setViewData:(NSMutableDictionary*)inputData;

-(BOOL)validate;

@end
