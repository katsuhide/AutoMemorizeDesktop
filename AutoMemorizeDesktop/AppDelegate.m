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

@implementation AppDelegate

@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize managedObjectContext = _managedObjectContext;

const BOOL ENV = NO;

// Insert code here to initialize your application
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // test method
//    [self testMethod];
    
    // ログ出力
    if(ENV){
        freopen([@"/tmp/xcode.log" fileSystemRepresentation], "w+", stderr);
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
    
    // Main画面を初期化
    [self initialize];
    
    // メインスレッドのポーリングを開始
//    [self run];
}

-(void)testMethod{
    
    // 正規表現検索
//    NSString *string = @"red. blue. <ss type> yellow. green. blue. </ss> black. white.<ss type> hoge </ss>aaaa";
    NSString *string = @"hahaha <ss type=\"cool\">(cool)</ss></span></p><p style=><span style=>Katz Lifehack : 2013-06-18 02:56:45</span><br/><span>???</span></p><p><span style=>Yota Sato : 2013-06-18 09:31:15</span><br/><span>7月に小野田さんと飲みにでも行\343\201\215ません？";
    NSError *error   = nil;
    NSRegularExpression *regexp = [NSRegularExpression regularExpressionWithPattern:@"<ss type.+?</ss>" options:0 error:&error];
    
    if (error != nil) {
        NSLog(@"%@", error);
    } else {
        NSArray *matchs = [regexp matchesInString:string options:0 range:NSMakeRange(0, string.length)];
        for(NSTextCheckingResult *match in matchs){
            int count = (int)match.numberOfRanges;
            for(int i = 0; i < count; i++){
                NSLog(@"%@", [string substringWithRange:[match rangeAtIndex:i]]);
            }
            
        }
    }
    
    // 正規表現検索置換
    NSString *template = @"";   // 置換後文字列
    NSString *replaced = [regexp stringByReplacingMatchesInString:string options:0 range:NSMakeRange(0,string.length) withTemplate:template];
    NSLog(@"%@",string);
    NSLog(@"%@",replaced);
    
    
    exit(0);
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
                NSLog(@"Skype Task created");
                task = [[TaskForSkype alloc]initWithTaskSource:source];
                break;
            case 1:
                // File Task
                NSLog(@"File Task Created.");
                task = [[TaskForFile alloc]initWithTaskSource:source];
                break;
            default:
                // Other Task
                NSLog(@"Other Task Created.");
                task = [[Task alloc]initWithTaskSource:source];
                break;
        }

        // インターバル条件を指定(TODOテスト時は5secに変更）
        int interval = INTERVAL;
        if(!ENV) {
            interval = 5;
        }
        
        // タスクタイマーを生成し、タスクキューに追加
        NSTimer *timer = [NSTimer
                          scheduledTimerWithTimeInterval:interval
                          target:task
                          selector:@selector(polling:)
                          userInfo:nil
                          repeats:YES];
        [_taskQueue addObject:timer];
    }
    
}

/*
 * メインスレッドのポーリング処理を実行もしくは停止
 */
-(IBAction)startAndStop:(id)sender{
    // 実行もしくは停止
    if(_statusFlag){
        // Status:true -> 停止命令
        [self stop];
        _statusFlag = false;
    }else{
        // Status:false -> 起動命令
        [self start];
        _statusFlag = true;
    }
    
    // StatusButtonを切り替える
    [self changeStatusBtn];
    
}

// StatusBtnを切り替える
-(void)changeStatusBtn{
    NSString *imagePath;
    if(_statusFlag){
        imagePath = [[NSBundle mainBundle] pathForResource:@"Play" ofType:@"tif"];
    }else{
        imagePath = [[NSBundle mainBundle] pathForResource:@"Pause" ofType:@"tif"];
    }
    NSImage *statusBtnImage = [[NSImage alloc]initByReferencingFile:imagePath];
    [_statusBtn setImage:statusBtnImage];
    
}

/*
 * メインスレッドのポーリング処理を再実行
 */
-(void)start{
    [self run];
}

/*
 * メインスレッドのポーリング処理を停止
 */
