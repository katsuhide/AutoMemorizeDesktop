//
//  CustomTableView.m
//  RecDesktop
//
//  Created by AirMyac on 6/30/13.
//  Copyright (c) 2013 com.katzlifehack. All rights reserved.
//

#import "CustomTableView.h"
#import "CustomHeaderCell.h"

@implementation CustomTableView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)drawRect:(NSRect)dirtyRect
{
    // Drawing code here.
}

- (void)_setupHeaderCell
{
    for (NSTableColumn* column in [self tableColumns]) {
        NSTableHeaderCell *cell = [column headerCell];
        CustomHeaderCell *newCell = [[CustomHeaderCell alloc] init];
        [newCell setAttributedStringValue:[cell attributedStringValue]];
        [column setHeaderCell:newCell];
    }
    
}


- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    
    if (self) {
        [self _setupHeaderCell];
    }
    return self;
}

@end
