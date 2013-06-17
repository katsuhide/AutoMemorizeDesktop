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
@dynamic participants;
@dynamic update_time;

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

-(NSArray*)splitTags{
    return [self.tags componentsSeparatedByString:@","];
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

@end
