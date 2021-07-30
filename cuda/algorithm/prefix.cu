#include<iostream>
#include<algorithm>
#include<ctime>
using namespace std;
template<unsigned int warp_size, unsigned int loop, typename T>
__global__ void prefix(T* begin, T* end, T* out, int n) {
  extern __shared__ T smem[];
  int idx = threadIdx.x;
  int laneid = idx % warp_size;
  int warp_idx = idx / warp_size;
  T acc_warp_sum = 0;
  for(int i = idx;i < n;i += blockDim.x) {
    T data = begin[i];
    T tmp = data;
    T t = 0;
#pragma unroll
    for(int j = 1;j < warp_size;j <<= 1) {
      t = __shfl_up(tmp, j);
      if(laneid >= j) {
        tmp += t;
      }
    }
    if(laneid == warp_size - 1) {
      smem[warp_idx] = tmp;
    }
    __syncthreads();
    T warp_tmp = 0;
    if(threadIdx.x < loop) {
      T warp_data = smem[threadIdx.x];
      warp_tmp = warp_data;
#pragma unroll
      for(int j = 1;j < warp_size;j <<= 1) {
        t = __shfl_up(warp_tmp, j);
        if(laneid >= j) {
          warp_tmp += t;
        }
      }
      smem[threadIdx.x] = warp_tmp;
    }
    __syncthreads();
    out[i] = (warp_idx > 0 ?smem[warp_idx - 1]:0) + tmp - data + acc_warp_sum;
    acc_warp_sum += smem[loop - 1];
  }
}
template<typename T>
void host_prefix(T*a ,int n) {
  int sum = 0;
  for(int i = 0;i < n;++i) {
    sum += a[i];
    a[i] = sum - a[i];
  }
}
typedef float dtype;
int main() {
  dtype *a;
  int n = 1<<20;
  n *= 100;
  dtype *b, *c;
  b = (dtype*)malloc(sizeof(dtype) * n);
  c = (dtype*)malloc(sizeof(dtype) * n);
  clock_t start,end;
  for(int i = 0;i < n;i++){b[i] = c[i] = random();}
  cudaMalloc((void**)&a, sizeof(dtype) * n);
  cudaMemcpy(a, b, sizeof(dtype)*n, cudaMemcpyHostToDevice);
  start = clock();
  prefix<32, 32><<<1, 1024, 32*4>>>(a, a + n, a, n);
  cudaDeviceSynchronize();
  end = clock();
  cudaMemcpy(b, a, sizeof(dtype)*n, cudaMemcpyDeviceToHost);
  cudaDeviceSynchronize();
  //for_each(b, b + n, [](int a)->void{cout << a << " ";});
  cout << "\n";
  cout << "time:" << end - start << endl;
  start = clock();
  host_prefix(c, n);
  end = clock();
  cout << "time:" << end - start << endl;
  //for(int i = 0;i < n;++i) {
  //  if(b[i] != c[i]) {
  //    cout << "error: "<<b[i] << " not equal " <<c[i]<<"\n";
  //  }
  //}
  return 0;
}


