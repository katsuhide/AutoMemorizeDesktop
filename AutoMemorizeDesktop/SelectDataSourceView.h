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

// Data Source Type Button
@property (assign) IBOutlet NSButton *skypeBtn;  // SKYPE
@property (assign) IBOutlet NSButton *pdfBtn;  // PDF
@property (assign) IBOutlet NSButton *textBtn;  // TEXT
@property (assign) IBOutlet NSButton *excelBtn;  // EXCEL
@property (assign) IBOutlet NSButton *wordBtn;  // WORD
@property (assign) IBOutlet NSButton *powerpointBtn;  // POWERPOINT
@property (assign) IBOutlet NSButton *numbersBtn;  // NUMBERS
@property (assign) IBOutlet NSButton *pagesBtn;  // PAGES
@property (assign) IBOutlet NSButton *keyBtn;  // KEYNOTE
@property (assign) IBOutlet NSButton *csvBtn;  // CSV
@property (assign) IBOutlet NSButton *markdownBtn;  // MARKDOWN


/*
 * 初期化
 */
-(void)initilize;

-(int)getDataSource;

-(NSString*)getTest;


@end
