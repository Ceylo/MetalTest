//
//  ImageLoader.swift
//  MetalTest
//
//  Created by Ceylo on 27/07/2017.
//  Copyright © 2017 Yalir. All rights reserved.
//

import Cocoa

@objc
class ImageLoader : NSObject {
  let width : Int
  let height : Int
  let bytesPerRow : Int
  let data : Data
  
  init(location : URL)
  {
    let image = NSImage(byReferencing: location)
    var imageRect = NSMakeRect(0.0, 0.0, image.size.width, image.size.height)
    let imageRef = image.cgImage(forProposedRect: &imageRect,
                                 context: nil, hints: nil)!
    
    self.width = imageRef.width
    self.height = imageRef.height
    let bytesPerPixel = 4
    self.bytesPerRow = bytesPerPixel * self.width
    
    let bitsPerComponent = 8
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    var data = Data(count: self.height * self.bytesPerRow)
    
    data.withUnsafeMutableBytes { (bytes : UnsafeMutablePointer<UInt8>) in
      
      let bimapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
        .union(.byteOrder32Big)
      
      let context = CGContext(data: bytes,
                              width: imageRef.width, height: imageRef.height,
                              bitsPerComponent: bitsPerComponent,
                              bytesPerRow: bytesPerPixel * imageRef.width,
                              space: colorSpace,
                              bitmapInfo: bimapInfo.rawValue)!
//      context.translateBy(x: 0, y: CGFloat(imageRef.height))
//      context.scaleBy(x: 1.0, y: -1.0)
      
      context.draw(imageRef, in: CGRect(x: 0, y: 0, width: imageRef.width, height: imageRef.height))
      displayRawBuffer(bytes, Int32(imageRef.width), Int32(imageRef.height))
    

//      
//      array.withUnsafeMutableBufferPointer{ (planes : inout UnsafeMutableBufferPointer<UnsafeMutablePointer<UInt8>>) in
//        
//        let bbb = UnsafeMutablePointer<UnsafeMutablePointer<UInt8>?>?(planes)
//        let bitmap = NSBitmapImageRep(bitmapDataPlanes: bbb,
//                                      pixelsWide: imageRef.width, pixelsHigh: imageRef.height,
//                                      bitsPerSample: 8,
//                                      samplesPerPixel: 4,
//                                      hasAlpha: true,
//                                      isPlanar: false,
//                                      colorSpaceName: NSDeviceRGBColorSpace,
//                                      bytesPerRow: bytesPerPixel * imageRef.width,
//                                      bitsPerPixel: 32)!
//        let nsimage = NSImage(size: NSMakeSize(CGFloat(imageRef.width), CGFloat(imageRef.height)))
//        nsimage.addRepresentation(bitmap)
//      }
    }
    
    self.data = data
  }
}
