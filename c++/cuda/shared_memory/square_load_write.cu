#include<iostream>
#include<ctime>
using namespace std;
#define R 32
#define C 32
//#define BY_R

__global__ void by_row(int* data) {
  __shared__ int cache[R][C];
  unsigned int idx = threadIdx.y * blockDim.x + threadIdx.x;
  cache[threadIdx.y][threadIdx.x] = idx;
  __syncthreads();
  data[idx] = cache[threadIdx.y][threadIdx.x];
}
__global__ void by_column(int* data) {
  __shared__ int cache[R][C];
  unsigned int idx = threadIdx.y * blockDim.x + threadIdx.x;
  cache[threadIdx.x][threadIdx.y] = idx;
  __syncthreads();
  data[idx] = cache[threadIdx.x][threadIdx.y];
}

int main() {
  clock_t start, end;
  int *a_dev;
  dim3 block(R,C);
  cudaMalloc((void**)&a_dev, sizeof(R*C));
  start = clock();
#ifdef BY_R
  by_row<<<1,block>>>(a_dev);
  cout << "gpu by_row    ";
#else
  by_column<<<1,block>>>(a_dev);
  cout << "gpu by_column    ";
#endif
  cudaDeviceSynchronize();
  end = clock();
  cout << end - start << "us" << endl;
  return 0;
}
