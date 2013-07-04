//
//  SelectDataSourceView.m
//  RecDesktop
//
//  Created by AirMyac on 7/2/13.
//  Copyright (c) 2013 com.katzlifehack. All rights reserved.
//

#import "SelectDataSourceView.h"

@interface SelectDataSourceView ()

@end

@implementation SelectDataSourceView

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

-(int)getDataSource{
    return (int)[_dataSourceComboBox indexOfSelectedItem];
    
}

/*
 * 初期化
 */
-(void)initilize{
    NSString *imagePath;
    NSImage *image;
    imagePath = [[NSBundle mainBundle] pathForResource:@"Status" ofType:@"psd"];
    image= [[NSImage alloc]initByReferencingFile:imagePath];
    [_skypeBtn setImage:image];
    [_skypeBtn setBordered:NO];
    
    imagePath = [[NSBundle mainBundle] pathForResource:@"Status" ofType:@"psd"];
    image= [[NSImage alloc]initByReferencingFile:imagePath];
    [_pdfBtn setImage:image];
    [_pdfBtn setBordered:NO];

    imagePath = [[NSBundle mainBundle] pathForResource:@"Status" ofType:@"psd"];
    image= [[NSImage alloc]initByReferencingFile:imagePath];
    [_excelBtn setImage:image];
    [_excelBtn setBordered:NO];

    imagePath = [[NSBundle mainBundle] pathForResource:@"Status" ofType:@"psd"];
    image= [[NSImage alloc]initByReferencingFile:imagePath];
    [_markdownBtn setImage:image];
    [_markdownBtn setBordered:NO];

    
}


@end
