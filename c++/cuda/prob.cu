#include<iostream>
using namespace std;
//test file product  on GPU
template<unsigned int blocksize, typename T>
__global__ void prob(T* a, T* b,unsigned int n) {
  unsigned int tid = threadIdx.x;
  unsigned int idx = threadIdx.x + blockDim.x*blockIdx.x*8;
  T *data = a + blockDim.x*blockIdx.x*8;
  //增加存储效率
  if(idx  + blockDim.x*7 < n) {
    a[idx] *= a[idx + blockDim.x];
    a[idx] *= a[idx + blockDim.x*2];
    a[idx] *= a[idx + blockDim.x*3];
    a[idx] *= a[idx + blockDim.x*4];
    a[idx] *= a[idx + blockDim.x*5];
    a[idx] *= a[idx + blockDim.x*6];
    a[idx] *= a[idx + blockDim.x*7];
  }
  __syncthreads();
  //规约
  if(blocksize >= 1024 && tid < 512) {
    data[tid] *= data[tid + 512];
  }
  __syncthreads();
  if(blocksize >= 512 && tid < 256) {
    data[tid] *= data[tid + 256];
  }
  __syncthreads();
  if(blocksize >= 256 && tid < 128) {
    data[tid] *= data[tid + 128];
  }
  __syncthreads();
  if(blocksize >= 128 && tid < 64) {
    data[tid] *= data[tid + 64];
  }
  __syncthreads();

  if(tid < 32) {
    volatile T *vmem = data;
    vmem[tid] *= vmem[tid + 32];
    vmem[tid] *= vmem[tid + 16];
    vmem[tid] *= vmem[tid + 8];
    vmem[tid] *= vmem[tid + 4];
    vmem[tid] *= vmem[tid + 2];
    vmem[tid] *= vmem[tid + 1];
  }
  if(tid == 0) {b[blockIdx.x] = data[0];}
}
int main() {
  unsigned int N = 1<<20;
  int SIZE = 512;
  dim3 block(SIZE,1);
  dim3 grid((block.x + N - 1)/block.x,1);
  float a[N],b[grid.x];
  for (int i = 0;i < N;i++) {
    a[i] = 1;
  }
  float *a_dev, *b_dev;
  cudaMalloc((float**)&a_dev, sizeof(float)*N);
  cudaMalloc((float**)&b_dev, sizeof(float)*grid.x);
  cudaMemcpy(a_dev, a, sizeof(float)*N, cudaMemcpyHostToDevice);
  cudaDeviceSynchronize();
  switch(SIZE) {
    case 512:
    prob<512><<<grid.x/8,block>>>(a_dev, b_dev, N);
    break;
  }
  cudaMemcpy(b, b_dev, sizeof(float)*grid.x, cudaMemcpyDeviceToHost);
  cudaDeviceSynchronize();
  float ans = 1.0f;
  for(int i = 0;i < grid.x;i++) {
    ans += b[i];
  }
  cout<<ans<<endl;
  return 0;
}
