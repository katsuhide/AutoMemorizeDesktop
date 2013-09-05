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
#import "SafariTaskService.h"
#import "EvernoteServiceUtil.h"
#import "Reachability.h"

@implementation AppDelegate

@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize managedObjectContext = _managedObjectContext;

const BOOL ENV = NO;
const BOOL PROTOTYPE = NO;

typedef enum dataTypeEnum : NSInteger{
    SKYPE,
    PDF,
    TEXT,
    EXCEL,
    WORD,
    POWERPOINT,
    NUMBERS,
    PAGES,
    KEY,
    SAFARI,
    PICTURE
} dataTypeEnum;


// Insert code here to initialize your application
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // HOCKEY.APP
    [[BITHockeyManager sharedHockeyManager] configureWithIdentifier:@"d95691d40bc53aff6926939837aff798"
                                                        companyName:@""
                                         crashReportManagerDelegate:self];
    [[BITHockeyManager sharedHockeyManager] startManager];
    
    // Reachabilityの起動
    _isReachable = NO;  // 一旦OFF LINEに
    [self createReachability];
    
    //    [self testMethod:nil];
    
    // 初回起動用にDataStore用のDirectoryの有無を確認して無ければ作成する
    NSURL *applicationFilesDirectory = [self applicationFilesDirectory];
    NSError *error = nil;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isFirst = ![fileManager fileExistsAtPath:[applicationFilesDirectory path]];
    
    if(![fileManager createDirectoryAtPath:[applicationFilesDirectory path] withIntermediateDirectories:YES attributes:nil error:&error]){
        NSLog(@"Couldn't create the data store directory.[%@, %@]", error, [error userInfo]);
        abort();
    }
    
    // ログ出力
    BOOL logFlag = [[self getPropertyInfo:@"LOG_FLAG"] boolValue];
    if(logFlag){
        NSString *logPath = [[applicationFilesDirectory path] stringByAppendingPathComponent:@"recdesktop.log"];
        freopen([logPath fileSystemRepresentation], "w+", stderr);
    }
    
    // ArrayControllerとmanagedObjectContextの紐付け
    [_taskArrayController setManagedObjectContext:self.managedObjectContext];
    
    // Notebokのメモリを確保
    _notebookList = [[NSMutableArray alloc]init];
    
    // 初回ログインではない場合ログインする
    if(!isFirst){
        [self doAuthorize:nil];
    }
    
    // Main画面を初期化
    [self initialize];
    
    // Preferences Viewの初期化
    [self initializePreView];
    
    // メインスレッドのポーリングを開始
    [self run];
        
}

// HOCEKY.APP
- (void)showMainApplicationWindow {
    // launch the main app window
    // remember not to automatically show the main window if using NIBs
    [_window makeFirstResponder: nil];
    [_window makeKeyAndOrderFront:nil];
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
            case 2:
                // Safari Task
                NSLog(@"[TaskName:%@]File Task Created.", source.task_name);
                task = [[TaskForSafari alloc]initWithTaskSource:source];
                break;
            default:
                // Other Task
                NSLog(@"[TaskName:%@]Other Task Created.", source.task_name);
                task = [[Task alloc]initWithTaskSource:source];
                break;
        }
        
        // インターバル条件を指定
        int interval = [(NSNumber*)[self getPropertyInfo:@"INTERVAL"] intValue];
        
        // タスクタイマーを生成し、タスクキューに追加
        NSTimer *timer = [NSTimer
                          scheduledTimerWithTimeInterval:interval
                          target:task
                          selector:@selector(polling:)
                          userInfo:source.task_name
                          repeats:YES];
        [_taskQueue addObject:timer];
    }
    
}

/*
 * TaskSourceの新規作成
 */
-(TaskSource*)createTaskSource{
    TaskSource *source = (TaskSource*)[self createObject:TASK_SOURCE];
    return source;
}

/*
 * タスクの登録
 */
