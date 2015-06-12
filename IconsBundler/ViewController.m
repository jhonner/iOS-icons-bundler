//
//  ViewController.m
//  IconsBundler
//
//  Created by Yann Bouschet on 22/05/2015.
//  Copyright (c) 2015 Yann Bouschet. All rights reserved.
//

#import "ViewController.h"
#import "NSImage+Resize.h"

#define APPICONSET @"AppIcon.appiconset"
#define IN_APPICONSET(a) [NSString stringWithFormat:@"%@/%@",APPICONSET,a]

typedef NS_ENUM(NSUInteger, buttonStatus) {
    drag,
    process,
    openFolder
};

@interface ViewController ()

@property (nonatomic) NSImage   *originalImage;
@property (nonatomic) NSInteger status;
@property (nonatomic) NSArray   *icons;
@property (nonatomic) NSInteger count;
@property (nonatomic) NSString  *desktopPath;
@property (nonatomic) NSString  *lastFolder;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    _status = drag;
    _count = 0;
    
    NSArray * paths = NSSearchPathForDirectoriesInDomains (NSDesktopDirectory, NSUserDomainMask, YES);
    _desktopPath = [paths objectAtIndex:0];
    
    [_imageView registerForDraggedTypes:[NSImage imageTypes]];
    [_imageView addObserver:self
                 forKeyPath:@"image"
                    options:NSKeyValueObservingOptionNew
                    context:nil];
    
    [self refreshButton];
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
    
    if(object == _imageView && [keyPath isEqualToString:@"image"]) {
        
        _originalImage = [_imageView.image copy];
        _status = process;
        
        [self refreshButton];
    }
}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];
    
}

- (IBAction)click:(id)sender {
    
    switch (_status) {
            
        case process:
            [self processImage];
            break;
            
        case openFolder:
            [self openFolder];
            break;
            
        default:
            break;
    }
    
}

- (void)processImage {
    
    if (_originalImage.size.width != _originalImage.size.height) {
        //non square
        [self alertWithTitle:@"Attention!" andMessage:@"Base image should be square."];
    }
    
    else if (_originalImage.size.width < 1024) {
        //not big enough
        [self alertWithTitle:@"Attention!" andMessage:@"Base image should be at least 1024x1024."];
    }
    
    else {
        if (_originalImage && [self batchProcess]) {
            _status = openFolder;
            [self refreshButton];
        }
    }
}

- (void)openFolder {
    
    if(_lastFolder) {
        [[NSWorkspace sharedWorkspace] openFile:_lastFolder];
    }
    
    _originalImage = nil;
    _imageView.image = nil;
    [_imageView setNeedsDisplay];
    
    _status = drag;
    
    [self refreshButton];
}

- (void)refreshButton {
    
    switch (_status) {
        case drag:
            _button.enabled = NO;
            _button.title = @"Drop an Image";
            break;
            
        case process:
            _button.enabled = YES;
            _button.title = @"Create Icons";
            break;
            
        case openFolder:
            _button.enabled = YES;
            _button.title = @"Show Icons";
            break;
            
        default:
            break;
    }
    
}

- (BOOL)batchProcess {
    
    NSDictionary *sizes = @{
                            IN_APPICONSET(@"Icon-Small"):@29,
                            IN_APPICONSET(@"Icon-Small@2x"):@58,
                            IN_APPICONSET(@"Icon-Small@3x"):@87,
                            IN_APPICONSET(@"Icon-40"):@40,
                            IN_APPICONSET(@"Icon-40@2x"):@80,
                            IN_APPICONSET(@"Icon-40@3x"):@120,
                            IN_APPICONSET(@"Icon-76"):@76,
                            IN_APPICONSET(@"Icon-76@2x"):@152,
                            IN_APPICONSET(@"Icon-60@2x"):@120,
                            IN_APPICONSET(@"Icon-60@3x"):@180,
                            @"Icon-60":@60,
                            @"Icon-72":@72,
                            @"Icon-72@2x":@144,
                            @"Icon-Small-50":@50,
                            @"Icon-Small-50@2x":@100,
                            @"Icon":@57,
                            @"Icon@2x":@114,
                            @"iTunesArtwork":@512,
                            @"iTunesArtwork@2x":@1024
                            };
    
    
    NSMutableArray *tmpArray = [NSMutableArray array];
    
    for (NSString *name in [sizes allKeys]) {
        
        NSNumber *lenghtNb = sizes[name];
        
        float length = [lenghtNb floatValue];
        
        NSImage *icon = [_originalImage resizeToSize:NSMakeSize(length, length)];
        
        if (icon) {
            [tmpArray addObject:@{
                                  @"name":name,
                                  @"icon":icon
                                  }];
        }
    }
    
    _icons = [NSArray arrayWithArray:tmpArray];
    
    return [self batchExport];
}

