//
//  ViewController.h
//  IconsBundler
//
//  Created by Yann Bouschet on 22/05/2015.
//  Copyright (c) 2015 Yann Bouschet. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface ViewController : NSViewController

@property (nonatomic) IBOutlet NSImageView   *imageView;
@property (nonatomic) IBOutlet NSButton      *button;

- (IBAction)click:(id)sender;

@end

