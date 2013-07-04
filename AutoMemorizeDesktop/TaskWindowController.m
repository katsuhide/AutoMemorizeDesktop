//
//  TaskWindowController.m
//  RecDesktop
//
//  Created by AirMyac on 7/2/13.
//  Copyright (c) 2013 com.katzlifehack. All rights reserved.
//

#import "TaskWindowController.h"
#import "AppDelegate.h"
#import "NSColor+Hex.h"

@implementation TaskWindowController

NSString *const selectDataSourceViewClass = @"SelectDataSourceView";
NSString *const skypeViewClass = @"SkypeView";
NSString *const additionalConditionClass = @"AdditionalConditionView";

//typedef enum dataSourceType : NSInteger{
//    SKYPE,
//    PDF,
//    TEXT,
//    MARKDOWN,
//    XLS,
//    DOC,
//    PPT,
//    KEYNOTE
//} dataSourceType;

typedef enum viewType : NSInteger{
    DATA_SOURCE_VIEW,
    SKYPE_USER_VIEW,
    ADDITIONAL_CONDITION_VIEW,
    FILE_VIEW
} viewType;



/*
 * Open the Task Window
 */
-(IBAction)openTaskWindow:(id)sender{
    // Windowを初期化
    [self initializedRegisterWindow:NO];
    // Windowを開く
    [_registerWindow makeKeyAndOrderFront:nil];
    
}

// Initialized Register Window
-(void)initializedRegisterWindow:(BOOL)isDisable{
    // 背景
    NSString *hex = @"#FFFFFF";
    NSColor *backColor = [NSColor colorFromHexadecimalValue:hex];
    [_registerWindow setBackgroundColor:backColor];
    
    // Data Source Icon
    NSString *imagePath;
    NSImage *image;
    imagePath = [[NSBundle mainBundle] pathForResource:@"Status" ofType:@"psd"];
    image= [[NSImage alloc]initByReferencingFile:imagePath];
    [_dataSourceView setImage:image];

    // Right Bow Icon
    imagePath = [[NSBundle mainBundle] pathForResource:@"Status" ofType:@"psd"];
    image= [[NSImage alloc]initByReferencingFile:imagePath];
    [_rightBow setImage:image];
    
    // Evernote Icon
    imagePath = [[NSBundle mainBundle] pathForResource:@"evernote_logo" ofType:@"png"];
    image= [[NSImage alloc]initByReferencingFile:imagePath];
    [_evernoteView setImage:image];
    
    // inputDataのインスタンスを初期化
    _inputData = [NSMutableDictionary dictionary];
 
    // 履歴の登録
    _viewNumber = [NSNumber numberWithInteger:DATA_SOURCE_VIEW];

    // Custom Viewを初期化
    [[_taskWindowController view] removeFromSuperview];

    // 初期画面を初期化
    [self initializedView];

}

// DataSource部分の切り替え
-(void)changeRegisterWindow:(BOOL)isDisable{
    // 画像の設定
    NSString *imagePath;
    NSImage *image;
    imagePath = [[NSBundle mainBundle] pathForResource:@"Status" ofType:@"psd"];
    image= [[NSImage alloc]initByReferencingFile:imagePath];
    [_skypeBtn setImage:image];
    [_skypeBtn setBordered:NO];
    
    imagePath = [[NSBundle mainBundle] pathForResource:@"Status" ofType:@"psd"];
    image= [[NSImage alloc]initByReferencingFile:imagePath];
    [_pdfBtn setImage:image];
    [_pdfBtn setBordered:NO];
    
    imagePath = [[NSBundle mainBundle] pathForResource:@"Status" ofType:@"psd"];
    image= [[NSImage alloc]initByReferencingFile:imagePath];
    [_textBtn setImage:image];

    imagePath = [[NSBundle mainBundle] pathForResource:@"Status" ofType:@"psd"];
    image= [[NSImage alloc]initByReferencingFile:imagePath];
    [_excelBtn setImage:image];

    imagePath = [[NSBundle mainBundle] pathForResource:@"Status" ofType:@"psd"];
    image= [[NSImage alloc]initByReferencingFile:imagePath];
    [_wordBtn setImage:image];
    
    imagePath = [[NSBundle mainBundle] pathForResource:@"Status" ofType:@"psd"];
    image= [[NSImage alloc]initByReferencingFile:imagePath];
    [_powerpointBtn setImage:image];
    
    imagePath = [[NSBundle mainBundle] pathForResource:@"Status" ofType:@"psd"];
    image= [[NSImage alloc]initByReferencingFile:imagePath];
    [_numbersBtn setImage:image];
    
    imagePath = [[NSBundle mainBundle] pathForResource:@"Status" ofType:@"psd"];
    image= [[NSImage alloc]initByReferencingFile:imagePath];
    [_pagesBtn setImage:image];
    
    imagePath = [[NSBundle mainBundle] pathForResource:@"Status" ofType:@"psd"];
    image= [[NSImage alloc]initByReferencingFile:imagePath];
    [_keyBtn setImage:image];
    
    imagePath = [[NSBundle mainBundle] pathForResource:@"Status" ofType:@"psd"];
    image= [[NSImage alloc]initByReferencingFile:imagePath];
    [_csvBtn setImage:image];
    [_csvBtn setBordered:NO];
    
    imagePath = [[NSBundle mainBundle] pathForResource:@"Status" ofType:@"psd"];
    image= [[NSImage alloc]initByReferencingFile:imagePath];
    [_markdownBtn setImage:image];
    [_markdownBtn setBordered:NO];

    // 表示・非表示の切り替え
    [_dataSourceLabel setHidden:isDisable];
    [_skypeBtn setHidden:isDisable];
    [_pdfBtn setHidden:isDisable];
    [_textBtn setHidden:isDisable];
    [_excelBtn setHidden:isDisable];
    [_wordBtn setHidden:isDisable];
    [_powerpointBtn setHidden:isDisable];
    [_numbersBtn setHidden:isDisable];
    [_pagesBtn setHidden:isDisable];
    [_keyBtn setHidden:isDisable];
    [_csvBtn setHidden:isDisable];
    [_markdownBtn setHidden:isDisable];
    
}


