#include<iostream>
using namespace std;
int n = 100;
__host__ __device__ bool read(int n) {
  return n != 0;
}

__host__ __device__ bool read0(int n) {
  return n == 0;
}

__global__ void test(int n) {
  if(read0(n)) {
    printf("true\n");
  }
  else if(read(n)){
    printf("false\n");
  }
}
int main() {
  dim3 block(8,2);
        test<<<1,block>>>(n);
        cudaDeviceSynchronize();
}
