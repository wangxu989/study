#include<iostream>
#include"./include/check_input.h"
#include"./include/prints.h"
using namespace std;
using namespace check;
using namespace prints;
__device__ float val;
void __global__ test() {
  printf("test_global_val: %f\n",val);
}
int main(int argc ,char* argv[]) {
  device_conf dev{1,1};
  check_input(argc, argv, dev);
  print_v(dev.blocksize, dev.gridsize);
  float t = 2.0f;
  cudaMemcpyToSymbol(val, &t, sizeof(float));
  dim3 block(dev.blocksize, 1);
  dim3 grid(dev.gridsize, 1);
  test<<<grid, block>>>();
  cudaDeviceSynchronize();
}

