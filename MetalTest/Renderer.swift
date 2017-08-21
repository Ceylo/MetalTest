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
    MTKTextureLoaderOriginTopLeft : NSNumber(value: true)
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
  var errors : Array<Error> = []
  
  init(imageURL : URL, device : MTLDevice)
  {
    self.device = device
    
    let defaultLib = device.newDefaultLibrary()!
    let kernelFunction = defaultLib.makeFunction(name: "grayscaleKernel")!
    computePipelineState = (try? device.makeComputePipelineState(function: kernelFunction))!
    
    inputTexture = loadInput(device: device, location: imageURL)

    let textureDesc = MTLTextureDescriptor()
    textureDesc.textureType = .type2D
    textureDesc.pixelFormat = .rgba8Unorm
    textureDesc.width = inputTexture.width
    textureDesc.height = inputTexture.height
    
    textureDesc.usage = [ .shaderWrite ]
    outputTexture = device.makeTexture(descriptor: textureDesc)
    
    textureDesc.usage = [ .shaderRead, .shaderWrite ]
    textureDesc.storageMode = .private
    workTexture1 = device.makeTexture(descriptor: textureDesc)
    workTexture2 = device.makeTexture(descriptor: textureDesc)
    

//    img.data.withUnsafeBytes { (rawPtr : UnsafePointer<UInt8>) in
//      displayRawBuffer(rawPtr, Int32(textureDesc.width), Int32(textureDesc.height))
//    }
    
    
    commandQueue = device.makeCommandQueue()
    
//    var outBuffer = Data(count: inputTexture.width * 4 * MemoryLayout<UInt8>.size * inputTexture.height)
//    outBuffer.withUnsafeMutableBytes { ( buff : UnsafeMutablePointer<UInt8>) in
//      inputTexture.getBytes(UnsafeMutableRawPointer(buff),
//                            bytesPerRow: inputTexture.width * 4 * MemoryLayout<UInt8>.size,
//                            from: region,
//                            mipmapLevel: 0)
//      
//      displayRawBuffer(buff, Int32(inputTexture.width), Int32(inputTexture.height))
//    }
  }
  
  func enqueueKernel(input : MTLTexture,
                     output : MTLTexture) -> MTLCommandBuffer
  {
    let commandBuffer = commandQueue.makeCommandBuffer()
    commandBuffer.label = "MyCommand"
    
    let w = computePipelineState.threadExecutionWidth
    let h = computePipelineState.maxTotalThreadsPerThreadgroup / w
    
    let threadsPerThreadGroup = MTLSizeMake(w, h, 1)
    let threadGroupsPerGrid = MTLSize(width: (inputTexture.width + w - 1) / w,
                                      height: (inputTexture.height + h - 1) / h,
                                      depth: 1)
    
    let computeEncoder = commandBuffer.makeComputeCommandEncoder()
    computeEncoder.setComputePipelineState(computePipelineState)
    computeEncoder.setTexture(input, at: 0)
    computeEncoder.setTexture(output, at: 1)
    computeEncoder.dispatchThreadgroups(threadGroupsPerGrid, threadsPerThreadgroup: threadsPerThreadGroup)
    computeEncoder.endEncoding()
    
    commandBuffer.commit()
    return commandBuffer
  }
  
  func enqueueOutputBlit() -> MTLCommandBuffer
  {
    let commandBuffer = commandQueue.makeCommandBuffer()
    commandBuffer.label = "Blit command"
    let blitEncoder = commandBuffer.makeBlitCommandEncoder()
    blitEncoder.synchronize(resource: outputTexture)
    blitEncoder.endEncoding()
    
    commandBuffer.commit()
    return commandBuffer
  }
  
  func render() -> Bool
  {
    var commandBuffers = [MTLCommandBuffer]()
    
    commandBuffers.append(enqueueKernel(input: inputTexture, output: workTexture1))
    
    for _ in 1 ... 24 {
      commandBuffers.append(enqueueKernel(input: workTexture1, output: workTexture2))
      commandBuffers.append(enqueueKernel(input: workTexture2, output: workTexture1))
    }
    commandBuffers.append(enqueueKernel(input: workTexture1, output: outputTexture))
    
    commandBuffers.append(enqueueOutputBlit())
    
    commandBuffers.last?.waitUntilCompleted()
    commandQueue.insertDebugCaptureBoundary()
    
//    if true {
//        var outBuffer = Data(count: inputTexture.width * 4 * MemoryLayout<UInt8>.size * inputTexture.height)
//        outBuffer.withUnsafeMutableBytes { ( buff : UnsafeMutablePointer<UInt8>) in
//          let region = MTLRegionMake2D(0, 0, inputTexture.width, inputTexture.height)
//          inputTexture.getBytes(UnsafeMutableRawPointer(buff),
//                                bytesPerRow: inputTexture.width * 4 * MemoryLayout<UInt8>.size,
//                                from: region,
//                                mipmapLevel: 0)
//          
//          displayRawBuffer(buff, Int32(inputTexture.width), Int32(inputTexture.height))
//        }
//    }
//    
//    if true {
//      var outBuffer = Data(count: outputTexture.width * 4 * MemoryLayout<UInt8>.size * outputTexture.height)
//      outBuffer.withUnsafeMutableBytes { ( buff : UnsafeMutablePointer<UInt8>) in
//        let region = MTLRegionMake2D(0, 0, outputTexture.width, outputTexture.height)
//        outputTexture.getBytes(UnsafeMutableRawPointer(buff),
//                              bytesPerRow: outputTexture.width * 4 * MemoryLayout<UInt8>.size,
//                              from: region,
//                              mipmapLevel: 0)
//        
//        displayRawBuffer(buff, Int32(outputTexture.width), Int32(outputTexture.height))
//      }
//    }
    
    for commandBuffer in commandBuffers {
      if let error = commandBuffer.error {
        errors.append(error)
        print(error)
      }
    }
    
    return errors.isEmpty
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
