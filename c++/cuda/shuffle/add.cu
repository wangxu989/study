#include<iostream>
#include<ctime>
using namespace std;
int __device__ warp_reduce(int data) {
  data += __shfl_xor(data,16);
  data += __shfl_xor(data,8);
  data += __shfl_xor(data,4);
  data += __shfl_xor(data,2);
  data += __shfl_xor(data,1);
  return data;
}
void __global__ reduce(int* indata, int* outdata, int n, int warps) {
  extern __shared__ int sm[];
  int laneid = threadIdx.x % 32;
  int warpid = threadIdx.x / 32;
  int idx = blockDim.x * blockIdx.x*4 + threadIdx.x;
  int data = indata[idx];
  int data1 = indata[idx + blockDim.x];
  int data2 = indata[idx + blockDim.x*2];
  int data3 = indata[idx + blockDim.x*3];
  data = warp_reduce(data) + warp_reduce(data1) + warp_reduce(data2) + warp_reduce(data3);
  //reduce global
   if(laneid == 0) {
    sm[warpid] = data;
  }
  __syncthreads();
  //reduce shm
  data = threadIdx.x < warps ? sm[threadIdx.x]:0;
  data = warp_reduce(data);
  if(threadIdx.x == 0) {
    atomicAdd(outdata,data);
  }
}
int main() {
  int n = 1 << 22;
  dim3 block(128, 1);
  dim3 grid((n + block.x - 1)/block.x/4, 1);
  int* in_dev, *in;
  int* out_dev, out;
  in = (int*)malloc(n*sizeof(int));
  for(int i = 0;i < n;++i) {
    in[i] = 1;
  }
  clock_t start ,end;
  cudaError_t error = cudaMalloc((void**)&in_dev, sizeof(int)*n);
  cout << "error : " <<error << endl;
  cudaMalloc((void**)&out_dev, sizeof(int));
  cudaMemcpy(in_dev, in, sizeof(int)*n, cudaMemcpyHostToDevice);
  start = clock();
  reduce<<<grid,block,block.x/32>>>(in_dev, out_dev, n, block.x/32);
  cudaDeviceSynchronize();
  end = clock();
  cudaMemcpy(&out, out_dev,sizeof(out), cudaMemcpyDeviceToHost);
  cudaDeviceSynchronize();
  int ans = 0;
  cout << "gpu time :" << end -start << "\n";
  cout << "ans :" << out << "\n";
  return 0;
}