-(void)registerTask:(NSDictionary*)inputData{
    // 画面の入力値からTaskを生成する
    TaskSource *source = (TaskSource*)[self createObject:TASK_SOURCE];
    
    // Basic Information
    NSNumber *dataSourceType = [inputData objectForKey:@"dataSourceType"];
    if([dataSourceType intValue] == SKYPE){
        source.task_type = dataSourceType;
    }else if([dataSourceType intValue] == SAFARI){
        source.task_type = [NSNumber numberWithInt:2];
    }else{
        source.task_type = [NSNumber numberWithInt:1];
    }
    source.status = [NSNumber numberWithInt:1];
    
    // Data Source 毎に固有の処理
    switch ([dataSourceType intValue]) {
        case SKYPE:
        {   // Skype
            // Upload Rule Description
            NSString *skypeUser = [inputData objectForKey:@"skypeUser"];
            source.task_name = [NSString stringWithFormat:@"Upload %@'s Skype Log every 5 minutes.", skypeUser];
            // Skype Uplodad Interval
            source.interval = [[self getPropertyInfo:@"SKYPE_INTERVAL"] stringValue];
            // Skype DB Path
            NSString *skypePath = [NSString stringWithFormat:@"~/Library/Application Support/Skype/%@/main.db", skypeUser];
            NSMutableString *params = [NSMutableString string];
            [params appendString:[source transformKeyValue:@"file_path" andValue:skypePath]];
            // Dividing Topic
            [params appendString:[source transformKeyValue:@"isClassify" andValue:[inputData objectForKey:@"isClassify"]]];
            source.params = params;
            
        }
            break;
        case PDF:
        case TEXT:
        case EXCEL:
        case WORD:
        case POWERPOINT:
        case NUMBERS:
        case PAGES:
        case KEY:
        case PICTURE:
        {   // File
            NSMutableString *params = [NSMutableString string];
            // Directory Path
            NSString *directoryPath = [inputData objectForKey:@"directoryPath"];
            [params appendString:[source transformKeyValue:@"file_path" andValue:directoryPath]];
            // File Extension
            NSString *extension = [self getFileExtension:inputData];
            [params appendString:[source transformKeyValue:@"extension" andValue:extension]];
            source.params = params;
            // Backup Path
            NSString *backupPath = [self getBackupPath:inputData];
            [params appendString:[source transformKeyValue:@"backupPath" andValue:backupPath]];
            source.params = params;
            // Search Sub Directory
            NSNumber *includeSubDirectory = [inputData objectForKey:@"includeSubDirectory"];
            [params appendString:[source transformKeyValue:@"search" andValue:[includeSubDirectory stringValue]]];
            // Move Files
            NSString *movesFile = [inputData objectForKey:@"movesFile"];
            [params appendString:[source transformKeyValue:@"movesFile" andValue:movesFile]];
            source.params = params;
            // Upload Rule Description
            source.task_name = [NSString stringWithFormat:@"Upload %@@%@ Data in real-time.", extension, directoryPath];
            // File Uplodad Interval
            source.interval = [[self getPropertyInfo:@"FILE_INTERVAL"] stringValue];
            
        }
            break;
        case SAFARI:
        {   // SAFARI
            // Upload Rule Description
            source.task_name = [NSString stringWithFormat:@"Upload Safari's Web History every 5 minutes."];
            // Safari Uplodad Interval
            source.interval = [[self getPropertyInfo:@"SAFARI_INTERVAL"] stringValue];
            
        }
            break;
            
        default:
            source.task_name = @"Upload Download Directory Data in real-time.";
            source.interval = @"1";  // 1hour
            break;
    }
    
    // Addtional Condition for Evernote
    source.note_title = [inputData objectForKey:@"notetitle"];
    NSString *notebookName = [inputData objectForKey:@"notebook"];
    NSString *guid = @"";
    for(NSDictionary *notebook in _notebookList){
        if([notebookName isEqualToString:[notebook objectForKey:@"name"]]){
            guid = [notebook objectForKey:@"guid"];
        }
    }
    source.notebook_guid = guid;
    source.tags = [inputData objectForKey:@"tag"];
    
    // System Information
    NSDate *now = [NSDate date];
    source.last_execute_time = now;
    source.last_added_time = now;
    source.update_time = now;
    
    // Taskを保存
    [self save];
    
    // Taskを初期化
    [self restart:nil];
    
}

// File Extensionを取得する
-(NSString*)getFileExtension:(NSDictionary*)inputData{
    NSDictionary *extensionType = [NSDictionary dictionaryWithObjectsAndKeys:
                                   @"pdf", @"1",
                                   @"txt", @"2",
                                   @"xls,xlsx", @"3",
                                   @"doc,docx", @"4",
                                   @"ppt,pptx", @"5",
                                   @"numbers", @"6",
                                   @"pages", @"7",
                                   @"key", @"8",
                                   @"png,jpg,bmp,pct,gif,tif,tiff,psd", @"10",
                                   nil];
    
    NSNumber *extensionFlag = [inputData objectForKey:@"dataSourceType"];
    NSString *extension = [extensionType objectForKey:[extensionFlag stringValue]];
    return extension;
}

