#include<iostream>
#include<ctime>
#include"head.h"
using namespace std;
#define R 
template<typename T>
void __global__ transpose(const T* src,T *after,unsigned int row, unsigned int column) {
  unsigned int idx = threadIdx.x + blockDim.x * blockIdx.x * 4;
  unsigned int idy = threadIdx.y + blockDim.y * blockIdx.y;
  if(idx + blockDim.x  * 3< row && idy < column) {
    //read merge
#ifdef C 
    unsigned int to = idx * column + idy;
    unsigned int fo = idy * row + idx;
    unsigned int step = blockDim.x * column;
    //read row write column
    after[to] = src[fo];
    after[to + step] = src[fo + blockDim.x];
    after[to + step*2] = src[fo + blockDim.x*2];
    after[to + step*3] = src[fo + blockDim.x*3];
#else 
    //read column write row
    unsigned int to = idx * column + idy;
    unsigned int fo = idy * row + idx;
    unsigned int step = blockDim.x * column;
    after[fo] = src[to];
    after[fo + blockDim.x] = src[to + step];
    after[fo + blockDim.x*2] = src[to + step*2];
    after[fo + blockDim.x*3] = src[to + step*3];
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
  int Column = 32;
  int nx = 1 << 9;
  int ny = 1 << 9;
  int N = nx * ny;
  int a[N], b[N],*a_dev,*b_dev;
  clock_t start, end;
  for(int i = 0;i < N;i++) {
    a[i] = i;
  }
  start = clock();
  transposeHost(a,b,nx,ny);
  end = clock();
  cout << "cpu :" << end - start << "ms" << endl;
  dim3 block(Row,Column);
  dim3 grid( (nx + Row*4 - 1)/Row/4,  (Column + ny - 1)/Column);
  cudaMalloc((void**)&a_dev,sizeof(a));
  cudaMalloc((void**)&b_dev,sizeof(a));
  cout << "brea 1" << sizeof(a) <<endl;
  cudaMemcpy(a_dev,a,sizeof(a),cudaMemcpyHostToDevice);
  start = clock();
  transpose<<<block,grid>>>(a_dev,b_dev,nx,ny);
  cudaDeviceSynchronize();
  end = clock();
  cudaMemcpy(a, b_dev, sizeof(a), cudaMemcpyDeviceToHost);
  cudaDeviceSynchronize();
  for(int i = 0;i < N;i++) {
    if(a[i] != b[i]) {
      cout <<"failed" << endl;
    }
  }
  cout <<"gpu:" <<  end - start << "ms" << endl;
  return 0;
}
