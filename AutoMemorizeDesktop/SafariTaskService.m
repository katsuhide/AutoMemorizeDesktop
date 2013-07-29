//
//  SafariTaskService.m
//  RecDesktop
//
//  Created by AirMyac on 7/24/13.
//  Copyright (c) 2013 com.katzlifehack. All rights reserved.
//

#import "SafariTaskService.h"
#import "AppDelegate.h"

@implementation SafariTaskService

@synthesize delegate;

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
 * 指定されたURLのページを描画する
 */
-(void)loadWebHistory:(NSString*)targetURL andQueueId:(int)queueId{
    
    _serviceQueueId = queueId;
    
    // URLをデコードする
    NSString *temp = [self decode:targetURL];
    
    // 拡張子を除外してURLにする
    NSString *urlString = [temp stringByReplacingOccurrencesOfString:@".webhistory" withString:@""];
    
    // 指定されたURLを開く
    NSRect rect = NSMakeRect(-1000, -1000, 1000, 100);
    _webView = [[WebView alloc] initWithFrame:rect];
    
    [[[_webView mainFrame] frameView] setAllowsScrolling:NO];
    
    NSURL *url = [NSURL URLWithString:urlString];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    [_webView setFrameLoadDelegate:self];
    [[_webView mainFrame] loadRequest:request];
    
}

/*
 * 描画に成功した場合の処理（PDFに保存しNoteを作成する）
 */
- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame {
    if ([sender mainFrame] == frame) {
        NSLog(@"Finish Load.");
        
        // PDFファイルを作成
        NSDictionary *condition = [self saveWebPageToPDF];
        
        // サービスキューの削除
        if ([self.delegate respondsToSelector:@selector(deleteServiceQueue:)]) {
            [self.delegate deleteServiceQueue:_serviceQueueId];
        }

        // 作成したPDFを元にEDAMNoteを作成する
        EvernoteServiceUtil *enService = [[EvernoteServiceUtil alloc]init];
        EDAMNote *note = [enService createEDAMNote:condition];
        NSLog(@"EDAMNote has created.");
  
        // EvernoteServiceUtilのdelegateにTaskForSafariをセットする
//        if ([self.delegate respondsToSelector:@selector(setEvernoteDelegate:)]) {
//            [self.delegate setEvernoteDelegate:enService];
//        }
        
        // PDFファイルを削除する
        NSFileManager *fileManager=[[NSFileManager alloc] init];
        NSError *error = nil;
        NSString *filePath = [condition objectForKey:@"filePath"];
        [fileManager removeItemAtPath:filePath error:&error];
        NSLog(@"file delete.[%@]", filePath);
        
        // EDAMNOTEをENにuploadする
        [enService registerNote:note];
        
    }
}


/*
 * 描画に失敗した場合の処理（何もしないで次のURLへ処理を回す）
 */
- (void)webView:(WebView *)sender didFailLoadWithError:(NSError *)error forFrame:(WebFrame *)frame{
    NSLog(@"[TaskName:%@]Failed to draw this page.[%@]", @"hogehoge", error);
}


// デコード
-(NSString*)decode:(NSString*)string{
    NSString *decodedString = (NSString*)CFBridgingRelease(CFURLCreateStringByReplacingPercentEscapesUsingEncoding(kCFAllocatorDefault, (CFStringRef)string, CFSTR(""), kCFStringEncodingUTF8));
    return decodedString;
    
}

// viewをpdfに保存する
-(NSDictionary*)saveWebPageToPDF{
    // ViewをPDFに保存
    [_webView setMediaStyle:@"screen"];
    NSView* view = [[[_webView mainFrame] frameView] documentView];
    NSRect rectForPDF = [view bounds];
    NSData* outdata = [view dataWithPDFInsideRect:rectForPDF];
    NSString *pdfName = [NSString stringWithFormat:@"%d.pdf", _serviceQueueId];
    NSURL *applicationFilesDirectory = [self applicationFilesDirectory];
    NSString *path = [[[applicationFilesDirectory path] stringByAppendingPathComponent:pdfName] stringByExpandingTildeInPath];
    [outdata writeToFile:path atomically:YES];
    NSLog(@"Finished saving pdf file.[%@]", pdfName);
    
    // EDAMNoteを作成するための情報をセット
    NSMutableDictionary *condition = [NSMutableDictionary dictionary];

    // Note Titleの指定
    NSString *title = [_webView mainFrameTitle];
    if([self.source.note_title length] == 0){
        // NoteTitleが指定されていない場合、ページタイトルをセット
        title = [_webView mainFrameTitle];
    }else{
        // NoteTitleが指定されている場合はそちらを優先
        title = self.source.note_title;
    }
    [condition setObject:title forKey:@"noteTitle"];
    
    // tagの指定
    NSMutableArray *tagNames = [NSMutableArray arrayWithArray:[self.source splitTags]];
    [condition setObject:tagNames forKey:@"tagNames"];
    
    // Notebookの指定
    NSString *notebookGUID = self.source.notebook_guid;
    [condition setObject:notebookGUID forKey:@"notebookGUID"];
    
    // body情報の指定
    NSString *url = [_webView mainFrameURL];
    [condition setObject:url forKey:@"body"];
    [condition setObject:path forKey:@"filePath"];
    
    return condition;
}

- (NSURL *)applicationFilesDirectory
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *appSupportURL = [[fileManager URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask] lastObject];
    return [appSupportURL URLByAppendingPathComponent:APP_NAME];
}


@end
