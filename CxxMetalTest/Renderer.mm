//
//  Renderer.cpp
//  MetalTest
//
//  Created by Ceylo on 26/08/2017.
//  Copyright © 2017 Yalir. All rights reserved.
//

#include "Renderer.hpp"
#include "MetalTextureIDs.h"
#include <cstdlib>
#import <Metal/Metal.h>
#import <MetalKit/MetalKit.h>
#include <vector>
#include <iostream>

struct Pimpl {
  id<MTLDevice> device;
  id<MTLComputePipelineState> computePipelineState;
  id<MTLCommandQueue> commandQueue;
  id<MTLTexture> inputTexture, outputTexture, workingTexture1, workingTexture2;
};

#define PIMPL_DECLS \
auto& device = m_pimpl->device; \
auto& computePipelineState = m_pimpl->computePipelineState; \
auto& commandQueue = m_pimpl->commandQueue; \
auto& inputTexture = m_pimpl->inputTexture; \
auto& outputTexture = m_pimpl->outputTexture; \
auto& workingTexture1 = m_pimpl->workingTexture1; \
auto& workingTexture2 = m_pimpl->workingTexture2;

#define CHECK_ERR(err) \
if (err) { \
NSLog(@"Failure: %@", err);\
std::abort();\
}

#define PRECOND(cond) { if (!(cond)) NSLog(@"Failed on condition: %s", #cond), std::abort(); }

id<MTLTexture> loadInput(id<MTLDevice> device, NSURL* location)
{
  MTKTextureLoader* loader = [[MTKTextureLoader alloc] initWithDevice:device];
  NSDictionary* loadOptions = @{
    MTKTextureLoaderOptionTextureUsage : @(MTLTextureUsageShaderRead),
    MTKTextureLoaderOriginTopLeft : @(YES),
    MTKTextureLoaderOptionSRGB : @(NO)
  };
  
  NSError* err;
  id<MTLTexture> tex = [loader newTextureWithContentsOfURL:location
                                                   options:loadOptions
                                                     error:&err];
  CHECK_ERR(err);
  return tex;
}

Renderer::Renderer(const std::string& inputImage)
: m_pimpl(std::make_unique<Pimpl>())
{
  PIMPL_DECLS;
  
  device = MTLCreateSystemDefaultDevice();
  PRECOND(device);
  id<MTLLibrary> defaultLib = [device newDefaultLibrary];
  PRECOND(defaultLib);
  id<MTLFunction> blurFunction = [defaultLib newFunctionWithName:@"blur3x3Kernel"];
  
  NSError* err;
  computePipelineState = [device newComputePipelineStateWithFunction:blurFunction
                                                               error:&err];
  CHECK_ERR(err);
  
  NSString* inputString = [NSString stringWithUTF8String:inputImage.c_str()];
  NSURL* imgURL = [[[NSBundle mainBundle] resourceURL] URLByAppendingPathComponent:inputString];
  inputTexture = loadInput(device, imgURL);
  
  MTLTextureDescriptor* desc = [[MTLTextureDescriptor alloc] init];
  desc.textureType = MTLTextureType2D;
  desc.pixelFormat = MTLPixelFormatRGBA8Unorm;
  desc.width = inputTexture.width;
  desc.height = inputTexture.height;
  
  desc.usage = MTLTextureUsageShaderWrite;
  outputTexture = [device newTextureWithDescriptor:desc];
  outputTexture.label = @"Final Output";
  
  desc.pixelFormat = MTLPixelFormatBGRA8Unorm;
  desc.usage = MTLTextureUsageShaderRead | MTLTextureUsageShaderWrite;
  desc.storageMode = MTLStorageModePrivate;
  workingTexture1 = [device newTextureWithDescriptor:desc];
  workingTexture1.label = @"Working texture 1";
  workingTexture2 = [device newTextureWithDescriptor:desc];
  workingTexture2.label = @"Working texture 2";
  
  commandQueue = [device newCommandQueue];
}

Renderer::~Renderer()
{
  
}

namespace {
  void enqueueKernel(id<MTLCommandBuffer> commandBuffer,
                     id<MTLTexture> inputTexture,
                     id<MTLTexture> outputTexture,
                     id<MTLComputePipelineState> computePipelineState)
  {
    
    auto w = computePipelineState.threadExecutionWidth;
    auto h = computePipelineState.maxTotalThreadsPerThreadgroup / w;
    
    auto threadsPerThreadGroup = MTLSizeMake(w, h, 1);
    auto threadGroupsPerGrid = MTLSizeMake((inputTexture.width + w - 1) / w,
                                           (inputTexture.height + h - 1) / h,
                                           1);
    
    auto computeEncoder = [commandBuffer computeCommandEncoder];
    computeEncoder.label = @"3x3 blur kernel";
    [computeEncoder setComputePipelineState:computePipelineState];
    [computeEncoder setTexture:inputTexture atIndex:kBlur3x3InputTexture];
    [computeEncoder setTexture:outputTexture atIndex:kBlur3x3OutputTexture];
    [computeEncoder dispatchThreadgroups:threadGroupsPerGrid
                   threadsPerThreadgroup:threadsPerThreadGroup];
    [computeEncoder endEncoding];
  }
}

