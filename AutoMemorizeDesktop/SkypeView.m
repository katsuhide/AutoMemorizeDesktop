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
}


-(NSMutableDictionary*)setViewData:(NSMutableDictionary*)inputData{
    NSString *skypeUser = [_skypeUserField stringValue];
    [inputData setValue:skypeUser forKey:@"skypeUser"];
    return inputData;
}

-(BOOL)validate{
    BOOL isValidate = NO;
    if([_skypeUserField stringValue].length == 0){
        [_skypeUserError setHidden:NO];
        isValidate = YES;
    }
    return isValidate;
}


@end
