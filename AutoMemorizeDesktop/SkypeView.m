//
//  SkypeView.m
//  RecDesktop
//
//  Created by AirMyac on 7/2/13.
//  Copyright (c) 2013 com.katzlifehack. All rights reserved.
//

#import "SkypeView.h"

@interface SkypeView ()

@end

@implementation SkypeView

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

-(void)initilize:(NSMutableDictionary*)inputData{
    [_skypeUserField setObjectValue:[inputData objectForKey:@"skypeUser"]];
    [_skypeUserError setHidden:YES];
    [_isClassify setState:[[inputData objectForKey:@"isClassify"] integerValue]];
    
}


-(NSMutableDictionary*)setViewData:(NSMutableDictionary*)inputData{
    NSString *skypeUser = [_skypeUserField stringValue];
    [inputData setValue:skypeUser forKey:@"skypeUser"];
    [inputData setValue:[NSNumber numberWithInteger:[_isClassify state]] forKey:@"isClassify"];
    return inputData;
}

-(BOOL)validate{
    BOOL isValidate = NO;
    // 必須チェック
    NSString *skypeUser = [_skypeUserField stringValue];
    if(skypeUser.length == 0){
        [_skypeUserError setHidden:NO];
        [_skypeUserError setStringValue:@"* Enter your Skype User Name."];
        isValidate = YES;
    }
    
    // Skype Userチェック
    NSString *skypePath = [NSHomeDirectory() stringByAppendingString:@"/Library/Application Support/Skype/"];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *filePath = [skypePath stringByAppendingString:skypeUser];
    if(![fileManager fileExistsAtPath:filePath]){
        [_skypeUserError setHidden:NO];
        [_skypeUserError setStringValue:@"* Invalid Skype User Name."];
        isValidate = YES;
    }
    return isValidate;
}


@end
