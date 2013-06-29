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
//    NSColor *backColor = [NSColor colorWithCalibratedRed:0.20392157 green:0.28627451 blue:0.36862745 alpha:0.99];
    NSString *hex = @"#F1EEFB";
//    NSString *hex = @"#DFE6F6";
    NSColor *backColor = [NSColor colorFromHexadecimalValue:hex];
//    [backColor set];
//    NSRectFill(rect);
    
    // 文字描画
    hex = @"#052776";
    NSColor *charColor = [NSColor colorFromHexadecimalValue:hex];
    NSMutableAttributedString *attributedString =
    [[NSMutableAttributedString alloc] initWithAttributedString:[self attributedStringValue]];

    NSDictionary* attributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                charColor, NSForegroundColorAttributeName,
                                [NSFont boldSystemFontOfSize:14.0], NSFontAttributeName,
                                nil];
//    [attributedString addAttributes:attributes range:NSMakeRange(0, [attributedString length])];
    [attributedString setAttributes:attributes range:NSMakeRange(0, [attributedString length])];
    rect.origin.y += 3;   // Y位置を調整（中央寄せになるように）
    [attributedString drawInRect:rect];
}

#pragma mark -
#pragma mark Overridden methods (NSCell)
- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
    [self _drawInRect:cellFrame];
}

@end
