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
        // タスクを実行してNoteListを作成する
        NSMutableArray *noteList = [self execute];
        
        // Note登録を実行する
        AppDelegate *appDelegate = (AppDelegate*)[[NSApplication sharedApplication] delegate];
        if(_canAddNote) {
            // 作成されたノートを個別に処理
            for(EDAMNote *note in noteList){
                // ノートを登録
                [appDelegate doAddNote:note];
                if(YES){    // TODO エラー処理を実装
                    // 対象のノートをoldディレクトリへ移動
                    [self moveFile:note];
                }
                // ノートの登録時間を更新
                [self updateLastAddedTime:now];
            }
        }else{
            NSLog(@"[TaskName:%@]Didn't create the Note since file does note exist.", self.source.task_name);
        }
        
        // タスクの実行時間を更新
        [self updateLastExecuteTime:now];
        
        // 更新したTaskSourceを永続化
        [appDelegate save];
        
    }
}


/*
 * FileTaskのロジックでEDAMNoteを生成する
 */
- (NSMutableArray*) execute {
    // 作成対象のファイルパスを取得
    NSMutableArray *filePathList = [self getFilePathList];
    
    // 対象ファイルが存在しない場合はノートを作成しない
    if([filePathList count] == 0){
        _canAddNote = FALSE;
    }else{
        _canAddNote = TRUE;
    }
    
    // EDAMNoteを作成する
    NSMutableArray *noteList = [[NSMutableArray alloc]init];
    for(NSString *filePath in filePathList){
        EDAMNote *note = [self createEDAMNote:filePath];
        [noteList addObject:note];
    }
    return noteList;
}


/*
 * 指定された条件でEvernoteへのポスト対象のファイルのフルパスを取得する
 */
-(NSMutableArray*)getFilePathList{
    // 指定された条件を取得
    NSString *directoryPath = [[self.source getKeyValue:@"file_path"] stringByExpandingTildeInPath];
    NSString *extension = [self.source getKeyValue:@"extension"];

    // 対象のパスのファイル一覧を取得
    NSFileManager *fileManager=[[NSFileManager alloc] init];
    NSError *error = nil;
    NSArray *allFileName = [fileManager contentsOfDirectoryAtPath:directoryPath error:&error];
    if (error) return nil;

    // 拡張子で絞り込む
    NSMutableArray *filePathList = [[NSMutableArray alloc] init];
    
    // 拡張子条件が存在する場合、各ファイルの拡張子が一致するかを確認したうえでフルパスのFileListを生成
    for (NSString *fileName in allFileName) {
        if([extension length] == 0){
            // 拡張子条件が空の場合
            NSString *fullPath = [directoryPath stringByAppendingPathComponent:fileName];
            [filePathList addObject:fullPath];
        }else if ([[fileName pathExtension] isEqualToString:extension]) {
            // 拡張子条件が存在する場合
            NSString *fullPath = [directoryPath stringByAppendingPathComponent:fileName];
            [filePathList addObject:fullPath];
        }
    }
    return filePathList;
    
}

/*
 * FileTask用のEDAMNoteを作成する
 */
- (EDAMNote*)createEDAMNote:(NSString*)filePath{
    // Note Titleの指定
    NSString *noteTitle;
    if([self.source.note_title length] == 0){
        noteTitle = filePath;
    }else{
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
    
    // EDAMResourceをリストに格納
    NSMutableArray *resources = [[NSMutableArray alloc] init];
    [self createResources:filePath andResouces:resources];
    
    
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
    EDAMNote* note = [[EDAMNote alloc] initWithGuid:nil title:noteTitle content:noteContent contentHash:nil contentLength:(int)noteContent.length created:0 updated:0 deleted:0 active:YES updateSequenceNum:0 notebookGuid:notebookGUID tagGuids:nil resources:resources attributes:nil tagNames:tagNames];
    
    return note;
    
}

/*
 * 対象のファイルを移動する
 */
-(void)moveFile:(EDAMNote*)note{
    // 退避ディレクトリを対象のパスの直下に作成
    NSDate *now = [NSDate date];
    NSString *baseDir = [[self.source getKeyValue:@"file_path"] stringByExpandingTildeInPath];
    NSString *backupDirName = [now toStringWithFormat:@"yyyyMMdd_HHmmss"];
    NSString *backupPath = [[self.source getKeyValue:@"backupPath"] stringByAppendingPathComponent:backupDirName];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error = nil;
    if(![fileManager createDirectoryAtPath:backupPath withIntermediateDirectories:YES attributes:nil error:&error]){
        NSLog(@"Couldn't create the data store directory.[%@, %@]", error, [error userInfo]);
        return;
    }

    // 対象のファイルを移動する
    EDAMResource *resource = [note.resources objectAtIndex:0];  // Resourceは１つの前提のため
    NSString *filePath = [baseDir stringByAppendingPathComponent:resource.attributes.fileName];
    NSString *toFilePath = [backupPath stringByAppendingPathComponent:resource.attributes.fileName];
    if(![fileManager moveItemAtPath:filePath toPath:toFilePath error:&error]){
        NSLog(@"Couldn't move this file:[%@] to this path:[%@].[%@, %@]", filePath, backupPath, error, [error userInfo]);
//        // ファイルが存在していて失敗した場合、別名で保存しておく TODO ちゃんとエラーハンドリングする
//        // oldディレクトリを日付形式に変えて作成して重複を防ぐ
//        NSDate *now = [NSDate date];
//        NSString *toFilePath2 = [toFilePath stringByAppendingString:[[now toLocalTime] toString]];
//        if(![fileManager moveItemAtPath:filePath toPath:toFilePath2 error:&error]){
//            NSLog(@"Couldn't move this file:[%@] to this path:[%@] as new file name:[%@].[%@, %@]", filePath, workPath, toFilePath2, error, [error userInfo]);
//        }else{
//            NSLog(@"Finished moving this file:[%@] to this path:[%@] as new file name:[%@].", filePath, workPath, toFilePath2);
//        }
    }else{
        NSLog(@"Finished moving this file:[%@] to this path:[%@].", filePath, backupPath);
    }
    
}

/*
 * ファイルパスからResourcesを作成
 */
- (void) createResources:(NSString*) filePath andResouces:(NSMutableArray*) resouces{
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


@end
