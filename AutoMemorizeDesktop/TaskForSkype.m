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
        // タスクを実行してNoteListを作成する
        NSMutableArray *noteList = [self createNoteList];

        // Note登録を実行する
        AppDelegate *appDelegate = (AppDelegate*)[[NSApplication sharedApplication] delegate];
        if(_canAddNote) {
            // 作成されたノートを個別に登録
            for(EDAMNote *note in noteList){
                [appDelegate doAddNote:note];
            }
            // ノートの登録時間を更新  TODO 最長メッセージ
            [self updateLastAddedTime:now];
        }else{
            NSLog(@"[TaskName:%@]Didn't create the Note since body is blank.", self.source.task_name);
        }

        // タスクの実行時間を更新
        [self updateLastExecuteTime:now];
        
        // 更新したTaskSourceを永続化
        [appDelegate save];
    }
}

/*
 * SkypeLogのNoteListを作成する
 */
- (NSMutableArray*) createNoteList {
    // 初期設定をNote作成フラグNOに設定
    _canAddNote = NO;
    
    // Topicの一覧を取得する
    NSArray* topicList = [self getTopicList];

    // Topic毎にノートを作成する
    NSMutableArray *noteList = [NSMutableArray array];
    int isClassifyFlag = [[self.source getKeyValue:@"isClassify"] intValue];
    if(isClassifyFlag == 0){
        // まとめて作成
        // タスク情報からQueryを作成
        NSString *sql = [NSString stringWithFormat:@"select from_dispname, datetime(timestamp,\"unixepoch\",\"localtime\") as datetime, body_xml from messages where timestamp >= strftime('%%s', datetime('%@', 'utc'));", [self.source.last_added_time toStringWithFormat:@"yyyy-MM-dd HH:mm:ss"]];
        
        // SkypeのMessageを取得
        NSMutableArray *result = [self getSkypeMessages:sql];
        //    NSLog(@"sql:%@, result:%@", sql, result);         // logが肥大化するためコメントアウト
        
        // Messageが空ではない場合のみノートは作成する
        if([result count] != 0){
            _canAddNote = YES;
            // EDAMNoteを作成しNoteListを作成
            EDAMNote *note = [self createEDAMNote:result andTopic:nil];
            [noteList addObject:note];
        }
        
    }else{
        // Topic毎に作成
        for(NSDictionary* topic in topicList){
            // タスク情報からQueryを作成
            NSMutableString *sql = [NSMutableString stringWithFormat:@"select msg.from_dispname, datetime(msg.timestamp,\"unixepoch\",\"localtime\") as datetime, msg.body_xml from messages msg inner join conversations conv on msg.convo_id = conv.id where msg.timestamp >= strftime('%%s', datetime('%@', 'utc')) and conv.id = '%@'", [self.source.last_added_time toStringWithFormat:@"yyyy-MM-dd HH:mm:ss"], [topic objectForKey:@"topicId"]];
            
            // SkypeのMessageを取得
            NSMutableArray *result = [self getSkypeMessages:sql];
//            NSLog(@"sql:%@, result:%@", sql, result);         // logが肥大化するためコメントアウト
            
            // Messageが空であった場合はノートは作成しない
            if([result count] != 0){
                _canAddNote = YES;
                // EDAMNoteを作成しNoteListを作成
                EDAMNote *note = [self createEDAMNote:result andTopic:[topic objectForKey:@"topicName"]];
                [noteList addObject:note];
            }
        }
    }

    return noteList;
}

/*
 * SkypeTask用のEDAMNOTEを作成する
 */
-(NSArray*)getTopicList{
    // Queryを作成
    NSString *sql = @"select id, displayname from conversations;";

    // Queryを実行
    return [self getTopicListFromDB:sql];
    
}


/*
 * SkypeTask用のEDAMNOTEを作成する
 */
