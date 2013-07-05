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
    [_directoryField selectItemAtIndex:0];
    [_directoryError setHidden:YES];
    [_otherDirectoryField setObjectValue:[inputData objectForKey:@"otherPath"]];

    [_otherDirectoryField setHidden:YES];
    
}

-(NSMutableDictionary*)setViewData:(NSMutableDictionary*)inputData{
    
    [inputData setValue:[NSNumber numberWithInteger:[_directoryField indexOfSelectedItem]] forKey:@"directory"];
    [inputData setValue:[_otherDirectoryField stringValue] forKey:@"otherPath"];
    return inputData;
    
}

-(BOOL)validate{
    BOOL isValidate = NO;
    if([_directoryField indexOfSelectedItem] < 0){
        [_directoryError setHidden:NO];
        isValidate = YES;
    }
    return isValidate;
}



@end
