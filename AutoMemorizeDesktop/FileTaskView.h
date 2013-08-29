//
//  FileTaskView.h
//  RecDesktop
//
//  Created by AirMyac on 7/5/13.
//  Copyright (c) 2013 com.katzlifehack. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface FileTaskView : NSViewController

@property (assign) IBOutlet NSTextField *directoryField;

@property (assign) IBOutlet NSTextField *directoryError;

@property (assign) IBOutlet NSButton *searchSubDirectory;

@property (assign) IBOutlet NSButton *fileChooseBtn;

-(void)initialize:(NSMutableDictionary*)inputData;

-(BOOL)validate;

-(NSMutableDictionary*)setViewData:(NSMutableDictionary*)inputData;

@end
