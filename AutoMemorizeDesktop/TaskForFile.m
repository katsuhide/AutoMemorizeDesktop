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
#import "EvernoteServiceUtil.h"

@implementation TaskForFile

/*
 * 定期実行で実行される処理
 */
- (void)polling:(NSTimer*)timer{
    NSDate *now = [NSDate date];
    if([self check:now]){

        // 対象に合致するファイルのフルパス一覧を取得
        NSArray *targetFiles = [self getFilePathList];

        AppDelegate *appDelegate = (AppDelegate*)[[NSApplication sharedApplication] delegate];
        
        if([targetFiles count] == 0){   // 対象のファイルが存在しない場合
#if DEBUG
            NSLog(@"[TaskName:%@]Didn't create the Note since file does note exist.", self.source.task_name);
#endif
            
        }else{  // 対象ファイルが存在する場合
            // 対象のファイル毎にNoteを作成してフィアルのローテートを実施する
            for(NSString *targetFile in targetFiles){
                
                
                
                // Noteの作成
                EDAMNote *note = [self createEDAMNote:targetFile];

                // Fileの更新時間
                NSDate *fileTimeStamp = [self getFileTimeStamp:targetFile];
                
                // NoteをEvernoteに登録する
                [[EvernoteNoteStore noteStore] createNote:note success:^(EDAMNote *note) {  // 登路に成功した場合
                    NSLog(@"====Registering Note has been succeeded.====");
                    // debug log
                    EvernoteServiceUtil *enService = [[EvernoteServiceUtil alloc]init];
                    [enService debugEDAMNote:note];
                    
                    // update last added time by fileTimeStamp
                    [self updateLastAddedTime:fileTimeStamp];
                    [appDelegate save];
                
                    
                    // ローテート設定の場合、対象ファイルのローテート
                    NSString *movesFile = [self.source getKeyValue:@"movesFile"];
                    if([movesFile intValue] == 1){
                        [self moveFile:targetFile andNow:now];
                    }
                 
                } failure:^(NSError *error) {   // 登録に失敗した場合
                    NSLog(@"Registering Note has been failured.[%@]",error);
                    
                }];
            }
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
    NSString *directoryPath = [[self.source getKeyValue:@"directoryPath"] stringByExpandingTildeInPath];
    NSString *extension = [self.source getKeyValue:@"extension"];

    // 対象のパスのファイル一覧を取得
    NSArray *allFileName = [self getFileNameList];

    // 拡張子で絞り込む
    NSMutableArray *filePathListExcludeExtension = [[NSMutableArray alloc] init];
    
    // 拡張子条件が存在する場合、各ファイルの拡張子が一致するかを確認したうえでフルパスのFileListを生成
    for (NSString *fileName in allFileName) {
        if([extension length] == 0){
            // 拡張子条件が空の場合
            NSString *fullPath = [directoryPath stringByAppendingPathComponent:fileName];
            [filePathListExcludeExtension addObject:fullPath];
        }else if ([self isExistFile:fileName andExtension:extension]) {
            // 拡張子条件が存在する場合
            NSString *fullPath = [directoryPath stringByAppendingPathComponent:fileName];
            [filePathListExcludeExtension addObject:fullPath];
        }
    }
    
    // ファイルローテートしない場合、前回アップロード時間以降に更新されたファイルのみ対象にする
    NSMutableArray *targetFilePathList = [NSMutableArray array];
    int movesFile = [[self.source getKeyValue:@"movesFile"] intValue];
    if(movesFile == 1){    // ローテートする
        targetFilePathList = filePathListExcludeExtension;
    }else{  // ローテートしない
        for(NSString *filePath in filePathListExcludeExtension){
            // 前回処理時間より大きい場合は対象に含める
            NSComparisonResult result = [self compareFileTimeStamp:self.source.last_added_time andFilePath:filePath];
            if(result > 0){
                [targetFilePathList addObject:filePath];
            }
        }
    }

    NSLog(@"%@", targetFilePathList);
    
    return targetFilePathList;
    
}

// 対象のパスのファイル一覧を取得
-(NSArray*)getFileNameList{

    NSFileManager *fileManager=[[NSFileManager alloc] init];
    NSString *directoryPath = [[self.source getKeyValue:@"directoryPath"] stringByExpandingTildeInPath];
    NSError *error = nil;
    
    // 対象ディレクトリのファイルを検索する（ファイル名の一覧）
    NSMutableArray *allFiles = [NSMutableArray array];
    int includeSubDirectory = [[self.source getKeyValue:@"includeSubDirectory"] intValue];
    if(includeSubDirectory == 0){
        // Not Include Sub Directory
        allFiles = [NSMutableArray arrayWithArray:[fileManager contentsOfDirectoryAtPath:directoryPath error:&error]];
        if (error) {
         return nil;
        }
    }else{
        // Include Sub Directory
        NSDirectoryEnumerator *directoryEnumerator = [fileManager enumeratorAtPath:directoryPath];
        for(NSString *fileName in directoryEnumerator){
            [allFiles addObject:fileName];
        }
    }
    
    return allFiles;
}

// 設定されている拡張子と一致するファイルが存在するか
-(BOOL)isExistFile:(NSString*)fileName andExtension:(NSString*)extension{
    BOOL isExist = NO;
    NSString *target = [fileName pathExtension];
    NSArray *params = [extension componentsSeparatedByString:@","];
    for(NSString *param in params){
        if([target isEqualToString:param]){
            isExist = YES;
        }
    }
    return isExist;
}

/*
 * FileTask用のEDAMNoteを作成する
 */
- (EDAMNote*)createEDAMNote:(NSString*)filePath{
    // Note Titleの指定
    NSString *noteTitle;
    if([self.source.note_title length] == 0){
        noteTitle = [filePath lastPathComponent];
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
-(void)moveFile:(NSString*)targetFile andNow:(NSDate*)now{
    // 退避ディレクトリを対象のパスの直下に作成
    NSString *baseDir = [[self.source getKeyValue:@"directoryPath"] stringByExpandingTildeInPath];
    NSString *backupDirName = [now toStringWithFormat:@"yyyyMMdd_HHmmss"];
    NSString *backupPath = [[self.source getKeyValue:@"backupPath"] stringByAppendingPathComponent:backupDirName];
    NSString *toFilePath = [targetFile stringByReplacingOccurrencesOfString:baseDir withString:backupPath]; // 対象のファイルパスを置換してローテート先のパスを作成
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error = nil;
    if(![fileManager createDirectoryAtPath:[toFilePath stringByDeletingLastPathComponent] withIntermediateDirectories:YES attributes:nil error:&error]){
        NSLog(@"Couldn't create the data store directory.[%@, %@]", error, [error userInfo]);
        return;
    }

    // 対象のファイルを移動する
    if(![fileManager moveItemAtPath:targetFile toPath:toFilePath error:&error]){
        NSLog(@"Couldn't move this file:[%@] to this path:[%@].[%@, %@]", targetFile, toFilePath, error, [error userInfo]);
    }else{
        NSLog(@"Finished moving this file:[%@] to this path:[%@].", targetFile, toFilePath);
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
