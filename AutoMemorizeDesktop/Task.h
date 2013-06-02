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

@interface Task : NSObject


@property (retain) NSMutableString *taskName;

@property (retain) NSMutableString *interval;

@property (retain) NSDate *lastExecuteTime;

@property (retain) NSMutableString *noteTitle;

@property (retain) NSMutableString *noteBook;

@property (retain) NSMutableString *tag;


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

-(id) initWith:(NSString *)str;

@end
