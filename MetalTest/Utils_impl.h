//
//  Utils_impl.h
//  MetalTest
//
//  Created by Ceylo on 29/07/2017.
//  Copyright © 2017 Yalir. All rights reserved.
//

#ifndef Utils_impl_h
#define Utils_impl_h

template <typename T>
bool isInsideTexture(uint2 pos, T texture)
{
  return pos.x >= 0 && pos.y >= 0 && pos.x < texture.get_width() && pos.y < texture.get_height();
}


template <typename T>
bool isWithinBorder(uint2 pos, T texture, uint borderLength)
{
  auto w = texture.get_width();
  auto h = texture.get_height();
  
  if (pos.x < borderLength || pos.y < borderLength)
    return true;
  
  if (pos.x >= w - borderLength || pos.y >= h - borderLength)
    return true;
  
  return false;
}


#endif /* Utils_impl_h */
