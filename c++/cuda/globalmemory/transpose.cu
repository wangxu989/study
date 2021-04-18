#include<iostream>
#include<ctime>
#include"head.h"
using namespace std;
#define R
template<typename T>
void __global__ transpose(const T* src,T *after,unsigned int row, unsigned int column) {
  unsigned int idx = threadIdx.x + blockDim.x * blockIdx.x * 4;
  unsigned int idy = threadIdx.y + blockDim.y * blockIdx.y;
  if(idx + blockDim.x * blockIdx.x * 4< row && idy < column) {
    //read merge
#ifdef R
    unsigned int fo = idx * column + idy;
    unsigned int to = idy * row + idx;
    //read column write row
    after[to] = src[fo];
    after[to + blockDim.x] = src[fo + blockDim.x];
    after[to + blockDim.x*2] = src[fo + blockDim.x*2];
    after[to + blockDim.x*3] = src[fo + blockDim.x*3];
#elif define C
    //read row write column
    after[idx * column + idy] = src[idy * row + idx];
    //after[idx * column + idy] = src[idy * row + idx];

#endif
  }
}
template<typename T>
void transposeHost(const T* src, T* after, unsigned int row, unsigned int column) {
  for (int i = 0;i < row;i++) {
    for(int j = 0;j < column;j++) {
      after[j * row + i] = src[i * column + j];
    }
  }
}
int main(int argc,char *argv[]) {
  int Row = 32;
  int Column = 16;
  int nx = 1 << 9;
  int ny = 1 << 9;
  int a[] = {0,1,2,3,4,5,6,7,8,9,10,11};
  int b[12];
  memset(b,0x0,sizeof(b));
  transposeHost(a,b,3,4);
  for (int i = 0;i < 12;i++) {
    cout << b[i] <<" ";
  }
  cout <<endl;
  int a_[ny * nx],*a_dev,*b_dev;
  dim3 block(Row,Column);
  dim3 grid( (nx + Row*4 - 1)/Row*4,  (Column + ny - 1)/Column);
  cudaMalloc((void**)&a_dev,sizeof(a_));
  cudaMalloc((void**)&b_dev,sizeof(a_));
  cout << "brea 1" << sizeof(a_) <<endl;
  cudaMemcpy(a_dev,a_,sizeof(a_),cudaMemcpyHostToDevice);
  clock_t start, end;
  start = clock();
  transpose<<<block,grid>>>(a_dev,b_dev,nx,ny);
  cudaDeviceSynchronize();
  end = clock();
  cout << end - start << "ms" << endl;
  return 0;
}
