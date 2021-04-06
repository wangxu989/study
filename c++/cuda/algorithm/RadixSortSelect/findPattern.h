#include<iostream>
#include<assert.h>

template<typename scalar_t>
struct THCNumerics{};

template <>
struct THCNumerics<float> {
  static inline __host__ __device__ bool ne(float a, float b) { return a != b; }
};

template <typename T>
__device__ __forceinline__ T doLdg(const T* p) {
#if __CUDA_ARCH__ >= 350
  return __ldg(p);
#else
  return *p;
#endif
}

template <typename T>
__host__ __device__ __forceinline__ T THCCeilDiv(T a, T b) {
  return (a + b - 1) / b;
}
template <typename T>
__host__ __device__ __forceinline__ T THCRoundUp(T a, T b) {
  return THCCeilDiv(a, b) * b;
}

template <typename scalar_t>
struct TopKTypeConfig {};

template <>
struct TopKTypeConfig<float> {
  typedef uint32_t RadixType;

  // Converts a float to an integer representation with the same
  // sorting; i.e., for floats f1, f2:
  // if f1 < f2 then convert(f1) < convert(f2)
  // We use this to enable radix selection of floating-point values.
  // This also gives a relative order for NaNs, but that's ok, as they
  // will all be adjacent
  // neg inf: signbit=1 exp=ff fraction=0 --> radix = 0 00 ff..
  // pos inf: signbit=0 exp=ff fraction=0 --> radix = 1 ff 00..
  // pos nan: signbit=0 exp=ff fraction>0 --> radix = 1 ff x>0
  // neg nan: signbit=1 exp=ff fraction>0 --> radix = 0 00 x<ff...
  static inline __device__ RadixType convert(float v) {
    RadixType x = __float_as_int(v);
    RadixType mask = (x & 0x80000000) ? 0xffffffff : 0x80000000;

    return (v == v) ? (x ^ mask) : 0xffffffff;
  }

  static inline __device__ float deconvert(RadixType v) {
    RadixType mask = (v & 0x80000000) ? 0x80000000 : 0xffffffff;

    return __int_as_float(v ^ mask);
  }
};

template <typename scalar_t, typename bitwise_t, typename index_t>
 __device__ scalar_t findPattern(
    scalar_t* smem,
    scalar_t* data,
    index_t sliceSize,
    index_t withinSliceStride,
    bitwise_t desired,
    bitwise_t desiredMask) {
  if (threadIdx.x < 2) {
    smem[threadIdx.x] = static_cast<scalar_t>(0);
  }
  __syncthreads();

  // All threads participate in the loop, in order to sync on the flag
  index_t numIterations =
      THCRoundUp(sliceSize, static_cast<index_t>(blockDim.x));
  for (index_t i = threadIdx.x; i < numIterations; i += blockDim.x) {
    bool inRange = (i < sliceSize);
    //scalar_t v = inRange ? data[i]:0;
    scalar_t v = inRange ? doLdg(&data[i * withinSliceStride]): static_cast<scalar_t>(0);
    //printf("i am %u data,vaild is < %u\n",i,sliceSize);
    //printf("convert from:%f   to:%u\n",(float)v,TopKTypeConfig<scalar_t>::convert(v));
    //printf("value :%u  expected:%u\n",(TopKTypeConfig<scalar_t>::convert(v))&desiredMask,desired);
    //printf("desiredMask:%u    desired%u\n",desiredMask, desired);

    if (inRange &&
        ((TopKTypeConfig<scalar_t>::convert(v) & desiredMask) == desired)) {
      // There should not be conflicts if we are using findPattern,
      // since the result is unique
      smem[0] = static_cast<scalar_t>(1);
      smem[1] = v; // can't use val as the flag, since it could be 0
    }

    __syncthreads();

    scalar_t found = smem[0];
    scalar_t val = smem[1];

    __syncthreads();

    // Check to see if a thread found the value
    
    if (THCNumerics<scalar_t>::ne(found, static_cast<scalar_t>(0))) {
      // all threads return this value
      printf("%f\n",val);
      return val;
    }

  }

  // should not get here
  assert(false);
  return static_cast<scalar_t>(0);
}
__global__ void test(float* data) {
  uint32_t idx = threadIdx.x + blockDim.x * blockIdx.x;
  __shared__ float smem[2];
  unsigned int sliceSize = 25;
  unsigned int withinSliceStride = 1;
  unsigned int desired = 1073741824;
  unsigned int desiredMask = 3221225472;
  float ret = findPattern(smem, data, sliceSize, withinSliceStride, desired, desiredMask);
}
//int main() {
//  dim3 block(32,1);
//  dim3 grid(128,1);
//  int n = block.x * grid.x;
//  float data[n];
//  float *data_dev;
//  cudaMalloc((void**)&data_dev, sizeof(float)*n);
//  cudaMemcpy(data_dev, data, sizeof(float)*n, cudaMemcpyHostToDevice);
//  cudaDeviceSynchronize();
//  test<<<block,grid>>>(data_dev);
//  cudaDeviceSynchronize();
//  return 0;
//}


