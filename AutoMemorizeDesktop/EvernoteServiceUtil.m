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
    
    return note;
}

// デバッグ用メソッド
-(void)debugEDAMNote:(EDAMNote*)note{
    NSLog(@"EDAMNote:NoteTitle:%@", note.title);
    NSLog(@"EDAMNote:Tags:%@", note.tagNames);
    NSLog(@"EDAMNote:Note Content:%@", note.content);
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

/*
 * EvernoteにNOTEを新規保存する処理を実行する
 */
-(void)registerNote:(EDAMNote*)note{
    // 作成されたEDAMNoteを登録する
    [[EvernoteNoteStore noteStore] createNote:note success:^(EDAMNote *note) {
        // Log the created note object
        NSLog(@"Note created.=====");
        [self debugEDAMNote:note];
        
        // 後処理
//        if([self.enDelegate respondsToSelector:@selector(afterRegisterNote:)]){
//            [self.enDelegate afterRegisterNote:note];
//        }
        
    } failure:^(NSError *error) {
        // Something was wrong with the note data
        // See EDAMErrorCode enumeration for error code explanation
        // http://dev.evernote.com/documentation/reference/Errors.html#Enum_EDAMErrorCode
        NSLog(@"Error : %@",error);
    }];

}




@end
