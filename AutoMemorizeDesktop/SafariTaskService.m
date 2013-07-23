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
 * 描画に成功した場合の処理（PDFに保存しNoteを作成する
 */
- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame {
    NSLog(@"finish");
    if ([sender mainFrame] == frame) {
        NSLog(@"didFinishLoadForFrame");
        [self saveWebPageToPDF];
        AppDelegate *appDelegate = (AppDelegate*)[[NSApplication sharedApplication] delegate];
        [appDelegate deleteServiceQueue:_serviceQueueId];
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
-(void)saveWebPageToPDF{
    NSLog(@"start save web pdf.");
    [_webView setMediaStyle:@"screen"];
    NSView* view = [[[_webView mainFrame] frameView] documentView];
    NSRect rectForPDF = [view bounds];
    NSData* outdata = [view dataWithPDFInsideRect:rectForPDF];
    NSString *pdfName = [NSString stringWithFormat:@"%d.pdf", _serviceQueueId];
    NSString* path = [NSString stringWithFormat:@"/Users/AirMyac/Desktop/%@", pdfName];
    [outdata writeToFile:path atomically:YES];
    
}


@end
