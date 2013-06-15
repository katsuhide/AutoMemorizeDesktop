//
//  NSData+EvernoteSDK.m
//  AutoMemorizeDesktop
//
//  Created by AirMyac on 6/16/13.
//  Copyright (c) 2013 com.katzlifehack. All rights reserved.
//

#import "NSData+EvernoteSDK.h"
#import <CommonCrypto/CommonCrypto.h>

@implementation NSData (EvernoteSDK)

- (NSData *) enmd5
{
    unsigned char md5Buffer[CC_MD5_DIGEST_LENGTH];
    CC_MD5(self.bytes, (CC_LONG)self.length, md5Buffer);
    NSMutableData * md5Data = [NSMutableData dataWithBytes:md5Buffer length: CC_MD5_DIGEST_LENGTH];
    return md5Data;
}

- (NSString *) enlowercaseHexDigits
{
    unsigned const char * bytes = [self bytes];
    
    NSMutableString * hex = [NSMutableString stringWithCapacity: [self length] * 2];
    
    NSUInteger i;
    for (i = 0; i < [self length]; i++) {
        [hex appendFormat: @"%.2x", bytes[i]];
    }
    
    return hex;
}

+ (NSData *) endataWithHexDigits: (NSString *) hexDigits
{
    if (!hexDigits) {
        return nil;
    }
    if ([hexDigits length] % 2 != 0) {
        return nil;
    }
    
    NSMutableData * data = [NSMutableData dataWithLength: [hexDigits length] / 2];
    
    const char * sourceBytes = [hexDigits cStringUsingEncoding: NSASCIIStringEncoding];
    unsigned char * bytes = [data mutableBytes];
    
    const char * pos = sourceBytes;
    for (NSUInteger count = 0; count < [hexDigits length] / 2; count++) {
        sscanf(pos, "%2hhx", &bytes[count]);
        pos += 2;
    }
    
	return [NSData dataWithData:data];
}

@end
