//
//  AppDelegate.m
//  AutoMemorizeDesktop
//
//  Created by AirMyac on 6/2/13.
//  Copyright (c) 2013 com.katzlifehack. All rights reserved.
//

#import "AppDelegate.h"
#import <CommonCrypto/CommonCrypto.h>
#import "TaskSource.h"
#import "CustomHeaderCell.h"
#import "NSColor+Hex.h"

@implementation AppDelegate

@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize managedObjectContext = _managedObjectContext;

const BOOL ENV = NO;

// Insert code here to initialize your application
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // test method
//    [self testMethod:nil];

    // ログ出力
    if(ENV){
        freopen([@"/tmp/recdesktop.log" fileSystemRepresentation], "w+", stderr);
    }

    // 初回起動用にDataStore用のDirectoryの有無を確認して無ければ作成する
    NSURL *applicationFilesDirectory = [self applicationFilesDirectory];
    NSError *error = nil;
    if(![[NSFileManager defaultManager] createDirectoryAtPath:[applicationFilesDirectory path] withIntermediateDirectories:YES attributes:nil error:&error]){
        NSLog(@"Couldn't create the data store directory.[%@, %@]", error, [error userInfo]);
        abort();
    }
    
    // ArrayControllerとmanagedObjectContextの紐付け
    [_taskArrayController setManagedObjectContext:self.managedObjectContext];
    
    // Evernoteへログイン
//    [self doAuthorize:nil];

    // Notebookの一覧を取得
//    [self getNotebookList];
    
    // Main画面を初期化
    [self initialize];

    // メインスレッドのポーリングを開始
//    [self run];
}

/*
 * メインスレッドのポーリング処理を開始
 */
-(void)run{
    NSLog(@"Main Thread has been started.");
    // タスクキューの初期化
    _taskQueue = [[NSMutableArray alloc]init];
    
    // Taskの一覧を取得
    NSArray *taskList = [self getTaskList];
    
    for(TaskSource *source in taskList){
        int taskType = [source.task_type intValue];
        Task *task;
        switch (taskType) {
            case 0:
                // Skype Task
                NSLog(@"[TaskName:%@]Skype Task created.", source.task_name);
                task = [[TaskForSkype alloc]initWithTaskSource:source];
                break;
            case 1:
                // File Task
                NSLog(@"[TaskName:%@]File Task Created.", source.task_name);
                task = [[TaskForFile alloc]initWithTaskSource:source];
                break;
            default:
                // Other Task
                NSLog(@"[TaskName:%@]Other Task Created.", source.task_name);
                task = [[Task alloc]initWithTaskSource:source];
                break;
        }

        // インターバル条件を指定
        int interval = INTERVAL;
        if(!ENV) {
            interval = 5;
        }
        
        // タスクタイマーを生成し、タスクキューに追加
        NSTimer *timer = [NSTimer
                          scheduledTimerWithTimeInterval:interval
                          target:task
                          selector:@selector(polling:)
                          userInfo:source.task_name
//                          userInfo:nil
                          repeats:YES];
        [_taskQueue addObject:timer];
    }
    
}

/*
 * TaskViewのRegisterAction
 */
-(IBAction)registerAction:(id)sender{
    // 画面の入力値からTaskを生成する
    TaskSource *source = (TaskSource*)[self createObject:TASK_SOURCE];
    source.task_name = [_taskNameField stringValue];
    source.status = [NSNumber numberWithInt:1];
    source.task_type = [NSNumber numberWithInt:[_taskViewController getTaskType]];
    source.interval = [_intervalField stringValue];
    source.note_title = [_notetitleField stringValue];
    
    NSString *notebookName = [_notebookField stringValue];
    NSString *guid = @"";
    for(NSDictionary *notebook in _notebookList){
        if([notebookName isEqualToString:[notebook objectForKey:@"name"]]){
            guid = [notebook objectForKey:@"guid"];
        }
    }
    source.notebook_guid = guid;

    source.tags = [_tagField stringValue];
    NSMutableString *params = [_taskViewController getParams];
    source.params = params;
    NSDate *now = [NSDate date];
    source.last_execute_time = now;
    source.last_added_time = now;
    source.update_time = now;
    
    // Taskを保存
    [self save];
    // TaskTableViewを初期化
    [self initializeTableView];
    // TaskViewを閉じる
    [self closeTaskView];
    // Taskを初期化
    [self restart:nil];
}


