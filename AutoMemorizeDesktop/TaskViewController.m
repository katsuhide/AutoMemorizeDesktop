//
//  NewTaskController.m
//  AutoMemorizeDesktop
//
//  Created by AirMyac on 6/15/13.
//  Copyright (c) 2013 com.katzlifehack. All rights reserved.
//

#import "TaskViewController.h"

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
            [(SkypeViewController*)self.taskViewController changeCustomTaskView:NO andData:nil];
            break;
        case 1:
            // File View
            self.taskViewController = [[FileViewController alloc]initWithNibName:fileViewName bundle:nil];
            [(FileViewController*)self.taskViewController changeCustomTaskView:NO andData:nil];
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
    
}


/*
 * TaskViewの初期化
 */
-(void)initializedTaskView{
    NSLog(@"initializedTaskView ExtedsParts");
    // アイテムを初期化
    [self changeTaskView:YES andData:nil];
//    [_taskTypeBtn selectItemAtIndex:0];
//    [_taskTypeField selectItemAtIndex:0];
    
    // Viewを初期化
    [self changeViewImpl];
}

/*
 * 選択されたTaskの情報を表示してTaskViewを開く(すべてDisableにする）
 */
-(void)viewTaskView:(TaskSource*)source{
    NSLog(@"viewTaskView ExtedsParts");
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
    [_taskTypeField selectItemAtIndex:[source.task_type intValue]];
}

-(void)changeCustomTaskView:(BOOL)isEditable andData:(TaskSource*)source{
    // TODO 分岐
    [(SkypeViewController*)self.taskViewController changeCustomTaskView:NO andData:source];
//    [(FileViewController*)self.taskViewController changeCustomTaskView:NO andData:source];

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
//    return [NSString stringWithFormat:@"%ld",[_taskTypeField indexOfSelectedItem]];
//    return [NSString stringWithFormat:@"%ld",(long)[_taskTypeBtn indexOfSelectedItem]];
}


@end
