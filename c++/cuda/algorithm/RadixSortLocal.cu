#include<iostream>
#include<ctime>
#include<assert.h>
#include<algorithm>
#define EACH_THREAD 256
#define SIZE 1024
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

template<unsigned int each,unsigned int size>
void __global__ RadixSort(float* data, unsigned int n) {
  //unsigned int idx = threadIdx.x + blockDim.x * blockIdx.x * each_thread;
  unsigned int tid = threadIdx.x;
  //bitwise push
  unsigned int local[each*2];
  for(unsigned int i = 0;i < each;++i) {
    //if(tid + i * blockDim.x < n) {
      local[i] = convert(data[tid + i * blockDim.x]);
    //}
  }
  __syncthreads();
  for (unsigned int bit = 0;bit < 32;bit++) {
      unsigned int mask = 1<<bit;
      unsigned int cnt[2] = {0,0};
      for(unsigned int i = 0;i < each;++i) {
        unsigned int elem = local[i];
        unsigned int index_type = (mask&elem)>>bit;
        local[cnt[index_type] + index_type * each] = elem;
        cnt[index_type]++;
      }
      for (unsigned int i = 0;i < cnt[1];++i) {
        local[cnt[0] + i] = local[i + each];
      }
  }
  //merge
 __shared__ unsigned int min_value, min_tid;
 __shared__ unsigned int list_idx[size];
 unsigned int elem = 0xffffffff;
 list_idx[tid] = 0;
 __syncthreads();
 for(unsigned int i = 0;i < n;i++) {
   elem = 0xffffffff;
   if(list_idx[tid] < each) {
     elem = local[list_idx[tid]];
   }
   __syncthreads();
   min_value = min_tid = 0xffffffff;
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
  dim3 block(SIZE,1);
  dim3 grid(1, 1);
  cudaMalloc((void**)&a_dev, sizeof(float)*N);
  cudaMemcpy(a_dev, a, sizeof(float)*N,cudaMemcpyHostToDevice);
  cudaDeviceSynchronize();
  start = clock();
  RadixSort<EACH_THREAD,SIZE><<<grid,block>>>(a_dev, N);
  cudaDeviceSynchronize();
  end = clock();
  cout << "gpu time:" << end - start << endl;
  cudaMemcpy(b, a_dev, sizeof(float)*N, cudaMemcpyDeviceToHost);
  cudaDeviceSynchronize();
  for (int i = 0;i < N;i++) {
   // cout << b[i] <<" ";
  }
  cout << endl;
  start = clock();
  RadixSortHost(a,N);
  end = clock();
  cout << "cpu time:" << end - start << endl;
  for (int i = 0;i < N;i++) {
    if(a[i] != b[i]) {
      printf("error: index%u gpu:%f cpu:%f\n",i,b[i], a[i]);
    }
  }

  return 0;
}
