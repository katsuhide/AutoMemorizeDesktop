//
//  TaskForFile.m
//  TimerTest
//
//  Created by AirMyac on 5/31/13.
//  Copyright (c) 2013 com.katzlifehack. All rights reserved.
//

#import "TaskForFile.h"
#import "AppDelegate.h"
#import "NSData+EvernoteSDK.h"

@implementation TaskForFile

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
            NSLog(@"Didn't create the Note since file does note exist.");
        }
        
        // 実行時間を更新
        [self updateLastExecuteTime:now];
        
        // 更新したTaskSourceを永続化
        [appDelegate save];
        
    }else{
        NSLog(@"File Task skipped since this time is not enable timing.");
    }
}


/*
 * タスクの処理内容
 */
- (EDAMNote*) execute {
    NSLog(@"TaskForFile Class method isn't implemented.");
    
    // 作成対象のファイルパスを取得
    NSMutableArray *filePathList = [self getFilePathList];
    
    // 対象ファイルが存在しない場合はノートを作成しない
    if([filePathList count] == 0){
        _canAddNote = FALSE;
    }else{
        _canAddNote = TRUE;
    }
    
    // EDAMNoteを作成する
    EDAMNote *note = [self createEDAMNote:filePathList];
    
    return note;
}


/*
 * 指定された条件でEvernoteへのポスト対象のファイルのフルパスを取得する
 */
-(NSMutableArray*)getFilePathList{
    NSMutableArray *filePathList = [NSMutableArray array];
    [filePathList addObject:@"/Users/AirMyac/Desktop/hoge.txt"];
    [filePathList addObject:@"/Users/AirMyac/Desktop/fuga.txt"];
    return filePathList;
}

/*
 * FileTask用のEDAMNoteを作成する
 */
- (EDAMNote*)createEDAMNote:(NSMutableArray*)filePathList{
    // Note Titleの指定
    NSString *noteTitle = self.source.task_name;
    
    // tagの指定
    NSMutableArray *tagNames = [NSMutableArray arrayWithArray:[self.source splitTags]];
    
    // Notebookの指定
    //    NSString* parentNotebookGUID;
    //    if(parentNotebook) {
    //        parentNotebookGUID = parentNotebook.guid;
    //    }
    
    // EDAMResourceをリストに格納
    NSMutableArray *resources = [[NSMutableArray alloc] init];
    [self createResources:filePathList andResouces:resources];
    
    
    // ENMLの作成
    NSMutableString* body = [NSMutableString string];
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
    NSLog(@"body:\n%@", noteContent);
    
    
    // NOTEを登録
    EDAMNote* note = [[EDAMNote alloc] initWithGuid:nil title:noteTitle content:noteContent contentHash:nil contentLength:(int)noteContent.length created:0 updated:0 deleted:0 active:YES updateSequenceNum:0 notebookGuid:nil tagGuids:nil resources:resources attributes:nil tagNames:tagNames];
    
    return note;
    
}

/*
 * ファイルパスからResourcesを作成
 */
- (void) createResources:(NSArray*) files andResouces:(NSMutableArray*) resouces{
    for(NSString *filePath in files){
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


@end
