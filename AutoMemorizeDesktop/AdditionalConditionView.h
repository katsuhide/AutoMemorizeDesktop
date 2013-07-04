//
//  AdditionalConditionView.h
//  RecDesktop
//
//  Created by AirMyac on 7/3/13.
//  Copyright (c) 2013 com.katzlifehack. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "AppDelegate.h"

@interface AdditionalConditionView : NSViewController

@property (assign) IBOutlet NSTextField *notetitleField;
@property (assign) IBOutlet NSComboBox *notebookField;
@property (assign) IBOutlet NSTokenField *tagField;

-(NSMutableDictionary*)setViewData:(NSMutableDictionary*)inputData;

-(void)initialize;

@end
