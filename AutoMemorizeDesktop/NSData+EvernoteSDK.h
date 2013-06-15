//
//  NSData+EvernoteSDK.h
//  AutoMemorizeDesktop
//
//  Created by AirMyac on 6/16/13.
//  Copyright (c) 2013 com.katzlifehack. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSData (EvernoteSDK)

/** MD5 hash of the receiver
 
 @returns The MD5 hash
 */
- (NSData *) enmd5;

/** hex representation of data (used in ENML media)
 
 @returns The hex representation in lower case
 */
- (NSString *) enlowercaseHexDigits;

+ (NSData *) endataWithHexDigits: (NSString *) hexDigits;

@end