// Backup Pathを取得する
-(NSString*)getBackupPath:(NSDictionary*)inputData{
    NSString *directory = [inputData objectForKey:@"backupPath"];
    NSString *filePath = [directory stringByExpandingTildeInPath];
    return filePath;
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
    
    // 必須チェック
    NSString *errorMsg = [self validateNewTask:source];
    if(errorMsg.length != 0){
        NSAlert *alert = [ NSAlert alertWithMessageText: @"Mandatory Field is left blank."
                                          defaultButton: @"OK"
                                        alternateButton: nil
                                            otherButton: nil
                              informativeTextWithFormat: @"%@", errorMsg];
        [alert runModal];
        // 保存しないようにオブジェクトを削除
        [_managedObjectContext deleteObject:source];
        return; // 後続の処理は実施しない
    }
    
    // Taskを保存
    [self save];
    // TaskTableViewを初期化
    [self initializeTableView];
    // TaskViewを閉じる
    [self closeTaskView];
    // Taskを初期化
    [self restart:nil];
    
    
}

-(NSString*)validateNewTask:(TaskSource*)source{
    NSMutableString *errorMsg = [NSMutableString string];
    
    // Task Name
    if(source.task_name.length == 0){
        [errorMsg appendString:@"Task Name\n"];
    }
    
    // Interval
    if(source.interval.length == 0){
        [errorMsg appendString:@"Interval\n"];
    }
    
    // Note Title
    if(source.note_title.length == 0){
        [errorMsg appendString:@"Note Title\n"];
    }
    
    int taskType = [source.task_type intValue];
    if(taskType == 0){
        // Skype Task
        // DB Fild Path
        if([source getKeyValue:@"file_path"].length == 0){
            [errorMsg appendString:@"Skype DB File Path\n"];
        }
        
    }else if(taskType == 1){
        // File Task
        // Target Directory
        if([source getKeyValue:@"file_path"].length == 0){
            [errorMsg appendString:@"Target Directory Path\n"];
        }
        
    }else{
        // Otherはないはずだが念のためメッセージを返す
        [errorMsg appendString:@"Task Type\n"];
    }
    
    return errorMsg;
    
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
    NSString *hex = @"#FFFFFF";
    NSColor *backColor = [NSColor colorFromHexadecimalValue:hex];
    [_window setBackgroundColor:backColor];
    
    int num = 0;
    for (NSTableColumn* column in [_taskTable tableColumns]) {
        NSTableHeaderCell *cell = [column headerCell];
        CustomHeaderCell *newCell = [[CustomHeaderCell alloc] init];
        [newCell changeBackColor:num];
        [newCell setAttributedStringValue:[cell attributedStringValue]];
        [column setHeaderCell:newCell];
        num++;
    }
    
    // 各種ボタン
    NSString *imagePath;
    // Status Button
    _statusFlag = false;    // 起動時はfalseで
    imagePath = [[NSBundle mainBundle] pathForResource:@"Status" ofType:@"psd"];
    NSImage *statusBtnImage = [[NSImage alloc]initByReferencingFile:imagePath];
    [_statusBtn setImage:statusBtnImage];
    [_statusBtn setBordered:NO];
    
    // Register Button
    imagePath = [[NSBundle mainBundle] pathForResource:@"Plus" ofType:@"psd"];
    NSImage *registerBtnImage = [[NSImage alloc]initByReferencingFile:imagePath];
    [_registerBtn setImage:registerBtnImage];
    [_registerBtn setBordered:NO];
    
    // Delete Button
    imagePath = [[NSBundle mainBundle] pathForResource:@"Minus" ofType:@"psd"];
    NSImage *deleteBtnImage = [[NSImage alloc]initByReferencingFile:imagePath];
    [_deleteBtn setImage:deleteBtnImage];
    [_deleteBtn setBordered:NO];
    
    // Table Viewの初期化
    [self initializeTableView];
    
}

/*
 * Register Task Buttonの色をタスクタイプで変える
 */
