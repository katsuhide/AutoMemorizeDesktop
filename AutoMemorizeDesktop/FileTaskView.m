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
    [_directoryField setObjectValue:[inputData objectForKey:@"directoryPath"]];
    [_directoryError setHidden:YES];
    [_searchSubDirectory setState:[[inputData objectForKey:@"includeSubDirectory"] integerValue]];
    
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


@end