/*
 * PreferencesViewを開く
 */
-(IBAction)openPreferences:(id)sender{
    [_preWindow makeKeyAndOrderFront:sender];

}

/*
 * TaskViewを開く
 */
-(IBAction)openTaskView:(id)sender{
    [self initializedTaskView];
    [_taskView makeKeyAndOrderFront:sender];
}


/*
 * TaskViewを閉じる
 */
-(void)closeTaskView{
    [_taskView close];
}

/*
 * Main画面を初期化
 */
-(void)initialize{
    // 背景
    NSColor *color = [NSColor colorWithCalibratedRed:1 green:1 blue:1 alpha:1];
    [_window setBackgroundColor:color];
//    [_window setAlphaValue:0.95];

//    for (NSTableColumn* column in [_taskTable tableColumns]) {
//        NSTableHeaderCell *cell = [column headerCell];
//        CustomHeaderCell *newCell = [[CustomHeaderCell alloc] init];
//        [newCell setAttributedStringValue:[cell attributedStringValue]];
//        [column setHeaderCell:newCell];
//    }
    
//    NSTableHeaderView *tableHeaderView = [[NSTableHeaderView alloc] initWithFrame:NSMakeRect(0, 0, 10, 60)];
//    NSTableHeaderView *tableHeaderView = _taskTable.headerView;
//    NSRect frame = tableHeaderView.frame;
//    frame.size.width = 200;
//    tableHeaderView.frame = frame;
//    [_taskTable setHeaderView:nil];
//    [_taskTable setHeaderView:tableHeaderView];
    
//    NSString *hex = @"#F1EEFB";
//    NSColor *backColor = [NSColor colorFromHexadecimalValue:hex];
//    [tableHeaderView setFrameSize:NSMakeSize(100, 100)];
//    [_taskTable setHeaderView:tableHeaderView];
    
    // 各種ボタン
    NSString *imagePath;
    // Status Button
    _statusFlag = false;    // 起動時はfalseで
    imagePath = [[NSBundle mainBundle] pathForResource:@"Last" ofType:@"tif"];
    imagePath = @"/Users/AirMyac/Desktop/material/botton2/status.psd";
    NSImage *statusBtnImage = [[NSImage alloc]initByReferencingFile:imagePath];
    [_statusBtn setImage:statusBtnImage];
    [_statusBtn setBordered:NO];
    
    // Info Button
    imagePath = [[NSBundle mainBundle] pathForResource:@"Info" ofType:@"tif"];
    imagePath = @"/Users/AirMyac/Desktop/material/botton2/info.psd";
    NSImage *infoBtnImage = [[NSImage alloc]initByReferencingFile:imagePath];
    [_infoBtn setImage:infoBtnImage];
    [_infoBtn setBordered:NO];
    
    // Register Button
//    imagePath = [[NSBundle mainBundle] pathForResource:@"Plus" ofType:@"tif"];
    imagePath = @"/Users/AirMyac/Desktop/material/botton2/plus.psd";
    NSImage *registerBtnImage = [[NSImage alloc]initByReferencingFile:imagePath];
    [_registerBtn setImage:registerBtnImage];
    [_registerBtn setBordered:NO];
    
    // Delete Button
    imagePath = [[NSBundle mainBundle] pathForResource:@"Block" ofType:@"tif"];
    imagePath = @"/Users/AirMyac/Desktop/material/botton2/minus.psd";
    NSImage *deleteBtnImage = [[NSImage alloc]initByReferencingFile:imagePath];
    [_deleteBtn setImage:deleteBtnImage];
    [_deleteBtn setBordered:NO];
    
    // Table Viewの初期化
    [self initializeTableView];

}

