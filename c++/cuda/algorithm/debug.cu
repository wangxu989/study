#include<iostream>
using namespace std;
typedef uint32_t RadixType;
__device__ unsigned int convert(float v) {
  // if v >= 0 v &= 2^31 else v &= 2^32 - 1,ensure anyif v >=0 or v < 0 by bitwise compare is vaild
  RadixType x = __float_as_int(v);
  RadixType mask = (x & 0x80000000) ? 0xffffffff : 0x80000000;
  return (v == v) ? (x ^ mask) : 0xffffffff;
}

__device__  float deconvert(RadixType v) {
  RadixType mask = (v & 0x80000000) ? 0x80000000 : 0xffffffff;
  return __int_as_float(v ^ mask);
}
__global__ void test() {
  float x = 1 << 20;
  printf("%f %u    %f",x , convert(x),deconvert(convert(x)));
}

int main() {
  dim3 block(1,1);
  dim3 grid(1,1);
  test<<<block,grid>>>();
  cudaDeviceSynchronize();
  return 0;
}
