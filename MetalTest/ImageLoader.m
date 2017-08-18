
#import "ImageLoader.h"
#import <Cocoa/Cocoa.h>
#import <stdlib.h>


@implementation ObjcImageLoader

- (nullable instancetype) initWithFileAtLocation:(nonnull NSURL *)location
{
  self = [super init];
  
  if (self)
  {
    NSImage* image = [[NSImage alloc] initWithContentsOfFile:location.path];
    
    NSRect imageRect = NSMakeRect(0, 0, image.size.width, image.size.height);
    CGImageRef imageRef = [image CGImageForProposedRect:&imageRect context:NULL hints:nil];
    
    // Create a suitable bitmap context for extracting the bits of the image
    _width = CGImageGetWidth(imageRef);
    _height = CGImageGetHeight(imageRef);
    NSUInteger bytesPerPixel = 4;
    _bytesPerRow = bytesPerPixel * _width;
    NSUInteger bitsPerComponent = 8;
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    NSMutableData *data = [NSMutableData dataWithLength:_height * _width * bytesPerPixel];
    CGContextRef context = CGBitmapContextCreate([data mutableBytes], _width, _height,
                                                 bitsPerComponent, _bytesPerRow, colorSpace,
                                                 kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGColorSpaceRelease(colorSpace);
    
    // Flip the context so the positive Y axis points down
//    CGContextTranslateCTM(context, 0, _height);
//    CGContextScaleCTM(context, 1, -1);
    
    CGContextDrawImage(context, CGRectMake(0, 0, _width, _height), imageRef);
    CGContextRelease(context);
    
    _data = data;
  }
  
  return self;
}

void displayRawBuffer(const unsigned char* const data, int width, int height)
{
  return;
  
  NSBitmapImageRep* rep =
  [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:&data
                                          pixelsWide:width
                                          pixelsHigh:height
                                       bitsPerSample:8
                                     samplesPerPixel:4
                                            hasAlpha:YES
                                            isPlanar:NO
                                      colorSpaceName:NSDeviceRGBColorSpace
                                         bytesPerRow:width * 4
                                        bitsPerPixel:32];
  NSImage* img = [[NSImage alloc] initWithSize:NSMakeSize(width, height)];
  [img addRepresentation:rep];
  
//  NSLog(@"%@", img);
}

void saveImage(const unsigned char* const data, int width, int height, NSString* _Nonnull path)
{
  NSBitmapImageRep* rep =
  [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:&data
                                          pixelsWide:width
                                          pixelsHigh:height
                                       bitsPerSample:8
                                     samplesPerPixel:4
                                            hasAlpha:YES
                                            isPlanar:NO
                                      colorSpaceName:NSDeviceRGBColorSpace
                                         bytesPerRow:width * 4
                                        bitsPerPixel:32];
  
  NSData *nsdata = [rep representationUsingType: NSTIFFFileType properties: nil];
  [nsdata writeToFile: path atomically: NO];
}

@end
