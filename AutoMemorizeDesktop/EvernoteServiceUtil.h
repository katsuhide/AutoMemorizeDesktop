//
//  EvernoteService.h
//  RecDesktop
//
//  Created by AirMyac on 7/24/13.
//  Copyright (c) 2013 com.katzlifehack. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <EvernoteSDK-Mac/EvernoteSDK.h>
#import "NSData+EvernoteSDK.h"

// デリゲートを定義
@protocol EvernoteDelegate <NSObject>

-(void)afterRegisterNote:(EDAMNote*)note;

@end

@interface EvernoteServiceUtil : NSObject

@property (nonatomic, assign) id<EvernoteDelegate> enDelegate;

// イニシャライザ
- (id)init;

/*
 * 指定された条件でEDAMNoteを作成する
 */
-(EDAMNote*)createEDAMNote:(NSDictionary*)condition;

/*
 * EvernoteにNOTEを新規保存する処理を実行する
 */
-(void)registerNote:(EDAMNote*)note;

@end
