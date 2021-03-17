#include<iostream>
using namespace std;
#define blockx 8
#define gridx 1
__global__ void print_hello_word(int iSize, int iDepth) {
  int tid = threadIdx.x;
  printf("Recursion=%d: HelloWorld from thread %d \
      block %d\n",iDepth, tid,blockIdx.x);
  if(iSize == 1) {return;}

  int nthreads = iSize>>1;

  if(tid == 0 && nthreads > 0) {
    print_hello_word<<<1,nthreads>>>(nthreads, ++iDepth);
    printf("------> nested execution depth: %d\n",iDepth);
  }
}
int main() {
  dim3 block(blockx, 1);
  dim3 grid(gridx, 1);
  print_hello_word<<<grid, block>>>(8,0);
  cudaDeviceSynchronize();
  return 0;
}