/*
 * TaskViewを初期化
 */
-(void)initializedTaskView{
    // 背景
    NSColor *color = [NSColor colorWithCalibratedRed:1 green:1 blue:1 alpha:1];
    [_taskView setBackgroundColor:color];

    // 共通部分のアイテムを初期化
    [self changeTaskView:YES andData:nil];
    // 拡張部分のアイテムを初期化
    [_taskViewController initializedTaskView];
    
}

/*
 * 選択されたTaskの情報を表示してTaskViewを開く(すべてDisableにする）
 */
-(void)viewTaskView:(TaskSource*)source{
    // 共通部分のアイテムを初期化
    [self changeTaskView:NO andData:source];
    // 拡張部分のアイテムを初期化
    [_taskViewController viewTaskView:source];

}

-(void)changeTaskView:(BOOL)isEditable andData:(TaskSource*)source{
    // 指定されたモードに設定
    [_taskNameField setEditable:isEditable];
    [_intervalField setEditable:isEditable];
    [_notetitleField setEditable:isEditable];
    [_notebookField setEnabled:isEditable];
    [_notebookField setSelectable:YES];
    [_tagField setEditable:isEditable];
    [_registerOKBtn setHidden:!isEditable];
    
    // データを設定もしくは初期化
    if(isEditable){
        // 登録モード
        [_taskView setTitle:@"New Task"];
        [_taskNameField setObjectValue:nil];
        [_intervalField setObjectValue:nil];
        [_notetitleField setObjectValue:nil];
        [_notebookField setObjectValue:nil];   // 一度空にする
        for(NSDictionary *notebook in _notebookList){
            [_notebookField addItemWithObjectValue:[notebook objectForKey:@"name"]];
        }
        [_tagField setObjectValue:nil];
    }else{
        // 参照モード
        [_taskView setTitle:@"View Task"];
        [_taskNameField setObjectValue:source.task_name];
        [_intervalField setObjectValue:source.interval];
        [_notetitleField setObjectValue:source.note_title];
        [_notebookField setObjectValue:[self transformGuidToName:source.notebook_guid]];
        [_tagField setObjectValue:source.tags];
    }

}


/*
 * TaskTableViewを初期化を実行する
 */
-(IBAction)view:(id)sender{
    [self initializeTableView];
}

/*
 * TaskTableViewを初期化
 */
-(void)initializeTableView{
    NSMutableArray *objects = [NSMutableArray arrayWithArray:[self getTaskList]];
    [_taskArrayController setContent:objects];
    
}

/*
 * 選択されたタスクの詳細情報を表示する
 */
-(IBAction)viewDetails:(id)sender{
    // 選択されたindexを取得する
    NSInteger row = [_taskTable selectedRow];
    
    if((int)row != -1){
        NSLog(@"View the details of Task:%ld", row);
        // 選択されたタスクのデータを表示する
        [_taskArrayController setSelectionIndex:row];
        NSArray *array = [_taskArrayController selectedObjects];
        [self viewTaskView:[array objectAtIndex:0]];
        [_taskView makeKeyAndOrderFront:sender];
    }
}


/*
 * 選択されたタスクを削除する
 */
-(IBAction)deleteTask:(id)sender{
    // 選択されたindexを取得する
    NSInteger row = [_taskTable selectedRow];
    
    if((int)row != -1){
        NSLog(@"delete:%ld", row);
        // 選択されたindexのデータを削除する
        [_taskArrayController setSelectionIndex:row];
        // 選択された行を削除
        [_taskArrayController removeObjectAtArrangedObjectIndex:row];
        [self save];
    }
    
}


/*
 * 選択されたタスクのステータスのON/OFFを切り替える
 */
-(IBAction)updateTaskStatus:(id)sender{
    // 選択されたindexを取得する
    NSInteger row = [_taskTable selectedRow];
    
    if((int)row != -1){
        // ステータスを更新する
        [_taskArrayController setSelectionIndex:row];
        TaskSource *source = [[_taskArrayController arrangedObjects] objectAtIndex:row];
        [source changeStatus];
        [self save];
    }
    
}

