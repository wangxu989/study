#include<iostream>
#include<ctime>
using namespace std;
template<unsigned int DIMX, unsigned int DIMY, typename T>
__global__ void transpose(T *in_data, T *out_data, unsigned int nx, unsigned int ny) {
  //padding = 2
  __shared__ T tile[DIMY][DIMX*2 + 2];
  unsigned int idx = threadIdx.x + blockDim.x * blockIdx.x * 2;
  unsigned int idy = threadIdx.y + blockDim.y * blockIdx.y;
  if(idx + blockDim.x < nx && idy < ny) {
    tile[threadIdx.y][threadIdx.x] = in_data[idy * nx + idx];
    tile[threadIdx.y][threadIdx.x + blockDim.x] = in_data[idy * nx + idx + blockDim.x];
    __syncthreads();
    unsigned int posB = threadIdx.y * blockDim.x + threadIdx.x;
    unsigned int column = posB / blockDim.y;
    unsigned int row = posB % blockDim.y;
    idx = column + blockDim.x * blockIdx.x * 2;
    idy = row + blockDim.y * blockIdx.y;
    out_data[idx * ny + idy] = tile[row][column];
    out_data[(idx + blockDim.x) * ny + idy] = tile[row][column + blockDim.x];
  }
}
template<typename T>
void transposeHost(T *in, T* out, unsigned int nx, unsigned int ny) {
  for(int i = 0;i < nx;++i) {
    for(int j = 0;j < ny;++j) {
      out[i * ny + j] = in[j * nx + i];
    }
  }
}
int main(int argc, char *argv[]) {
  unsigned int nx = 1 << 9;
  unsigned int ny = 1 << 9;
  constexpr unsigned int blockx = 32;
  constexpr unsigned int blocky = 32;
  clock_t start, end;
  int in[nx * ny], out[nx * ny], *in_dev, *out_dev;
  auto init = [](auto*in ,unsigned int size)->void {
    for(int i = 0;i < size;++i) {
      in[i] = random()%1000;
    }
  };
  init(in, nx * ny);
  cudaMalloc((void**)&in_dev, sizeof(in));
  cudaMalloc((void**)&out_dev, sizeof(in));
  cudaMemcpy(in_dev, in ,sizeof(in), cudaMemcpyHostToDevice);
  cudaDeviceSynchronize();
  transposeHost(in, out, nx, ny);
  dim3 block(blockx, blocky);
  dim3 grid((nx + blockx - 1) / blockx / 2, (ny + blocky - 1) / blocky);
  start = clock();
  transpose<blockx, blocky><<<grid, block>>>(in_dev, out_dev, nx,ny);
  cudaDeviceSynchronize();
  end = clock();
  cout <<" gpu time: " << end - start<<endl;
  cudaMemcpy(in, out_dev,sizeof(in), cudaMemcpyDeviceToHost);
  cudaDeviceSynchronize();
  cudaFree(in_dev);
  cudaFree(out_dev);
  int n = 0;
  for (int i = 0;i < nx * ny;++i) {
    if(out[i] != in[i]) {
      n++;
    }
  }
  cout << n << endl;
  return 0;
}
