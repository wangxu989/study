#include"./config.cuh"
#include<iostream>
using namespace std;
void __global__ test(int* outdata) {
  int idx = threadIdx.x;
  outdata[idx] = __shfl_xor(idx, 2);
}
int main() {
  MODEL_(one_arg) model{32,1};// one wrap
  int *out,ans[32];
  model(test,&out, 32);
  cudaMemcpy(ans, out,sizeof(int)*32, cudaMemcpyDeviceToHost);
  cudaDeviceSynchronize();
  for(int i = 0;i < 32;++i) {
    cout << ans[i] << " ";
  }
  cout << "\n";
  return 0;
}
