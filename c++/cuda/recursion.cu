#include<iostream>
#include<ctime>
//recursion version  of sum
using namespace std;
template<typename T>
__global__ void add(T* a,T* b,unsigned int iSize) {
  unsigned int tid = threadIdx.x;
  T* idata = a + blockDim.x * blockIdx.x;
  T* odata = b + blockIdx.x;
  if(iSize == 2 && tid == 0) {
    *b = idata[0] + idata[1];   
    return;
  }
  int stride = iSize>>1;
  if (stride > 1 && tid < stride) {
    idata[tid] += idata[tid + stride];
  }
  //__syncthreads();
  if(tid == 0) {
    //idata & odata
    //why ? 
    //odata : because after depth0 blockIdx.x = 0
    add<<<1, stride>>>(idata, odata, stride);
    //cudaDeviceSynchronize();
  }
 // __syncthreads();
}
int main() {
  int N = 1<<20;
  int SIZE = 512;
  dim3 block(SIZE,1);
  dim3 grid((block.x + N -1) / block.x,1);
  float a[N],b[grid.x];
  auto init = [&](auto a,unsigned int size)->void{
    for(int i = 0;i < size;i++) {
      a[i] = 1;
    }
  };
  init(a, N);
  float *a_dev, *b_dev;
  cudaMalloc((float**)&a_dev, sizeof(float)*N);
  cudaMalloc((float**)&b_dev, sizeof(float)*grid.x);
  cudaMemcpy(a_dev, a, sizeof(float)*N,cudaMemcpyHostToDevice);
  cudaDeviceSynchronize();
  clock_t start, end;
  start = clock();
  add<<<grid, block>>>(a_dev, b_dev, block.x);
  cudaDeviceSynchronize();
  end = clock();
  cudaMemcpy(b, b_dev, sizeof(float)*grid.x,cudaMemcpyDeviceToHost);
  cout<<"GPU use time :"<<end - start<<"ms"<<endl;
  float ans = 0;
  for(int i = 0;i < grid.x;i++) {
    ans += b[i];
  }
  cout<<ans<<endl;
  return 0;
}
