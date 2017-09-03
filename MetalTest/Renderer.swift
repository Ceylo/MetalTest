//
//  Renderer.swift
//  MetalTest
//
//  Created by Ceylo on 27/07/2017.
//  Copyright © 2017 Yalir. All rights reserved.
//

import Metal
import MetalKit
import Foundation

func loadInput(device : MTLDevice, location : URL) -> MTLTexture
{
  let loader = MTKTextureLoader(device: device)
  let loadOptions = [
    MTKTextureLoaderOptionTextureUsage : NSNumber(value: MTLTextureUsage.shaderRead.rawValue),
    MTKTextureLoaderOriginTopLeft : NSNumber(value: true),
    MTKTextureLoaderOptionSRGB : NSNumber(value: false)
  ]
  
  return (try? loader.newTexture(withContentsOf: location, options:loadOptions))!
}

class Renderer {
  
  var device : MTLDevice
  var computePipelineState : MTLComputePipelineState
  var commandQueue : MTLCommandQueue
  var inputTexture : MTLTexture
  var outputTexture : MTLTexture
  var workTexture1 : MTLTexture
  var workTexture2 : MTLTexture
  
  init(imageURL : URL, device : MTLDevice)
  {
    self.device = device
    
    let defaultLib = device.newDefaultLibrary()!
    let blurFunction = defaultLib.makeFunction(name: "blur3x3Kernel")!
    computePipelineState = (try? device.makeComputePipelineState(function: blurFunction))!
    
    inputTexture = loadInput(device: device, location: imageURL)

    let textureDesc = MTLTextureDescriptor()
    textureDesc.textureType = .type2D
    textureDesc.pixelFormat = .rgba8Unorm
    textureDesc.width = inputTexture.width
    textureDesc.height = inputTexture.height
    
    textureDesc.usage = [ .shaderWrite ]
    outputTexture = device.makeTexture(descriptor: textureDesc)
    outputTexture.label = "Final Output"
    
    textureDesc.pixelFormat = .bgra8Unorm
    textureDesc.usage = [ .shaderRead, .shaderWrite ]
    textureDesc.storageMode = .private
    workTexture1 = device.makeTexture(descriptor: textureDesc)
    workTexture1.label = "Working texture 1"
    workTexture2 = device.makeTexture(descriptor: textureDesc)
    workTexture2.label = "Working texture 2"
    commandQueue = device.makeCommandQueue()
  }
  
  func enqueueKernel(commandBuffer : MTLCommandBuffer,
                     input : MTLTexture,
                     output : MTLTexture)
  {
    let w = computePipelineState.threadExecutionWidth
    let h = computePipelineState.maxTotalThreadsPerThreadgroup / w
    
    let threadsPerThreadGroup = MTLSizeMake(w, h, 1)
    let threadGroupsPerGrid = MTLSize(width: (inputTexture.width + w - 1) / w,
                                      height: (inputTexture.height + h - 1) / h,
                                      depth: 1)
    
    let computeEncoder = commandBuffer.makeComputeCommandEncoder()
    computeEncoder.label = "3x3 blur kernel"
    computeEncoder.setComputePipelineState(computePipelineState)
    computeEncoder.setTexture(input, at: Int(kBlur3x3InputTexture.rawValue))
    computeEncoder.setTexture(output, at: Int(kBlur3x3OutputTexture.rawValue))
    computeEncoder.dispatchThreadgroups(threadGroupsPerGrid, threadsPerThreadgroup: threadsPerThreadGroup)
    computeEncoder.endEncoding()
  }
  
  func render()
  {
    let allCommandsBuffer = commandQueue.makeCommandBuffer()
    
    enqueueKernel(commandBuffer: allCommandsBuffer, input: inputTexture, output: workTexture1)
    
    for _ in 1 ... 24 {
      enqueueKernel(commandBuffer: allCommandsBuffer, input: workTexture1, output: workTexture2)
      enqueueKernel(commandBuffer: allCommandsBuffer, input: workTexture2, output: workTexture1)
    }
    enqueueKernel(commandBuffer: allCommandsBuffer, input: workTexture1, output: outputTexture)
    
    // Fetch texture from GPU
    let blitEncoder = allCommandsBuffer.makeBlitCommandEncoder()
    blitEncoder.label = "CPU/GPU sync"
    blitEncoder.synchronize(resource: outputTexture)
    blitEncoder.endEncoding()
    
    allCommandsBuffer.commit()
    allCommandsBuffer.waitUntilCompleted()
    commandQueue.insertDebugCaptureBoundary()
    
    if let error = allCommandsBuffer.error {
      print("Metal error: \(error)")
    }
  }
  
  func saveOutput(to : String)
  {
    var outBuffer = Data(count: outputTexture.width * 4 * MemoryLayout<UInt8>.size * outputTexture.height)
    outBuffer.withUnsafeMutableBytes { ( buff : UnsafeMutablePointer<UInt8>) in
      let region = MTLRegionMake2D(0, 0, outputTexture.width, outputTexture.height)
      outputTexture.getBytes(UnsafeMutableRawPointer(buff),
                             bytesPerRow: outputTexture.width * 4 * MemoryLayout<UInt8>.size,
                             from: region,
                             mipmapLevel: 0)
      
      saveImage(buff, Int32(outputTexture.width), Int32(outputTexture.height), to)
    }
  }
}
