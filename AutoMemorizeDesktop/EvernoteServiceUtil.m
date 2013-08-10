//
//  EvernoteService.m
//  RecDesktop
//
//  Created by AirMyac on 7/24/13.
//  Copyright (c) 2013 com.katzlifehack. All rights reserved.
//

#import "EvernoteServiceUtil.h"
#import "AppDelegate.h"
#import "NSDate+Util.h"


@implementation EvernoteServiceUtil

@synthesize enDelegate;

/**
 * イニシャライザ
 */
- (id)init
{
    if (self = [super init]) {
        // 初期処理
    }
    return self;
}

/*
 * 指定された条件でEDAMNoteを作成する
 */
-(EDAMNote*)createEDAMNote:(NSDictionary*)condition{
    // Note Titleを指定
    NSString *noteTitle = [condition objectForKey:@"noteTitle"];
    
    // tagを指定
    NSMutableArray *tagNames = [condition objectForKey:@"tagNames"];
    
    // Notebookを指定
    NSString *notebookGUID = [condition objectForKey:@"notebookGUID"];
    AppDelegate *appDelegate = (AppDelegate*)[[NSApplication sharedApplication] delegate];
    if(![appDelegate isExistNotebook:notebookGUID]){
        notebookGUID = nil;
    }

    // EDAMResourceを作成
    NSString *filePath = [condition objectForKey:@"filePath"];
    NSMutableArray *resources = [[NSMutableArray alloc] init];
    [self createResources:filePath andResouces:resources];
    
    // EMNLを作成
    NSMutableString* body = [NSMutableString string];
    
    // <en-body>
    NSString *str = [condition objectForKey:@"body"];
    if([str length] != 0){
        [body appendString:str];
        [body appendString:@"<br/>"];
    }
    
    // <en-media>
    for(EDAMResource *resouce in resources){
        [body appendString:@"<en-media type=\""];
        [body appendString:resouce.mime];
        [body appendString:@"\" hash=\""];
        [body appendString:[resouce.data.bodyHash enlowercaseHexDigits]];
        [body appendString:@"\"/>"];
    }
    NSString *noteContent = [NSString stringWithFormat:@"<?xml version=\"1.0\" encoding=\"UTF-8\"?>"
                             "<!DOCTYPE en-note SYSTEM \"http://xml.evernote.com/pub/enml2.dtd\">"
                             "<en-note>"
                             "%@"
                             "</en-note>",body];

    // EDAMNoteを作成
    EDAMNote* note = [[EDAMNote alloc] initWithGuid:nil title:noteTitle content:noteContent contentHash:nil contentLength:(int)noteContent.length created:0 updated:0 deleted:0 active:YES updateSequenceNum:0 notebookGuid:notebookGUID tagGuids:nil resources:resources attributes:nil tagNames:tagNames];
    
    [self debugEDAMNote:note];
    
    return note;
}

// デバッグ用メソッド
-(void)debugEDAMNote:(EDAMNote*)note{
    NSLog(@"EDAMNote{\nNote Title:%@\nTag Guids:%@\nTags:%@\nNote Guid:%@\nNote Content:%@\n}", note.title, note.tagGuids, note.tagNames, note.guid, note.content);
}

/*
 * ファイルパスからResourcesを作成
 */
- (void) createResources:(NSString*) filePath andResouces:(NSMutableArray*) resouces{
    // 指定されたファイルパスが空なら何も作成しない
    if([filePath length] == 0){
        return;
    }
    
    // 指定されたファイルパスからEDAMResourceを作成
    NSString *fileName = [filePath lastPathComponent];
    NSString *mime = [self mimeTypeForFileAtPath:filePath];
    NSData *myFileData = [NSData dataWithContentsOfFile:filePath];
    NSData *bodyHash = [myFileData enmd5];
    EDAMData *edamData = [[EDAMData alloc] initWithBodyHash:bodyHash size:(int)myFileData.length body:myFileData];
    EDAMResourceAttributes *attribute = [[EDAMResourceAttributes alloc] init];
    attribute.fileName = fileName;
    EDAMResource* resource = [[EDAMResource alloc] initWithGuid:nil noteGuid:nil data:edamData mime:mime width:0 height:0 duration:0 active:0 recognition:0 attributes:attribute updateSequenceNum:0 alternateData:nil];
    [resouces addObject:resource];
}

/*
 * ファイルパスからMIMEを取得する
 */
- (NSString*) mimeTypeForFileAtPath: (NSString *) path {
    if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
        return nil;
    }
    CFStringRef UTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (__bridge CFStringRef)[path pathExtension], NULL);
    CFStringRef mimeType = UTTypeCopyPreferredTagWithClass (UTI, kUTTagClassMIMEType);
    CFRelease(UTI);
    if (!mimeType) {
        return @"application/octet-stream";
    }
    return (__bridge_transfer NSString*)mimeType;
}

/*
 * EvernoteにNOTEを新規保存する処理を実行する
 */
