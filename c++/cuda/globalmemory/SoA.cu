#include<iostream>
#include<ctime>
using namespace std;
#define Size 512
struct SoA {
  float x[N];
  float y[N];
};
void __global__  test_SoA(struct SoA *data,unsigned int n) {
  unsigned int idx = threadIdx.x + blockDim.x * blockIdx.x;
  if (idx < n) {
    data->x[idx] += 1.0f;
    data->y[idx] += 2.0f;
  }
}
int main() {
  int N = 1 << 18;
  dim3 block(Size, 1);
  dim3 grid((Size + N - 1)/Size, 1);
  
  struct SoA a , *a_dev;
  cudaMalloc((void**)(&a_dev),sizeof(struct SoA));
  cudaMemcpy(a_dev, &a ,sizeof(struct SoA), cudaMemcpyHostToDevice);
  clock_t start ,end;
  start = clock();
  test_SoA<<<block,grid>>>(a_dev,N);
  cudaDeviceSynchronize();
  end = clock();
  cout << "sum time gpu compute:" << end -start << endl;
  cudaDeviceReset();
  return 0;
}
