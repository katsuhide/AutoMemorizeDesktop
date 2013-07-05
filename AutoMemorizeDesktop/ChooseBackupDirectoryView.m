//
//  ChooseBackupDirectoryView.m
//  RecDesktop
//
//  Created by AirMyac on 7/5/13.
//  Copyright (c) 2013 com.katzlifehack. All rights reserved.
//

#import "ChooseBackupDirectoryView.h"

@interface ChooseBackupDirectoryView ()

@end

@implementation ChooseBackupDirectoryView

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}


-(void)initialize:(NSMutableDictionary*)inputData{
    [_backupDirectoryField setObjectValue:[inputData objectForKey:@"backupPath"]];
    [_directoryError setHidden:YES];
    
    NSString *imagePath = [[NSBundle mainBundle] pathForResource:@"FileChoose" ofType:@"png"];
    NSImage *image = [[NSImage alloc]initByReferencingFile:imagePath];
    [_fileChooseBtn setImage:image];
//    [_fileChooseBtn setBordered:NO];

}

-(BOOL)validate{
    BOOL isValidate = NO;
    if([[_backupDirectoryField stringValue] length] == 0){
        [_directoryError setHidden:NO];
        isValidate = YES;
    }
    return isValidate;
}

-(NSMutableDictionary*)setViewData:(NSMutableDictionary*)inputData{
    [inputData setValue:[_backupDirectoryField stringValue] forKey:@"backupPath"];
    return inputData;    
}

-(IBAction)setChoosedFilePath:(id)sender{
    NSString *path;
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    [panel setCanChooseFiles:NO];
    [panel setCanChooseDirectories:YES];
    [panel setAllowsMultipleSelection:YES]; // yes if more than one dir is allowed
    NSInteger clicked = [panel runModal];
    if (clicked == NSFileHandlingPanelOKButton) {
        for (NSURL *url in [panel URLs]) {
            path = [url path];
        }
    }
    [_backupDirectoryField setStringValue:path];
}


@end
