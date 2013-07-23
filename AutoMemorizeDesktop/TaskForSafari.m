//
//  TaskForSafari.m
//  RecDesktop
//
//  Created by AirMyac on 7/19/13.
//  Copyright (c) 2013 com.katzlifehack. All rights reserved.
//

#import "TaskForSafari.h"
#import "AppDelegate.h"
#import "NSData+EvernoteSDK.h"

// LOCK OBJECT
BOOL LOAD_ROCK;

@implementation TaskForSafari

/*
 * 定期実行で実行される処理
 */
- (void)polling:(NSTimer*)timer{
    NSDate *now = [NSDate date];
    
    NSLog(@"check");
    if(LOAD_ROCK){
        return;
    }
    
    // 実行すべき時間か判定する
//    if([self check:now]){
        if(YES){    //TODO
            
        NSLog(@"check true");
        
        // 履歴のURL一覧を取得
        NSDate *lastExecutedTime = self.source.last_added_time;
        NSArray *targetURLs = [self getURLList:lastExecutedTime];
        
        // 対象URLが存在しない場合処理しない
        if([targetURLs count] == 0){
            NSLog(@"[TaskName:%@]Didn't create the Note since web history does note exist.", self.source.task_name);
            return;
        }
        
        // 対象のURL毎にPDFに一旦ページを保存してNoteを作成してフィアルのローテートを実施する
        AppDelegate *appDelegate = (AppDelegate*)[[NSApplication sharedApplication] delegate];
        for(NSString *targetURL in targetURLs){

            NSLog(@"file loop");
            
            // ロックのチェック
            if(LOAD_ROCK){
                NSLog(@"start of file loop");
                [NSThread sleepForTimeInterval:5];
            }

            // ロックを取得
            LOAD_ROCK = YES;
            [NSThread sleepForTimeInterval:5];  // 念のため少し待つ　TODO PDFNoteを作成するまで待つならplistにロックを定義すべき？

            // URLのページをPDFに一時的に保存
            [self loadWebHistory:targetURL];
            
            // Noteの作成
//            NSString *targetFilePath = nil;
//            EDAMNote *note = [self createEDAMNote:targetFilePath andURL:(NSString*)targetURL];
            
            // Noteの登録
//            [appDelegate doAddNote:note];
            
            // ノートの登録時間を更新
            NSDate *date = [self getFileTimeStamp:targetURL andDirectoryPath:@"/Users/AirMyac/Library/Caches/Metadata/Safari/History"];
            [self updateLastAddedTime:date];
            
            break;
            // 対象ファイルを削除
            
        }
        
        // タスクの実行時間を更新
        [self updateLastExecuteTime:now];
        
        // 更新したTaskSourceを永続化
//        [appDelegate save];
        
    }
}

/*
 * 指定されたURLのWebページをPDFファイルに保存してそのパスを返す
 */
-(void)loadWebHistory:(NSString*)targetURL{
    
//    // TODO
//    while (LOAD_ROCK) {
//        NSLog(@"sleep");
//        [NSThread sleepForTimeInterval:5];
//    }
//    // ロックを取得
//    LOAD_ROCK = YES;
    
    
    // URLをデコードする
    NSString *temp = [self decode:targetURL];
    
    // 拡張子を除外してURLにする
    NSLog(@"%@", temp);
    NSString *urlString = [temp stringByReplacingOccurrencesOfString:@".webhistory" withString:@""];
    NSLog(@"%@", urlString);
    
    // 指定されたURLを開く
    NSRect rect = NSMakeRect(-1000, -10000, 100, 100);
    _webView = [[WebView alloc] initWithFrame:rect];
    
    [[[_webView mainFrame] frameView] setAllowsScrolling:NO];
    
    NSURL *url = [NSURL URLWithString:urlString];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    [_webView setFrameLoadDelegate:self];
    [[_webView mainFrame] loadRequest:request];
    
}

/*
 * 描画に成功した場合の処理（PDFに保存しNoteを作成する
 */
- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame {
    NSLog(@"finish");
    if ([sender mainFrame] == frame) {
        NSLog(@"didFinishLoadForFrame");
        [self saveWebPageToPDF];
        LOAD_ROCK = NO;
    }
}

/*
 * 描画に失敗した場合の処理（何もしないで次のURLへ処理を回す）
 */
- (void)webView:(WebView *)sender didFailLoadWithError:(NSError *)error forFrame:(WebFrame *)frame{
    NSLog(@"[TaskName:%@]Failed to draw this page.[%@]", self.source.task_name, error);
}




// デコード
-(NSString*)decode:(NSString*)string{
    NSString *decodedString = (NSString*)CFBridgingRelease(CFURLCreateStringByReplacingPercentEscapesUsingEncoding(kCFAllocatorDefault, (CFStringRef)string, CFSTR(""), kCFStringEncodingUTF8));
    return decodedString;
    
}


