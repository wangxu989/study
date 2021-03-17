#include<iostream>
#include<ctime>
using namespace std;
#define O3
__global__ void add(int*a,int*b,unsigned int n) {
  unsigned int tid = threadIdx.x;
  unsigned int idx = threadIdx.x + blockIdx.x * blockDim.x * 8;
  int *idata = a + blockIdx.x * blockDim.x*8;
  if(idx + 7*blockDim.x < n) {
    a[idx] += a[idx + blockDim.x];
    a[idx] += a[idx + 2*blockDim.x];
    a[idx] += a[idx + 3*blockDim.x];
    a[idx] += a[idx + 4*blockDim.x];
    a[idx] += a[idx + 5*blockDim.x];
    a[idx] += a[idx + 6*blockDim.x];
    a[idx] += a[idx + 7*blockDim.x];
  }
  //if(idx  + blockDim.x < n) a[idx] += a[idx + blockDim.x];
  __syncthreads();
  for(int stride = blockDim.x/2;stride > 32;stride>>=1) {
    if(tid < stride) {
      idata[tid] += idata[tid + stride];
    }
    __syncthreads();
  }
  if(tid < 32) {
    volatile int *vmem = idata;
    vmem[tid] += vmem[tid + 32];
    vmem[tid] += vmem[tid + 16];
    vmem[tid] += vmem[tid + 8];
    vmem[tid] += vmem[tid + 4];
    vmem[tid] += vmem[tid + 2];
    vmem[tid] += vmem[tid + 1];
  }
  if (tid == 0) {b[blockIdx.x] = idata[0];}
}
int main(int argc,char*argv[]) {
  int SIZE =  512;
  int N = 1<<20;
  dim3 block(SIZE,1);
  dim3 grid((block.x + N - 1)/block.x, 1);
  int a[N];
  auto init = [&](auto* a,unsigned int size) -> void{
    for(int i = 0;i < size;i++) {
      a[i] = 1;
    }
  };
  int *a_dev, *ans_dev,ans[grid.x];
  init(a, N);
  cudaMalloc((int**)(&a_dev),sizeof(int)*N);
  cudaMalloc((int**)(&ans_dev),sizeof(int)*grid.x);
  cudaMemcpy(a_dev, a, sizeof(int)*N, cudaMemcpyHostToDevice);
  cudaDeviceSynchronize();
  clock_t start,end;
  start = clock();
  add<<<grid.x/8, block>>>(a_dev, ans_dev, N);
  cudaDeviceSynchronize();
  end = clock();
  cout<<"GPU time : "<<end - start<<"ms"<<endl;
  start = clock();
  for(int i = 1;i < N;i++) {
    a[0] += a[i];
  }
  cout<<a[0]<<endl;
  end = clock();
  cout<<"CPU time : "<<end - start<<"ms"<<endl;
  cudaMemcpy (&ans, ans_dev, sizeof(int)*grid.x, cudaMemcpyDeviceToHost);
  cudaDeviceSynchronize();
  int ret = 0;
  for (int i = 0;i < grid.x;i++) {
    ret += ans[i];
  }
  cout<<ret<<endl;
  return 0;
} 
