//
//  TaskWindowController.h
//  RecDesktop
//
//  Created by AirMyac on 7/2/13.
//  Copyright (c) 2013 com.katzlifehack. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SelectDataSourceView.h"
#import "SkypeView.h"
#import "AdditionalConditionView.h"
#import "FileTaskView.h"

@interface TaskWindowController : NSObject

@property (strong) NSViewController *taskWindowController;

// Register Window
@property (strong) IBOutlet NSWindow *registerWindow;

// Custome View
@property (weak) IBOutlet NSView *taskWindow;

// Viewの履歴
@property (retain) NSNumber *viewNumber;

// Data Type
@property (retain) NSNumber *dataType;

// Image View
@property (retain) IBOutlet NSImageView *dataSourceView;
@property (retain) IBOutlet NSImageView *rightBow;
@property (retain) IBOutlet NSImageView *evernoteView;

// Register View
@property (assign) IBOutlet NSTextField *dataSourceLabel;
@property (assign) IBOutlet NSButton *skypeBtn;  // SKYPE
@property (assign) IBOutlet NSButton *pdfBtn;  // PDF
@property (assign) IBOutlet NSButton *textBtn;  // TEXT
@property (assign) IBOutlet NSButton *excelBtn;  // EXCEL
@property (assign) IBOutlet NSButton *wordBtn;  // WORD
@property (assign) IBOutlet NSButton *powerpointBtn;  // POWERPOINT
@property (assign) IBOutlet NSButton *numbersBtn;  // NUMBERS
@property (assign) IBOutlet NSButton *pagesBtn;  // PAGES
@property (assign) IBOutlet NSButton *keyBtn;  // KEYNOTE
//@property (assign) IBOutlet NSButton *csvBtn;  // CSV
//@property (assign) IBOutlet NSButton *markdownBtn;  // MARKDOWN

// 全View共通コンポーネント
@property (assign) IBOutlet NSButton *backBtn;  // 全画面共通の前へ戻るためのボタン
@property (assign) IBOutlet NSButton *registerBtn;    // Register実行用のボタン
@property (assign) IBOutlet NSButton *nextBtn;  // DataSourceViewのボタン
@property (assign) IBOutlet NSTextField *backLabel;
@property (assign) IBOutlet NSTextField *registerLabel;
@property (assign) IBOutlet NSTextField *nextLabel;

// 入力されたタスクに関する情報
@property (retain) NSMutableDictionary *inputData;


/*
 * Open the Task Window
 */
-(IBAction)openTaskWindow:(id)sender;

/*
 * When user push the Skype Button
 */
-(IBAction)pushSkypeBtn:(id)sender;


/*
 * Display the Select Data Source View
 */
-(IBAction)displaySelectDataSourceView:(id)sender;

/*
 * When user push the next btn
 */
-(IBAction)pushNextBtn:(id)sender;

/*
 * Display the Skype View
 */
- (IBAction)displaySkypeView:(id)sender;

/*
 * Display the Additional Condition View
 */
- (IBAction)displayAdditionalConditionView:(id)sender;

/*
 * Display the File View
 */
- (IBAction)displayFileView:(id)sender;


/*
 * Display the previous View
 */
-(IBAction)backView:(id)sender;

/*
 * Register Action Execute
 */
-(IBAction)registerTask:(id)sender;


@end
