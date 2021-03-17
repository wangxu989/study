#include<iostream>
#include<ctime>
using namespace std;
#define O1
__global__ void add(int *a,int*b,unsigned int n) {
  unsigned int tid = threadIdx.x;
  int *idata = a + blockIdx.x * blockDim.x;
  unsigned int idx = tid + blockIdx.x * blockDim.x ;
  if(idx >= n) {
    //printf("%d,",blockIdx.x);
    return;
  }
  //printf("%d, ",a[idx]);
#ifdef O3
  for(int stride = blockDim.x/2;stride > 0;stride>>=1) {
    if(tid < stride) {
      idata[tid] += idata[tid + stride];
    }
    __syncthreads();
  }
#else
  for (int i = 1;i < blockDim.x;i *= 2) {
#ifdef O1
    if((tid %(2 * i)) == 0) {
      idata[tid] += idata[tid + i];  
    }
#endif
#ifdef O2
    int index = 2*i*tid;
    if(index < blockDim.x) {
      idata[index] += idata[index + i];
    }
#endif
    __syncthreads();

  }
#endif
  if (tid == 0) {b[blockIdx.x] = idata[0];}
}
int main(int argc,char*argv[]) {
  int SIZE = 512;
  int N = 1<<20;
  dim3 block(SIZE,1);
  int num_gridx = (block.x + N - 1) / block.x;
  dim3 grid(num_gridx, 1);
  std::cout<<"grid: "<<grid.x<<" block: "<<block.x<<std::endl;
  int a[N];
  auto init = [&](auto* a,unsigned int size) -> void{
    for(int i = 0;i < size;i++) {
      //a[i] = random()%100;
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
  add<<<grid, block>>>(a_dev, ans_dev, N);
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
  cout<<ret;
  return 0;
} 
