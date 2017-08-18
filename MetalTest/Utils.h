//
//  Utils.h
//  MetalTest
//
//  Created by Ceylo on 29/07/2017.
//  Copyright © 2017 Yalir. All rights reserved.
//

#ifndef Utils_h
#define Utils_h

#import <simd/simd.h>
using namespace metal;

template <typename T>
bool isInsideTexture(uint2 pos, T texture);

template <typename T>
bool isWithinBorder(uint2 pos, T texture, uint borderLength);


// Details
#include "Utils_impl.h"

#endif /* Utils_h */