- (EDAMNote*)createEDAMNote:(NSMutableArray*)result andTopic:(NSString*)topic{
    // Note Titleの指定
    NSString *noteTitle;
    if([self.source.note_title length] == 0){
        // NoteTitleが指定されていない場合、デフォルトタイトルかTopic名称を設定する
        if(topic == nil){
            noteTitle = @"Skype Log";
        }else{
            noteTitle = topic;
        }
        
    }else{
        // NoteTitleが指定されている場合はそちらを優先
        noteTitle = self.source.note_title;
    }

    // tagの指定
    NSMutableArray *tagNames = [NSMutableArray arrayWithArray:[self.source splitTags]];
    
    // Notebookの指定
    NSString *notebookGUID = self.source.notebook_guid;
    AppDelegate *appDelegate = (AppDelegate*)[[NSApplication sharedApplication] delegate];
    if(![appDelegate isExistNotebook:notebookGUID]){
        notebookGUID = nil;
    }
    
    // ENMLの作成
    int count = 0;
    NSMutableString *body = [NSMutableString string];
    for(NSDictionary *dic in result){   // TODO resultを分解しておく必要あり
        // ENMLに対応していないタグを除去
        NSString *replaced = [self excludeInvalidTag:[dic objectForKey:@"body"]];
        
        // 奇数、偶数でスタイルを変えてbodyを構成
        if(count % 2 == 0){
            [body appendString:[NSString stringWithFormat:@"<p style=\"background-color:#EBF2FF\">"
                    "<span style=\"color:#849A9A;font-size:80%%\">%@ : %@</span><br/>"
                    "<span>%@</span></p>",
                    [dic objectForKey:@"name"], [dic objectForKey:@"datetime"], replaced]];
        }else {
            [body appendString:[NSString stringWithFormat:@"<p>"
                    "<span style=\"color:#849A9A;font-size:80%%\">%@ : %@</span><br/>"
                    "<span>%@</span></p>",
                    [dic objectForKey:@"name"], [dic objectForKey:@"datetime"], replaced]];
        }
        count++;
        
    }

    // ENMLのテンプレートにbodyを追加する
    NSString *noteContent = [NSString stringWithFormat:@"<?xml version=\"1.0\" encoding=\"UTF-8\"?>"
                             "<!DOCTYPE en-note SYSTEM \"http://xml.evernote.com/pub/enml2.dtd\">"
                             "<en-note>"
                             "%@"
                             "</en-note>",body];
    
    NSLog(@"body:\n%@", noteContent);
    
    // NOTEを登録
    EDAMNote* note = [[EDAMNote alloc] initWithGuid:nil title:noteTitle content:noteContent contentHash:nil contentLength:(int)noteContent.length created:0 updated:0 deleted:0 active:YES updateSequenceNum:0 notebookGuid:notebookGUID tagGuids:nil resources:nil attributes:nil tagNames:tagNames];
    
    return note;
}

// 非対応のタグを除去
-(NSString*)excludeInvalidTag:(NSString*)original{
    NSMutableString *replaced = [NSMutableString stringWithString:original];
    NSString *template = @"";   // 置換後文字列
    
    NSString *pattern = @"<ss type.+?</ss>";   // 検索条件
    [replaced setString:[self replaceInvalidTag:replaced andPattern:pattern andTemplate:template]];
    
    pattern = @"<quote .+?</quote>";    // 検索条件
    [replaced setString:[self replaceInvalidTag:replaced andPattern:pattern andTemplate:template]];
    return replaced;
    
}

// 置換
-(NSString*)replaceInvalidTag:(NSString*)target andPattern:(NSString*)pattern andTemplate:(NSString*)template{
    NSError *error   = nil;
    NSRegularExpression *regexp = [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:&error];
    NSString *replaced = [regexp stringByReplacingMatchesInString:target options:0 range:NSMakeRange(0,target.length) withTemplate:template];
    return replaced;
    
}


/*
 * SkypeにDBに接続してChat Messageを取得する
 */
- (NSMutableArray*)getSkypeMessages:(NSString*)sql{
    // DB設定情報
    NSString *databasePath = [self.source getKeyValue:@"file_path"];
    FMDatabase *db  = [FMDatabase databaseWithPath:[databasePath stringByExpandingTildeInPath]];
    
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

/*
 * SkypeにDBに接続してTopicを取得する
 */
- (NSMutableArray*)getTopicListFromDB:(NSString*)sql{
    // DB設定情報
    NSString *databasePath = [self.source getKeyValue:@"file_path"];

    // Open DB
    FMDatabase *db  = [FMDatabase databaseWithPath:[databasePath stringByExpandingTildeInPath]];
    [db open];
    
    // Execute Query
    FMResultSet *results = [db executeQuery:sql];
    
    // Output
    NSMutableArray *result = [NSMutableArray array];
    while ([results next]) {
        NSArray *key = [NSArray arrayWithObjects:@"topicId", @"topicName", nil];
        NSArray *value = [NSArray arrayWithObjects:[results stringForColumn:@"id"], [results stringForColumn:@"displayname"], nil];
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
