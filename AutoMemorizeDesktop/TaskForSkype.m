//
//  TaskForSkype.m
//  TimerTest
//
//  Created by AirMyac on 5/31/13.
//  Copyright (c) 2013 com.katzlifehack. All rights reserved.
//

#import "TaskForSkype.h"
#import "AppDelegate.h"
#import "EvernoteServiceUtil.h"

@implementation TaskForSkype


/*
 * 定期実行で実行される処理
 */
- (void)polling:(NSTimer*)timer{

    // 現在時刻で実行判定
    NSDate *now = [NSDate date];
    if([self check:now]){
        
        // Topic毎に処理をするかを判定
        int isClassifyFlag = [[self.source getKeyValue:@"isClassify"] intValue];
        if(isClassifyFlag == 0){
            // Topic毎に処理をしない場合
            [self doWithoutDividingTopic:now];
            
        }else{
            // Topic毎に処理をする場合
            [self doWithDividingTopic:now];
            
        }

        // タスクの実行時間を更新する
        AppDelegate *appDelegate = (AppDelegate*)[[NSApplication sharedApplication] delegate];
        [self updateLastExecuteTime:now];
        [appDelegate save];
        
    }
}

// トッピック毎に処理をしない場合
-(void)doWithoutDividingTopic:(NSDate*)executedTime{

    // 既存ノートの有無を確認するための検索条件を設定する
    NSString *noteTitle = [self createNoteTitle:nil];
    EDAMNoteFilter *filter = [[EDAMNoteFilter alloc]init];
    [filter setWords:[NSString stringWithFormat:@"intitle:%@", noteTitle]];
    
    // 既存ノートを検索する
    [[EvernoteNoteStore noteStore] findNotesWithFilter:filter offset:0 maxNotes:10 success:^(EDAMNoteList *list) {   // Note検索が成功した場合
        // ノートを追加更新する
        [self doByUpdatingNote:list andExecutedTime:(NSDate*)executedTime andTopic:nil];
        
    } failure:^(NSError *error) {   // Note検索が失敗した場合
        NSLog(@"Find Note has beenn failured.[%@]", error);
        // ノートを新規作成する
        [self doByNewRegisteringNote:nil];

    }];
    
}

// トッピック毎に処理をする場合
-(void)doWithDividingTopic:(NSDate*)executedTime{
    
    // 対象となるTopicリストを作成する
    NSArray *topicList = [self getTopicList];

    // Topic毎にSkyepMessagesを取得してNote登録を実行する
    for(NSDictionary *topic in topicList){
        // 既存ノートの有無を確認するための検索条件を設定する
        NSString *noteTitle = [self createNoteTitle:[topic objectForKey:@"topicName"]];
        EDAMNoteFilter *filter = [[EDAMNoteFilter alloc]init];
        [filter setWords:[NSString stringWithFormat:@"intitle:%@", noteTitle]];
        
        // 既存ノートを検索する
        [[EvernoteNoteStore noteStore] findNotesWithFilter:filter offset:0 maxNotes:10 success:^(EDAMNoteList *list) {   // Note検索が成功した場合
            if([[list notes] count] == 0){  // 検索がヒットしなかった場合
                // ノートを新規作成する
                [self doByNewRegisteringNote:topic];
                
            }else{  // 検索がヒットした場合
                // ノートを追加更新する
                [self doByUpdatingNote:list andExecutedTime:(NSDate*)executedTime andTopic:(NSDictionary*)topic];
                
            }
            
        } failure:^(NSError *error) {   // Note検索が失敗した場合
            NSLog(@"Find Note has beenn failured.[%@]", error);
            // ノートを新規作成する
            [self doByNewRegisteringNote:topic];
            
        }];

    }
    
}


// 検索された既存ノートを元にノートを更新する処理
-(void)doByUpdatingNote:(EDAMNoteList*)list andExecutedTime:(NSDate*)executedTime andTopic:(NSDictionary*)topic{

    // 既存ノートのguidを取得する
    NSString *guid = [NSString string];
    for(EDAMNote *note in [list notes]){
        // 複数とることは想定していないが、複数とれた場合は最後のノートに追記する
        guid = note.guid;
    }
    
    // 既存ノートの情報を取得する
    [[EvernoteNoteStore noteStore] getNoteWithGuid:guid withContent:YES withResourcesData:YES withResourcesRecognition:YES withResourcesAlternateData:YES success:^(EDAMNote *note) {   // Note取得が成功した場合
        // ノートを追加更新する
        [self updatebyAppendingNoteContent:note andTopic:(NSDictionary*)topic];
        
    } failure:^(NSError *error) {   // Note取得が失敗した場合
        NSLog(@"Get Note has beenn failured.[%@]", error);
        // ノートを新規作成する
        [self doByNewRegisteringNote:topic];
    
    }];
}


