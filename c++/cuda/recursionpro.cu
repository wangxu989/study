#include<iostream>
#include<ctime>
//recursion version  of sum
//before: every block's thread0 will generate a grid which contains half threads of father block. time consume :0.014331s
//after:first grid compute the first layer and second grid which has half threads of father grid compute the second layer... 
using namespace std;
template<typename T>
__global__ void add(T* a,T* b,int stride, const int iDim) {
  //iDim is constant val and equal first layer's block.x
  unsigned int tid = threadIdx.x;
  T* idata = a + blockIdx.x * iDim;
  if(stride == 1 && tid == 0) {
    b[blockIdx.x] = idata[0] + idata[1];
    return;
  }
  idata[tid] += idata[tid + stride];
  if(tid == 0 && blockIdx.x == 0) {
    add<<<gridDim.x, stride/2>>>(a, b, stride/2, iDim);
  }
}
int main() {
  int N = 1<<18;
  //int N = 1<<20;
  //problem: when N <= 18 result is valid but else will get a invalid result;
  int SIZE = 1024;
  dim3 block(SIZE,1);
  dim3 grid((block.x + N -1) / block.x,1);
  float a[N],b[grid.x];
  auto init = [&](auto a,int size)->void{
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
  add<<<grid, block.x/2>>>(a_dev, b_dev, block.x/2, block.x);
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
