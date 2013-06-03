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

- (void)dealloc
{
    [super dealloc];
}

// Insert code here to initialize your application
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // 初回起動用にDataStore用のDirectoryの有無を確認して無ければ作成する
    NSURL *applicationFilesDirectory = [self applicationFilesDirectory];
    NSError *error = nil;
    if(![[NSFileManager defaultManager] createDirectoryAtPath:[applicationFilesDirectory path] withIntermediateDirectories:YES attributes:nil error:&error]){
        NSLog(@"Couldn't create the data store directory.[%@, %@]", error, [error userInfo]);
        abort();
    }

    // 対象のタスクを生成
    Task *task = [[Task alloc]init];
    // インターバル条件を指定の上、タスクを定期実行
    NSTimer *timer = [NSTimer
                      scheduledTimerWithTimeInterval:INTERVAL
                      target:task
                      selector:@selector(polling:)
                      userInfo:nil
                      repeats:YES];
    
}

-(void)hoge{
    NSLog(@"hoge");
}

/*
 * EvernoteにNOTEを新規保存する処理を実行する
 */
-(void)doAddNote:(EDAMNote*)note{
    // EvernoteAPIの設定情報
    NSString *EVERNOTE_HOST = BootstrapServerBaseURLStringSandbox;
    NSString *CONSUMER_KEY = @"katzlifehack";
    NSString *CONSUMER_SECRET = @"9490d8896d0bb1a3";
    [EvernoteSession setSharedSessionHost:EVERNOTE_HOST
                              consumerKey:CONSUMER_KEY
                           consumerSecret:CONSUMER_SECRET];
    
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
    
    [[EvernoteNoteStore noteStore] createNote:note success:^(EDAMNote *note) {
        // Log the created note object
        NSLog(@"Note created : %@",note.title);
        
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

// register method
- (IBAction)registerAction:(id)sender{
    // NSManagedObjectの生成
    TaskSource *taskSource = (TaskSource*)[self createObject:TASK_SOURCE];
    taskSource.task_name = @"task1";
    taskSource.interval = @"10";
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


@end