// ノートを追加更新で更新する処理
-(void)updatebyAppendingNoteContent:(EDAMNote*)baseNote andTopic:(NSDictionary*)topic{
    
    // 本文を取得
    NSString *baseContent = baseNote.content;
    
    // 置換部分の抜き出し(en-noteタグで囲まれた文字列）
    EvernoteServiceUtil *enService = [[EvernoteServiceUtil alloc]init];
    NSString *baseString = [enService getEnNoteString:baseContent];
    
    // タスク情報からQueryを作成
    NSString *sql = [self createSQLForMessages:topic];
    
    // SkypeのMessageを取得
    NSMutableArray *result = [self getSkypeMessages:sql];
    
    // 追加分のbodyを作成
    NSString *addString = [self createNewBody:result];
    
    // DBの結果からmax時間を取得
    NSDate *latestTime = [self getLatestTimeOfMessages:result];

    // 追加分があった場合のみ更新する
    if([addString length] != 0){    // 追加分が空ではなかった場合

        // 追加分を追記
        NSMutableString *newString = [NSMutableString stringWithString:baseString];
        [newString appendString:@"<br/>"];     // 改行を挿入
        [newString appendString:addString];    // 追加分を追記
        
        // EDAMNoteを更新
        NSMutableDictionary *dic = [NSMutableDictionary dictionary];
        [dic setObject:newString forKey:@"body"];
        baseNote.content = [enService createBody:dic and:nil];
        
        // Noteを更新する
        [[EvernoteNoteStore noteStore] updateNote:baseNote success:^(EDAMNote *note) {

            NSLog(@"====Updating Note has been succeeded.====");
            EvernoteServiceUtil *enService = [[EvernoteServiceUtil alloc]init];
            [enService debugEDAMNote:note];
            // Last Added Timeを更新する
            AppDelegate *appDelegate = (AppDelegate*)[[NSApplication sharedApplication] delegate];
            [self updateLastAddedTime:latestTime];
            [appDelegate save];
            
        } failure:^(NSError *error) {
            NSLog(@"Updating Note has been failured.");
            
        }];
        
    }   // 追加分が空であった場合何もしない

}


// ノートを新規登録する処理
-(void)doByNewRegisteringNote:topic{

    // Note Titleの指定
    NSMutableString *noteTitle = [NSMutableString string];
    if([self.source.note_title length] == 0){
        // NoteTitleが指定されていない場合、デフォルトタイトルかTopic名称を設定する
        if(topic == nil){
            [noteTitle setString:@"Skype Log"];
        }else{
            [noteTitle setString:[topic objectForKey:@"topicName"]];
        }
        
    }else{
        // NoteTitleが指定されている場合はそちらを優先
        [noteTitle setString:self.source.note_title];
    }
    
    // Note Titleに日付を付与
    NSDate *now = [NSDate date];
    NSString *nowString = [now toStringWithFormat:@"yyyy/MM/dd"];
    [noteTitle appendString:@" @"];
    [noteTitle appendString:nowString];

    // tagの指定
    NSMutableArray *tagNames = [NSMutableArray arrayWithArray:[self.source splitTags]];
    
    // Notebookの指定
    NSString *notebookGUID = self.source.notebook_guid;
    AppDelegate *appDelegate = (AppDelegate*)[[NSApplication sharedApplication] delegate];
    if(![appDelegate isExistNotebook:notebookGUID]){
        notebookGUID = nil;
    }
    
    // タスク情報からQueryを作成
    NSString *sql = [self createSQLForMessages:topic];
    
    // SkypeのMessageを取得
    NSMutableArray *result = [self getSkypeMessages:sql];
    
    // 追加分のbodyを作成
    NSString *newBody = [self createNewBody:result];
    
    // DBの結果からmax時間を取得
    NSDate *latestTime = [self getLatestTimeOfMessages:result];
    
    if([newBody length] != 0){  // bodyが空でなかった場合
        // ENMLのテンプレートにbodyを追加する
        NSString *noteContent = [NSString stringWithFormat:@"<?xml version=\"1.0\" encoding=\"UTF-8\"?>"
                                 "<!DOCTYPE en-note SYSTEM \"http://xml.evernote.com/pub/enml2.dtd\">"
                                 "<en-note>"
                                 "%@"
                                 "</en-note>", newBody];
        
        // EDAMNoteを作成
        EDAMNote* note = [[EDAMNote alloc] initWithGuid:nil title:noteTitle content:noteContent contentHash:nil contentLength:(int)noteContent.length created:0 updated:0 deleted:0 active:YES updateSequenceNum:0 notebookGuid:notebookGUID tagGuids:nil resources:nil attributes:nil tagNames:tagNames];
        
        // NoteをEvernoteに登録する
        [[EvernoteNoteStore noteStore] createNote:note success:^(EDAMNote *note) {  // 登路に成功した場合
            NSLog(@"====Registering Note has been succeeded.====");
            EvernoteServiceUtil *enService = [[EvernoteServiceUtil alloc]init];
            [enService debugEDAMNote:note];
            AppDelegate *appDelegate = (AppDelegate*)[[NSApplication sharedApplication] delegate];
            [self updateLastAddedTime:latestTime];
            [appDelegate save];
            
        } failure:^(NSError *error) {   // 登録に失敗した場合
            NSLog(@"Registering Note has been failured.[%@]",error);
        }];
        
    }   // bodyが空であった場合何もしない
    
}