/*
 * Evernote OAuth認証
 */
-(IBAction)doAuthorize:(id)sender{
    [self createEvernoteSession];
    EvernoteSession *session = [EvernoteSession sharedSession];
    [session authenticateWithWindow:self.window completionHandler:^(NSError *error) {
        if (error || !session.isAuthenticated) {
            NSRunCriticalAlertPanel(@"Error", @"Could not authenticate", @"OK", nil, nil);
        }
        else {
            NSLog(@"authenticationToken:%@", session.authenticationToken);
            EvernoteUserStore *userStore = [EvernoteUserStore userStore];
            [userStore getUserWithSuccess:^(EDAMUser *user){
                [_signInOrOutBtn setTitle:@"Sign Out"];
                [_userNameLabel setObjectValue:user.username];
            } failure:^(NSError *error) {
                NSLog(@"Error : %@",error);
            }];

        }
    }];

}

// EvernoteAPIのSessionを作成
-(void)createEvernoteSession{
    // EvernoteAPIの設定情報
//    NSString *EVERNOTE_HOST = BootstrapServerBaseURLStringUS;
    NSString *EVERNOTE_HOST = BootstrapServerBaseURLStringSandbox;
    NSString *CONSUMER_KEY = @"katzlifehack";
    NSString *CONSUMER_SECRET = @"9490d8896d0bb1a3";
    
    [EvernoteSession setSharedSessionHost:EVERNOTE_HOST
                              consumerKey:CONSUMER_KEY
                           consumerSecret:CONSUMER_SECRET];
    
}

/*
 * Evernote OAuth認証ログアウト
 */
-(IBAction)doLogoutOAuth:(id)sender{
    [[EvernoteSession sharedSession] logout];
    [_signInOrOutBtn setTitle:@"Sign In"];
    [_userNameLabel setObjectValue:@""];
}

/*
 * EvernoteにSignIn済みかのチェック
 */
-(BOOL)isSignedEvernote{
    EvernoteSession *session = [EvernoteSession sharedSession];
    return session.isAuthenticated;
}


/*
 * Evernote SignIn or SignOut
 */
-(IBAction)doSignInOrOut:(id)sender{
    EvernoteSession *session = [EvernoteSession sharedSession];
    if(session.isAuthenticated){
        // SignOut処理
        [self doLogoutOAuth:nil];
        
    }else{
        // SignIn処理
        [self doAuthorize:nil];
    }

    
}


/*
 * Notebookのリストを取得
 */
-(void)getNotebookList{
    _notebookList = [[NSMutableArray alloc]init];
    EvernoteNoteStore *noteStore = [EvernoteNoteStore noteStore];
    [noteStore listNotebooksWithSuccess:^(NSArray *notebooks) {
        for(EDAMNotebook *notebook in notebooks){
            NSString *guid = [NSString stringWithString:notebook.guid];
            NSString *name = [NSString stringWithString:notebook.name];
            NSDictionary *dic = [NSDictionary dictionaryWithObjectsAndKeys:
                                 guid, @"guid",
                                 name, @"name",nil];
            [_notebookList addObject:dic];
        }
    } failure:^(NSError *error) {
        NSLog(@"Couldn't get the notebook list.[%@[", error);
    }];
}

/*
 * 指定されたGUIDのNotebookが存在するかをチェックする
 */
-(BOOL)isExistNotebook:(NSString*)guid{
    for(NSDictionary *notebook in _notebookList){
        if([guid isEqualToString:[notebook objectForKey:@"guid"]]){
            return YES;
        }
    }
    return NO;
}

/*
 * GUIDからNotebookNameに変換する
 */
-(NSString*)transformGuidToName:(NSString*)guid{
    NSString *notebookName = @"";
    for(NSDictionary *notebook in _notebookList){
        if([guid isEqualToString:[notebook objectForKey:@"guid"]]){
            notebookName = [notebook objectForKey:@"name"];
        }
    }
    return notebookName;
}


