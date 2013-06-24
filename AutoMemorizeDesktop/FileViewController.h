//
//  FileViewController.h
//  AutoMemorizeDesktop
//
//  Created by AirMyac on 6/15/13.
//  Copyright (c) 2013 com.katzlifehack. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "TaskSource.h"

@interface FileViewController : NSViewController

@property (assign) IBOutlet NSTextField *targetFilePathField;
@property (assign) IBOutlet NSTextField *fileExtensionField;

-(NSString*)getTargetFilePathField;

-(NSString*)getFileExtensionField;

-(NSMutableString*)getParams;

-(void)changeCustomTaskView:(BOOL)isEditable andData:(TaskSource*)source;

@end
