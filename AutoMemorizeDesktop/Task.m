//
//  Task.m
//  TimerTest
//
//  Created by AirMyac on 5/31/13.
//  Copyright (c) 2013 com.katzlifehack. All rights reserved.
//

#import "Task.h"
#import "AppDelegate.h"

@implementation Task

-(id) initWithTaskSource:(TaskSource *)source{
    if(self = [super init]){
        self.source = source;
        // TODO 以降の処理はいらないはず
        self.taskName = [NSMutableString stringWithString:source.task_name];
        self.interval = [NSMutableString stringWithString:source.interval];
        self.lastExecuteTime = source.last_execute_time;
        self.noteTitle = [NSMutableString stringWithString:source.note_title];
        if(source.notebook_guid != nil){
            self.notebook_guid = [NSMutableString stringWithString:source.notebook_guid];
        }
        self.tag = [[NSMutableArray alloc]initWithArray:[source splitTags]];
        self.param = [[NSMutableArray alloc]initWithArray:[source splitParams]];
    }
    return self;
}


/*
 * タスクの実行判定
 */
- (BOOL)check:(NSDate*)now {
    // 前回時間にインターバル時間を足して、次回実行開始時間を計算
    NSTimeInterval intval = [self.interval intValue];
    NSDate *nextTime = [self.lastExecuteTime dateByAddingTimeInterval:intval];
    
    // 時間の判定
    NSLog(@"result:%ld, now:%@, next:%@",[now compare:nextTime], [now toString], [nextTime toString]);
    if([now compare:nextTime] < 0){
        return NO;
    }else{
        return YES;
    }

}

/*
 * 定期実行で実行される処理
 */
- (void)polling:(NSTimer*)timer{
    NSDate *now = [NSDate date];
    // 実行判定
    if([self check:now]){
        // タスクを実行
        [self execute];
        // 実行時間を更新
        [self updateLastExecuteTime:now];
        AppDelegate *appDelegate = (AppDelegate*)[[NSApplication sharedApplication] delegate];
        [appDelegate save];
        
    }else{
        // タスクは未実行
        NSLog(@"Did not executed.[%@]", NSStringFromClass([self class]));
    }

}

/*
 * タスクの処理内容
 */
- (EDAMNote*) execute {
    NSLog(@"Execute method does not implemented.");
    return nil;
}

/*
 * 実行時間の更新
 */
-(void)updateLastExecuteTime:(NSDate*)now{
    // 実行時間を出力
    NSLog(@"[Class:%@][ExecutedTime:%@]", NSStringFromClass([self class]), [self.lastExecuteTime toString]);
    // 実行時間を更新
    self.source.last_execute_time = now;
    self.source.update_time = now;
}

@end
