//
//  SelectDataSourceView.m
//  RecDesktop
//
//  Created by AirMyac on 7/2/13.
//  Copyright (c) 2013 com.katzlifehack. All rights reserved.
//

#import "SelectDataSourceView.h"

@interface SelectDataSourceView ()

@end

@implementation SelectDataSourceView

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

-(int)getDataSource{
    return (int)[_dataSourceComboBox indexOfSelectedItem];
    
}

-(NSString*)getTest{
    return [_test stringValue];
}


@end
