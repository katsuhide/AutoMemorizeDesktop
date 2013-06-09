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
@dynamic tags;
@dynamic note_title;
@dynamic notebook_guid;
@dynamic params;
@dynamic update_time;

-(void)print{
    NSLog(@"{\n"
          "\ttask_name:%@\n"
          "\ttask_type:%@\n"
          "\tstatus:%@\n"
          "\tinterval:%@\n"
          "\tlast_execte_time:%@\n"
          "\tnote_title:%@\n"
          "\tnotebook_guid:%@\n"
          "\ttags:%@\n"
          "\tparams:%@\n"
          "\tupdate_time:%@\n}",
          self.task_name, self.task_type, [self changeStatus], self.interval, [self.last_execute_time toString], self.note_title, self.notebook_guid, self.tags, self.params, [self.update_time toString]);
}

-(NSString*)changeStatus{
    NSString *str = @"OFF";
    if([self.status compare:[NSNumber numberWithInt:1]] == 0){
        str = @"ON";
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

-(NSArray*)splitParams{
    return [self.params componentsSeparatedByString:@","];
}

// Paramsに{key=value}形式でデータを登録する
-(NSString*)transformKeyValue:(NSString*) key andValue:(NSString*) value{
    return [NSString stringWithFormat:@"%@=%@|", key, value];
}


@end
