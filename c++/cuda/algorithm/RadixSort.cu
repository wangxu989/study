#include<iostream>
#include<ctime>
#include<assert.h>
#include<algorithm>
#define EACH_THREAD 32
#define SIZE 512
using namespace std;
template<typename T>
__device__ unsigned int convert(T t) {
  assert(false);
}
template<>
__device__ __host__ unsigned int convert(float v) {
  // if v >= 0 v |= 2^31 else v = ~(v) - 1,ensure anyif v >=0 or v < 0 by bitwise compare is vaild
  unsigned int cmp = *reinterpret_cast<unsigned int*>(&v);
  unsigned int ret = (cmp & (1<<31)) ?  ~(cmp): (cmp | 0x80000000);
  return ret;
}

__device__ __host__ float deconvert(unsigned int v) {
  unsigned int tmp = (v & (1 << 31)) ?  (v ^ 0x80000000) : ~(v);
  return *reinterpret_cast<float*>(&tmp);
}

template<unsigned int each_thread>
void __global__ RadixSort(float* data, unsigned int* sort_tmp0,unsigned int* sort_tmp1, unsigned int n) {
  unsigned int idx = threadIdx.x + blockDim.x * blockIdx.x * each_thread;
  unsigned int tid = threadIdx.x;
  if(idx >= n) {
    return ;
  }
  //bitwise push
  for (unsigned int bit = 0;bit < 32;bit++) {
      unsigned int mask = 1<<bit;
      unsigned int cnt0 = 0,cnt1 = 0;
      for(unsigned int i = tid;i < n;i += blockDim.x) {
        unsigned int elem = (bit == 0 ? convert(data[i]):sort_tmp0[i]);
        if((elem&mask) != 0) {
          sort_tmp1[cnt1 + tid] = elem;
          cnt1 += blockDim.x;
        }
        else {
          sort_tmp0[cnt0 + tid] = elem;
          cnt0 += blockDim.x;
        }
      }
      for (unsigned int i = 0;i < cnt1;i += blockDim.x) {
        sort_tmp0[cnt0 + i + tid] = sort_tmp1[i + tid];
      }
  }
  //merge
  __shared__ unsigned int min_value, min_tid;
  __shared__ unsigned int list_idx[512];
  unsigned int elem = 0xffffffff;
  list_idx[tid] = 0;
  __syncthreads();
  for(unsigned int i = 0;i < n;i++) {
    unsigned int x = (list_idx[tid] * blockDim.x) + tid;
    if(x < n) {
      elem = sort_tmp0[x];
    }
    else {
      elem = 0xffffffff;
    }
    if(tid == 0) {
      min_value = min_tid = 0xffffffff;
    }
    __syncthreads();
    atomicMin(&min_value,elem);
    __syncthreads();

    if(min_value == elem) {
      atomicMin(&min_tid, tid);
    }
    __syncthreads();
    if(min_tid == tid) {
      list_idx[tid]++;
      data[i] = deconvert(min_value);
    }
    __syncthreads();
  }
}

void RadixSortHost(float *v,unsigned int size) {
  unsigned int sort_tmp0[size],sort_tmp1[size];
  for(int bit = 0;bit < 32;bit++) {
    unsigned int mask = 1 << bit;
    unsigned int cnt0 = 0,cnt1 = 0;
    for (int i = 0;i < size;i++) {
      unsigned int elem = ((bit == 0) ?convert(v[i]):sort_tmp0[i]);
      if((elem & mask) != 0) {
        sort_tmp1[cnt1++] = elem;
      }
      else {
        sort_tmp0[cnt0++] = elem;
      }
    }
    for(int i = 0;i < cnt1;i++) {
      sort_tmp0[cnt0 + i] = sort_tmp1[i];
    }
  }
  for(int i = 0;i < size;i++) {
    v[i] = deconvert(sort_tmp0[i]);
  }
}
__shared__ unsigned int sort_tmp0[SIZE * EACH_THREAD];
__shared__ unsigned int sort_tmp1[SIZE * EACH_THREAD];

int main() {
  int N = SIZE * EACH_THREAD;
  float a[N],b[N];
  auto init = [](auto*a ,unsigned int size)->void {
    for(int i = 0;i < size;i++) {
      a[i] = pow(-1,i) * (random()%1000);
    }
  };
  init(a, N);
  float *a_dev;
  clock_t start ,end;
  unsigned int *sort_tmp0, *sort_tmp1;
  dim3 block(512,1);
  dim3 grid( (N + block.x -1) / block.x /EACH_THREAD , 1);
  cudaMalloc((void**)&a_dev, sizeof(float)*N);
  cudaMalloc((void**)&sort_tmp0, sizeof(unsigned int)*N);
  cudaMalloc((void**)&sort_tmp1, sizeof(unsigned int)*N);
  cudaMemcpy(a_dev, a, sizeof(float)*N,cudaMemcpyHostToDevice);
  cudaDeviceSynchronize();
  start = clock();
  RadixSort<EACH_THREAD><<<grid,block>>>(a_dev, sort_tmp0, sort_tmp1, N);
  cudaDeviceSynchronize();
  end = clock();
  cout << "gpu time:" << end - start << endl;
  cudaMemcpy(b, a_dev, sizeof(float)*N, cudaMemcpyDeviceToHost);
  cudaDeviceSynchronize();
  for (int i = 0;i < N;i++) {
   // cout << b[i] <<" ";
  }
  cout << endl;
  RadixSortHost(a,N);
  for (int i = 0;i < N;i++) {
    if(a[i] != b[i]) {
      //printf("error: index%u gpu:%f cpu:%f\n",i,b[i], a[i]);
    }
  }

  return 0;
}
