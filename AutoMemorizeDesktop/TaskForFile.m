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

int fileTaskQueue = 0;

@implementation TaskForFile

/*
 * 定期実行で実行される処理
 */
- (void)polling:(NSTimer*)timer{
    NSDate *now = [NSDate date];
    if([self check:now]){

        AppDelegate *appDelegate = (AppDelegate*)[[NSApplication sharedApplication] delegate];

        // Queueが残っている場合は処理をスキップする
        if(fileTaskQueue > 0){
#if DEBUG
            NSLog(@"[%@]File Task Queue has been remained.", self.source.task_name);
#endif
            
        }else{
            
            // 対象に合致するファイルのフルパス一覧を取得
            NSArray *targetFiles = [self getFilePathList];
            
            if([targetFiles count] == 0){   // 対象のファイルが存在しない場合
#if DEBUG
                NSLog(@"[TaskName:%@]Didn't create the Note since file does note exist.", self.source.task_name);
#endif
                
            }else{  // 対象ファイルが存在する場合
                // Queueを設定
                fileTaskQueue = (int)[targetFiles count];

                // 対象のファイル毎にNoteを作成してフィアルのローテートを実施する
                for(NSString *targetFile in targetFiles){
                    
                    // 追記するタイプか確認する
                    NSString* str = [self.source getKeyValue:@"movesFile"];
                    int movesFile = [str intValue];
                    if((str == nil) || (movesFile == 1)){   // ver2.0以前はnilのため
                        // 新規更新する
                        [self registerEDAMNote:targetFile];
                        
                    }else{
                        // 検索して追記する
                        [self searchAndUpdateEDAMNote:targetFile];
                        
                    }
                }
            }
        }

        // タスクの実行時間を更新
        [self updateLastExecuteTime:now];
        
        // 更新したTaskSourceを永続化
        [appDelegate save];
        
    }
}


/*
 * ノートを新規作成する
 */
-(void)registerEDAMNote:(NSString*)filePath{
    // Noteの作成
    EDAMNote *note = [self createEDAMNote:filePath];
    
    // NoteをEvernoteに登録する
    [[EvernoteNoteStore noteStore] createNote:note success:^(EDAMNote *note) {  // 登路に成功した場合
        NSLog(@"====Registering Note has been succeeded.====\n%@", note);
        
        // update last added time by fileTimeStamp
        NSDate *fileTimeStamp = [self getFileTimeStamp:filePath];
        [self updateLastAddedTime:fileTimeStamp];
        AppDelegate *appDelegate = (AppDelegate*)[[NSApplication sharedApplication] delegate];
        [appDelegate save];
        
        
        // ローテート設定の場合、対象ファイルのローテート
        NSString* str = [self.source getKeyValue:@"movesFile"];
        int movesFile = [str intValue];
        if((str == nil) || (movesFile == 1)){   // ver2.0以前はnilのため
            [self moveFile:filePath andNow:[NSDate date]];
        }
        
        // Queueの削除
        fileTaskQueue--;
        
    } failure:^(NSError *error) {   // 登録に失敗した場合
        NSLog(@"Registering Note has been failured.[%@]",error);
        
        // Queueの削除(次の処理で再実行するからQueueは削除する)
        fileTaskQueue--;
        
    }];
    
}

/*
 * 既存ノートを検索して追記する
 */
