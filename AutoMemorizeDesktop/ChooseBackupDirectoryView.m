//
//  ChooseBackupDirectoryView.m
//  RecDesktop
//
//  Created by AirMyac on 7/5/13.
//  Copyright (c) 2013 com.katzlifehack. All rights reserved.
//

#import "ChooseBackupDirectoryView.h"
#import "AppDelegate.h"

@interface ChooseBackupDirectoryView ()

@end

@implementation ChooseBackupDirectoryView

NSDictionary *inputDataOfView;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Initialization code here.
        inputDataOfView = [NSDictionary dictionary];
    }
    
    return self;
}


-(void)initialize:(NSMutableDictionary*)inputData{
    inputDataOfView = inputData;
    [_backupDirectoryField setObjectValue:[inputData objectForKey:@"backupPath"]];
    [_directoryError setHidden:YES];
    
    NSString *imagePath = [[NSBundle mainBundle] pathForResource:@"FileChoose" ofType:@"png"];
    NSImage *image = [[NSImage alloc]initByReferencingFile:imagePath];
    [_fileChooseBtn setImage:image];

}

-(BOOL)validate{
    BOOL isValidate = NO;
    // 必須チェック
    NSString *backupDirectroy = [_backupDirectoryField stringValue];
    if([backupDirectroy length] == 0){
        [_directoryError setStringValue:@"* Choose the backup directory."];
        isValidate = YES;
        [_directoryError setHidden:!isValidate];
        return isValidate;
    }
    
    // バックアップディレクトリをサブディレクトリに設定していないかをチェック
    AppDelegate *appDelegate = (AppDelegate*)[[NSApplication sharedApplication] delegate];
    NSString *targetDirectoryPath = [appDelegate getFilePath:inputDataOfView];
    int includeSubdirectory = [[inputDataOfView objectForKey:@"search"] intValue];
    if(includeSubdirectory == 0){
        // サブディレクトリを検索対象に含めない場合
        if([[targetDirectoryPath stringByExpandingTildeInPath] isEqualToString:[backupDirectroy stringByExpandingTildeInPath]]){
            [_directoryError setStringValue:[NSString stringWithFormat:@"* Can't specify the subdirectory of this directory.[%@]", targetDirectoryPath]];
            isValidate = YES;
            [_directoryError setHidden:!isValidate];
            return isValidate;
        }
    }else{
        // サブディレクトリを検索対象に含める場合
        if([self isIncludeDirectory:targetDirectoryPath andSubDirectory:backupDirectroy]){
            [_directoryError setStringValue:[NSString stringWithFormat:@"* Can't specify the subdirectory of this directory.[%@]", targetDirectoryPath]];
            isValidate = YES;
            [_directoryError setHidden:!isValidate];
            return isValidate;
        }
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


-(BOOL)isIncludeDirectory:(NSString*)parentDirectory andSubDirectory:(NSString*)subDirectory{
    BOOL isInclude = YES;
    NSRange range = [subDirectory rangeOfString:parentDirectory];
    if (range.location == NSNotFound) {
        isInclude = NO;
    }
    return isInclude;
}

@end
