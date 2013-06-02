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
        self.lastExecuteTime = [[NSMutableString alloc]initWithString:@"0"];
        self.interval = [[NSMutableString alloc]initWithString:@"5"];
        
    }
    return self;
}

/*
 * タスクの実行判定
 */
- (BOOL) check {
    return YES;
}


/*
 * タスクの処理内容
 */
- (EDAMNote*) execute {
    // 前回の実行時間を出力
    NSLog(@"Task Class : %@", self.lastExecuteTime);
    // 実行時間を更新
    NSDate *now = [NSDate date];
    [self.lastExecuteTime setString:[now toString]];
    return nil;
    
}

/*
 * 定期実行で実行される処理
 */
- (void)polling:(NSTimer*)timer{
    [self execute];
    AppDelegate *appDelegate = (AppDelegate*)[[NSApplication sharedApplication] delegate];
    [appDelegate hoge];

}

- (id)initWith:(NSString *)str{
    self.lastExecuteTime = [[NSMutableString alloc] initWithString:str];
    return self;
}


@end
