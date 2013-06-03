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
@dynamic interval;
@dynamic last_execute_time;
@dynamic tags;
@dynamic note_title;
@dynamic notebook_guid;
@dynamic params;

-(void)print{
    NSLog(@"{\n"
          "\ttask_name:%@\n"
          "\ttask_type:%@\n"
          "\tinterval:%@\n"
          "\tlast_execte_time:%@\n"
          "\tnote_title:%@\n"
          "\tnotebook_guid:%@\n"
          "\ttags:%@\n"
          "\tparams:%@\n",
          self.task_name, self.task_type, self.interval, self.last_execute_time, self.note_title, self.notebook_guid, self.tags, self.params);
}

@end
