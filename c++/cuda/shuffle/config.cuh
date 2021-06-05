#include<stdio.h>
#include<stdlib.h>
#define MODEL_(s) Model_##s
class MODEL_(one_arg){
public:
  MODEL_(one_arg)(dim3 b, dim3 g):block(b),grid(g) {
    
  }  
  template<typename F, typename T>
  void operator()(F fun, T** out_dev, int outsize) {
    cudaMalloc((void**)out_dev, sizeof(T)*outsize);
    fun<<<grid,block>>>(*out_dev);  
    cudaDeviceSynchronize();
  }
private:
  dim3 block,grid;
};
