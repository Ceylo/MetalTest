

#import <Foundation/Foundation.h>

@interface ObjcImageLoader : NSObject

- (nullable instancetype) initWithFileAtLocation:(nonnull NSURL *)location;

// Width of image in pixels
@property (nonatomic, readonly) NSUInteger      width;

// Height of image in pixels
@property (nonatomic, readonly) NSUInteger      height;

// RGBA 32-bpp data
@property (nonatomic, readonly, nonnull) NSData *data;

@property (nonatomic, readonly) NSUInteger bytesPerRow;

@end

void displayRawBuffer(const unsigned char* const data, int width, int height);

void saveImage(const unsigned char* const data, int width, int height, NSString* _Nonnull path);
// saveImage(buff, Int32(outputTexture.width), Int32(outputTexture.height), to)
