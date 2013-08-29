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
    NSString *backupDirectory = [_backupDirectoryField stringValue];
    
    // ディレクトリが指定されていない場合はファイル移動しないためバリデーションも不要
    if([backupDirectory length] == 0){
        return isValidate;
    }
    
    // ディレクトリの存在チェック
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL existsSpecifiedDirectory = ![fileManager fileExistsAtPath:backupDirectory];
    if(!existsSpecifiedDirectory){
        [_directoryError setStringValue:[NSString stringWithFormat:@"* The specified directory does not exist.[%@]", backupDirectory]];
        isValidate = YES;
        [_directoryError setHidden:!isValidate];
        return isValidate;
    }

    // バックアップディレクトリをサブディレクトリに設定していないかをチェック
    NSString *targetDirectoryPath = [inputDataOfView objectForKey:@"directoryPath"];
    int includeSubdirectory = [[inputDataOfView objectForKey:@"includeSubDirectory"] intValue];
    if(includeSubdirectory == 0){
        // サブディレクトリを検索対象に含めない場合
        if([[targetDirectoryPath stringByExpandingTildeInPath] isEqualToString:[backupDirectory stringByExpandingTildeInPath]]){
            [_directoryError setStringValue:[NSString stringWithFormat:@"* Can't specify the subdirectory of this directory.[%@]", targetDirectoryPath]];
            isValidate = YES;
            [_directoryError setHidden:!isValidate];
            return isValidate;
        }
    }else{
        // サブディレクトリを検索対象に含める場合
        if([self isIncludeDirectory:targetDirectoryPath andSubDirectory:backupDirectory]){
            [_directoryError setStringValue:[NSString stringWithFormat:@"* Can't specify the subdirectory of this directory.[%@]", targetDirectoryPath]];
            isValidate = YES;
            [_directoryError setHidden:!isValidate];
            return isValidate;
        }
    }
    
    return isValidate;
}

-(NSMutableDictionary*)setViewData:(NSMutableDictionary*)inputData{
    NSString *backupDirectory = [_backupDirectoryField stringValue];
    [inputData setValue:backupDirectory forKey:@"backupPath"];
    if([backupDirectory length] == 0){  // バックアップディレクトリが指定されていない場合はファイル移動しない
        [inputData setValue:@"0" forKey:@"movesFile"];
    }else{  // バックアップディレクトリが指定されている場合はファイル移動する
        [inputData setValue:@"1" forKey:@"movesFile"];
    }
    
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
