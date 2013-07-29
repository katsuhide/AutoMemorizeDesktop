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
NSString *const fileTaskViewClass = @"FileTaskView";
NSString *const chooseBackupDirViewClass = @"ChooseBackupDirectoryView";
NSString *const safariViewClass = @"SafariView";

NSString *const nextLabelString = @"       Next       ";
NSString *const additionalLabelString = @"Additional Setting";

typedef enum dataTypeEnum : NSInteger{
    SKYPE,
    PDF,
    TEXT,
    EXCEL,
    WORD,
    POWERPOINT,
    NUMBERS,
    PAGES,
    KEY,
    SAFARI
} dataTypeEnum;

typedef enum viewTypeEnum : NSInteger{
    DATA_SOURCE_VIEW,
    SKYPE_USER_VIEW,
    ADDITIONAL_CONDITION_VIEW,
    FILE_VIEW,
    CHOOSE_BACKUPDIR_VIEW,
    SAFARI_VIEW
} viewTypeEnum;



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
    imagePath = [[NSBundle mainBundle] pathForResource:@"question" ofType:@"png"];
    image= [[NSImage alloc]initByReferencingFile:imagePath];
    [_dataSourceView setImage:image];

    // Right Bow Icon
    imagePath = [[NSBundle mainBundle] pathForResource:@"RightBow" ofType:@"png"];
    image= [[NSImage alloc]initByReferencingFile:imagePath];
    [_rightBow setImage:image];
    
    // Evernote Icon
    imagePath = [[NSBundle mainBundle] pathForResource:@"evernote_logo" ofType:@"png"];
    image= [[NSImage alloc]initByReferencingFile:imagePath];
    [_evernoteView setImage:image];
    
    // Back Btn
    imagePath = [[NSBundle mainBundle] pathForResource:@"Left" ofType:@"png"];
    image= [[NSImage alloc]initByReferencingFile:imagePath];
    [_backBtn setImage:image];
    [_backBtn setBordered:YES];

    // Next Btn
    imagePath = [[NSBundle mainBundle] pathForResource:@"Right" ofType:@"png"];
    image= [[NSImage alloc]initByReferencingFile:imagePath];
    [_nextBtn setImage:image];
    [_nextBtn setBordered:YES];
    
    // inputDataのインスタンスを初期化
    _inputData = [NSMutableDictionary dictionary];
 
    // 履歴の登録
    _viewNumber = [NSNumber numberWithInteger:DATA_SOURCE_VIEW];

    // Custom Viewを初期化
    [[_taskWindowController view] removeFromSuperview];

    // 初期画面を初期化
    [self initializedView];

}

// Data Source Iconの切り替え
-(void)changeDataSourceIcon:(NSString*)imagePath{
    NSImage *image= [[NSImage alloc]initByReferencingFile:imagePath];
    [_dataSourceView setImage:image];
}

// DataSource部分の切り替え
-(void)changeRegisterWindow:(BOOL)isDisable{
    // 画像の設定
    NSString *imagePath;
    NSImage *image;
    imagePath = [[NSBundle mainBundle] pathForResource:@"skype" ofType:@"png"];
    image= [[NSImage alloc]initByReferencingFile:imagePath];
    [_skypeBtn setImage:image];
    
    imagePath = [[NSBundle mainBundle] pathForResource:@"Pdf" ofType:@"psd"];
    image= [[NSImage alloc]initByReferencingFile:imagePath];
    [_pdfBtn setImage:image];
    
    imagePath = [[NSBundle mainBundle] pathForResource:@"Text" ofType:@"psd"];
    image= [[NSImage alloc]initByReferencingFile:imagePath];
    [_textBtn setImage:image];

    imagePath = [[NSBundle mainBundle] pathForResource:@"Excel" ofType:@"psd"];
    image= [[NSImage alloc]initByReferencingFile:imagePath];
    [_excelBtn setImage:image];

    imagePath = [[NSBundle mainBundle] pathForResource:@"Word" ofType:@"psd"];
    image= [[NSImage alloc]initByReferencingFile:imagePath];
    [_wordBtn setImage:image];
    
    imagePath = [[NSBundle mainBundle] pathForResource:@"PowerPoint" ofType:@"psd"];
    image= [[NSImage alloc]initByReferencingFile:imagePath];
    [_powerpointBtn setImage:image];
    
    imagePath = [[NSBundle mainBundle] pathForResource:@"Numbers" ofType:@"psd"];
    image= [[NSImage alloc]initByReferencingFile:imagePath];
    [_numbersBtn setImage:image];
    
    imagePath = [[NSBundle mainBundle] pathForResource:@"Pages" ofType:@"psd"];
    image= [[NSImage alloc]initByReferencingFile:imagePath];
    [_pagesBtn setImage:image];
    
    imagePath = [[NSBundle mainBundle] pathForResource:@"Keynote" ofType:@"psd"];
    image= [[NSImage alloc]initByReferencingFile:imagePath];
    [_keyBtn setImage:image];

    imagePath = [[NSBundle mainBundle] pathForResource:@"safari" ofType:@"png"];
    image= [[NSImage alloc]initByReferencingFile:imagePath];
    [_safariBtn setImage:image];

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
    [_safariBtn setHidden:isDisable];
    
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
    // DataSourceTypeを登録
    _dataType = [NSNumber numberWithInt:SKYPE];
    [_inputData setValue:_dataType forKey:@"dataSourceType"];
    
    // Data Source部分を非表示にする
    [self changeRegisterWindow:YES];

    // Data Source Iconを切り替える
    NSString *imagePath = [[NSBundle mainBundle] pathForResource:@"skype" ofType:@"png"];
    [self changeDataSourceIcon:imagePath];

    // Skype Viewを表示する
    [self displaySkypeView:nil];
    
}

