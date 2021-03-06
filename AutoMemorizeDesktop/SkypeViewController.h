//
//  SkypeViewController.h
//  AutoMemorizeDesktop
//
//  Created by AirMyac on 6/15/13.
//  Copyright (c) 2013 com.katzlifehack. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "TaskSource.h"

@interface SkypeViewController : NSViewController
@property (assign) IBOutlet NSTextField *skypeDBFilePathField;
@property (assign) IBOutlet NSTextField *participantsField;

-(NSString*)getSkypeDBFilePathField;

-(NSString*)getParticipantsField;

-(NSMutableString*)getParams;

-(void)changeCustomTaskView:(BOOL)isEditable andData:(TaskSource*)source;

@end
