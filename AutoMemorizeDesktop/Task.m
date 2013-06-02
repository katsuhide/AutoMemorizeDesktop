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


- (id)init
{
    if(self = [super init]){
        /* initialization code */
//        self.lastExecuteTime = [[NSMutableString alloc]initWithString:@"0"];
        self.lastExecuteTime = [[NSDate alloc] init];
        self.interval = [[NSMutableString alloc]initWithString:@"10"];
        
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
    self.lastExecuteTime = now;
}


- (id)initWith:(NSString *)str{
    self.lastExecuteTime = [[NSMutableString alloc] initWithString:str];
    return self;
}


@end