-(void)registerNote:(EDAMNote*)note{
    // 作成されたEDAMNoteを登録する
    [[EvernoteNoteStore noteStore] createNote:note success:^(EDAMNote *note) {
        NSLog(@"====Registering Note has been succeeded.====");
        [self debugEDAMNote:note];
        
        // 後処理
        if([self.enDelegate respondsToSelector:@selector(afterRegisterNote:)]){
            [self.enDelegate afterRegisterNote:note];
        }
        
    } failure:^(NSError *error) {
        NSLog(@"Registering Note has been failured.[%@]",error);

    }];

}


/*
 * 指定された条件でNoteを検索する
 */
-(NSArray*)findNotes:(NSDictionary*)filters{
    EDAMNoteFilter *filter = [[EDAMNoteFilter alloc]init];
    [filter setWords:@"intitle:updatenotetest intitle:2012/12/13"];
    [[EvernoteNoteStore noteStore] findNotesWithFilter:filter offset:0 maxNotes:10 success:^(EDAMNoteList *list) {
        for(EDAMNote *note in [list notes]){
            [self debugEDAMNote:note];
        }

    } failure:^(NSError *error) {
        NSLog(@"error:[%@]", error);
    }];
    return nil;
}

/*
 * 指定されたguidでNoteを取得する
 */
-(EDAMNote*)getNote:(NSString*)guid{
    [[EvernoteNoteStore noteStore] getNoteWithGuid:guid withContent:YES withResourcesData:YES withResourcesRecognition:YES withResourcesAlternateData:YES success:^(EDAMNote *note) {
        // Note取得に成功した場合
        NSLog(@"Get Note has beenn succeeded.");
        [self debugEDAMNote:note];
        
    } failure:^(NSError *error) {
        // Note取得に失敗した場合
        NSLog(@"Get Note has beenn failured.[%@]", error);

    }];

    return nil;
    
}

/*
 * 指定されたguidでNoteを取得し、updateする
 */
-(void)updateNote:(NSString*)guid andDEAMNoteCondition:(NSDictionary*)condition{
    // guid指定でNoteを取得
    [[EvernoteNoteStore noteStore] getNoteWithGuid:guid withContent:YES withResourcesData:YES withResourcesRecognition:YES withResourcesAlternateData:YES success:^(EDAMNote *note) {
        // Note取得に成功した場合
        NSLog(@"Get Note has beenn succeeded.");
    
        // 本文を取得
        NSString *bfContent = note.content;

        // 置換部分の抜き出し(en-noteタグで囲まれた文字列）
        NSMutableString *afContent = [NSMutableString stringWithString:[self getEnNoteString:bfContent]];
        
        // 追加情報を追加
        [afContent appendString:@"これはNoteの追記分だよ！！！"];
        
        // 置換
        NSMutableDictionary *dic = [NSMutableDictionary dictionary];
        [dic setObject:afContent forKey:@"body"];
        NSString *content = [self createBody:dic and:nil];
        note.content = content;
        
        // NoteをUpdate
        [[EvernoteNoteStore noteStore] updateNote:note success:^(EDAMNote *note) {
            NSLog(@"success update");
        } failure:^(NSError *error) {
            NSLog(@"failuer update");
        }];
        
    } failure:^(NSError *error) {
        // Note取得に失敗した場合
        NSLog(@"Get Note has beenn failured.[%@]", error);

    }];
    
}


/*
 * <en-note>...</en-note>に囲まれた文字列を取得する
 */
-(NSString*)getEnNoteString:(NSString*)content{
    
    // <en-note>の開始位置を調べる
    NSString *pattern = @"<en-note>";
    NSRange rangeFrom = [content rangeOfString:pattern];
    if(rangeFrom.location == NSNotFound){
        return nil;
    }
        
    // </en-note>の開始位置を調べる
    pattern = @"</en-note>";
    NSRange rangeTo = [content rangeOfString:pattern];
    if(rangeTo.location == NSNotFound){
        return nil;
    }
    
    // <en-note>...</en-note>に囲まれた文字列を抜き出す
    NSString *string = [content substringWithRange:NSMakeRange((rangeFrom.location + rangeFrom.length) , (rangeTo.location - rangeFrom.location - rangeFrom.length))];
    
    return string;
}

// Note.Contentを指定されたパラメーターで作成する
-(NSString*)createBody:(NSDictionary*)condition and:(NSArray*)resources{
    // EMNLを作成
    NSMutableString* body = [NSMutableString string];
    
    // <en-body>（本文）
    NSString *str = [condition objectForKey:@"body"];
    if([str length] != 0){
        [body appendString:str];
        [body appendString:@"<br/>"];
    }
    
    // <en-media>
    for(EDAMResource *resouce in resources){
        [body appendString:@"<en-media type=\""];
        [body appendString:resouce.mime];
        [body appendString:@"\" hash=\""];
        [body appendString:[resouce.data.bodyHash enlowercaseHexDigits]];
        [body appendString:@"\"/>"];
    }
    NSString *noteContent = [NSString stringWithFormat:@"<?xml version=\"1.0\" encoding=\"UTF-8\"?>"
                             "<!DOCTYPE en-note SYSTEM \"http://xml.evernote.com/pub/enml2.dtd\">"
                             "<en-note>"
                             "%@"
                             "</en-note>",body];

    return noteContent;
    
}

@end
