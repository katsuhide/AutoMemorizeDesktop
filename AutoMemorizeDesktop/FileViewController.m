//
//  FileViewController.m
//  AutoMemorizeDesktop
//
//  Created by AirMyac on 6/15/13.
//  Copyright (c) 2013 com.katzlifehack. All rights reserved.
//

#import "FileViewController.h"

@interface FileViewController ()

@end

@implementation FileViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

-(NSString*)getTargetFilePathField{
    return [_targetFilePathField stringValue];
}

-(NSString*)getFileExtensionField{
    return [_fileExtensionField stringValue];
}

-(NSMutableString*)getParams{
    NSMutableString *params = [NSMutableString string];
    [params appendString:[self transformKeyValue:@"file_path" andValue:[self getTargetFilePathField]]];
    [params appendString:[self transformKeyValue:@"extension" andValue:[self getFileExtensionField]]];
    return params;
}

// key=value形式でデータを生成する
-(NSString*)transformKeyValue:(NSString*) key andValue:(NSString*) value{
    return [NSString stringWithFormat:@"%@=%@|", key, value];
}


@end
