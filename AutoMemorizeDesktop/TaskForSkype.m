//
//  TaskForSkype.m
//  TimerTest
//
//  Created by AirMyac on 5/31/13.
//  Copyright (c) 2013 com.katzlifehack. All rights reserved.
//

#import "TaskForSkype.h"

@implementation TaskForSkype


/*
 * タスクの実行判定
 */
- (BOOL) check {
    return YES;
}


/*
 * タスクの処理内容
 */
- (EDAMNote*) execute {
    // SkypeのMessageを取得
    NSString *sql = @"select from_dispname, datetime(timestamp,\"unixepoch\",\"localtime\") as datetime, body_xml from messages where convo_id = (select conv_dbid from chats where participants = 'katsuhide1982 monji.takuro');";
    NSMutableArray *result = [self getSkypeMessages:sql];
    
    // EDAMNoteを作成し、Evernoteに保存
    EDAMNote *note = [self createEDAMNote:result];
    return note;
}

/*
 * SkypeTask用のEDAMNOTEを作成する
 */
- (EDAMNote*)createEDAMNote:(NSMutableArray*)result{
    // Note Titleの指定
    NSString *noteTitle = @"skype note";

    // tagの指定
    NSMutableArray *tagNames = [NSMutableArray arrayWithObject:@"skype"];
    
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
                    [dic objectForKey:@"name"], [dic objectForKey:@"datetime"], @"hoge hoge hoge hoge"]];
        }else {
            [body appendString:[NSString stringWithFormat:@"<p>"
                    "<span style=\"color:#849A9A;font-size:80%%\">%@ : %@</span><br/>"
                    "<span>%@</span></p>",
                    [dic objectForKey:@"name"], [dic objectForKey:@"datetime"], @"hige hige hige"]];
        }
        count++;
        // テスト用
        if(count == 10){
            break;
        }
        
    }
    
    NSString *noteContent = [NSString stringWithFormat:@"<?xml version=\"1.0\" encoding=\"UTF-8\"?>"
                             "<!DOCTYPE en-note SYSTEM \"http://xml.evernote.com/pub/enml2.dtd\">"
                             "<en-note>"
                             "%@"
                             "</en-note>",body];
    NSLog(@"%@", noteContent);
    
    // NOTEを登録
    EDAMNote* note = [[EDAMNote alloc] initWithGuid:nil title:noteTitle content:noteContent contentHash:nil contentLength:noteContent.length created:0 updated:0 deleted:0 active:YES updateSequenceNum:0 notebookGuid:nil tagGuids:nil resources:nil attributes:nil tagNames:tagNames];
    
    return note;
}



/*
 * SkypeにDBに接続してChat Messageを取得する
 */
- (NSMutableArray*)getSkypeMessages:(NSString*)sql{
    // DB設定情報
    NSString *databaseName = @"main.db";
    NSString *path = @"/Users/AirMyac/Library/Application Support/Skype/katsuhide1982";
    NSString *databasePath = [path stringByAppendingPathComponent:databaseName];
    FMDatabase *db  = [FMDatabase databaseWithPath:databasePath];
    
    // Open DB
    [db open];
    
    // Execute Query
    FMResultSet *results = [db executeQuery:sql];
    
    // Output
    NSMutableArray *result = [NSMutableArray array];
    while ([results next]) {
        NSArray *key = [NSArray arrayWithObjects:@"name", @"datetime", @"body", nil];
        NSArray *value = [NSArray arrayWithObjects:[results stringForColumn:@"from_dispname"], [results stringForColumn:@"datetime"], [results stringForColumn:@"body_xml"], nil];
        NSDictionary *dic = [NSDictionary dictionaryWithObjects:value forKeys:key];
        [result addObject:dic];
    }
    
    // Release result set
    [results close];
    
    // Close DB
    [db close];
    
    return result;
    
}


- (NSMutableArray*)getParticipants {

    // Query
    NSString *sql = @"select distinct participants from chats;";

    return nil;
    
}

@end
