//
//  TaskForFile.h
//  TimerTest
//
//  Created by AirMyac on 5/31/13.
//  Copyright (c) 2013 com.katzlifehack. All rights reserved.
//

#import "Task.h"

@interface TaskForFile : Task

@property (assign) BOOL canAddNote;

/*
 * ノート登録後の後処理
 */
-(void)afterRegister:(BOOL)isSuceeded;


@end