/*
 * When user push the Pdf Button
 */
-(IBAction)pushPdfBtn:(id)sender{
    // DataSourceTypeを登録
    _dataType = [NSNumber numberWithInt:PDF];
    [_inputData setValue:_dataType forKey:@"dataSourceType"];
    
    // 共通処理
    [self pushFileTypeBtn];
    
}

/*
 * When user push the Text Button
 */
-(IBAction)pushTextBtn:(id)sender{
    // DataSourceTypeを登録
    _dataType = [NSNumber numberWithInt:TEXT];
    [_inputData setValue:_dataType forKey:@"dataSourceType"];
    
    // 共通処理
    [self pushFileTypeBtn];
    
}

/*
 * When user push the EXCEL Button
 */
-(IBAction)pushExcelBtn:(id)sender{
    // DataSourceTypeを登録
    _dataType = [NSNumber numberWithInt:EXCEL];
    [_inputData setValue:_dataType forKey:@"dataSourceType"];
    
    // 共通処理
    [self pushFileTypeBtn];
    
}

/*
 * When user push the WORD Button
 */
-(IBAction)pushWordBtn:(id)sender{
    // DataSourceTypeを登録
    _dataType = [NSNumber numberWithInt:WORD];
    [_inputData setValue:_dataType forKey:@"dataSourceType"];
    
    // 共通処理
    [self pushFileTypeBtn];
    
}

/*
 * When user push the POWERPOINT Button
 */
-(IBAction)pushPowerpointBtn:(id)sender{
    // DataSourceTypeを登録
    _dataType = [NSNumber numberWithInt:POWERPOINT];
    [_inputData setValue:_dataType forKey:@"dataSourceType"];
    
    // 共通処理
    [self pushFileTypeBtn];
    
}

/*
 * When user push the NUMBERS Button
 */
-(IBAction)pushNumbersBtn:(id)sender{
    // DataSourceTypeを登録
    _dataType = [NSNumber numberWithInt:NUMBERS];
    [_inputData setValue:_dataType forKey:@"dataSourceType"];
    
    // 共通処理
    [self pushFileTypeBtn];
    
}

/*
 * When user push the PAGES Button
 */
-(IBAction)pushPagesBtn:(id)sender{
    // DataSourceTypeを登録
    _dataType = [NSNumber numberWithInt:PAGES];
    [_inputData setValue:_dataType forKey:@"dataSourceType"];
    
    // 共通処理
    [self pushFileTypeBtn];
    
}


/*
 * When user push the KEYNOTE Button
 */
-(IBAction)pushKeyBtn:(id)sender{
    // DataSourceTypeを登録
    _dataType = [NSNumber numberWithInt:KEY];
    [_inputData setValue:_dataType forKey:@"dataSourceType"];
    
    // 共通処理
    [self pushFileTypeBtn];
    
}


/*
 * When user push the SAFARI Button
 */
-(IBAction)pushSafariBtn:(id)sender{
    // DataSourceTypeを登録
    _dataType = [NSNumber numberWithInt:SAFARI];
    [_inputData setValue:_dataType forKey:@"dataSourceType"];
    
    // Data Source部分を非表示にする
    [self changeRegisterWindow:YES];
    
    // Data Source Iconを切り替える
    NSString *imagePath = [self getFileTypeImagePath];
    [self changeDataSourceIcon:imagePath];
    
    // Safari Viewを表示する
    [self displaySafariView:nil];
    
}


// File Type 関連のボタンが押下された場合の共通処理
-(void)pushFileTypeBtn{
    // Data Source部分を非表示にする
    [self changeRegisterWindow:YES];
    
    // Data Source Iconを切り替える
    NSString *imagePath = [self getFileTypeImagePath];
    [self changeDataSourceIcon:imagePath];

    // File Viewを表示する
    [self displayFileView:nil];
    
}

