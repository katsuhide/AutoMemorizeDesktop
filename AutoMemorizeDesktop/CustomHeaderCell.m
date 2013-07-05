//
//  CustomHeaderCell.m
//  RecDesktop
//
//  Created by AirMyac on 6/30/13.
//  Copyright (c) 2013 com.katzlifehack. All rights reserved.
//

#import "CustomHeaderCell.h"
#import "NSColor+Hex.h"

@implementation CustomHeaderCell

- (void)_drawInRect:(NSRect)rect
{
    // 背景描画
    NSString *hex = [self getHex:_colorFlag];
    
    NSColor *backColor = [NSColor colorFromHexadecimalValue:hex];
    [backColor set];
    NSRectFill(rect);
    
    // 文字描画
    hex = @"#FFFFFF";
    NSColor *charColor = [NSColor colorFromHexadecimalValue:hex];
    NSMutableAttributedString *attributedString =
    [[NSMutableAttributedString alloc] initWithAttributedString:[self attributedStringValue]];

    NSDictionary* attributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                charColor, NSForegroundColorAttributeName,
                                [NSFont boldSystemFontOfSize:14.0], NSFontAttributeName,
                                nil];
    [attributedString setAttributes:attributes range:NSMakeRange(0, [attributedString length])];
    
//    rect.origin.y += 3;   // Y位置を調整（中央寄せになるように）
    [attributedString drawInRect:rect];
}

#pragma mark -
#pragma mark Overridden methods (NSCell)
- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
    [self _drawInRect:cellFrame];
}

-(void)changeBackColor:(int)num{
    _colorFlag = [NSNumber numberWithInt:num];

    NSString *hex = @"#f6d965";
    NSColor *backColor = [NSColor colorFromHexadecimalValue:hex];
    [backColor set];
}

-(NSString*)getHex:(NSNumber*)num{
    NSString *hex;
//    int flag = [num intValue];
//    switch (flag) {
//        case 0:
//            hex = @"#5cb6ff";   // light blue
//            break;
//        case 1:
//            hex = @"#9be8c5";   // light green
//            break;
//        case 2:
//            hex = @"#ed7a6e";   // light red
//            break;
//        case 3:
//            hex = @"#f6d965";   // light orange
//            break;
//        case 4:
//            hex = @"#4f73cf";   // light drak blue
//            break;
//        default:
//            hex = @"#ecf0f1";   // cloud
//            break;
//    }
    hex = @"#bdc3c7";   // Silver
    return hex;
}

@end
