#include<iostream>
#include<ctime>
using namespace std;
typedef unsigned int index_t;
void __global__ transpose(float *src, float *target, index_t nx, index_t ny) {
  index_t blk_y = blockIdx.x;
  index_t blk_x = (blockIdx.x + blockIdx.y) % gridDim.x;

  index_t ix = blockDim.x * blk_x + threadIdx.x;
  index_t iy = blockDim.y * blk_y + threadIdx.y;

  if(ix < nx && iy < ny) {
    target[ix * ny + iy] = src[iy * nx + ix];
  }
}
void __device__ __host__ transposeHost(float *src, float *target, index_t row ,index_t column) {
  for (index_t i = 0;i < row;++i) {
    for (index_t j = 0;j < column;++j) {
      target[j * column + i] = src[i * row + j];
    }
  }
}
int main() {
  int N = 1 << 18;
  cout << N;
  int nx = 1 << 9;
  int ny = 1 << 9;
  int blockx = 32;
  int blocky = 32;
  clock_t start, end;
  float a[N],b[N];
  for(int i = 0;i < N;i++) {
    a[i] = i;
  }
  start = clock();
  transposeHost(a, b, nx,ny);
  end = clock();
  cout << "cpu time:" << end -start <<endl;
  float *a_dev, *b_dev;
  cudaMalloc((void**)&a_dev, sizeof(a));
  cudaMalloc((void**)&b_dev, sizeof(a));
  cudaMemcpy(a_dev, a, sizeof(a), cudaMemcpyHostToDevice);
  dim3 block(blockx, blocky);
  dim3 grid((nx + blockx - 1)/blockx,(ny + blocky - 1)/blocky);
  start = clock();
  transpose<<<block, grid>>>(a_dev, b_dev, nx, ny);
  cudaDeviceSynchronize();
  end = clock();
  cudaMemcpy(a,b_dev, sizeof(a), cudaMemcpyDeviceToHost);
  cudaDeviceSynchronize();
  cout << "gpu time:" << end -start <<endl;
  for(int i = 0;i < N;i++) {
    if(a[i] != b[i]) {
      cout << a[i] << "   "<<b[i] <<endl;
    }
  }
  return 0;
}
