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
    // OFF LINEならskip
    AppDelegate *appDelegate = (AppDelegate*)[[NSApplication sharedApplication] delegate];
    if(!appDelegate.isReachable){
#if DEBUG
        NSLog(@"[TaskName:%@]The Internet connection appears to be offline.", self.source.task_name);
#endif
        return NO;
    }
    
    // Evernoteで認証されていなければskipする
    if(![appDelegate isSignedEvernote]){
#if DEBUG
        NSLog(@"[TaskName:%@]Didn't Signed In the Evernote.", self.source.task_name);
#endif
        return NO;
    }
    
    // Task StatusがOFFならskipする
    if([self.source.status intValue] == 0){
#if DEBUG
        NSLog(@"[TaskName:%@]The status is OFF.", self.source.task_name);
#endif
        return NO;
    }

    // 前回時間にインターバル時間を足して、次回実行開始時間を計算
    NSTimeInterval intval = [self.source.interval doubleValue];    // 時間で入力される想定
    NSDate *nextTime = [self.source.last_execute_time dateByAddingTimeInterval:(intval * 3600)];
    
    // 時間の判定
    if([now compare:nextTime] < 0){
#if DEBUG
        NSLog(@"[TaskName:%@]Disable timing. result:%ld, now:%@, next:%@", self.source.task_name, [now compare:nextTime], [now toString], [nextTime toString]);
#endif
        return NO;
    }else{
#if DEBUG
        NSLog(@"[TaskName:%@]Enable timing. result:%ld, now:%@, next:%@", self.source.task_name, [now compare:nextTime], [now toString], [nextTime toString]);
#endif
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
- (NSMutableArray*) execute {
    NSLog(@"Execute method does not implemented.");
    return nil;
}

/*
 * 実行時間の更新
 */
-(void)updateLastExecuteTime:(NSDate*)date{
    // 実行時間を出力
    NSLog(@"[Class:%@][PreviousExecutedTime:%@][CurrentExecutedTime:%@]", NSStringFromClass([self class]), [self.source.last_execute_time toString], [date toString]);
    // 実行時間を更新
    self.source.last_execute_time = date;
    self.source.update_time = date;
}

/*
 * ノート登録時間の更新
 */
-(void)updateLastAddedTime:(NSDate*)date{
    // ノート登録時間を出力
    NSLog(@"[Class:%@][PreviousAddedTime:%@][CurrentAddedTime:%@]", NSStringFromClass([self class]), [self.source.last_added_time toString], [date toString]);

    // 前回更新時間と比較して時間が進んでいれば、ノート登録時間を更新する
    NSComparisonResult result = [self.source.last_added_time compare:date];
    if(result < 0){
        self.source.last_added_time = date;
    }
}

/*
 * ノート登録後の後処理
 */
-(void)afterRegister:(BOOL)isSuceeded{
    NSLog(@"Not implemented.");
}

/*
 * 指定したファイルと指定した時間の比較を実施
 */
-(NSComparisonResult)compareFileTimeStamp:(NSDate*)lastExecutedTime andFilePath:(NSString*)filePath{
    // ファイルのタイムスタンプを取得
    NSError *error = nil;
    NSDictionary* dicFileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:&error];
    if (error) {
        return -1;
    }
    
    // 比較
    NSDate *fileTimeStamp = [dicFileAttributes objectForKey:@"NSFileModificationDate"];
#if DEBUG
    NSLog(@"Name:%@, file:%@, target:%@", [filePath lastPathComponent], [fileTimeStamp toLocalTime], [lastExecutedTime toLocalTime]);
#endif
    NSComparisonResult result = [fileTimeStamp compare:lastExecutedTime];
    return result;
    
}

/*
 * 指定したファイルのタイムスタンプを取得
 */
-(NSDate*)getFileTimeStamp:(NSString*)filePath{
    NSError *error = nil;
    NSDictionary* dicFileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:&error];
    return [dicFileAttributes objectForKey:@"NSFileModificationDate"];
}

@end
