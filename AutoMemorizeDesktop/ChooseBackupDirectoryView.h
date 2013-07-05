//
//  ChooseBackupDirectoryView.h
//  RecDesktop
//
//  Created by AirMyac on 7/5/13.
//  Copyright (c) 2013 com.katzlifehack. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface ChooseBackupDirectoryView : NSViewController

@property (assign) IBOutlet NSTextField *backupDirectoryField;

@property (assign) IBOutlet NSTextField *directoryError;

@property (assign) IBOutlet NSButton *fileChooseBtn;

-(void)initialize:(NSMutableDictionary*)inputData;

-(BOOL)validate;

-(NSMutableDictionary*)setViewData:(NSMutableDictionary*)inputData;

-(IBAction)setChoosedFilePath:(id)sender;

@end