-(void)changeRegisterOkBtn:(int)flag{
    
    NSString *imagePath;;
    switch (flag) {
        case 0:
            [_registerOKBtn setHidden:NO];
            imagePath = [[NSBundle mainBundle] pathForResource:@"RegisterOkBtnLightBlue" ofType:@"psd"];
            break;
        case 1:
            [_registerOKBtn setHidden:NO];
            imagePath = [[NSBundle mainBundle] pathForResource:@"RegisterOkBtnLightGreen" ofType:@"psd"];
            break;
        default:
            [_registerOKBtn setHidden:YES]; //対応していないためボタンを非表示
            return;
    }
    
    NSImage *registerOkBtnImage = [[NSImage alloc]initByReferencingFile:imagePath];
    [_registerOKBtn setImage:registerOkBtnImage];
    [_registerOKBtn setBordered:NO];
    
}

/*
 * TaskViewを初期化
 */
-(void)initializedTaskView{
    // 背景
    NSString *hex = @"#FFFFFF";
    NSColor *backColor = [NSColor colorFromHexadecimalValue:hex];
    [_taskView setBackgroundColor:backColor];
    
    // 共通部分のアイテムを初期化
    [self changeTaskView:YES andData:nil];
    // 拡張部分のアイテムを初期化
    [_taskViewController initializedTaskView];
    
}

/*
 * 選択されたTaskの情報を表示してTaskViewを開く(すべてDisableにする）
 */
-(void)viewTaskView:(TaskSource*)source{
    // 背景
    NSString *hex = @"#FFFFFF";
    NSColor *backColor = [NSColor colorFromHexadecimalValue:hex];
    [_taskView setBackgroundColor:backColor];
    
    // 共通部分のアイテムを初期化
    [self changeTaskView:NO andData:source];
    // 拡張部分のアイテムを初期化
    [_taskViewController viewTaskView:source];
    // Registerボタンを非表示に
    [_registerOKBtn setHidden:YES];
    
}

/*
 * Preferences Viewの初期化
 */
-(void)initializePreView{
    // 背景
    NSString *hex = @"#FFFFFF";
    NSColor *backColor = [NSColor colorFromHexadecimalValue:hex];
    [_preWindow setBackgroundColor:backColor];
    // ボタン
    NSString *imagePath;
    if([self isSignedEvernote]){
        // 認証時の処理に任せるため何もしない
    }else{
        // Sign In表示
        imagePath = [[NSBundle mainBundle] pathForResource:@"SignIn" ofType:@"psd"];
        NSImage *signInOrOutBtnImage = [[NSImage alloc]initByReferencingFile:imagePath];
        [_signInOrOutBtn setImage:signInOrOutBtnImage];
        [_signInOrOutBtn setBordered:NO];
        // ログインユーザを非表示
        [_userNameLabel setObjectValue:@"(Not Signed)"];
        
    }
    
    // All Start
    imagePath = [[NSBundle mainBundle] pathForResource:@"AllStart" ofType:@"psd"];
    NSImage *allStartBtnImage = [[NSImage alloc]initByReferencingFile:imagePath];
    [_allStartBtn setImage:allStartBtnImage];
    [_allStartBtn setBordered:NO];
    
    // All Stop
    imagePath = [[NSBundle mainBundle] pathForResource:@"AllStop" ofType:@"psd"];
    NSImage *allStopBtnImage = [[NSImage alloc]initByReferencingFile:imagePath];
    [_allStopBtn setImage:allStopBtnImage];
    [_allStopBtn setBordered:NO];
    
    // All Restart
    imagePath = [[NSBundle mainBundle] pathForResource:@"AllRestart" ofType:@"psd"];
    NSImage *allRestartBtnImage = [[NSImage alloc]initByReferencingFile:imagePath];
    [_allRestartBtn setImage:allRestartBtnImage];
    [_allRestartBtn setBordered:NO];
    
}

