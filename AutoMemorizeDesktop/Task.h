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
- (NSMutableArray*)execute;

/*
 * 定期実行で実行される処理
 */
- (void)polling:(NSTimer*)timer;

/*
 * 実行時間の更新
 */
-(void)updateLastExecuteTime:(NSDate*)now;

/*
 * ノート登録時間の更新
 */
-(void)updateLastAddedTime:(NSDate*)now;

/*
 * ノート登録後の後処理
 */
-(void)afterRegister:(BOOL)isSuceeded;

/*
 * 指定したファイルと指定した時間の比較を実施
 */
-(NSComparisonResult)compareFileTimeStamp:(NSDate*)lastExecutedTime andFilePath:(NSString*)filePath;

/*
 * 指定したファイルのタイムスタンプを取得
 */
-(NSDate*)getFileTimeStamp:(NSString*)filePath;

@end
