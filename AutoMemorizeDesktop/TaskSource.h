//
//  TaskSource.h
//  AutoMemorizeDesktop
//
//  Created by AirMyac on 6/3/13.
//  Copyright (c) 2013 com.katzlifehack. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "NSDate+Util.h"
#import <EvernoteSDK-Mac/EvernoteSDK.h>

@interface TaskSource : NSManagedObject

// save to DB
@property (nonatomic, retain) NSString * task_name;
@property (nonatomic, retain) NSNumber * task_type;
@property (nonatomic, retain) NSNumber * status;
@property (nonatomic, retain) NSString * interval;
@property (nonatomic, retain) NSDate * last_execute_time;
@property (nonatomic, retain) NSDate * last_added_time;
@property (nonatomic, retain) NSString * tags;
@property (nonatomic, retain) NSString * note_title;
@property (nonatomic, retain) NSString * notebook_guid;
@property (nonatomic, retain) NSString * params;
@property (nonatomic, retain) NSDate * update_time;

// not save to DB
@property (assign) NSImage  *statusImage;
@property (assign) NSImage  *typeImage;
@property (assign) EDAMNotebook *noteBook;

-(void)print;

/*
 * Task StatusのOn/Offを切り替える
 */
-(void)changeStatus;

-(NSArray*)splitTags;

-(NSMutableDictionary*)splitParams;

-(NSString*)transformKeyValue:(NSString*) key andValue:(NSString*) value;

/*
 * paramsから指定したkeyに対応するvalueを取得する
 */
-(NSString*)getKeyValue:(NSString*)key;

@end