// 各種DataSourceの画像パスを取得する
-(NSString*)getFileTypeImagePath{
    NSString *imagePath;
    
    switch ([[_inputData objectForKey:@"dataSourceType"] intValue]) {
        case PDF:
            imagePath = [[NSBundle mainBundle] pathForResource:@"Pdf" ofType:@"psd"];
            break;
        case TEXT:
            imagePath = [[NSBundle mainBundle] pathForResource:@"Text" ofType:@"psd"];
            break;
        case EXCEL:
            imagePath = [[NSBundle mainBundle] pathForResource:@"Excel" ofType:@"psd"];
            break;
        case WORD:
            imagePath = [[NSBundle mainBundle] pathForResource:@"Word" ofType:@"psd"];
            break;
        case POWERPOINT:
            imagePath = [[NSBundle mainBundle] pathForResource:@"PowerPoint" ofType:@"psd"];
            break;
        case NUMBERS:
            imagePath = [[NSBundle mainBundle] pathForResource:@"Numbers" ofType:@"psd"];
            break;
        case PAGES:
            imagePath = [[NSBundle mainBundle] pathForResource:@"Pages" ofType:@"psd"];
            break;
        case KEY:
            imagePath = [[NSBundle mainBundle] pathForResource:@"Keynote" ofType:@"psd"];
            break;
        case SAFARI:
            imagePath = [[NSBundle mainBundle] pathForResource:@"safari" ofType:@"png"];
            break;
        default:
            break;
    }
    return imagePath;
}


/*
 * When user push the next btn
 */
-(IBAction)pushNextBtn:(id)sender{
    // その画面のデータをセットする
    BOOL isSucceeded = [self executeSetViewData];
    
    // 次の画面を表示する
    if(isSucceeded){
        switch ([_viewNumber intValue]) {
            case FILE_VIEW:
                //
                [self displayChooseBackupDirectoryView:nil];
                break;
            default:    // File Task View以外はAdditional Viewを表示
                [self displayAdditionalConditionView:nil];
                break;
        }
        
    }

}

/*
 * Display the Skype View
 */
