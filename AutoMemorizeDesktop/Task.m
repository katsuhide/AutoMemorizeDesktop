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
    }
    return self;
}


/*
 * タスクの実行判定
 */
- (BOOL)check:(NSDate*)now {
    // Task StatusがOFFならskipする
    if([self.source.status intValue] == 0){
        NSLog(@"The status of the %@ is OFF.", self.source.task_name);
        return NO;
    }

    // 前回時間にインターバル時間を足して、次回実行開始時間を計算
    NSTimeInterval intval = [self.source.interval doubleValue];    // 時間で入力される想定
    NSDate *nextTime = [self.source.last_execute_time dateByAddingTimeInterval:(intval * 3600)];    // TODO テストなんで分を秒に変換（本来は*3600)
    
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
    NSLog(@"[Class:%@][PreviousExecutedTime:%@][CurrentExecutedTime:%@]", NSStringFromClass([self class]), [self.source.last_execute_time toString], [now toString]);
    // 実行時間を更新
    self.source.last_execute_time = now;
    self.source.update_time = now;
}

@end
