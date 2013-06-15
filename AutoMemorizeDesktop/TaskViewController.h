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

@interface TaskViewController : NSObject

@property (weak) IBOutlet NSView *taskView;
@property (strong) NSViewController *taskViewController;

@property (assign) IBOutlet NSComboBox *taskTypeField;
@property (assign) IBOutlet NSPopUpButton *taskTypeBtn;

/*
 * New Task Viewの拡張部分を切り替える
 */
-(IBAction)changeView:(id)sender;

/*
 * TaskViewの初期化
 */
-(void)initializedTaskView;

/*
 * TaskViewの拡張部分の情報を取得
 */
-(NSMutableString*)getParams;

/*
 * TaskTypeを取得
 */
-(int)getTaskType;


@end
