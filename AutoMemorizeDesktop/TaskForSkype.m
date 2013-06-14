//
//  TaskForSkype.m
//  TimerTest
//
//  Created by AirMyac on 5/31/13.
//  Copyright (c) 2013 com.katzlifehack. All rights reserved.
//

#import "TaskForSkype.h"
#import "AppDelegate.h"

@implementation TaskForSkype


/*
 * 定期実行で実行される処理
 */
- (void)polling:(NSTimer*)timer{
    NSDate *now = [NSDate date];
    if([self check:now]){
        // タスクを実行してNoteを作成する
        EDAMNote *note = [self execute];
        
        // Note登録を実行する
        AppDelegate *appDelegate = (AppDelegate*)[[NSApplication sharedApplication] delegate];
        if(_canAddNote) {
            [appDelegate doAddNote:note];
        }else{
            NSLog(@"Didn't create the Note since body is blank.");
        }

        // 実行時間を更新
        [self updateLastExecuteTime:now];
        
        // 更新したTaskSourceを永続化
        [appDelegate save];

    }else{
        NSLog(@"Skype Task skipped since this time is not enable timing.");
    }

}

/*
 * タスクの処理内容
 */
- (EDAMNote*) execute {
    // タスク情報からQueryを作成
    NSMutableString *sql = [NSMutableString stringWithFormat:@"select from_dispname, datetime(timestamp,\"unixepoch\",\"localtime\") as datetime, body_xml from messages where timestamp >= strftime('%%s', datetime('%@', 'utc'))", [self.source.last_execute_time toStringWithFormat:@"yyyy-MM-dd HH:mm:ss"]];
    NSString *participants = [self.source getKeyValue:@"participants"];
    if(participants.length != 0){
        [sql appendFormat:@" and convo_id = (select distinct conv_dbid from chats where participants = '%@');",[self.source getKeyValue:@"participants"]];
    }else{
        [sql appendString:@";"];
    }
    
    // SkypeのMessageを取得
    NSMutableArray *result = [self getSkypeMessages:sql];
    
    // Messageが空であった場合はノートは作成しない
    if([result count] == 0){
        _canAddNote = FALSE;
    }else{
        _canAddNote = TRUE;
    }
    
    // EDAMNoteを作成し、Evernoteに保存
    EDAMNote *note = [self createEDAMNote:result];
    return note;
}

/*
 * SkypeTask用のEDAMNOTEを作成する
 */
- (EDAMNote*)createEDAMNote:(NSMutableArray*)result{
    // Note Titleの指定
    NSString *noteTitle = self.source.task_name;

    // tagの指定
    NSMutableArray *tagNames = [NSMutableArray arrayWithArray:[self.source splitTags]];
    
    // Notebookの指定
    //    NSString* parentNotebookGUID;
    //    if(parentNotebook) {
    //        parentNotebookGUID = parentNotebook.guid;
    //    }
    
    // ENMLの作成
    int count = 0;
    NSMutableString *body = [NSMutableString string];
    for(NSDictionary *dic in result){
        if(count % 2 == 0){
            [body appendString:[NSString stringWithFormat:@"<p style=\"background-color:#EBF2FF\">"
                    "<span style=\"color:#849A9A;font-size:80%%\">%@ : %@</span><br/>"
                    "<span>%@</span></p>",
                    [dic objectForKey:@"name"], [dic objectForKey:@"datetime"], [dic objectForKey:@"body"]]];
        }else {
            [body appendString:[NSString stringWithFormat:@"<p>"
                    "<span style=\"color:#849A9A;font-size:80%%\">%@ : %@</span><br/>"
                    "<span>%@</span></p>",
                    [dic objectForKey:@"name"], [dic objectForKey:@"datetime"], [dic objectForKey:@"body"]]];
        }
        count++;
        
    }
    
    NSString *noteContent = [NSString stringWithFormat:@"<?xml version=\"1.0\" encoding=\"UTF-8\"?>"
                             "<!DOCTYPE en-note SYSTEM \"http://xml.evernote.com/pub/enml2.dtd\">"
                             "<en-note>"
                             "%@"
                             "</en-note>",body];
    
    NSLog(@"body:\n%@", noteContent);
    
    // NOTEを登録
    EDAMNote* note = [[EDAMNote alloc] initWithGuid:nil title:noteTitle content:noteContent contentHash:nil contentLength:noteContent.length created:0 updated:0 deleted:0 active:YES updateSequenceNum:0 notebookGuid:nil tagGuids:nil resources:nil attributes:nil tagNames:tagNames];
    
    return note;
}


/*
 * SkypeにDBに接続してChat Messageを取得する
 */
- (NSMutableArray*)getSkypeMessages:(NSString*)sql{
    // DB設定情報
    NSString *databasePath = [self.source getKeyValue:@"file_path"];
    FMDatabase *db  = [FMDatabase databaseWithPath:databasePath];
    
    // Open DB
    [db open];
    
    // Execute Query
    FMResultSet *results = [db executeQuery:sql];
    
    // Output
    NSMutableArray *result = [NSMutableArray array];
    while ([results next]) {
        NSArray *key = [NSArray arrayWithObjects:@"name", @"datetime", @"body", nil];
        NSString *body_xml = ([results stringForColumn:@"body_xml"].length == 0) ? @"":[results stringForColumn:@"body_xml"];
        NSArray *value = [NSArray arrayWithObjects:[results stringForColumn:@"from_dispname"], [results stringForColumn:@"datetime"], body_xml, nil];
        NSDictionary *dic = [NSDictionary dictionaryWithObjects:value forKeys:key];
        [result addObject:dic];
    }
    
    // Release result set
    [results close];
    
    // Close DB
    [db close];
    
    return result;
    
}

@end
