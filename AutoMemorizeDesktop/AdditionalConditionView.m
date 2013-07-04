//
//  AdditionalConditionView.m
//  RecDesktop
//
//  Created by AirMyac on 7/3/13.
//  Copyright (c) 2013 com.katzlifehack. All rights reserved.
//

#import "AdditionalConditionView.h"

@interface AdditionalConditionView ()

@end

@implementation AdditionalConditionView

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

-(void)initialize{
    
    [_notetitleField setObjectValue:nil];
    [_notebookField setObjectValue:nil];
    AppDelegate *appDelegate = (AppDelegate*)[[NSApplication sharedApplication] delegate];
    NSMutableArray *notebookList = [appDelegate getNotebookList];
    for(NSDictionary *notebook in notebookList){
        [_notebookField addItemWithObjectValue:[notebook objectForKey:@"name"]];
    }    
    [_tagField setObjectValue:nil];
    
}

-(NSMutableDictionary*)setViewData:(NSMutableDictionary*)inputData{
    NSString *noteTitle = [_notetitleField stringValue];
    NSString *notebookName = [_notebookField stringValue];
    NSString *tag = [_tagField stringValue];
    
    [inputData setValue:noteTitle forKey:@"notetitle"];
    [inputData setValue:notebookName forKey:@"notebook"];
    [inputData setValue:tag forKey:@"tag"];

    return inputData;
}


@end
