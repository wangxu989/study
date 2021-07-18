#include<stdio.h>
#include<stdlib.h>
#include<iostream>
#include<ctime>
using namespace std;
__device__ int reduction(int a) {
  a += __shfl_xor(a, 16);
  a += __shfl_xor(a, 8);
  a += __shfl_xor(a, 4);
  a += __shfl_xor(a, 2);
  a += __shfl_xor(a, 1);
  return a;
}
void h_matmul(int *a, int* b,int* target, int height, int width, int width2, int n ) {
  for(int i = 0;i < height;++i) {
    for (int j = 0;j < width2;++j) {
      for (int k = 0;k < width;++k) {
        target[i * width2 + j] += a[i * height + k] * b[width2 * k + j];
      }
    }
  }
}
//thread should match target's size otherwith input's size 
//per = ceil(width / blockDim.x)
template<unsigned int step, unsigned per>
void __global__ matmul(int *a, int* b,int* target, int height, int width, int width2, int n) {
  //__shared__ int src[blockDim.y][blockDim.x + 1];
  __shared__ int src[32][32 + 1];
  __shared__ int tmp_target[32][32];
  int b_id = blockIdx.x % step;
  int idx = b_id * blockDim.x + threadIdx.x;
  int idy = blockIdx.y * blockDim.y + threadIdx.y;
  if (idy < height && idx < width) {
    src[threadIdx.y][threadIdx.x] = a[idy * width + idx];
  }
  int pos = blockIdx.y * blockDim.x + threadIdx.x;
  int pos_x = pos / blockDim.y;
  int pos_y = pos % blockDim.y;
  //every thread deal width2/blockDim.x datas
  int count = 0;
  int tmp = 0;
  int warp_id = threadIdx.x%32;
  for (int i = b_id;i < width2; i += per) {
    tmp_target[pos_y][pos_x]  = src[pos_y][pos_x] * b[idx * width2 + i];
    tmp = tmp_target[threadIdx.y][threadIdx.x];
    __syncthreads();
    if(warp_id == 0) {
      atomicAdd(&target[idy * width2 + b_id], reduction(tmp));
    }
  }
}
int main(int argc, char* argv[]) {
  dim3 block(32, 32);
  int height = 1 << 10;
  int width = 1 << 10;
  int N = height * width;
  constexpr int width2 = 1 << 10;
  int n = width * width2;
  int n1 = height * width2;
  dim3 grid((width2 / block.x) * (width / block.x), height / block.y);
  int *a, *b, *c;
  a = (int*)malloc(sizeof(int)*N);
  cudaMallocManaged((void**)&a, sizeof(int)*N);
  b = (int*)malloc(sizeof(int)*n);
  cudaMallocManaged((void**)&b, sizeof(int)*n);
  c = (int*)malloc(sizeof(int)*n1);
  cudaMallocManaged((void**)&c, sizeof(int)*n1);
  constexpr int per = 1024;
  constexpr int step = (width2 + per - 1)/ per;
  clock_t s, e;
  float time;
  cudaEvent_t start,end;
  cudaEventCreate(&start);
  cudaEventCreate(&end);
  cudaEventRecord(start);
  s = clock();
  matmul<step, per><<<grid, block>>>(a, b, c, height, width, width2, N);
  cudaEventRecord(end);
  cudaEventSynchronize(end);
  e = clock();
  cudaEventElapsedTime(&time, start ,end);
  cout << "gpu time is :" << time << "ms" << endl;
  cout << "gpu time is :" << e -s << "us" << endl;
  return 0;
}
