#include<stdio.h>
#include<stdlib.h>

int reduction(int a) {
  a += shlf_xor(a, 16);
  a += shlf_xor(a, 8);
  a += shfl_xor(a, 4);
  a += shfl_xor(a, 2);
  a += shfl_xor(a, 1);
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
template<unsigned int per_deal>
void __global__ matmul(int *a, int* b,int* target, int height, int width, width2, int n ) {
  extern  __shared__ int smem[]；
  int idx = blockDim.x * blockIdx.x + threadIdx.x;
  int idy = blockDim.y * blockIdx.y + threadIdx.y;
  smem[threadIdx.y * blockDim.x + threadIdx.x] += a[idx * width + idy] * b[];
  smem[threadIdx.y * blockDim.x + threadIdx.x] += a[idx * width + idy] * b[];

}
int main(int argc, char* argv[]) {
  dim3 block(32, 16);
  int height = 1 << 11;
  int width = 1 << 11;
  int N = height * width;
  int width2 = 1 << 10;
  int n = width * width2;
  int n1 = height * width2;
  dim3 grid(width * width2 / block.x, height / block.y);
  int *a, *b, *c;
  a = (int*)malloc(sizeof(int)*N);
  cudaMallocManaged((void**)&a, sizeof(int)*N);
  b = (int*)malloc(sizeof(int)*n);
  cudaMallocManaged((void**)&a, sizeof(int)*n);
  cudaMallocManaged((void**)&c, sizeof(int)*n1);
  matmul<<<grid, block, block.x * block.y * 2 * sizeof(int)>>>(a, b, target, height, width, width2, N);
  cudaDeviceSynchronize();
  return 0;
}
