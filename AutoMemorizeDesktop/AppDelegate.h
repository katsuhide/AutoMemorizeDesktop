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
#import "TaskViewController.h"

@interface AppDelegate : NSObject <NSApplicationDelegate>
// Environment
extern const BOOL ENV;

// CoreData
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
#define APP_NAME @"AutoMemorizeDesktop"
#define TASK_SOURCE @"TaskSource"

// TableView
@property (nonatomic,strong) IBOutlet NSArrayController *taskArrayController;
@property (assign) IBOutlet NSTableView *taskTable;

// View
@property (assign) IBOutlet NSWindow *window;
@property (assign) IBOutlet NSPanel *taskView;
@property (assign) IBOutlet TaskViewController *taskViewController;

// Main Thread
#define INTERVAL 60  // 秒

@property (retain) NSMutableArray *taskQueue;

// Task Panle
@property (assign) IBOutlet NSTextField *taskNameField;
@property (assign) IBOutlet NSTextField *intervalField;
@property (assign) IBOutlet NSTextField *notetitleField;
@property (assign) IBOutlet NSComboBox *notebookField;
@property (assign) IBOutlet NSTokenField *tagField;


/*
 * EvernoteにNOTEを新規保存する処理を実行する
 */
-(void)doAddNote:(EDAMNote*)note;

// Save
-(void)save;

@end
