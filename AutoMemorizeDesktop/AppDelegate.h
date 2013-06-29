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
#define APP_NAME @"RecDesktop"
#define TASK_SOURCE @"TaskSource"

// TableView
@property (nonatomic,strong) IBOutlet NSArrayController *taskArrayController;
@property (assign) IBOutlet NSTableView *taskTable;

// View
@property (assign) IBOutlet NSWindow *window;
@property (strong) IBOutlet NSPanel *preWindow;
@property (strong) IBOutlet NSPanel *taskView;
@property (assign) IBOutlet TaskViewController *taskViewController;

// Button
@property (assign) IBOutlet NSButton *statusBtn;
@property (assign) IBOutlet NSButton *infoBtn;
@property (assign) IBOutlet NSButton *registerBtn;
@property (assign) IBOutlet NSButton *deleteBtn;
@property (assign) IBOutlet NSButton *registerOKBtn;
@property (assign) IBOutlet NSButton *signInOrOutBtn;
@property (assign) IBOutlet NSButton *allStartBtn;
@property (assign) IBOutlet NSButton *allStopBtn;
@property (assign) IBOutlet NSButton *allRestartBtn;
@property (assign) BOOL statusFlag;


// Main Thread
#define INTERVAL 15  // 秒
@property (retain) NSMutableArray *taskQueue;

// Task Panle
@property (assign) IBOutlet NSTextField *taskNameField;
@property (assign) IBOutlet NSTextField *intervalField;
@property (assign) IBOutlet NSTextField *notetitleField;
@property (assign) IBOutlet NSComboBox *notebookField;
@property (assign) IBOutlet NSTokenField *tagField;

@property (assign) IBOutlet NSTextField *userNameLabel;

@property (strong) NSMutableArray *notebookList;

/*
 * EvernoteにNOTEを新規保存する処理を実行する
 */
-(void)doAddNote:(EDAMNote*)note;

// Save
-(void)save;

/*
 * EvernoteにSignIn済みかのチェック
 */
-(BOOL)isSignedEvernote;

/*
 * 指定されたGUIDのNotebookが存在するかをチェックする
 */
-(BOOL)isExistNotebook:(NSString*)guid;




@end
