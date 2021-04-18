#include<iostream>
using namespace std;
__global__ void test(float *data) {
  unsigned int tid = threadIdx.x;
  if(tid < 32) {
    volatile float *in = data;
    in[tid] += in[tid + 32];
    in[tid] += in[tid + 16];
    in[tid] += in[tid + 8];
    in[tid] += in[tid + 4];
    in[tid] += in[tid + 2];
    in[tid] += in[tid + 1];
  }
}
int main() {
  float in[64];
  for(int i = 0;i < 64;++i) {
    in[i] = 1;
  }
  float *in_dev;
  cudaMalloc((void**)&in_dev, sizeof(in));
  cudaMemcpy(in_dev, in , sizeof(in), cudaMemcpyHostToDevice);
  dim3 block(32,1);
  dim3 grid(1,1);
  test<<<grid, block>>>(in_dev);
  cudaMemcpy(in, in_dev , sizeof(in), cudaMemcpyDeviceToHost);
  cudaDeviceSynchronize();
  for(int i = 0;i < 64;++i) {
    cout << in[i] <<"  ";
  }
  return 0;
}