-(void)changeTaskView:(BOOL)isEditable andData:(TaskSource*)source{
    // 指定されたモードに設定
    [_taskNameField setEditable:isEditable];
    [_intervalField setEditable:isEditable];
    [_notetitleField setEditable:isEditable];
    [_notebookField setEnabled:isEditable];
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
        // 本当に削除するか確認
        NSInteger deleteFlag = 0;
        NSString *errorMsg = @"Are you sure you want to delete this Upload Rule?";
        if(errorMsg.length != 0){
            NSAlert *alert = [ NSAlert alertWithMessageText: @"RecDesktop"
                                              defaultButton: @"OK"  // 1
                                            alternateButton: @"Cancel"  // 0
                                                otherButton: nil    // -1
                                  informativeTextWithFormat: @"%@", errorMsg];
            deleteFlag = [alert runModal];
        }
        // OKの場合のみ削除
        if(deleteFlag == 1){
            NSLog(@"delete:%ld", row);
            // 選択されたindexのデータを削除する
            [_taskArrayController setSelectionIndex:row];
            // 選択された行を削除
            [_taskArrayController removeObjectAtArrangedObjectIndex:row];
            [self save];
        }
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
        // テーブルを再描画
        [_taskTable reloadData];
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
            //            NSLog(@"authenticationToken:%@", session.authenticationToken);
            NSLog(@"Login");
            
            // NoteBookの取得
            [self setupNotebookList];
            
            // Login User周りの情報を更新
            EvernoteUserStore *userStore = [EvernoteUserStore userStore];
            [userStore getUserWithSuccess:^(EDAMUser *user){
                // Sign Outボタンを表示
                NSString *imagePath;
                imagePath = [[NSBundle mainBundle] pathForResource:@"SignOut" ofType:@"psd"];
                NSImage *signInOrOutBtnImage = [[NSImage alloc]initByReferencingFile:imagePath];
                [_signInOrOutBtn setImage:signInOrOutBtnImage];
                [_signInOrOutBtn setBordered:NO];
                // ログインユーザを表示
                [_userNameLabel setObjectValue:user.username];
                
            } failure:^(NSError *error) {
                NSLog(@"Error : %@",error);
                // Sign Inボタンを表示
                NSString *imagePath;
                imagePath = [[NSBundle mainBundle] pathForResource:@"SignIn" ofType:@"psd"];
                NSImage *signInOrOutBtnImage = [[NSImage alloc]initByReferencingFile:imagePath];
                [_signInOrOutBtn setImage:signInOrOutBtnImage];
                [_signInOrOutBtn setBordered:NO];
                // ログインユーザを非表示
                [_userNameLabel setObjectValue:@"(Not Signed)"];
            }];
            
        }
    }];
    
}

// EvernoteAPIのSessionを作成
-(void)createEvernoteSession{
    // EvernoteAPIの設定情報
    
    NSString *EVERNOTE_HOST;
    NSString *filePath;
    if(ENV){
        EVERNOTE_HOST = BootstrapServerBaseURLStringUS;
        filePath = [[NSBundle mainBundle] pathForResource:@"recdesktop" ofType:@"plist"];
    }else{
        EVERNOTE_HOST = BootstrapServerBaseURLStringSandbox;
        filePath = [[NSBundle mainBundle] pathForResource:@"recdesktop_sandbox" ofType:@"plist"];
    }
    
    // ファイルマネージャを作成
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    // ファイルが存在しないか?
    if (![fileManager fileExistsAtPath:filePath]) { // yes
        NSLog(@"plistが存在しません．");
        exit(0);
    }
    
    // plistを読み込む
    NSDictionary *output = [NSDictionary dictionaryWithContentsOfFile:filePath];
    
    NSString *CONSUMER_KEY = [output objectForKey:@"CONSUMER_KEY"];
    NSString *CONSUMER_SECRET = [output objectForKey:@"CONSUMER_SECRET"];
    
    [EvernoteSession setSharedSessionHost:EVERNOTE_HOST
                              consumerKey:CONSUMER_KEY
                           consumerSecret:CONSUMER_SECRET];
    
}

/*
 * Evernote OAuth認証ログアウト
 */
