#include<iostream>
#include<ctime>
using namespace std;
#define Bits 20
#define BlockDimx 512
__device__ float out;
template<unsigned int  BlockSize, typename T>
__global__ void add(T *in_data, unsigned int N) {
  __shared__ T smem[BlockSize];
  T tmp_val = T(0);
  unsigned int idx = threadIdx.x + blockDim.x * blockIdx.x*4;
  if (idx +  blockDim.x * 3 < N) {
    T a1 = in_data[idx];
    T a2 = in_data[idx + blockDim.x];
    T a3 = in_data[idx + blockDim.x * 2];
    T a4 = in_data[idx + blockDim.x * 3];
    tmp_val = a1 + a2 + a3 + a4;
  }
  smem[threadIdx.x] = tmp_val;
  __syncthreads();

  if(BlockSize >= 1024 && threadIdx.x < 512) {
    smem[threadIdx.x] += smem[threadIdx.x + 512];
  }
  __syncthreads();


  if(BlockSize >= 512 && threadIdx.x < 256) {
    smem[threadIdx.x] += smem[threadIdx.x + 256];
  }
  __syncthreads();
  if(BlockSize >= 256 && threadIdx.x < 128) {
    smem[threadIdx.x] += smem[threadIdx.x + 128];
  }
  __syncthreads();
  if(BlockSize >= 128 && threadIdx.x < 64) {
    smem[threadIdx.x] += smem[threadIdx.x + 64];
  }
  __syncthreads();
  if(threadIdx.x < 32) {
    volatile T* vmem = smem;
    vmem[threadIdx.x] += vmem[threadIdx.x + 32];
    vmem[threadIdx.x] += vmem[threadIdx.x + 16];
    vmem[threadIdx.x] += vmem[threadIdx.x + 8];
    vmem[threadIdx.x] += vmem[threadIdx.x + 4];
    vmem[threadIdx.x] += vmem[threadIdx.x + 2];
    vmem[threadIdx.x] += vmem[threadIdx.x + 1];
  }
  if(threadIdx.x == 0) {
    atomicAdd(&out, smem[0]);   
  }
}

int main(int argc ,char *argv[]) {
  unsigned int N = 1 << Bits;
  dim3 block(BlockDimx,1);
  dim3 grid((N + BlockDimx -1) / BlockDimx / 4, 1);
  float in[N], *in_dev, t = 0;
  clock_t start ,end;
  auto init = [](auto *in ,unsigned int size)->void {
    for(int i = 0;i < size;++i) {
      in[i] = 1;
    }
  };
  init(in, N);
  cudaMalloc((void**)&in_dev, sizeof(in));
  cudaMemcpy(in_dev, in, sizeof(in), cudaMemcpyHostToDevice);
  start = clock();
  add<BlockDimx><<<grid, block>>>(in_dev, N);
  cudaDeviceSynchronize();
  end = clock();
  float ans;
  cudaMemcpyFromSymbol(&ans, out, sizeof(float));
  cudaDeviceSynchronize();
  printf("%f\n", ans);
  printf("%d\n", block.x * grid.x * 4);
  cout <<"gpu time: "<<end -start<<endl;
  return 0;
}