/*
 * EvernoteにNOTEを新規保存する処理を実行する
 */
-(void)doAddNote:(EDAMNote*)note{
    [self createEvernoteSession];
    EvernoteSession *session = [EvernoteSession sharedSession];
    [session authenticateWithWindow:self.window completionHandler:^(NSError *error) {
        if (error || !session.isAuthenticated) {
            NSRunCriticalAlertPanel(@"Error", @"Could not authenticate", @"OK", nil, nil);
        }
        else {
            NSLog(@"authenticationToken:%@", session.authenticationToken);
            // 作成されたEDAMNoteを登録する
            [self addNote:note];
        }
    }];
    
}

/*
 * EvernoteにNOTEを新規保存する
 */
- (void)addNote:(EDAMNote*)note{
    NSString *content = note.content;
    [[EvernoteNoteStore noteStore] createNote:note success:^(EDAMNote *note) {
        // Log the created note object
        NSLog(@"Note created.\n[EDAMNote:]%@\n[Note Content:]%@",note, content);
    } failure:^(NSError *error) {
        // Something was wrong with the note data
        // See EDAMErrorCode enumeration for error code explanation
        // http://dev.evernote.com/documentation/reference/Errors.html#Enum_EDAMErrorCode
        NSLog(@"Error : %@",error);
    }];
    
}


// Returns the directory the application uses to store the Core Data store file. This code uses a directory named "AutoMemorizeDesktop" in the user's Application Support directory.
- (NSURL *)applicationFilesDirectory
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *appSupportURL = [[fileManager URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask] lastObject];
    return [appSupportURL URLByAppendingPathComponent:APP_NAME];
}

// Creates if necessary and returns the managed object model for the application.
- (NSManagedObjectModel *)managedObjectModel
{
    if (_managedObjectModel) {
        return _managedObjectModel;
    }
	
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"Model" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

// Returns the persistent store coordinator for the application. This implementation creates and return a coordinator, having added the store for the application to it. (The directory for the store is created, if necessary.)
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (_persistentStoreCoordinator) {
        return _persistentStoreCoordinator;
    }
    
    NSManagedObjectModel *mom = [self managedObjectModel];
    if (!mom) {
        NSLog(@"%@:%@ No model to generate a store from", [self class], NSStringFromSelector(_cmd));
        return nil;
    }
    
    NSURL *applicationFilesDirectory = [self applicationFilesDirectory];
    NSError *error = nil;
    NSURL *url = [applicationFilesDirectory URLByAppendingPathComponent:@"main.db"];
    NSPersistentStoreCoordinator *coordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:mom];
    if (![coordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:url options:nil error:&error]) {
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    _persistentStoreCoordinator = coordinator;
    return _persistentStoreCoordinator;
}

// Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.)
- (NSManagedObjectContext *)managedObjectContext
{
    if (_managedObjectContext) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (!coordinator) {
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        [dict setValue:@"Failed to initialize the store" forKey:NSLocalizedDescriptionKey];
        [dict setValue:@"There was an error building up the data file." forKey:NSLocalizedFailureReasonErrorKey];
        NSError *error = [NSError errorWithDomain:@"YOUR_ERROR_DOMAIN" code:9999 userInfo:dict];
        [[NSApplication sharedApplication] presentError:error];
        return nil;
    }
    _managedObjectContext = [[NSManagedObjectContext alloc] init];
    [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    
    return _managedObjectContext;
}

// Returns the NSUndoManager for the application. In this case, the manager returned is that of the managed object context for the application.
- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow *)window
{
    return [[self managedObjectContext] undoManager];
}