-(IBAction)doLogoutOAuth:(id)sender{
    [[EvernoteSession sharedSession] logout];
    // Sign Inボタンを表示
    NSString *imagePath;
    imagePath = [[NSBundle mainBundle] pathForResource:@"SignIn" ofType:@"psd"];
    NSImage *signInOrOutBtnImage = [[NSImage alloc]initByReferencingFile:imagePath];
    [_signInOrOutBtn setImage:signInOrOutBtnImage];
    [_signInOrOutBtn setBordered:NO];
    // ログインユーザを非表示
    [_userNameLabel setObjectValue:@"(Not Signed)"];
    // NotebookListを空にする
    [_notebookList removeAllObjects];
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
-(void)setupNotebookList{
    EvernoteNoteStore *noteStore = [EvernoteNoteStore noteStore];
    [noteStore listNotebooksWithSuccess:^(NSArray *notebooks) {
        // Notebook Nameでソート
        NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES];
        NSArray *sortedNotebooks = [notebooks sortedArrayUsingDescriptors:@[sortDescriptor]];
        // Notebookをセット
        [_notebookList removeAllObjects];
        for(EDAMNotebook *notebook in sortedNotebooks){
            NSString *guid = [NSString stringWithString:notebook.guid];
            NSString *name = [NSString stringWithString:notebook.name];
            NSDictionary *dic = [NSDictionary dictionaryWithObjectsAndKeys:
                                 guid, @"guid",
                                 name, @"name",nil];
            [_notebookList addObject:dic];
        }
    } failure:^(NSError *error) {
        NSLog(@"error code :%ld", error.code);
        NSLog(@"userInfo : %@", error.userInfo);
        NSLog(@"userInfo error code: %@", [error.userInfo objectForKey:@"codes"]);
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
 * NotebookListを取得
 */
-(NSMutableArray*)getNotebookList{
    return _notebookList;
}

/*
 * NotebookNameからGUIDを取得
 */
-(NSString*)getNotebookGuid:(NSString*)notebookName{
    NSString *guid = @"";
    for(NSDictionary *notebook in _notebookList){
        if([notebookName isEqualToString:[notebook objectForKey:@"name"]]){
            guid = [notebook objectForKey:@"guid"];
        }
    }
    return guid;
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

/*
 * EvernoteSessionを取得する（ログインされている前提）
 */
-(EvernoteSession*)getEvernoteSession{
    EvernoteSession *session = [EvernoteSession sharedSession];
    return session;
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
    NSString *dbName = [self getPropertyInfo:@"DB_NAME"];
    NSURL *url = [applicationFilesDirectory URLByAppendingPathComponent:dbName];
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
 * ヘルプメニュー
 */
-(IBAction)help:(id)sender{
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://docs.google.com/drawings/d/1vaUyT2ML_46XwCHNqRkx-ztj5ys7JNWrdQ9UGkL4LwA/edit?usp=sharing"]];
}

/*
 *
 */
-(void)createReachability{
    // Allocate a reachability object
    Reachability* reach = [Reachability reachabilityWithHostname:@"www.google.com"];
    
    // Set the blocks
    reach.reachableBlock = ^(Reachability*reach)
    {
        _isReachable = YES;
    };
    
    reach.unreachableBlock = ^(Reachability*reach)
    {
        _isReachable = NO;
    };
    
    // Start the notifier, which will cause the reachability object to retain itself!
    [reach startNotifier];
    
}


/*
 * Safariタスクが既に登録されているかを確認する
 */
-(BOOL)isExistSafariTask{
    // TaskTypeがSafariのタスクを取得する
    NSFetchRequest *fetchRequest = [self createRequest:TASK_SOURCE];
    NSError *error = nil;
    // 取得条件の設定
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"task_type = %ld", 2];  // 1:key, 2:value
    [fetchRequest setPredicate:pred];
    NSArray *result = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
    if([result count] == 0){
        return NO;
    }else{
        return YES;
    }
}

/*
 * Property Fileからデータを取得する
 */
-(id)getPropertyInfo:(NSString*)key{
    // configuration property file
    NSString *filePath;
    if(ENV){
        filePath = [[NSBundle mainBundle] pathForResource:@"recdesktop" ofType:@"plist"];
    }else{
        filePath = [[NSBundle mainBundle] pathForResource:@"recdesktop_sandbox" ofType:@"plist"];
    }
    
    // create file manager
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    // check whether file exist
    if (![fileManager fileExistsAtPath:filePath]) { // yes
        NSLog(@"Property file doesn't exist.[%@]", filePath);
        exit(0);
    }
    
    // get the data from property file
    NSDictionary *output = [NSDictionary dictionaryWithContentsOfFile:filePath];
    return [output objectForKey:key];
    
}

/*
 * テストメソッド
 */
-(IBAction)testMethod:(id)sender{
    
    NSString* str = nil;
    int hoge = [str intValue];
    NSLog(@"%d", hoge);
    
    if((str == nil) || (hoge != 0)) {
        NSLog(@"hoge");
    }
    
    exit(0);
    
}


/*
 * EvernoteへNoteを登録した後の処理
 */
-(void)afterRegisterNote:(EDAMNote*)note{
    NSLog(@"Note Created.[%@]", note.title);
}

-(TaskSource*)createTestTaskSource{
    TaskSource *source = (TaskSource*)[self createObject:TASK_SOURCE];
    source.task_name = @"Safari Task";
    source.task_type = [NSNumber numberWithInt:2];
    NSDate *now = [NSDate date];
    source.last_added_time = now;
    //    source.last_added_time = [now dateByAddingTimeInterval:-3600];
    
    return source;
    
}

@end
