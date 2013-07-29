//
//  SafariView.m
//  RecDesktop
//
//  Created by AirMyac on 7/29/13.
//  Copyright (c) 2013 com.katzlifehack. All rights reserved.
//

#import "SafariView.h"
#import "AppDelegate.h"

@interface SafariView ()

@end

@implementation SafariView

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}


-(void)initialize:(NSMutableDictionary*)inputData{
    // 初期化
    [_safariError setHidden:YES];
}

-(NSMutableDictionary*)setViewData:(NSMutableDictionary*)inputData{
    // 画面データの取得
    return inputData;
}

-(BOOL)validate{
    BOOL isValidate = NO;
    // 履歴ディレクトリが存在しているかをチェック
    NSString *webHistoryPath = [NSHomeDirectory() stringByAppendingString:@"/Library/Caches/Metadata/Safari/History/"];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if(![fileManager fileExistsAtPath:webHistoryPath]){
        [_safariError setStringValue:[NSString stringWithFormat:@"* Safari's Web History Directory doesn't exist.[%@]", webHistoryPath]];
        isValidate = YES;
        [_safariError setHidden:!isValidate];
        return isValidate;
    }

    // Safari Taskが存在しているかをチェック
    AppDelegate *appDelegate = (AppDelegate*)[[NSApplication sharedApplication] delegate];
    isValidate = [appDelegate isExistSafariTask];
    if(isValidate){
        [_safariError setStringValue:@"* Safari Task already exists."];
        [_safariError setHidden:!isValidate];
        return isValidate;
    }
    return isValidate;
}

@end
