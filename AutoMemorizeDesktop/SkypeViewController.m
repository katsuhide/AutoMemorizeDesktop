//
//  SkypeViewController.m
//  AutoMemorizeDesktop
//
//  Created by AirMyac on 6/15/13.
//  Copyright (c) 2013 com.katzlifehack. All rights reserved.
//

#import "SkypeViewController.h"
#import "NSColor+Hex.h"

@interface SkypeViewController ()

@end

@implementation SkypeViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

-(NSString*)getSkypeDBFilePathField{
    return [_skypeDBFilePathField stringValue];
}

-(NSString*)getParticipantsField{
    return [_participantsField stringValue];
}

-(NSMutableString*)getParams{
    NSMutableString *params = [NSMutableString string];
    [params appendString:[self transformKeyValue:@"file_path" andValue:[self getSkypeDBFilePathField]]];
    [params appendString:[self transformKeyValue:@"participants" andValue:[self getParticipantsField]]];
    return params;
}

// key=value形式でデータを生成する
-(NSString*)transformKeyValue:(NSString*) key andValue:(NSString*) value{
    return [NSString stringWithFormat:@"%@=%@|", key, value];
}

-(void)changeCustomTaskView:(BOOL)isEditable andData:(TaskSource*)source{
    // 指定されたモードに設定
    [_skypeDBFilePathField setEditable:isEditable];
    [_participantsField setEditable:isEditable];
    
    // データを設定もしくは初期化
    if(isEditable){
        [_skypeDBFilePathField setStringValue:nil];
        [_participantsField setStringValue:nil];
        
    }else{
        [_skypeDBFilePathField setStringValue:[source getKeyValue:@"file_path"]];
        [_participantsField setStringValue:[source getKeyValue:@"participants"]];
    }
    
}

@end
