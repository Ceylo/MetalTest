//
//  Renderer.hpp
//  MetalTest
//
//  Created by Ceylo on 26/08/2017.
//  Copyright © 2017 Yalir. All rights reserved.
//

#ifndef Renderer_hpp
#define Renderer_hpp

#include <string>
#include <memory>

struct BenchInitData
{
  BenchInitData();
  ~BenchInitData();
  
  BenchInitData(BenchInitData&& other);
  BenchInitData& operator=(BenchInitData&& other);
  
  std::unique_ptr<struct BenchInitPimpl> pimpl;
};

class Renderer {
public:
  Renderer(const std::string& inputImage);
  ~Renderer();
  
  BenchInitData bench_setup(int mpx);
  void bench_upload(const BenchInitData& data);
  void bench_texcopy(const BenchInitData& data);
  void render();
  void saveOutputTo(const std::string& filename);
  
private:
  std::unique_ptr<struct Pimpl> m_pimpl;
};

#endif /* Renderer_hpp */