/*
 * 履歴のURL一覧を取得
 */
-(NSArray*)getURLList:(NSDate*)lastExecutedTime{
    
    // Safariの履歴ディレクトリのファイル一覧を取得
    NSString *directoryPath = @"/Users/AirMyac/Library/Caches/Metadata/Safari/History";
    NSString *extension = @"webhistory";
    NSArray *allFileList = [self getFileList:directoryPath andFileExtension:extension andIncludeSubDirectory:NO];
    
    // 前回時間より新しい履歴が確認する
    NSMutableArray *urlList = [NSMutableArray array];
    for(NSString *fileName in allFileList){
        // 前回処理時間より大きい場合は対象に含める
        NSComparisonResult result = [self compareFileTimeStamp:lastExecutedTime andFilePath:fileName andDirectoryPath:directoryPath];
        if(result > 0){
            [urlList addObject:fileName];
        }
        
    }
    
    return urlList;
    
}

/*
 * 指定したファイルと指定した時間の比較を実施
 */
-(NSComparisonResult)compareFileTimeStamp:(NSDate*)lastExecutedTime andFilePath:(NSString*)fileName andDirectoryPath:(NSString*)directoryPath{
    // ファイルのタイムスタンプを取得
    NSError *error = nil;
    NSString *filePath = [NSString stringWithString:[directoryPath stringByAppendingPathComponent:fileName]];
    NSDictionary* dicFileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:&error];
    if (error) {
        return -1;
    }

    // 比較
    NSDate *fileTimeStamp = [dicFileAttributes objectForKey:@"NSFileModificationDate"];
    NSLog(@"file:%@, target:%@", [fileTimeStamp toLocalTime], [lastExecutedTime toLocalTime]);
    NSComparisonResult result = [fileTimeStamp compare:lastExecutedTime];
    return result;
    
}

/*
 * 指定したファイルの時間を取得
 */
-(NSDate*)getFileTimeStamp:(NSString*)fileName andDirectoryPath:(NSString*)directoryPath{
    NSError *error = nil;
    NSString *filePath = [NSString stringWithString:[directoryPath stringByAppendingPathComponent:fileName]];
    NSDictionary* dicFileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:&error];
    return [dicFileAttributes objectForKey:@"NSFileModificationDate"];
}


/*
 * 指定された条件でファイルを検索し、ファイル名を返す
 * 検索条件：対象のディレクトリ、対象ファイルの拡張子、サブディレクトリを検索対象に含めるか
 */
-(NSArray*)getFileList:(NSString*)directoryPath andFileExtension:(NSString*)fileExtension andIncludeSubDirectory:(BOOL)includeSubDirectory{
    
    NSFileManager *fileManager=[[NSFileManager alloc] init];
    NSError *error = nil;
    
    NSMutableArray *allFileList = [NSMutableArray array];
    NSMutableArray *targetFileList = [NSMutableArray array];
    // 指定したディレクトリのファイルを取得
    if(includeSubDirectory){
        // Include Sub Directory
        NSDirectoryEnumerator *directoryEnumerator = [fileManager enumeratorAtPath:directoryPath];
        for(NSString *filePath in directoryEnumerator){
            [allFileList addObject:filePath];
        }
    }else{
        // Not Include Sub Directory
        NSArray *result = [fileManager contentsOfDirectoryAtPath:directoryPath error:&error];
        if (error) {
            return nil;
        }else{
            [allFileList addObjectsFromArray:result];
        }
    }
    
    // 指定した拡張子のファイルを絞り込む
    for(NSString *fileName in allFileList){
        if([self isExistFile:fileName andExtension:fileExtension]){
            [targetFileList addObject:fileName];
        }
    }
    
    return targetFileList;
    
}

// 設定されている拡張子と一致するファイルが存在するか
-(BOOL)isExistFile:(NSString*)fileName andExtension:(NSString*)extension{
    
    // 拡張子が指定されていない場合は常にTUREを返す
    if([extension length] == 0){
        return YES;
    }
    
    // 拡張子が指定されている場合は検査する
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
- (EDAMNote*)createEDAMNote:(NSString*)filePath andURL:(NSString*)targetURL{
    // Note Titleの指定
    NSString *noteTitle;
    if([self.source.note_title length] == 0){
        noteTitle = targetURL;
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
 * 対象のファイルを削除する
 */
-(void)deleteFile:(NSString*)targetFile{
    
    
    
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

-(void)saveWebPageToPDF{

    NSLog(@"load web page");
    
    [_webView setMediaStyle:@"screen"];
    NSView* view = [[[_webView mainFrame] frameView] documentView];
    NSRect rectForPDF = [view bounds];
    NSData* outdata = [view dataWithPDFInsideRect:rectForPDF];
    NSString* path = @"/Users/AirMyac/Desktop/normal.pdf";
    [outdata writeToFile:path atomically:YES];
    
}

@end
