#include<iostream>
#include<ctime>
#define exp 20
#define Size 512
using namespace std;
struct AoS{
  float x,y;
};
void __global__ AoS(AoS* data,unsigned int n) {
  unsigned int idx = threadIdx.x + blockDim.x * blockIdx.x;
  if (idx < n) {
    data[idx].x += 1.0f;
    data[idx].y += 2.0f;
  }
}
int main() {
  int dev = 0;
  cudaDeviceProp deviceProp;
  cudaGetDeviceProperties(&deviceProp, dev);
  cout << "device " << dev << ": " << deviceProp.name << endl;
  int N = 1 << 18; 
  dim3 block(Size,1);
  dim3 grid((Size + N - 1) / Size, 1);
  struct AoS a[N],*a_dev;
  cudaMalloc((void**)&a_dev, sizeof(struct AoS)*N);
  cudaMemcpy(a_dev, a, sizeof(a), cudaMemcpyHostToDevice);
  clock_t start ,end;
  start = clock();
  AoS<<<grid, block>>>(a_dev, N);
  cudaDeviceSynchronize();
  end = clock();
  cout << "sum time in gpu compute:" << end - start << "ms" << endl;
  cudaFree(a_dev);
  cudaDeviceReset();
  return 0;
}