/*
 * Display the Select Data Source View
 */
-(IBAction)displaySelectDataSourceView:(id)sender{
    NSLog(@"displayDataSourceView");
    // Data Source Viewを表示
    [[_taskWindowController view] removeFromSuperview];
    
    _taskWindowController = [[SelectDataSourceView alloc]initWithNibName:selectDataSourceViewClass bundle:nil];
    
    [_taskWindow addSubview:[_taskWindowController view]];
    [[_taskWindowController view] setFrame:[_taskWindow bounds]];

    [(SelectDataSourceView*)_taskWindowController initilize];
    
    // ボタンを全て非表示にしたうえで必要なボタンのみ表示
    [self disableAllBtn];
    [_nextBtn setHidden:NO];
    
    // inputDataのインスタンスを初期化
    _inputData = [NSMutableDictionary dictionary];
    
    // 履歴の登録
    _viewNumber = [NSNumber numberWithInteger:DATA_SOURCE_VIEW];

}

/*
 * When user push the Skype Button
 */
-(IBAction)pushSkypeBtn:(id)sender{
//    SelectDataSourceView *sview = (SelectDataSourceView*)self.taskWindowController;
//    int dataSourceType = [sview getDataSource];
    int dataSourceType = 0;

    // DataSourceTypeを登録
    [_inputData setValue:[NSNumber numberWithInt:dataSourceType] forKey:@"dataSourceType"];
    
    // Data Source部分を非表示にする
    [self changeRegisterWindow:YES];
    
    // Skype Viewを表示する
    [self displaySkypeView:nil];
    
}



/*
 * When user push the next btn
 */
-(IBAction)pushNextBtn:(id)sender{
    // その画面のデータをセットする
    [self executeSetViewData];
    
    // Additional画面を表示する
    [self displayAdditionalConditionView:nil];


//    SelectDataSourceView *sview = (SelectDataSourceView*)self.taskWindowController;
//    int dataSourceType = [sview getDataSource];
//    NSLog(@"TaskType:%d", dataSourceType);
//
//    // DataSourceTypeを登録
//    [_inputData setValue:[NSNumber numberWithInt:dataSourceType] forKey:@"dataSourceType"];
//    
//    // TODO validation
//    
//    // TODO 適切なViewを表示
//    [self displaySkypeView:nil];
    
}

/*
 * Display the Skype View
 */
- (IBAction)displaySkypeView:(id)sender{
    NSLog(@"displaySkypeView");
    [[_taskWindowController view] removeFromSuperview];

    _taskWindowController = [[SkypeView alloc]initWithNibName:skypeViewClass bundle:nil];
    
    [_taskWindow addSubview:[_taskWindowController view]];
    [[_taskWindowController view] setFrame:[_taskWindow bounds]];
    
    // 履歴の登録
    _viewNumber = [NSNumber numberWithInteger:SKYPE_USER_VIEW];

    // 画面の初期化
    [self initializedView];
    
}

/*
 * Display the Additional Condition View
 */