- (IBAction)displaySkypeView:(id)sender{
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
 * Display the File View
 */
- (IBAction)displayFileView:(id)sender{
    [[_taskWindowController view] removeFromSuperview];
    
    _taskWindowController = [[FileTaskView alloc]initWithNibName:fileTaskViewClass bundle:nil];
    
    [_taskWindow addSubview:[_taskWindowController view]];
    [[_taskWindowController view] setFrame:[_taskWindow bounds]];
    
    // 履歴の登録
    _viewNumber = [NSNumber numberWithInteger:FILE_VIEW];
    
    // 画面の初期化
    [self initializedView];
    
}

/*
 * Display the Safari View
 */
- (IBAction)displaySafariView:(id)sender{
    [[_taskWindowController view] removeFromSuperview];
    
    _taskWindowController = [[SafariView alloc]initWithNibName:safariViewClass bundle:nil];
    
    [_taskWindow addSubview:[_taskWindowController view]];
    [[_taskWindowController view] setFrame:[_taskWindow bounds]];
    
    // 履歴の登録
    _viewNumber = [NSNumber numberWithInteger:SAFARI_VIEW];
    
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
 * Display the Choose Backup Directory View
 */
- (IBAction)displayChooseBackupDirectoryView:(id)sender{
    [[_taskWindowController view] removeFromSuperview];
    _taskWindowController = [[ChooseBackupDirectoryView alloc]initWithNibName:chooseBackupDirViewClass bundle:nil];
    [_taskWindow addSubview:[_taskWindowController view]];
    [[_taskWindowController view] setFrame:[_taskWindow bounds]];
    
    // 履歴の登録
    _viewNumber = [NSNumber numberWithInteger:CHOOSE_BACKUPDIR_VIEW];
    
    // 画面の初期化
    [self initializedView];
}


/*
 * Display the previous View
 */
-(IBAction)backView:(id)sender{
    int dataTypeFlag = [[_inputData objectForKey:@"dataSourceType"] intValue];
    switch ([_viewNumber intValue]) {
        case DATA_SOURCE_VIEW:
            // 存在しないケース
            break;
        case SKYPE_USER_VIEW:
            [self initializedRegisterWindow:NO];
            break;
        case FILE_VIEW:
            [self initializedRegisterWindow:NO];
            break;
        case SAFARI_VIEW:
            [self initializedRegisterWindow:NO];
            break;
        case CHOOSE_BACKUPDIR_VIEW:
            [self displayFileView:nil];
            break;
        case ADDITIONAL_CONDITION_VIEW:
            if(dataTypeFlag == SKYPE){
                // Skype
                [self displaySkypeView:nil];
            }else if(dataTypeFlag == SAFARI){
                // Safari
                [self displaySafariView:nil];
            }else{
                // File
                [self displayChooseBackupDirectoryView:nil];
            }
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
    BOOL isSucceeded = [self executeSetViewData];

    if(isSucceeded){
        // inputdataを元にTaskSourceを生成して登録
        AppDelegate *appDelegate = (AppDelegate*)[[NSApplication sharedApplication] delegate];
        [appDelegate registerTask:_inputData];
        
        // Task Windowを閉じる
        [_registerWindow close];
        
    }
}

// 今いる画面のsetViewDataを実行する
-(BOOL)executeSetViewData{
    BOOL isSucceeded = YES;
    
    switch ([_viewNumber intValue]) {
        case DATA_SOURCE_VIEW:
            // 存在しないケース
            break;
        case SKYPE_USER_VIEW:
        {
            SkypeView *currentView = (SkypeView*)self.taskWindowController;
            // validation
            if([currentView validate]){
                isSucceeded = NO;
                break;
            }
            // データをセット
            [currentView setViewData:_inputData];
            
        }
            break;
        case FILE_VIEW:
        {
            FileTaskView *currentView = (FileTaskView*)self.taskWindowController;
            // validation
            if([currentView validate]){
                isSucceeded = NO;
                break;
            }

            // データをセット
            [currentView setViewData:_inputData];

        }
            break;
        case CHOOSE_BACKUPDIR_VIEW:
        {
            ChooseBackupDirectoryView *currentView = (ChooseBackupDirectoryView*)self.taskWindowController;
            // validation
            if([currentView validate]){
                isSucceeded = NO;
                break;
            }
            
            // データをセット
            [currentView setViewData:_inputData];
            
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
        case SAFARI_VIEW:
        {
            SafariView *currentView = (SafariView*)self.taskWindowController;
            // validation
            if([currentView validate]){
                isSucceeded = NO;
                break;
            }
            // データをセット
            [currentView setViewData:_inputData];
            
        }
            break;
        default:
            break;
    }
    
    return isSucceeded;
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
            [_nextLabel setStringValue:additionalLabelString];
            
            // 画面固有のコンポーネントの初期化
            SkypeView *currentView = (SkypeView*)self.taskWindowController;
            [currentView initialize:_inputData];
        }
            break;
            
        case FILE_VIEW:
        {
            // ボタンを全て非表示にしたうえで必要なボタンのみ表示
            [self disableAllBtn];
            [_backBtn setHidden:NO];
            [_registerBtn setHidden:YES];
            [_nextBtn setHidden:NO];
            [_backLabel setHidden:NO];
            [_registerLabel setHidden:YES];
            [_nextLabel setHidden:NO];
            [_nextLabel setStringValue:nextLabelString];
            
            // 画面固有のコンポーネントの初期化
            FileTaskView *currentView = (FileTaskView*)self.taskWindowController;
            [currentView initialize:_inputData];

        }
            break;

        case SAFARI_VIEW:
        {
            // ボタンを全て非表示にしたうえで必要なボタンのみ表示
            [self disableAllBtn];
            [_backBtn setHidden:NO];
            [_registerBtn setHidden:NO];
            [_nextBtn setHidden:NO];
            [_backLabel setHidden:NO];
            [_registerLabel setHidden:NO];
            [_nextLabel setHidden:NO];
            [_nextLabel setStringValue:additionalLabelString];
            
            // 画面固有のコンポーネントの初期化
            SafariView *currentView = (SafariView*)self.taskWindowController;
            [currentView initialize:_inputData];
            
        }
            break;
            
        case CHOOSE_BACKUPDIR_VIEW:
        {
            // ボタンを全て非表示にしたうえで必要なボタンのみ表示
            [self disableAllBtn];
            [_backBtn setHidden:NO];
            [_registerBtn setHidden:NO];
            [_nextBtn setHidden:NO];
            [_backLabel setHidden:NO];
            [_registerLabel setHidden:NO];
            [_nextLabel setHidden:NO];
            [_nextLabel setStringValue:additionalLabelString];
            
            // 画面固有のコンポーネントの初期化
            FileTaskView *currentView = (FileTaskView*)self.taskWindowController;
            [currentView initialize:_inputData];
            
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

-(IBAction)hoge:(id)sender{
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    [panel setCanChooseFiles:NO];
    [panel setCanChooseDirectories:YES];
    [panel setAllowsMultipleSelection:YES]; // yes if more than one dir is allowed
    
    NSInteger clicked = [panel runModal];
    
    if (clicked == NSFileHandlingPanelOKButton) {
        for (NSURL *url in [panel URLs]) {
            // do something with the url here.
            NSLog(@"url:%@", [url path]);
        }
    }
}

@end
