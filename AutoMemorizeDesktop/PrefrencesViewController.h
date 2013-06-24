//
//  PrefrencesViewController.h
//  AutoMemorizeDesktop
//
//  Created by AirMyac on 6/25/13.
//  Copyright (c) 2013 com.katzlifehack. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface PrefrencesViewController : NSViewController

@property (nonatomic,strong) IBOutlet NSArrayController *preArrayController;
@property (assign) IBOutlet NSWindow *preWindow;

@end
