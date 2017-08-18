//
//  ReferenceRenderer.m
//  MetalTest
//
//  Created by Ceylo on 17/08/2017.
//  Copyright © 2017 Yalir. All rights reserved.
//

#import "ReferenceRenderer.h"
#import "MetalTest-Swift.h"
#import "ImageLoader.h"

@interface ReferenceRenderer ()

@property ImageLoader* imageDesc;
@property NSMutableData* inputImage;
@property NSMutableData* outputImage;

@end

@implementation ReferenceRenderer

- (id) initWithImageAtURL:(NSURL *)imgURL
{
  self = [super init];
  if (self)
  {
    self.imageDesc = [[ImageLoader alloc] initWithLocation:imgURL];
    self.inputImage = [self.imageDesc.data mutableCopy];
    self.outputImage = [NSMutableData dataWithLength:self.imageDesc.data.length];
  }
  
  return self;
}

BOOL isWithinBorder(long x, long y, long w, long h, int borderLength)
{
  if (x < borderLength || y < borderLength)
    return YES;
  
  if (x >= w - borderLength || y >= h - borderLength)
    return YES;
  
  return NO;
}

void writePixel(unsigned char* baseAddress,
                unsigned char r,
                unsigned char g,
                unsigned char b,
                unsigned char a)
{
  baseAddress[0] = r;
  baseAddress[1] = g;
  baseAddress[2] = b;
  baseAddress[3] = a;
}

void executePixel(unsigned char* inP, unsigned char* outP,
                  long x, long y,
                  long width, long height,
                  long stride)
{
  if (x == 0 && y == 0) {
    writePixel(outP, 255, 0, 0, 255);
    return;
  }
  
  if (isWithinBorder(x, y, width, height, 1)) {
    writePixel(outP, 0, 255, 255, 255);
    return;
  }
  
  const int pxStride = 4;
#define left(buff) (buff - pxStride)
#define right(buff) (buff + pxStride)
#define top(buff) (buff - stride)
#define bottom(buff) (buff + stride)
  
#define topLeft(buff) left(top(buff))
#define topRight(buff) right(top(buff))
#define bottomLeft(buff) left(bottom(buff))
#define bottomRight(buff) right(bottom(buff))
  
  
  for (int comp = 0; comp < 4; comp++)
  {
    int sum =
      topLeft(inP)[comp] + top(inP)[comp] + topRight(inP)[comp] +
      left(inP)[comp] + inP[comp] + right(inP)[comp] +
      bottomLeft(inP)[comp] + bottom(inP)[comp] + bottomRight(inP)[comp];
    outP[comp] = sum / 9;
  }
}

void execute(unsigned char* inputBuffer, unsigned char* outputBuffer,
             long width, long height, long rowByteSize)
{
  unsigned char* inputLinePtr = inputBuffer;
  unsigned char* outputLinePtr = outputBuffer;
  
  for (long y = 0; y < height; y++)
  {
    for (long x = 0; x < width; x++)
      executePixel(inputLinePtr + x * 4, outputLinePtr + x * 4, x, y, width, height, rowByteSize);
    
    inputLinePtr += rowByteSize;
    outputLinePtr += rowByteSize;
  }
}

- (BOOL) render
{
  unsigned char* inputBuffer = _inputImage.mutableBytes;
  unsigned char* outputBuffer = _outputImage.mutableBytes;
  
  for (int i = 0; i <= 25; ++i)
  {
    execute(inputBuffer, outputBuffer, _imageDesc.width, _imageDesc.height, _imageDesc.bytesPerRow);
    execute(outputBuffer, inputBuffer, _imageDesc.width, _imageDesc.height, _imageDesc.bytesPerRow);
  }
  
  execute(inputBuffer, outputBuffer, _imageDesc.width, _imageDesc.height, _imageDesc.bytesPerRow);
  
  return YES;
}


- (void) saveOutputTo:(NSString *)path
{
  saveImage(self.outputImage.bytes, self.imageDesc.width, self.imageDesc.height, path);
}

@end