// Performs the save action for the application, which is to send the save: message to the application's managed object context. Any encountered errors are presented to the user.
- (IBAction)saveAction:(id)sender
{
    NSError *error = nil;
    if (![[self managedObjectContext] commitEditing]) {
        NSLog(@"%@:%@ unable to commit editing before saving", [self class], NSStringFromSelector(_cmd));
    }
    if (![[self managedObjectContext] save:&error]) {
        [[NSApplication sharedApplication] presentError:error];
    }
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender
{
    // Save changes in the application's managed object context before the application terminates.
    if (!_managedObjectContext) {
        return NSTerminateNow;
    }
    if (![[self managedObjectContext] commitEditing]) {
        NSLog(@"%@:%@ unable to commit editing to terminate", [self class], NSStringFromSelector(_cmd));
        return NSTerminateCancel;
    }
    if (![[self managedObjectContext] hasChanges]) {
        return NSTerminateNow;
    }
    
    NSError *error = nil;
    if (![[self managedObjectContext] save:&error]) {
        // Customize this code block to include application-specific recovery steps.
        BOOL result = [sender presentError:error];
        if (result) {
            return NSTerminateCancel;
        }
        NSString *question = NSLocalizedString(@"Could not save changes while quitting. Quit anyway?", @"Quit without saves error question message");
        NSString *info = NSLocalizedString(@"Quitting now will lose any changes you have made since the last successful save", @"Quit without saves error question info");
        NSString *quitButton = NSLocalizedString(@"Quit anyway", @"Quit anyway button title");
        NSString *cancelButton = NSLocalizedString(@"Cancel", @"Cancel button title");
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:question];
        [alert setInformativeText:info];
        [alert addButtonWithTitle:quitButton];
        [alert addButtonWithTitle:cancelButton];
        
        NSInteger answer = [alert runModal];
        
        if (answer == NSAlertAlternateReturn) {
            return NSTerminateCancel;
        }
    }
    return NSTerminateNow;
}

// NSManagedObjectの生成
-(NSManagedObject*)createObject:(NSString*)entity_name{
    return [NSEntityDescription insertNewObjectForEntityForName:entity_name inManagedObjectContext:self.managedObjectContext];
}

// NSFetchRequestの生成
-(NSFetchRequest*)createRequest:(NSString*)entity_name{
    return [[NSFetchRequest alloc] initWithEntityName:entity_name];
}

// Save
-(void)save{
    NSError *error = nil;
    if (![[self managedObjectContext] commitEditing]) {
        NSLog(@"%@:%@ unable to commit editing before saving", [self class], NSStringFromSelector(_cmd));
    }
    if (![[self managedObjectContext] save:&error]) {
        [[NSApplication sharedApplication] presentError:error];
    }
}

/*
 * Task Listを取得する
 */
-(NSArray*)getTaskList{
    NSFetchRequest *fetchRequest = [self createRequest:TASK_SOURCE];
    NSError *error = nil;
    return [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
}

/*
 * メインスレッドのポーリング処理を実行もしくは停止
 */
-(IBAction)startOrStop:(id)sender{
    // 実行もしくは停止
    if(_statusFlag){
        // Status:true -> 停止命令
        [self stop:nil];
        _statusFlag = false;
    }else{
        // Status:false -> 起動命令
        [self start:nil];
        _statusFlag = true;
    }
}

/*
 * メインスレッドのポーリング処理を再実行
 */
-(IBAction)start:(id)sender{
    [self run];
}

/*
 * メインスレッドのポーリング処理を停止
 */
-(IBAction)stop:(id)sender{
    for(NSTimer *timer in _taskQueue){
        NSLog(@"[TaskName:%@]Timer has been stopped.", timer.userInfo);
        [timer invalidate];
    }
}

/*
 * メインスレッドのポーリング処理をリスタート
 */
-(IBAction)restart:(id)sender{
    [self stop:nil];
    [self start:nil];
}

/*
 * テストメソッド
 */
-(IBAction)testMethod:(id)sender{

//    exit(0);
}

///*
// * PreferencesViewを初期化
// */
//-(void)initializedPreferencesView{
//    EvernoteSession *session = [EvernoteSession sharedSession];
//    if(session.isAuthenticated){
//        [_signInOrOutBtn setTitle:@"Sign Out"];
//    }else{
//        [_signInOrOutBtn setTitle:@"Sign In"];
//        [_userNameLabel setObjectValue:@"-"];
//    }
//}


@end
