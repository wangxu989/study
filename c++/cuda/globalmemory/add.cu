#include<iostream>
#include<ctime>
#define Size 512
using namespace std;
template<typename T, unsigned int BlockSize>
void __global__ add(const T* lhs,const T *rhs ,T*sum, const unsigned int n) {
  unsigned int idx = threadIdx.x + blockIdx.x * blockDim.x*4;
  if(idx + 3*blockDim.x < n) {
    sum[idx] = lhs[idx] + rhs[idx];
    sum[idx + blockDim.x] = lhs[idx + blockDim.x] + rhs[idx + blockDim.x];
    sum[idx + blockDim.x*2] = lhs[idx + blockDim.x*2] + rhs[idx + blockDim.x*2];
    sum[idx + blockDim.x*3] = lhs[idx + blockDim.x*3] + rhs[idx + blockDim.x*3];
  }
}
int main() {
  int N = 1 << 19;
  dim3 block(Size,1);
  dim3 grid( (N + Size - 1)/Size/4 ,1);
  float  a[N],b[N],c[N] ,*a_dev,*b_dev,*c_dev;
  clock_t start, end;
  memset(c, 0 , sizeof(c));
  auto init = [&](auto* a,unsigned int n) {
    for (int i = 0;i < n;i++) {
      a[i] = (float)(rand()&0xff) / 100.0f;
    }
  };
  init(a,N);
  init(b,N);
  cudaMalloc((void**)&a_dev, sizeof(float)*N);
  cudaMalloc((void**)&b_dev, sizeof(float)*N);
  cudaMalloc((void**)&c_dev, sizeof(float)*N);
  cudaMemcpy(a_dev ,a , sizeof(a),cudaMemcpyHostToDevice);
  cudaMemcpy(b_dev ,b , sizeof(b),cudaMemcpyHostToDevice);
  start = clock();
  add<float,Size><<<grid, block>>>(a_dev, b_dev, c_dev,N);
  cudaDeviceSynchronize();
  end = clock();
  cout << "sum time on gpu:" << end - start << endl;

  cudaMemcpy(c, c_dev,sizeof(c),cudaMemcpyDeviceToHost);
  for (int i = 0;i < N;i++) {
    if(a[i] + b[i] != c[i]) {
      cout << "failed" <<endl;
    }
  }
  return 0;
}
