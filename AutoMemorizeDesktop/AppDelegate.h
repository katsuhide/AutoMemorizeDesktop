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


// Main Thread
#define INTERVAL 5
@property (retain) NSMutableArray *taskQueue;

// Task Panle
@property (assign) IBOutlet NSTextField *taskNameField;
@property (assign) IBOutlet NSComboBox *taskTypeField;
@property (assign) IBOutlet NSTextField *intervalField;
@property (assign) IBOutlet NSTextField *notetitleField;
@property (assign) IBOutlet NSComboBox *notebookField;
@property (assign) IBOutlet NSTokenField *tagField;
@property (assign) IBOutlet NSTextField *skypeDBFilePathField;
@property (assign) IBOutlet NSTextField *participantsField;


/*
 * EvernoteにNOTEを新規保存する処理を実行する
 */
-(void)doAddNote:(EDAMNote*)note;

// Save
-(void)save;

@end