- (IBAction)displayAdditionalConditionView:(id)sender{
    NSLog(@"displayAdditinalConditionView");
    [[_taskWindowController view] removeFromSuperview];
    
    _taskWindowController = [[AdditionalConditionView alloc]initWithNibName:additionalConditionClass bundle:nil];
    
    [_taskWindow addSubview:[_taskWindowController view]];
    [[_taskWindowController view] setFrame:[_taskWindow bounds]];
    
    // 履歴の登録
    _viewNumber = [NSNumber numberWithInteger:ADDITIONAL_CONDITION_VIEW];

    // 画面の初期化
    [self initializedView];
}

/*
 * Display the previous View
 */
-(IBAction)backView:(id)sender{
    NSLog(@"Previous View:%@", _viewNumber);
 
    switch ([_viewNumber intValue]) {
        case DATA_SOURCE_VIEW:
            // 存在しないケース
            break;
        case SKYPE_USER_VIEW:
            [self initializedRegisterWindow:NO];
            break;
        case ADDITIONAL_CONDITION_VIEW:
            [self displaySkypeView:nil];
            break;
        case FILE_VIEW:
            
            break;
        default:
            break;
    }

}

/*
 * Register Action Execute
 */
-(IBAction)registerTask:(id)sender{

    // Registerを実行した画面のデータをセット
    [self executeSetViewData];

    NSLog(@"%@", _inputData);
    
    // inputdataを元にTaskSourceを生成して登録
    AppDelegate *appDelegate = (AppDelegate*)[[NSApplication sharedApplication] delegate];
    [appDelegate registerTask:_inputData];
    
    // 画面の初期化 TODO 必要なら
    
    // Task Windowを閉じる
    [_registerWindow close];
    
}

// 今いる画面のsetViewDataを実行する
-(void)executeSetViewData{
    
    switch ([_viewNumber intValue]) {
        case DATA_SOURCE_VIEW:
            // 存在しないケース
            break;
        case SKYPE_USER_VIEW:
        {
            // データをセット
            SkypeView *currentView = (SkypeView*)self.taskWindowController;
            [currentView setViewData:_inputData];
            
            // TODO validation
            
        }
            break;
        case ADDITIONAL_CONDITION_VIEW:
        {
            // データをセット
            AdditionalConditionView *currentView = (AdditionalConditionView*)self.taskWindowController;
            [currentView setViewData:_inputData];
            
            // 任意項目なのでバリデーションは不要
        }
            break;
        case FILE_VIEW:
        {
            
        }
            break;
        default:
            break;
    }
    
}

// 今いる画面の初期化を実行する
-(void)initializedView{
    switch ([_viewNumber intValue]) {
        case DATA_SOURCE_VIEW:
            // Data Source部分を初期化する
            [self changeRegisterWindow:NO];
            
            // ボタンを全て非表示
            [self disableAllBtn];
            break;
            
        case SKYPE_USER_VIEW:
        {
            // ボタンを全て非表示にしたうえで必要なボタンのみ表示
            [self disableAllBtn];
            [_backBtn setHidden:NO];
            [_registerBtn setHidden:NO];
            [_nextBtn setHidden:NO];
            [_backLabel setHidden:NO];
            [_registerLabel setHidden:NO];
            [_nextLabel setHidden:NO];

            
            // 画面固有のコンポーネントの初期化
            SkypeView *currentView = (SkypeView*)self.taskWindowController;
            [currentView initilize:_inputData];
        }
            break;
            
        case ADDITIONAL_CONDITION_VIEW:
        {
            // ボタンを全て非表示にしたうえで必要なボタンのみ表示
            [self disableAllBtn];
            [_backBtn setHidden:NO];
            [_registerBtn setHidden:NO];
            [_nextBtn setHidden:YES];
            [_backLabel setHidden:NO];
            [_registerLabel setHidden:NO];
            [_nextLabel setHidden:YES];
            
            // 画面固有のコンポーネントの初期化
            AdditionalConditionView *currentView = (AdditionalConditionView*)self.taskWindowController;
            [currentView initialize];
        }
            break;
            
        case FILE_VIEW:
            // ボタンを全て非表示にしたうえで必要なボタンのみ表示
            [self disableAllBtn];
            [_backBtn setHidden:NO];
            [_registerBtn setHidden:NO];
            [_nextBtn setHidden:NO];
            [_backLabel setHidden:NO];
            [_registerLabel setHidden:NO];
            [_nextLabel setHidden:NO];
            break;

        default:
            break;
    }
    
}

// 全ボタンを非表示
-(void)disableAllBtn{
    [_backBtn setHidden:YES];
    [_registerBtn setHidden:YES];
    [_nextBtn setHidden:YES];
    [_backLabel setHidden:YES];
    [_registerLabel setHidden:YES];
    [_nextLabel setHidden:YES];
}


@end
