#include<iostream>
#include"./head.h"
using namespace std;
template<typename T, unsigned int blocksize>
void __global__ add(T* data,T* odata, unsigned int n) {
  unsigned int tid = threadIdx.x;
  T* idata = data + blockDim.x * blockIdx.x * 8;
  unsigned id = threadIdx.x + blockDim.x *blockIdx.x * 8;
  //展开
  if (id + 7*blockDim.x < n) {
    idata[tid] += idata[tid + blockDim.x];
    idata[tid] += idata[tid + 2*blockDim.x];
    idata[tid] += idata[tid + 3*blockDim.x];
    idata[tid] += idata[tid + 4*blockDim.x];
    idata[tid] += idata[tid + 5*blockDim.x];
    idata[tid] += idata[tid + 6*blockDim.x];
    idata[tid] += idata[tid + 7*blockDim.x];
  }
  __syncthreads();
  if(blocksize >= 512 && tid < 256) {
    idata[tid] += idata[tid + 256];
  }
  __syncthreads();
  if(blocksize >= 256 && tid < 128) {
    idata[tid] += idata[tid + 128];
  }
  __syncthreads();
  if(blocksize >= 128 && tid < 64) {
    idata[tid] += idata[tid + 64];
  }
  __syncthreads();
  if(tid < 32) {
    volatile T * vmem = idata;
    vmem[tid] += vmem[tid + 32];
    vmem[tid] += vmem[tid + 16];
    vmem[tid] += vmem[tid + 8];
    vmem[tid] += vmem[tid + 4];
    vmem[tid] += vmem[tid + 2];
    vmem[tid] += vmem[tid + 1];
  }
  if (tid == 0) {
    odata[blockIdx.x] = idata[0];
  }
}
int main() {
  int N = 1<<20;
  int SIZE = 512;
  dim3 block(SIZE , 1);
  dim3 grid((N + block.x - 1)/block.x , 1);
  float* h_a, *h_b;
  float *d_a, *d_b;
  cudaHostAlloc((void **)&h_a, N*sizeof(float), cudaHostAllocMapped);
  cudaHostAlloc((void **)&h_b, grid.x/8, cudaHostAllocMapped);
  auto init = [&](auto a,unsigned int n)->void{
    for(int i = 0;i < n;i++) {
      a[i] = 1;
    }
  };
  init(h_a, N);
  init(h_b, grid.x/8);
  cudaHostGetDevicePointer((void**)&d_a, h_a, 0);
  cudaHostGetDevicePointer((void**)&d_b, h_b, 0);
  clock_t start, end;
  start = clock();
  add<float,512><<<grid.x/8, block>>>(d_a, d_b, N);
  cudaDeviceSynchronize();
  end = clock();
  cout << "GPU Time is :" << end - start << '\n';
  float ans = 0.0f;
  for(int i = 0;i < grid.x/8;i++) {
    ans += h_b[i];
  }
  cout << ans << '\n';
  return 0;
}
