//
//  main.swift
//  MetalTest
//
//  Created by Ceylo on 27/07/2017.
//  Copyright © 2017 Yalir. All rights reserved.
//

import Metal

let devices = MTLCopyAllDevices()
let sessionLength : TimeInterval = 5 // seconds
let maxIterations = 10

print("Available Metal Devices:")
for device in devices {
  print("\t\(device.name!)")
  print("\t- low-power: \(device.isLowPower)")
  print("\t- maxThreadsPerThreadgroup: \(device.maxThreadsPerThreadgroup)")
  print("\t- recommendedMaxWorkingSetSize: \(device.recommendedMaxWorkingSetSize)")
  print("\t- headless: \(device.isHeadless)")
  print("")
}

print("Generating reference...")

let imgUrl = Bundle.main.url(forResource: "38mpx", withExtension: "jpg")!
let ref = ReferenceRenderer(imageAt: imgUrl)!
let startCpuRender = Date()
ref.render()
let endCpuRender = Date()
print("Rendered in \(String(format: "%.02f", endCpuRender.timeIntervalSince(startCpuRender) * 1000))ms")
ref.saveOutput(to: "/tmp/ref.tiff")

for device in devices {
  print("[\(device.name!)] Starting rendering session for \(sessionLength)s...")
  
  let initStart = Date()
  let renderer = Renderer(imageURL: imgUrl, device: device)
  let initEnd = Date()
  
  print("Init time: \(String(format: "%.02f", initEnd.timeIntervalSince(initStart)))ms")
  var times = [String]()
  
  let renderSessionStart = Date()
  var saveTime : TimeInterval = 0
  var n = 0
  while Date().timeIntervalSince(renderSessionStart) - saveTime < sessionLength {
  
//  while n < maxIterations {
    let renderStart = Date()
    let success = renderer.render()
    let renderEnd = Date()
    
    if success {
      let renderTimeMs = renderEnd.timeIntervalSince(renderStart) * 1000
      times.append("\(String(format: "%.01f", renderTimeMs))ms\t")
    } else {
      times.append("FAIL\t")
    }
    
    n += 1
    let saveStart = Date()
    renderer.saveOutput(to: "/tmp/\(device.name!)_\(n).jpg")
    let saveEnd = Date()
    saveTime += saveEnd.timeIntervalSince(saveStart)
  }
  
  print("Rendering times:")
  for time in times {
    print(time, terminator:"")
  }
  print("")
  
  print("")
  print("=====================================================")
  print("")
}
