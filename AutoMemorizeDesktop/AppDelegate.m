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
    [self doAuthorize:nil];

    // Notebookの一覧を取得して設定
    _notebookList = [[NSMutableArray alloc]init];
    [self setupNotebookList];
    
    // Main画面を初期化
    [self initialize];

    // Preferences Viewの初期化
    [self initializePreView];
    
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
    if([dataSourceType intValue] == 0){
        source.task_type = dataSourceType;
    }else{
        source.task_type = [NSNumber numberWithInt:1];
    }
    source.status = [NSNumber numberWithInt:1];

    // Data Source 毎に固有の処理
    switch ([dataSourceType intValue]) {
        case 0:
        {
            // Skype
            NSString *skypeUser = [inputData objectForKey:@"skypeUser"];
            source.task_name = [NSString stringWithFormat:@"Upload %@ Data by 5 minutes", skypeUser];
            //            source.interval = @"0.42";  // 約5min TODO
            source.interval = @"0.003";  // 約10sec
            NSString *skypePath = [NSString stringWithFormat:@"~/Library/Application Support/Skype/%@/main.db", skypeUser];
            
            NSMutableString *params = [NSMutableString string];
            [params appendString:[source transformKeyValue:@"file_path" andValue:skypePath]];
            source.params = params;
        
        }
            break;
        case 1:
        case 2:
        case 3:
        case 4:
        case 5:
        case 6:
        case 7:
        case 8:
        {
            // PDF
            NSMutableString *params = [NSMutableString string];
            // File Path
            NSString *filePath = [self getFilePath:inputData];
            [params appendString:[source transformKeyValue:@"file_path" andValue:filePath]];
            // File Extension
            NSString *extension = [self getFileExtension:inputData];
            [params appendString:[source transformKeyValue:@"extension" andValue:extension]];
            source.params = params;
            // Backup Path
            NSString *backupPath = [self getBackupPath:inputData];
            [params appendString:[source transformKeyValue:@"backupPath" andValue:backupPath]];
            source.params = params;
            
            // Upload Rule Description
            source.task_name = [NSString stringWithFormat:@"Upload %@@%@ Data by realtime", extension, filePath];
        }
            break;
            
        default:
            source.task_name = @"Upload Download Directory Data by relatime";
            source.interval = @"0.003";  // 約10sec
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
    source.tags = [inputData objectForKey:@"tag"];  // TODO 形式を要チェック
    
    // System Information
    NSDate *now = [NSDate date];
    source.last_execute_time = now;
    source.last_added_time = now;
    source.update_time = now;

    // Taskを保存
    [self save];
    
    // Taskを初期化
//    [self restart:nil];
    
}

// File Pathを取得する
-(NSString*)getFilePath:(NSDictionary*)inputData{
    int directoryFlag = [[inputData objectForKey:@"directory"] intValue];
    NSDictionary *directoryType = [NSDictionary dictionaryWithObjectsAndKeys:
                                   @"~/Desktop", @"0",
                                   @"~/Downloads", @"1",
                                   @"~/Documents", @"2",
                                   nil];
    NSString *directory = [directoryType objectForKey:[[NSNumber numberWithInt:directoryFlag] stringValue]];
    NSString *filePath = [directory stringByExpandingTildeInPath];
    return filePath;
}

// File Extensionを取得する
-(NSString*)getFileExtension:(NSDictionary*)inputData{
    NSDictionary *extensionType = [NSDictionary dictionaryWithObjectsAndKeys:
                                   @"pdf", @"1",
                                   @"txt", @"2",
                                   @"xls", @"3",
                                   @"doc", @"4",
                                   @"ppt", @"5",
                                   @"numbers", @"6",
                                   @"pages", @"7",
                                   @"key", @"8",
                                   @"csv", @"9",
                                   @"md", @"10",
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
    imagePath = [[NSBundle mainBundle] pathForResource:@"Status" ofType:@"psd"];
    NSImage *statusBtnImage = [[NSImage alloc]initByReferencingFile:imagePath];
    [_statusBtn setImage:statusBtnImage];
    [_statusBtn setBordered:NO];
    
    // Info Button
    imagePath = [[NSBundle mainBundle] pathForResource:@"Info" ofType:@"psd"];
    NSImage *infoBtnImage = [[NSImage alloc]initByReferencingFile:imagePath];
    [_infoBtn setImage:infoBtnImage];
    [_infoBtn setBordered:NO];
    
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

    // Register Task Button
    imagePath = @"/Users/AirMyac/Desktop/material/botton2/RegisterOkBtn.psd";
    NSImage *registerOkBtnImage = [[NSImage alloc]initByReferencingFile:imagePath];
    [_registerOKBtn setImage:registerOkBtnImage];
    [_registerOKBtn setBordered:NO];

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
        imagePath = @"/Users/AirMyac/Desktop/material/botton2/SignIn.psd";
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
    // Sign Inボタンを表示
    NSString *imagePath;
    imagePath = [[NSBundle mainBundle] pathForResource:@"SignIn" ofType:@"psd"];
    NSImage *signInOrOutBtnImage = [[NSImage alloc]initByReferencingFile:imagePath];
    [_signInOrOutBtn setImage:signInOrOutBtnImage];
    [_signInOrOutBtn setBordered:NO];
    // ログインユーザを非表示
    [_userNameLabel setObjectValue:@"(Not Signed)"];

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
        [_notebookList removeAllObjects];
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
    NSLog(@"testMethod by Appdelegate.");
    
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
