//
//  TaskWindowController.m
//  RecDesktop
//
//  Created by AirMyac on 7/2/13.
//  Copyright (c) 2013 com.katzlifehack. All rights reserved.
//

#import "TaskWindowController.h"
#import "AppDelegate.h"

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
    ADDITIONAL_CONDITION_VIEW
} viewType;



/*
 * Open the Task Window
 */
-(IBAction)openTaskWindow:(id)sender{
    // Windowを開く
    [_registerWindow makeKeyAndOrderFront:nil];
    
    // 初期画面であるData Source Viewを設定
    [self displaySelectDataSourceView:nil];
    
}

/*
 * Display the Select Data Source View
 */
-(IBAction)displaySelectDataSourceView:(id)sender{
    NSLog(@"displayDataSourceView");
    [[_taskWindowController view] removeFromSuperview];
    
    _taskWindowController = [[SelectDataSourceView alloc]initWithNibName:selectDataSourceViewClass bundle:nil];
    
    [_taskWindow addSubview:[_taskWindowController view]];
    [[_taskWindowController view] setFrame:[_taskWindow bounds]];

    // ボタンを全て非表示にしたうえで必要なボタンのみ表示
    [self disableAllBtn];
    [_nextBtn setHidden:NO];
    
    // inputDataのインスタンスを初期化
    _inputData = [NSMutableDictionary dictionary];
    
    // 履歴の登録
    _viewNumber = [NSNumber numberWithInteger:DATA_SOURCE_VIEW];

}


/*
 * When user push the next btn
 */
-(IBAction)pushNextBtn:(id)sender{
    SelectDataSourceView *sview = (SelectDataSourceView*)self.taskWindowController;
    
    int dataSourceType = [sview getDataSource];
    NSLog(@"TaskType:%d", dataSourceType);
    NSLog(@"Text:%@", [sview getTest]);

    // DataSourceTypeを登録
    [_inputData setValue:[NSNumber numberWithInt:dataSourceType] forKey:@"dataSourceType"];
    
    // TODO validation
    
    // TODO 適切なViewを表示
    [self displaySkypeView:nil];
    
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

    // ボタンを全て非表示にしたうえで必要なボタンのみ表示
    [self disableAllBtn];
    [_backBtn setHidden:NO];
    [_addtitonalBtn setHidden:NO];
    [_registerOKBtn setHidden:NO];
    
    // 履歴の登録
    _viewNumber = [NSNumber numberWithInteger:SKYPE_USER_VIEW];

    
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
    
    // ボタンを全て非表示にしたうえで必要なボタンのみ表示
    [self disableAllBtn];
    [_backBtn setHidden:NO];
    [_registerOKBtn setHidden:NO];
    
    // 履歴の登録
    _viewNumber = [NSNumber numberWithInteger:ADDITIONAL_CONDITION_VIEW];

}



/*
 * Display the previous View
 */
-(IBAction)backView:(id)sender{
    NSLog(@"Previous View:%@", _viewNumber);
 
    // TODO numberはリストにする
    switch ([_viewNumber intValue]) {
        case 0:
            break;
        case 1:
            [self displaySelectDataSourceView:nil];
            break;
        case 2:
            [self displaySkypeView:nil];
            break;
        case 3:
            break;
        default:
            break;
    }
    
}

/*
 * Register Action Execute
 */
-(IBAction)registerTask:(id)sender{

    AppDelegate *appDelegate = (AppDelegate*)[[NSApplication sharedApplication] delegate];
    
    switch ([_viewNumber intValue]) {
        case DATA_SOURCE_VIEW:
            // 存在しないケース
            break;
        case SKYPE_USER_VIEW:
        {
            // データをセット
            SkypeView *sView = (SkypeView*)self.taskWindowController;
            NSString *skypeUser = [sView getSkypeUser];
            NSString *skypePath = [NSString stringWithFormat:@"~/Library/Application Support/Skype/%@/main.db", skypeUser];
            [_inputData setValue:skypePath forKey:@"file_path"];
            
            // TODO validation
            
        }
            break;
        case ADDITIONAL_CONDITION_VIEW:
        {
            NSString *noteTitle = @"note title";
            NSString *notebookName = @"aaaa";
            NSString *notebookGuid = @"1111111";
            NSString *tag = @"";
            [_inputData setValue:noteTitle forKey:@"noteTitle"];
            [_inputData setValue:notebookGuid forKey:@"notebook"];
            [_inputData setValue:tag forKey:@"tag"];
        }
            
            break;
        default:
            break;
    }

    NSLog(@"%@", _inputData);
    
    // これはdelegateの方でやるべきかな？
    TaskSource *source = [appDelegate createTaskSource];
    source.task_name = @"new gui test";
    source.task_type = [_inputData objectForKey:@"dataSourceType"];
    NSDate *now = [NSDate date];
    source.last_execute_time = now;
    source.last_added_time = now;
    source.update_time = now;
    
    
}


// 全ボタンを非表示
-(void)disableAllBtn{
    [_nextBtn setHidden:YES];
    [_backBtn setHidden:YES];
    [_addtitonalBtn setHidden:YES];
    [_registerOKBtn setHidden:YES];
}


@end