struct BenchInitPimpl
{
  id <MTLTexture> inputTexture;
  id <MTLTexture> outputTexture;
};

BenchInitData::BenchInitData()
: pimpl(std::make_unique<BenchInitPimpl>())
{
}

BenchInitData::~BenchInitData()
{
}

BenchInitData::BenchInitData(BenchInitData&& other)
: pimpl(std::move(other.pimpl))
{
}

BenchInitData& BenchInitData::operator=(BenchInitData&& other)
{
  pimpl = std::move(other.pimpl);
  return *this;
}



BenchInitData Renderer::bench_setup(int mpx)
{
  BenchInitData data;
  
  MTLTextureDescriptor* desc = [[MTLTextureDescriptor alloc] init];
  desc.textureType = MTLTextureType2D;
  desc.pixelFormat = MTLPixelFormatRGBA8Unorm;
  desc.width = 1000 * std::sqrt(mpx);
  desc.height = 1000 * std::sqrt(mpx);
  
  desc.usage = MTLTextureUsageShaderRead;
  data.pimpl->inputTexture = [m_pimpl->device newTextureWithDescriptor:desc];
  data.pimpl->inputTexture.label = @"Input";
  
  desc.usage = MTLTextureUsageShaderWrite;
  desc.storageMode = MTLStorageModePrivate;
  data.pimpl->outputTexture = [m_pimpl->device newTextureWithDescriptor:desc];
  data.pimpl->outputTexture.label = @"Output";
  
  return data;
}

void Renderer::bench_upload(const BenchInitData& data)
{
  auto width = data.pimpl->inputTexture.width;
  auto height = data.pimpl->inputTexture.height;
  
  std::unique_ptr<unsigned char[]> pixels(new unsigned char[width * height * 4]);
  auto fullImage = MTLRegionMake2D(0, 0, width, height);
  [data.pimpl->inputTexture replaceRegion:fullImage
                              mipmapLevel:0
                                withBytes:pixels.get()
                              bytesPerRow:width * 4];
}

void Renderer::bench_texcopy(const BenchInitData& data)
{
  PIMPL_DECLS;
  
  auto width = data.pimpl->inputTexture.width;
  auto height = data.pimpl->inputTexture.height;
  
  id<MTLCommandBuffer> commandBuffer = [commandQueue commandBuffer];
  id<MTLBlitCommandEncoder> blitEncoder = [commandBuffer blitCommandEncoder];
  
  [blitEncoder copyFromTexture:data.pimpl->inputTexture
                   sourceSlice:0
                   sourceLevel:0
                  sourceOrigin:MTLOriginMake(0, 0, 0)
                    sourceSize:MTLSizeMake(width, height, 1)
                     toTexture:data.pimpl->outputTexture
              destinationSlice:0
              destinationLevel:0
             destinationOrigin:MTLOriginMake(0, 0, 0)];
  [blitEncoder endEncoding];
  [commandBuffer commit];
  [commandBuffer waitUntilCompleted];
}

void Renderer::render()
{
  PIMPL_DECLS;
  id<MTLCommandBuffer> allCommandsBuffer = [commandQueue commandBuffer];
  
  enqueueKernel(allCommandsBuffer, inputTexture, workingTexture1, computePipelineState);
  
  for (int i = 0; i < 25; ++i) {
    enqueueKernel(allCommandsBuffer, workingTexture1, workingTexture2, computePipelineState);
    enqueueKernel(allCommandsBuffer, workingTexture2, workingTexture1, computePipelineState);
  }
  
  enqueueKernel(allCommandsBuffer, workingTexture1, outputTexture, computePipelineState);
  
  // Fetch texture from GPU
  id<MTLBlitCommandEncoder> blitEncoder = [allCommandsBuffer blitCommandEncoder];
  blitEncoder.label = @"CPU/GPU sync";
  [blitEncoder synchronizeResource:outputTexture];
  [blitEncoder endEncoding];
  
  [allCommandsBuffer commit];
  [allCommandsBuffer waitUntilCompleted];
  [commandQueue insertDebugCaptureBoundary];
  
  if (NSError* error = allCommandsBuffer.error)
    NSLog(@"Metal error: %@", error);
}

void Renderer::saveOutputTo(const std::string& filename)
{
  
}
