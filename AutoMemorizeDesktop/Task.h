//
//  Task.h
//  TimerTest
//
//  Created by AirMyac on 5/31/13.
//  Copyright (c) 2013 com.katzlifehack. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <EvernoteSDK-Mac/EvernoteSDK.h>

@interface Task : NSObject


@property (assign) NSMutableString *taskName;

@property (assign) NSMutableString *interval;

@property (assign) NSMutableString *lastExecuteTime;

@property (assign) NSMutableString *noteTitle;

@property (assign) NSMutableString *noteBook;

@property (assign) NSMutableString *tag;


/*
 * タスクの実行判定
 */
- (BOOL) check;

/*
 * タスクの処理内容
 */
- (EDAMNote*) execute;

- (id) initWith:(NSString *)str;

@end
