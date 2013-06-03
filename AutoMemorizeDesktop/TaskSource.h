//
//  TaskSource.h
//  AutoMemorizeDesktop
//
//  Created by AirMyac on 6/3/13.
//  Copyright (c) 2013 com.katzlifehack. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface TaskSource : NSManagedObject

@property (nonatomic, retain) NSString * task_name;
@property (nonatomic, retain) NSString * task_type;
@property (nonatomic, retain) NSString * interval;
@property (nonatomic, retain) NSDate * last_execute_time;
@property (nonatomic, retain) NSString * tags;
@property (nonatomic, retain) NSString * note_title;
@property (nonatomic, retain) NSString * notebook_guid;
@property (nonatomic, retain) NSString * params;

-(void)print;

@end
