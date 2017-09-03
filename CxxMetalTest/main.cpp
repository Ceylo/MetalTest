//
//  main.cpp
//  CxxMetalTest
//
//  Created by Ceylo on 26/08/2017.
//  Copyright © 2017 Yalir. All rights reserved.
//

#include <iostream>
#include <chrono>
#include "Renderer.hpp"

struct MsDiff {
  using T = std::chrono::steady_clock::time_point;
  MsDiff(T startTime, T endTime)
  : startTime(startTime), endTime(endTime) {}
  
  T startTime;
  T endTime;
};

std::ostream& operator<<(std::ostream& os, const MsDiff& diff)
{
  return os << std::chrono::duration_cast<std::chrono::milliseconds>(diff.endTime - diff.startTime).count()
  << "ms";
}

void measure(const std::string& label, std::function<void ()> lambda)
{
  auto start = std::chrono::steady_clock::now();
  lambda();
  auto end = std::chrono::steady_clock::now();
  auto diff = MsDiff(start, end);
  std::cout << label << ": " << diff << std::endl;
}

int main(int argc, const char * argv[])
{
  measure("init", []() { Renderer renderer("24mpx.jpg"); });
  
  {
    Renderer renderer("24mpx.jpg");
    
    for (int mpx = 1; mpx < 21; ++mpx)
    {
      BenchInitData data;
      
      measure("pipeline setup " + std::to_string(mpx) + " Mpx",
              [&]() { data = renderer.bench_setup(mpx); });
      
      measure("upload? " + std::to_string(mpx) + " Mpx",
              [&]() { renderer.bench_upload(data); } );
      measure("upload? " + std::to_string(mpx) + " Mpx",
              [&]() { renderer.bench_upload(data); } );
      measure("upload? " + std::to_string(mpx) + " Mpx",
              [&]() { renderer.bench_upload(data); } );
      
      measure("gpu copy " + std::to_string(mpx) + " Mpx",
              [&]() { renderer.bench_texcopy(data); } );
      measure("gpu copy " + std::to_string(mpx) + " Mpx",
              [&]() { renderer.bench_texcopy(data); } );
      measure("gpu copy " + std::to_string(mpx) + " Mpx",
              [&]() { renderer.bench_texcopy(data); } );
    }
  }
  
  Renderer renderer("24mpx.jpg");
  for (int i = 0; i < 10; ++i)
    measure("render", [&](){ renderer.render(); } );
  
  return 0;
}
