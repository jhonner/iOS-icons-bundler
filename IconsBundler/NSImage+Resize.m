//
//  NSImage+Resize.m
//  Agenda2
//
//  Created by Martin Hewitson on 6/1/11.
//  Copyright 2011 AEI Hannover . All rights reserved.
//

#import "NSImage+Resize.h"


@implementation NSImage (Resize)

- (NSImage*)resizeToSize:(NSSize)aSize {
    NSRect oldRect = NSMakeRect(0.0, 0.0, self.size.width, self.size.height);
    NSRect newRect = NSMakeRect(0.0, 0.0, aSize.width, aSize.height);
 
    NSImage *newImage = [[NSImage alloc] initWithSize:NSMakeSize(aSize.width, aSize.height)];
    
    [newImage lockFocus];
    [self drawInRect:newRect
            fromRect:oldRect
           operation:NSCompositeCopy
            fraction:1.0];
    [newImage unlockFocus];
    
    return newImage;
}

@end