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
#import "TaskSource.h"

@interface TaskWindowController : NSObject

@property (strong) NSViewController *taskWindowController;

// Register Window
@property (strong) IBOutlet NSWindow *registerWindow;

// Custome View
@property (weak) IBOutlet NSView *taskWindow;

// Viewの履歴
@property (retain) NSNumber *viewNumber;


// ボタン
@property (assign) IBOutlet NSButton *nextBtn;  // DataSourceViewのボタン
@property (assign) IBOutlet NSButton *backBtn;  // 全画面共通の前へ戻るためのボタン
@property (assign) IBOutlet NSButton *addtitonalBtn; // AdditionalConditin画面を開くためのボタン
@property (assign) IBOutlet NSButton *registerOKBtn;    // Register実行用のボタン

// 入力されたタスクに関する情報
@property (retain) NSMutableDictionary *inputData;


/*
 * Open the Task Window
 */
-(IBAction)openTaskWindow:(id)sender;

/*
 * Display the Select Data Source View
 */
-(IBAction)displaySelectDataSourceView:(id)sender;

/*
 * When user push the next btn
 */
-(IBAction)pushNextBtn:(id)sender;

/*
 * Display the Skype User View
 */
- (IBAction)displaySkypeView:(id)sender;

/*
 * Display the Additional Condition View
 */
- (IBAction)displayAdditionalConditionView:(id)sender;

/*
 * Display the previous View
 */
-(IBAction)backView:(id)sender;

/*
 * Register Action Execute
 */
-(IBAction)registerTask:(id)sender;


@end