/*
 * SkypeMessageの結果をENMLに変換
 * SkypeMessageが空であった場合は空文字を返す
 */
-(NSString*)createNewBody:(NSArray*)result{
    // ENMLの作成
    int count = 0;
    NSMutableString *body = [NSMutableString string];
    for(NSDictionary *dic in result){
        
        // ENMLに対応していないタグを除去
        NSString *replaced = [self excludeInvalidTag:[dic objectForKey:@"body"]];
        
        // 改行コードを<br/>に置換
        replaced = [self replaceBrTag:replaced];
        
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
    return body;
}


// NoteTitleを作成する
-(NSString*)createNoteTitle:(NSString*)topic{
    
    NSMutableString *noteTitle = [NSMutableString string];
    if([self.source.note_title length] == 0){   // NoteTitleが指定されていない場合
        // デフォルトタイトルかTopic名称を設定する
        if(topic == nil){
            [noteTitle setString:@"Skype Log"];
        }else{
            [noteTitle setString:topic];
        }
        
    }else{  // NoteTitleが指定されている場合は
        // そちらの条件を優先
        [noteTitle setString:self.source.note_title];
    }
    // Note Titleに日付を付与
    NSDate *now = [NSDate date];
    NSString *nowString = [now toStringWithFormat:@"yyyy/MM/dd"];
    [noteTitle appendString:@" @"];
    [noteTitle appendString:nowString];
    
    return noteTitle;
    
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

// 正規表現置換
-(NSString*)replaceInvalidTag:(NSString*)target andPattern:(NSString*)pattern andTemplate:(NSString*)template{
    NSError *error   = nil;
    NSRegularExpression *regexp = [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:&error];
    NSString *replaced = [regexp stringByReplacingMatchesInString:target options:0 range:NSMakeRange(0,target.length) withTemplate:template];
    return replaced;
    
}

// 改行コードを<br>に置換
-(NSString*)replaceBrTag:(NSString*)string{
    // 文字列置換
    NSString *template = @"<br/>";   // 置換後文字列
    NSString *replaced = [string stringByReplacingOccurrencesOfString:@"\n" withString:template];
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

// Messages用のSQLを作成する
-(NSString*)createSQLForMessages:(NSDictionary*)topic{
    NSString *sql;
    if(topic != nil){
        // topic毎の場合、topic idで検索
        sql = [NSMutableString stringWithFormat:@"select msg.from_dispname, datetime(msg.timestamp,\"unixepoch\",\"localtime\") as datetime, msg.body_xml from messages msg inner join conversations conv on msg.convo_id = conv.id where msg.timestamp > strftime('%%s', datetime('%@', 'utc')) and conv.id = '%@'", [self.source.last_added_time toStringWithFormat:@"yyyy-MM-dd HH:mm:ss"], [topic objectForKey:@"topicId"]];
    }else{
        // topic毎ではない場合、条件式は無し
        sql = [NSString stringWithFormat:@"select from_dispname, datetime(timestamp,\"unixepoch\",\"localtime\") as datetime, body_xml from messages where timestamp > strftime('%%s', datetime('%@', 'utc'));", [self.source.last_added_time toStringWithFormat:@"yyyy-MM-dd HH:mm:ss"]];
    }
    return sql;

}

// Messagesの検索結果から最新のタイムスタンプを取得する
-(NSDate*)getLatestTimeOfMessages:(NSArray*)result{

    NSDate *latestTime = [[NSDate alloc] initWithString:@"2001-01-01 00:00:00 +0000"];
    for(NSDictionary *dic in result){
        NSString *str = [dic objectForKey:@"datetime"];
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
        NSDate *messageTime = [formatter dateFromString:str];
        NSComparisonResult result = [latestTime compare:messageTime];
        if(result < 0){
            latestTime = messageTime;
        }
    }
    
    return latestTime;
}

@end
