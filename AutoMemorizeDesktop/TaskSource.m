//
//  TaskSource.m
//  AutoMemorizeDesktop
//
//  Created by AirMyac on 6/3/13.
//  Copyright (c) 2013 com.katzlifehack. All rights reserved.
//

#import "TaskSource.h"


@implementation TaskSource

@dynamic task_name;
@dynamic task_type;
@dynamic status;
@dynamic interval;
@dynamic last_execute_time;
@dynamic last_added_time;
@dynamic tags;
@dynamic note_title;
@dynamic notebook_guid;
@dynamic params;
@dynamic update_time;
@dynamic statusImage;
@dynamic typeImage;
@dynamic noteBook;

-(void)print{
    NSLog(@"{\n"
          "\ttask_name:%@\n"
          "\ttask_type:%@\n"
          "\tstatus:%@\n"
          "\tinterval:%@\n"
          "\tlast_execte_time:%@\n"
          "\tlast_added_time:%@\n"
          "\tnote_title:%@\n"
          "\tnotebook_guid:%@\n"
          "\ttags:%@\n"
          "\tparams:%@\n"
          "\tupdate_time:%@\n}",
          self.task_name, [self getTask_type], [self getStatus], self.interval, [self.last_execute_time toString], [self.last_added_time toString], self.note_title, self.notebook_guid, self.tags, self.params, [self.update_time toString]);
}

/*
 * Task StatusのOn/Offを切り替える
 */
-(void)changeStatus{
    if([self.status compare:[NSNumber numberWithInt:1]] == 0){
        self.status = [NSNumber numberWithInt:0];
    }else{
        self.status = [NSNumber numberWithInt:1];
    }
}

-(NSString*)getStatus{
    NSString *str = @"OFF";
    if([self.status compare:[NSNumber numberWithInt:1]] == 0){
        str = @"ON";
    }
    return str;
}

-(NSString*)getTask_type{
    NSString *str = @"OTHER";
    int index = [self.task_type intValue];
    switch (index) {
        case 0:
            str = @"SKype Task";
            break;
        case 1:
            str = @"File Task";
            break;
        default:
            break;
    }
    return str;
}

-(NSString*)getLast_execute_time{
    return [self.last_execute_time toString];
}

-(NSString*)getUpdate_time{
    return [self.update_time toString];
}

-(NSString*)getLast_added_time{
    return [self.last_added_time toString];
}


-(NSArray*)splitTags{
    if([self.tags length] == 0){
        return nil;
    }else{
        return [self.tags componentsSeparatedByString:@","];
    }
}

-(NSMutableDictionary*)splitParams{
    NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
    NSArray *array = [self.params componentsSeparatedByString:@"|"];
    for(NSString *str in array){
        if(str.length != 0){
            NSArray *ary = [str componentsSeparatedByString:@"="];
            NSString *key = [ary objectAtIndex:0];
            NSString *value = [ary objectAtIndex:1];
            [dic setValue:value forKey:key];
        }
    }
    return dic;
}


// key=value形式でデータを生成する
-(NSString*)transformKeyValue:(NSString*) key andValue:(NSString*) value{
    return [NSString stringWithFormat:@"%@=%@|", key, value];
}

/*
 * paramsから指定したkeyに対応するvalueを取得する
 */
-(NSString*)getKeyValue:(NSString*)key{
    NSMutableDictionary *dic = [self splitParams];
    NSString *str = [dic objectForKey:key];
    return str;
    
}

/*
 * タスクステータスに合った画像を出力
 */
-(NSImage*)getStatusImage{
    NSString *file;
    if([self.status intValue] == 0){
        file = [[NSBundle mainBundle] pathForResource:@"Pause" ofType:@"psd"];
    }else{
        file = [[NSBundle mainBundle] pathForResource:@"Play" ofType:@"psd"];
    }
    NSImage *image = [[NSImage alloc]initByReferencingFile:file];
    return image;
}

/*
 * タスクタイプに合った画像を出力
 */
-(NSImage*)getTypeImage{
    NSString *file;
    int type = [self.task_type intValue];
    if(type == 0){
        file = [[NSBundle mainBundle] pathForResource:@"skype" ofType:@"png"];
    }else if(type == 1){
        file = [[NSBundle mainBundle] pathForResource:@"documents_folder" ofType:@"png"];
    }else{
        
    }
    NSImage *image = [[NSImage alloc]initByReferencingFile:file];
    return image;
}

@end
