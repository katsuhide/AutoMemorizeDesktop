//
//  NewTaskController.m
//  AutoMemorizeDesktop
//
//  Created by AirMyac on 6/15/13.
//  Copyright (c) 2013 com.katzlifehack. All rights reserved.
//

#import "TaskViewController.h"
#import "NSColor+Hex.h"
#import "AppDelegate.h"

@implementation TaskViewController

// 各viewのControllerクラス名
NSString *const skypeViewName = @"SkypeViewController";
NSString *const fileViewName = @"FileViewController";


/*
 * New Task Viewの拡張部分を切り替える
 */
-(IBAction)changeView:(id)sender{
    [self changeViewImpl];
}

// Task Viewの拡張部分の生成処理の実装
-(void)changeViewImpl{
    // 選択されているTaskTypeを取得
    int taskType = (int)[_taskTypeField indexOfSelectedItem];
    // Task Viewの拡張部分を生成
    [self changeViewController:taskType];
}

-(void)changeViewController:(int)taskType{
    [[_taskViewController view] removeFromSuperview];
    BOOL flag = TRUE;
    switch (taskType) {
        case 0:
            // Skype View
            self.taskViewController = [[SkypeViewController alloc]initWithNibName:skypeViewName bundle:nil];
            break;
        case 1:
            // File View
            self.taskViewController = [[FileViewController alloc]initWithNibName:fileViewName bundle:nil];
            break;
        default:
            // Other（表示しない）
            flag = FALSE;
            break;
    }

    // Custom Viewを作成
    if(flag){
        [_taskView addSubview:[_taskViewController view]];
        [[_taskViewController view] setFrame:[_taskView bounds]];
    }

    // ボタンの変更
    AppDelegate *appDelegate = (AppDelegate*)[[NSApplication sharedApplication] delegate];
    [appDelegate changeRegisterOkBtn:taskType];
    
}


/*
 * TaskViewの初期化
 */
-(void)initializedTaskView{    
    // アイテムを初期化
    [self changeTaskView:YES andData:nil];
    // Viewを初期化
    [self changeViewImpl];
}

/*
 * 選択されたTaskの情報を表示してTaskViewを開く(すべてDisableにする）
 */
-(void)viewTaskView:(TaskSource*)source{
    // TaskViewの拡張部分にデータを表示
    [self changeTaskView:NO andData:source];
    // CustomeViewを初期化
    [self changeViewImpl];
    // CustomeViewにデータを表示
    [self changeCustomTaskView:NO andData:source];
    
}


-(void)changeTaskView:(BOOL)isEditable andData:(TaskSource*)source{
    // 指定されたモードに設定
    [_taskTypeField setEnabled:isEditable];
    // データを設定もしくは初期化
    int taskType = [source.task_type intValue];
    [_taskTypeField selectItemAtIndex:taskType];
    
    // 背景
//    NSString *hex = @"#ecf0f1";
//    NSColor *backColor = [NSColor colorFromHexadecimalValue:hex];
//    [_taskTypeField setBackgroundColor:backColor];

}

-(void)changeCustomTaskView:(BOOL)isEditable andData:(TaskSource*)source{
    // 選択されているTaskTypeを取得
    int taskType = (int)[_taskTypeField indexOfSelectedItem];
    switch (taskType) {
        case 0:
            // Skype View
            [(SkypeViewController*)self.taskViewController changeCustomTaskView:isEditable andData:source];
            break;
        case 1:
            // File View
            [(FileViewController*)self.taskViewController changeCustomTaskView:isEditable andData:source];
            break;
        default:
            // Other（表示しない）
            break;
    }
}


/*
 * TaskViewの拡張部分の情報を取得
 */
-(NSMutableString*)getParams{
    NSMutableString *params = [[NSMutableString alloc]init];
    int taskType = (int)[_taskTypeField indexOfSelectedItem];
    switch (taskType) {
        case 0:
            NSLog(@"skype view");
            // Skype View
            params = [(SkypeViewController*)self.taskViewController getParams];
            break;
        case 1:
            // File View
            params = [(FileViewController*)self.taskViewController getParams];
            break;
        default:
            // Other（表示しない）
            break;
    }
    return params;
}

/*
 * TaskTypeを取得
 */
-(int)getTaskType{
    return (int)[_taskTypeField indexOfSelectedItem];
}


@end
