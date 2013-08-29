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
#import "SafariTaskService.h"

// LOCK OBJECT
BOOL LOAD_ROCK;

// LOCK COUNT
int lockCount;

@implementation TaskForSafari

/*
 * 定期実行で実行される処理
 */
- (void)polling:(NSTimer*)timer{
    // ロック中か確認する
    if(LOAD_ROCK){
        NSLog(@"ROCK![Check Count:%d]", lockCount);
        [NSThread sleepForTimeInterval:5];
        if(lockCount >= 100){
            NSLog(@"Lock Count is over 100. Application will be shutdown.");
            exit(0);
        }
        lockCount++;
        return;
    }
    
    // 実行すべき時間か判定する
    NSDate *now = [NSDate date];
    if([self check:now]){
        // 履歴のURL一覧を取得（前回登録したURLの最新時刻で検索）
        NSArray *hisotryURLs = [self getURLList:self.source.last_added_time];
        
        // 不要な履歴を削除する
        NSArray *targetURLs = [self excludeURLList:hisotryURLs];
        
        // 履歴を昇順にソートする
        targetURLs = [self sortAscByTimestamp:targetURLs];
//        NSLog(@"targetURLs:\r\n%@", targetURLs);
        
        // 対象URLが存在しない場合処理しない
        if([targetURLs count] == 0){
            NSLog(@"[TaskName:%@]Didn't create the Note since web history does note exist.", self.source.task_name);
            return;
        }

        // ロックの取得
        LOAD_ROCK = YES;
        lockCount = 0;
        
        // Queueを初期化
        _serviceQueue = [NSMutableDictionary dictionary];

        // 対象のURL毎にPDFに一旦ページを保存してNoteを作成してフィアルのローテートを実施する
        int count = 0;
        for(NSString *targetURL in targetURLs){
            NSLog(@"Create Queue for %@", targetURL);
            // 1URLに対して1サービスを作成し、Queueに登録
            SafariTaskService *service = [[SafariTaskService alloc]init];
            service.source = self.source;
            [_serviceQueue setObject:service forKey:[[NSNumber alloc]initWithInt:count]];
            service.delegate = self;
            
            // サービスの実行
            [service loadWebHistory:targetURL andQueueId:count];
            
            // インクリメント
            count++;
            
            // ノートの登録時間を更新
            NSString *webHistoryPath = [NSHomeDirectory() stringByAppendingString:@"/Library/Caches/Metadata/Safari/History"];
            NSString *filePath = [NSString stringWithString:[webHistoryPath stringByAppendingPathComponent:targetURL]];
            NSDate *date = [self getFileTimeStamp:filePath];
            [self updateLastAddedTime:date];
            
        }
        
        // タスクの実行時間を更新
        [self updateLastExecuteTime:now];
        
        // 更新したTaskSourceを永続化
        AppDelegate *appDelegate = (AppDelegate*)[[NSApplication sharedApplication] delegate];
        [appDelegate save];
        
    }
}

/*
 * サービスキューを削除し、空になった場合はロックを解除する
 */
-(void)deleteServiceQueue:(int)queueId{
    [_serviceQueue removeObjectForKey:[[NSNumber alloc]initWithInt:queueId]];
    [self statusServiceQueue:nil];
    if ([_serviceQueue count] == 0) {
        LOAD_ROCK = NO; // ロックの解除
    }
}

/*
 * EvernoteServiceUtilのDelegateをセット
 */
-(void)setEvernoteDelegate:(EvernoteServiceUtil*)enService{
    enService.enDelegate = self;
}

/*
 * EvernoteにNoteを登録成功した場合の処理
 */
-(void)afterRegisterNote:(EDAMNote*)note{
    // TODO
}

/*
 * サービスキューの状態を出力
 */
-(void)statusServiceQueue:(id)sender{
    NSLog(@"Service Queue: %@", _serviceQueue);
}


/*
 * 履歴のURL一覧を取得
 */
-(NSArray*)getURLList:(NSDate*)lastExecutedTime{
    // Safariの履歴ディレクトリのファイル一覧を取得
    NSString *directoryPath = [NSHomeDirectory() stringByAppendingString:@"/Library/Caches/Metadata/Safari/History"];
    NSString *extension = @"webhistory";
    NSArray *allFileList = [self getFileList:directoryPath andFileExtension:extension andIncludeSubDirectory:NO];
    
    // 前回時間より新しい履歴が確認する
    NSMutableArray *urlList = [NSMutableArray array];
    for(NSString *fileName in allFileList){
        // 前回処理時間より大きい場合は対象に含める
        NSString *filePath = [NSString stringWithString:[directoryPath stringByAppendingPathComponent:fileName]];
        NSComparisonResult result = [self compareFileTimeStamp:lastExecutedTime andFilePath:filePath];
        if(result > 0){
            [urlList addObject:fileName];
        }
        
    }
    return urlList;
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

// 不要な履歴を削除する
-(NSArray*)excludeURLList:(NSArray*)historyURLs{
    NSMutableArray* targetURLs = [NSMutableArray array];
    for(NSString* url in historyURLs){
        BOOL isTarget = YES;

        // httpを含まないURLは削除
        NSRange range = [url rangeOfString:@"http"];
        if(range.location == NSNotFound){
            isTarget = NO;
        }

        // 1つでもexcludeリストに合致したら削除
        NSMutableArray *excludeList = [NSMutableArray array];
        [excludeList addObject:@"evernote.com"];
        [excludeList addObject:@"google.com"];
        [excludeList addObject:@"facebook.com"];
        [excludeList addObject:@"youtube.com"];
        [excludeList addObject:@"github.com"];
        [excludeList addObject:@"gistboxapp.com"];
        [excludeList addObject:@"wri.pe"];
        [excludeList addObject:@"dailymotion.com"];

        for(NSString *str in excludeList){
            NSRange range = [url rangeOfString:str];
            if(range.location != NSNotFound){
                isTarget = NO;
            }
        }

        // 対象ならリストに追加
        if(isTarget){
            [targetURLs addObject:url];
        }
    }
    return targetURLs;
    
}

// ファイルのタイムスタンプでソート
-(NSArray*)sortAscByTimestamp:(NSArray*)array{
    NSMutableArray *attributes = [NSMutableArray array];
    NSString *directoryPath = [NSHomeDirectory() stringByAppendingString:@"/Library/Caches/Metadata/Safari/History"];
    NSError *error = nil;
    for(NSString *fileName in array){
        NSMutableDictionary *tmpDictionary = [NSMutableDictionary dictionary];
        NSString *filePath = [directoryPath stringByAppendingPathComponent:fileName];
        NSDictionary *attr = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:&error];
        [tmpDictionary setDictionary:attr];
        [tmpDictionary setObject:fileName forKey:@"FileName"];
        [tmpDictionary setObject:filePath forKey:@"FilePath"];
        [attributes addObject:tmpDictionary];
    }
    // ソート
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:NSFileCreationDate ascending:YES];
    NSArray *sortarray = [NSArray arrayWithObject:sortDescriptor];
    
    // 並び替えられたファイル配列
    NSArray *resultarray = [attributes sortedArrayUsingDescriptors:sortarray];
    NSMutableArray *arrays = [NSMutableArray array];
    for(NSDictionary *dic in resultarray){
        [arrays addObject:[dic objectForKey:@"FileName"]];
    }
    return arrays;
}

@end
