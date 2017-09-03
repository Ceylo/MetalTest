//
//  GPGPU.metal
//  MetalTest
//
//  Created by Ceylo on 27/07/2017.
//  Copyright © 2017 Yalir. All rights reserved.
//

#include <metal_stdlib>
#include "Utils.h"
#include "MetalTextureIDs.h"

using namespace metal;

using PxTp = half;
using PxTp3 = half3;
using PxTp4 = half4;

kernel void blur3x3Kernel(texture2d<PxTp, access::read> input [[ texture(kBlur3x3InputTexture) ]] ,
                          texture2d<PxTp, access::write> output [[ texture(kBlur3x3OutputTexture) ]],
                          uint2 pos [[ thread_position_in_grid ]])
{
  if (! isInsideTexture(pos, output))
    return;
  
  if (pos.x == 0 && pos.y == 0)
  {
    output.write(PxTp4(1.0, 0.0, 0.0, 1.0), pos);
    return;
  }
  
  if (isWithinBorder(pos, output, 1))
  {
    output.write(PxTp4(0.0, 1.0, 1.0, 1.0), pos);
    return;
  }
  
  PxTp3 kernelSum =
      input.read(uint2(pos.x-1, pos.y-1)).rgb
    + input.read(uint2(pos.x,   pos.y-1)).rgb
    + input.read(uint2(pos.x+1, pos.y-1)).rgb
    
    + input.read(uint2(pos.x-1, pos.y)).rgb
    + input.read(uint2(pos.x,   pos.y)).rgb
    + input.read(uint2(pos.x+1, pos.y)).rgb
    
    + input.read(uint2(pos.x-1, pos.y+1)).rgb
    + input.read(uint2(pos.x,   pos.y+1)).rgb
    + input.read(uint2(pos.x+1, pos.y+1)).rgb;
  
  PxTp3 mean = kernelSum / 9;
  output.write(PxTp4(mean.r, mean.g, mean.b, 1.0), pos);
}

