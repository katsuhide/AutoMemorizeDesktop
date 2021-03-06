//
//  FileTaskView.m
//  RecDesktop
//
//  Created by AirMyac on 7/5/13.
//  Copyright (c) 2013 com.katzlifehack. All rights reserved.
//

#import "FileTaskView.h"

@interface FileTaskView ()

@end

@implementation FileTaskView

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

-(void)initialize:(NSMutableDictionary*)inputData{
    // target directory
    [_directoryField setObjectValue:[inputData objectForKey:@"directoryPath"]];
    [_directoryError setHidden:YES];
    
    // includeSubDirectory check box
    [_searchSubDirectory setState:[[inputData objectForKey:@"includeSubDirectory"] integerValue]];
    
    // file chooser btn
    NSString *imagePath = [[NSBundle mainBundle] pathForResource:@"FileChoose" ofType:@"png"];
    NSImage *image = [[NSImage alloc]initByReferencingFile:imagePath];
    [_fileChooseBtn setImage:image];
    
}

-(BOOL)validate{
    BOOL isValidate = NO;
    if([[_directoryField stringValue] length] == 0){
        [_directoryError setHidden:NO];
        isValidate = YES;
    }
    return isValidate;
}

-(NSMutableDictionary*)setViewData:(NSMutableDictionary*)inputData{
    [inputData setValue:[_directoryField stringValue] forKey:@"directoryPath"];
    [inputData setValue:[NSNumber numberWithInteger:[_searchSubDirectory state]] forKey:@"includeSubDirectory"];
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
    [_directoryField setStringValue:path];
}

@end
