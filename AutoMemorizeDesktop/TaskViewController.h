//
//  NewTaskController.h
//  AutoMemorizeDesktop
//
//  Created by AirMyac on 6/15/13.
//  Copyright (c) 2013 com.katzlifehack. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SkypeViewController.h"
#import "FileViewController.h"
#import "TaskSource.h"

@interface TaskViewController : NSObject

@property (weak) IBOutlet NSView *taskView;
@property (strong) NSViewController *taskViewController;

@property (assign) IBOutlet NSComboBox *taskTypeField;

/*
 * New Task Viewの拡張部分を切り替える
 */
-(IBAction)changeView:(id)sender;

/*
 * TaskViewの初期化
 */
-(void)initializedTaskView;

/*
 * 選択されたTaskの情報を表示してTaskViewを開く(すべてDisableにする）
 */
-(void)viewTaskView:(TaskSource*)source;


/*
 * TaskViewの拡張部分の情報を取得
 */
-(NSMutableString*)getParams;

/*
 * TaskTypeを取得
 */
-(int)getTaskType;

@end
