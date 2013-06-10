//
//  Task.h
//  TimerTest
//
//  Created by AirMyac on 5/31/13.
//  Copyright (c) 2013 com.katzlifehack. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <EvernoteSDK-Mac/EvernoteSDK.h>
#import "NSDate+Util.h"
#import "TaskSource.h"

@interface Task : NSObject

@property (retain) TaskSource *source;

//@property (retain) NSMutableString *taskName;
//
//@property (retain) NSMutableString *interval;
//
//@property (retain) NSDate *lastExecuteTime;
//
//@property (retain) NSMutableString *noteTitle;
//
//@property (retain) NSMutableString *notebook_guid;
//
//@property (retain) NSMutableArray *tag;
//
//@property (retain) NSMutableArray *param;

/*
 * TaskSourceで初期化
 */

-(id) initWithTaskSource:(TaskSource *)source;


/*
 * タスクの実行判定
 */
- (BOOL)check:(NSDate*)now;

/*
 * タスクの処理内容
 */
- (EDAMNote*)execute;

/*
 * 定期実行で実行される処理
 */
- (void)polling:(NSTimer*)timer;

/*
 * 実行時間の更新
 */
-(void)updateLastExecuteTime:(NSDate*)now;

    
@end