- (BOOL)batchExport {
    
    BOOL didExport = NO;
    
    NSFileManager *defaultManager = [NSFileManager defaultManager];
    
    NSString *folderPath = [self folderPath];
    NSString *subFolderPath = [folderPath stringByAppendingPathComponent:APPICONSET];
    
    if([defaultManager createDirectoryAtPath:folderPath
                                 withIntermediateDirectories:YES
                                                  attributes:nil
                                                       error:NULL]) {
        
        if([defaultManager createDirectoryAtPath:subFolderPath
                                     withIntermediateDirectories:YES
                                                      attributes:nil
                                                           error:NULL]) {
            
            NSBundle* mainBundle = [NSBundle mainBundle];
        

            NSString *fileInBundle = [mainBundle pathForResource:@"Contents" ofType:@"json"];
            NSString *fileInFolder = [subFolderPath stringByAppendingPathComponent:@"Contents.json"];
            
            [defaultManager moveItemAtPath:fileInBundle toPath:fileInFolder error:NULL];

            
            for (NSDictionary *dict in _icons) {
                
                NSString *name = dict[@"name"];
                NSImage *icon = dict[@"icon"];
                
                NSString *path = [folderPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.png",name]];
                
                didExport = [self saveImage:icon atPath:path];
                
                if(!didExport) break;
            }
        }
    }
    
    if (didExport) {
        _lastFolder = [NSString stringWithString:folderPath];
    }
    
    return didExport;
}

- (BOOL)saveImage:(NSImage *)image atPath:(NSString *)path {
    
    NSBitmapImageRep *newRep = [self unscaledBitmapImageRepForImage:image];
    NSData *pngData = [newRep representationUsingType:NSPNGFileType properties:nil];
    
    return [pngData writeToFile:path atomically:YES];
}

- (NSBitmapImageRep *)unscaledBitmapImageRepForImage:(NSImage*)image {
    
    NSBitmapImageRep *rep = [[NSBitmapImageRep alloc]
                             initWithBitmapDataPlanes:NULL
                             pixelsWide:image.size.width
                             pixelsHigh:image.size.height
                             bitsPerSample:8
                             samplesPerPixel:4
                             hasAlpha:YES
                             isPlanar:NO
                             colorSpaceName:NSDeviceRGBColorSpace
                             bytesPerRow:0
                             bitsPerPixel:0];
    rep.size = image.size;
    
    [NSGraphicsContext saveGraphicsState];
    [NSGraphicsContext setCurrentContext:[NSGraphicsContext graphicsContextWithBitmapImageRep:rep]];
    
    [image drawAtPoint:NSMakePoint(0, 0)
              fromRect:NSZeroRect
             operation:NSCompositeSourceOver
              fraction:1.0];
    
    [NSGraphicsContext restoreGraphicsState];
    
    return rep;
}

- (NSString*)folderPath {
    
    NSString *folderPath = nil;
    
    BOOL isDir;
    BOOL exists = YES;
    
    while (exists) {
        NSString *folderName = @"icons";
        if(_count > 0) folderName = [NSString stringWithFormat:@"%@-%ld",folderName,_count];
        
        folderPath = [_desktopPath stringByAppendingPathComponent:folderName];
        exists = [[NSFileManager defaultManager] fileExistsAtPath:folderPath isDirectory:&isDir];
        _count++;
    }
    
    return folderPath;
}

- (void)alertWithTitle:(NSString*)title andMessage:(NSString*)message {
    NSAlert *alert = [[NSAlert alloc] init];
    [alert addButtonWithTitle:@"OK"];
    [alert setMessageText:title];
    [alert setInformativeText:message];
    [alert setAlertStyle:NSWarningAlertStyle];
    [alert runModal];
}

@end
