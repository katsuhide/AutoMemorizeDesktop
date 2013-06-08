//
//  AppDelegate.h
//  AutoMemorizeDesktop
//
//  Created by AirMyac on 6/2/13.
//  Copyright (c) 2013 com.katzlifehack. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Task.h"
#import "TaskForFile.h"
#import "TaskForSkype.h"
#import <EvernoteSDK-Mac/EvernoteSDK.h>

@interface AppDelegate : NSObject <NSApplicationDelegate>

@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (nonatomic,strong) IBOutlet NSArrayController *taskArrayController;

#define INTERVAL 5
#define APP_NAME @"AutoMemorizeDesktop"
#define TASK_SOURCE @"TaskSource"

@property (assign) IBOutlet NSWindow *window;
@property (retain) NSMutableArray *taskQueue;

/*
 * EvernoteにNOTEを新規保存する処理を実行する
 */
-(void)doAddNote:(EDAMNote*)note;

// Save
-(void)save;

@end