-(void)searchAndUpdateEDAMNote:(NSString*)filePath{
    // 検索条件を設定する
    EDAMNoteFilter *filter = [[EDAMNoteFilter alloc]init];
    NSString *fileName = [filePath lastPathComponent];
    NSString *keyword = fileName;     // ファイル名で検索する
    [filter setWords:keyword];
    
    // Create NotesMetadataResultSpec
    EDAMNotesMetadataResultSpec *resultSpec = [[EDAMNotesMetadataResultSpec alloc]init];
    [resultSpec setIncludeTitle:YES];
    [resultSpec setIncludeNotebookGuid:YES];
    [resultSpec setIncludeTagGuids:YES];
    [resultSpec setIncludeCreated:YES];
    [resultSpec setIncludeUpdated:YES];
    
    // ノートを検索する
    [[EvernoteNoteStore noteStore] findNotesMetadataWithFilter:filter offset:0 maxNotes:1 resultSpec:resultSpec success:^(EDAMNotesMetadataList *metadata) {
        if([[metadata notes] count] != 0){
            // EDAMNoteの作成
            EDAMNote *note = [self createEDAMNote:filePath];
            
            // guidの設定
            NSString *guid = [[[metadata notes] objectAtIndex:0] guid];
            note.guid = guid;
            
            // ノートの更新
            [[EvernoteNoteStore noteStore] updateNote:note success:^(EDAMNote *note) {
                NSLog(@"====Updating Note has been succeeded.====\n%@", note);
                
                // update last added time by fileTimeStamp
                NSDate *fileTimeStamp = [self getFileTimeStamp:filePath];
                [self updateLastAddedTime:fileTimeStamp];
                AppDelegate *appDelegate = (AppDelegate*)[[NSApplication sharedApplication] delegate];
                [appDelegate save];

                fileTaskQueue--;
                
            } failure:^(NSError *error) {
                NSLog(@"Updating Note has been failured.");
                // 新規Note作成
                [self registerEDAMNote:filePath];
                
            }];
            
        }else{
            NSLog(@"No Note with the specified file name has been found.");
            // 新規Note作成
            [self registerEDAMNote:filePath];
            
        }
        
    } failure:^(NSError *error) {
        NSLog(@"Find NoteMetadata has been failured.[%@]", error);
        // 新規Note作成
        [self registerEDAMNote:filePath];
        
    }];

    
}


/*
 * 指定された条件でEvernoteへのポスト対象のファイルのフルパスを取得する
 */
-(NSMutableArray*)getFilePathList{
    // 指定された条件を取得
    NSString *directoryPath = [[self.source getKeyValue:@"file_path"] stringByExpandingTildeInPath];
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
    NSMutableArray *filePathListFromLastAddedTime = [NSMutableArray array];
    int movesFile = [[self.source getKeyValue:@"movesFile"] intValue];
    if(movesFile == 1){    // ローテートする
        filePathListFromLastAddedTime = filePathListExcludeExtension;
    }else{  // ローテートしない
        for(NSString *filePath in filePathListExcludeExtension){
            // 前回処理時間より大きい場合は対象に含める
            NSComparisonResult result = [self compareFileTimeStamp:self.source.last_added_time andFilePath:filePath];
            if(result > 0){
                [filePathListFromLastAddedTime addObject:filePath];
            }
        }
    }
    
    // 更新時間で昇順ソート
    NSError *error = nil;
    NSMutableArray *attributes = [NSMutableArray array];
    for(NSString *filePath in filePathListFromLastAddedTime){
        NSMutableDictionary *tmpDictionary = [NSMutableDictionary dictionary];
        NSDictionary *attr = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:&error];
        [tmpDictionary setDictionary:attr];
        [tmpDictionary setObject:filePath forKey:@"filePath"];
        [attributes addObject:tmpDictionary];
    }
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:NSFileModificationDate ascending:YES];
    NSArray *sortarray = [NSArray arrayWithObject:sortDescriptor];
    NSArray *resultArray = [attributes sortedArrayUsingDescriptors:sortarray];
    
    // ファイルのフルパスだけ抜き出す
    NSMutableArray *targetFilePathList = [NSMutableArray array];
    for(NSDictionary *dic in resultArray){
        [targetFilePathList addObject:[dic objectForKey:@"filePath"]];
    }
    
    
#if DEBUG
    NSLog(@"%@", targetFilePathList);
#endif
    
    return targetFilePathList;
    
}

// 対象のパスのファイル一覧を取得
-(NSArray*)getFileNameList{

    NSFileManager *fileManager=[[NSFileManager alloc] init];
    NSString *directoryPath = [[self.source getKeyValue:@"file_path"] stringByExpandingTildeInPath];
    NSError *error = nil;
    
    // 対象ディレクトリのファイルを検索する（ファイル名の一覧）
    NSMutableArray *allFiles = [NSMutableArray array];
    int includeSubDirectory = [[self.source getKeyValue:@"search"] intValue];
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
    
    // NOTEを登録
    EDAMNote* note = [[EDAMNote alloc] initWithGuid:nil title:noteTitle content:noteContent contentHash:nil contentLength:(int)noteContent.length created:0 updated:0 deleted:0 active:YES updateSequenceNum:0 notebookGuid:notebookGUID tagGuids:nil resources:resources attributes:nil tagNames:tagNames];
    
    return note;
    
}

/*
 * 対象のファイルを移動する
 */
-(void)moveFile:(NSString*)targetFile andNow:(NSDate*)now{
    // 退避ディレクトリを対象のパスの直下に作成
    NSString *baseDir = [[self.source getKeyValue:@"file_path"] stringByExpandingTildeInPath];
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
