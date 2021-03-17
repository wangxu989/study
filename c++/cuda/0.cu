#include<iostream>
using namespace std;
#define SIZE 64
__global__ void choice(float *array) {
  float a = 0.0,b = 0.0;
  int index = blockIdx.x*blockDim.x + threadIdx.x;

  if(index%2) {
    a = 100.0f;
  }else {
    b = 200.0f;
  }
  array[index] = a + b;
  printf("val_choice:%f\n",array[index]);
}
__global__ void choice1(float *array) {
  float a = 0.0f,b = 0.0f;
  int index = blockDim.x * blockIdx.x + threadIdx.x;
  if((index/warpSize)%2) {
    a = 100.0f;
  }else {
    b = 200.0f;
  }
  array[index] = a + b;
  printf("val_choice1:%f\n",array[index]);
}
__global__ void compare(float*a,float*b,char *c) {
  int index = blockIdx.x*blockDim.x + threadIdx.x;
  if(a[index] != b[index]) {
    *c = 'f';
  }
}
int main() {
  dim3 block(SIZE,1);
  dim3 grid((SIZE + block.x - 1)/block.x,1);
  int n = grid.x*block.x;
  float *a;
  float *b;
  char *c;
  char c_host = 't';
  cudaMalloc((float**)&a,sizeof(float)*n);
  cudaMalloc((float**)&b,sizeof(float)*n);
  cudaMalloc((bool**)&c,sizeof(bool));
  cudaMemcpy(c, &c_host, sizeof(char), cudaMemcpyHostToDevice);
  choice<<<grid, block>>>(a);
  choice1<<<grid, block>>>(b);
  compare<<<grid, block>>>(a,b,c);
  cudaMemcpy(&c_host, c, sizeof(char), cudaMemcpyDeviceToHost);
  cudaDeviceSynchronize();
  if(c_host == 'f') {
    cout<<"faild"<<endl;
  }
  else {
    cout<<"success"<<endl;
  }
  cudaFree(a);
  cudaFree(b);
  cudaFree(c);
  return 0;
}
