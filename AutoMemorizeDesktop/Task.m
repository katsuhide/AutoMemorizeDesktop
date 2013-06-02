//
//  Task.m
//  TimerTest
//
//  Created by AirMyac on 5/31/13.
//  Copyright (c) 2013 com.katzlifehack. All rights reserved.
//

#import "Task.h"

@implementation Task


- (id)init
{
    if(self = [super init]){
        /* initialization code */
        
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

    NSLog(@"Task Class method.");
    NSLog(@"%@", self.lastExecuteTime);
    return nil;
    
}


- (id)initWith:(NSString *)str{
    self.lastExecuteTime = [[NSMutableString alloc] initWithString:str];
    return self;
}


@end
