//
//  AppDelegate.m
//  AutoMemorizeDesktop
//
//  Created by AirMyac on 6/2/13.
//  Copyright (c) 2013 com.katzlifehack. All rights reserved.
//

#import "AppDelegate.h"
#import <CommonCrypto/CommonCrypto.h>

@implementation AppDelegate

- (void)dealloc
{
    [super dealloc];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application

    // 対象のタスクを生成
    Task *task = [[TaskForSkype alloc]init];
    // インターバル条件を指定の上、タスクを定期実行
    NSTimer *timer = [NSTimer
                      scheduledTimerWithTimeInterval:[task.interval intValue]
                      target:task
                      selector:@selector(polling:)
                      userInfo:nil
                      repeats:YES];
    
//    EDAMNote *note = [task execute];

//    [self doAddNote:note];
    
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

@end
