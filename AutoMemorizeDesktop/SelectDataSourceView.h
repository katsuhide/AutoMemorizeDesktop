//
//  SelectDataSourceView.h
//  RecDesktop
//
//  Created by AirMyac on 7/2/13.
//  Copyright (c) 2013 com.katzlifehack. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface SelectDataSourceView : NSViewController

// DataSourceView
@property (retain) IBOutlet NSComboBox *dataSourceComboBox;
@property (retain) IBOutlet NSTextField *test;

-(int)getDataSource;

-(NSString*)getTest;

@end