-(void)stop{
    for(NSTimer *timer in _taskQueue){
        [timer invalidate];
        NSLog(@"Task has been stopped.");
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
    source.notebook_guid = [_notebookField stringValue];    // TODO GUIDに変換が必要
    source.tags = [_tagField stringValue];
    NSMutableString *params = [_taskViewController getParams];
    source.params = params;
    NSDate *now = [NSDate date];
    source.last_execute_time = now;
    source.last_added_time = now;
    source.update_time = now;

//    source.task_type = [_taskTypeField stringValue];
//    NSMutableString *params = [NSMutableString stringWithString:[source transformKeyValue:@"file_path" andValue:[_skypeDBFilePathField stringValue]]];
//    [params appendString:[source transformKeyValue:@"participants" andValue:[_participantsField stringValue]]];
    
    // Taskを保存
    [self save];
    // TaskTableViewを初期化
    [self initializeTableView];
    // TaskViewを閉じる
    [self closeTaskView];
}

/*
 * TaskViewを開く
 */
-(IBAction)openTaskView:(id)sender{
    NSLog(@"Open the TaskView");
    [self initializedTaskView];
    [_taskView makeKeyAndOrderFront:sender];
}


/*
 * TaskViewを閉じる
 */
-(void)closeTaskView{
    NSLog(@"Close the TaskView");
//    [self initializedTaskView];
    [_taskView close];
}

/*
 * Main画面を初期化
 */
-(void)initialize{
    NSString *imagePath;
    // Status Button
    _statusFlag = false;    // 起動時はfalseで
    imagePath = [[NSBundle mainBundle] pathForResource:@"Last" ofType:@"tif"];
    NSImage *statusBtnImage = [[NSImage alloc]initByReferencingFile:imagePath];
    [_statusBtn setImage:statusBtnImage];
    [_statusBtn setBordered:NO];
    
    // Info Button
    imagePath = [[NSBundle mainBundle] pathForResource:@"Info" ofType:@"tif"];
    NSImage *infoBtnImage = [[NSImage alloc]initByReferencingFile:imagePath];
    [_infoBtn setImage:infoBtnImage];
    [_infoBtn setBordered:NO];
    
    // Register Button
    imagePath = [[NSBundle mainBundle] pathForResource:@"Plus" ofType:@"tif"];
    NSImage *registerBtnImage = [[NSImage alloc]initByReferencingFile:imagePath];
    [_registerBtn setImage:registerBtnImage];
    [_registerBtn setBordered:NO];
    
    // Delete Button
    imagePath = [[NSBundle mainBundle] pathForResource:@"Block" ofType:@"tif"];
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
    // 共通部分のアイテムを初期化
    [_taskNameField setObjectValue:nil];
//    [_taskTypeField setObjectValue:nil];
    [_intervalField setObjectValue:nil];
    [_notetitleField setObjectValue:nil];
    [_notebookField setObjectValue:nil];
    [_tagField setObjectValue:nil];
    
    // 拡張部分のアイテムを初期化
    [_taskViewController initializedTaskView];
    
}

/*
 * TaskTableViewを初期化を実行する
 */
-(IBAction)view:(id)sender{
    NSLog(@"view method");
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

// TaskListを取得する
-(NSArray*)getTaskList{
    NSFetchRequest *fetchRequest = [self createRequest:TASK_SOURCE];
    NSError *error = nil;
    return [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
}


/*
 *
 * ===========ここ以降はいらないテストソース===================
 *
 */

// register method
- (IBAction)registerActionTemp:(id)sender{
    // NSManagedObjectの生成
    TaskSource *source = (TaskSource*)[self createObject:TASK_SOURCE];
    source.task_name = @"Other Task1";
    source.task_type = [NSNumber numberWithInt:3];
    source.status = [NSNumber numberWithInt:1];
    source.interval = @"10";
    source.tags = @"tag1,tag2";
    source.note_title = @"Other Task Note Title1";
    source.update_time = [NSDate date];
    [self save];
}

// update method
- (IBAction)updateAction:(id)sender{
    
    NSArray *taskList = [self getTaskList];
    for(TaskSource *source in taskList){
        NSString *str = [NSString stringWithFormat:@"%@!", source.task_name];
        source.task_name = str;
        source.last_execute_time = [NSDate date];
        source.update_time = [NSDate date];
    }
    [self save];
}


// get method
- (IBAction)getAction:(id)sender{
    NSFetchRequest *fetchRequest = [self createRequest:TASK_SOURCE];
    NSError *error = nil;
    NSArray *result = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
    if(!result){
        NSLog(@"%@:%@", error, [error userInfo]);
    }else{
        for(TaskSource *taskSource in result) {
            [taskSource print];
        }
    }
}

-(IBAction)testMethod:(id)sender{
    NSLog(@"test method");
}

@end
