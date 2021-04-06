#include<stdio.h>
#include<algorithm>
#include<iostream>
#include"./findPattern.h"
#include<ctime>
#define RADIX_SIZE 4
#define RADIX_BITS 2
#define RADIX_MASK 3
#define K 1
#define order true

 // bool order = true ;max topk else min topk
using namespace std;

static inline __device__ void gpuAtomicAdd(int32_t *address, int32_t val) {
  atomicAdd(address, val);
}
__device__ __forceinline__ int getLaneId() {
#if defined(__HIP_PLATFORM_HCC__)
  return __lane_id();
#else
  int laneId;
  asm("mov.s32 %0, %%laneid;" : "=r"(laneId) );
  return laneId;
#endif
}

__device__ __forceinline__ unsigned int ACTIVE_MASK()
{
#ifndef __HIP_PLATFORM_HCC__
  return __activemask();
#else
  // will be ignored anyway
  return 0xffffffff;
#endif
}


#if defined(__HIP_PLATFORM_HCC__)
__device__ __forceinline__ unsigned long long int WARP_BALLOT(int predicate)
{
  return __ballot(predicate);
}
#else
__device__ __forceinline__ unsigned int WARP_BALLOT(int predicate, unsigned int mask = 0xffffffff)
{
#ifndef __HIP_PLATFORM_HCC__
  return __ballot_sync(mask, predicate);
#else
  return __ballot(predicate);
#endif
}
#endif


template<typename T>
struct Bitfield{};


template<>
struct Bitfield<unsigned int> {
  static __device__ __forceinline__
    unsigned int getBitfield(unsigned int val, int pos, int len) {
#if defined(__HIP_PLATFORM_HCC__)
      pos &= 0xff;
      len &= 0xff;

      unsigned int m = (1u << len) - 1u;
      return (val >> pos) & m;
#else
      unsigned int ret;
      asm("bfe.u32 %0, %1, %2, %3;" : "=r"(ret) : "r"(val), "r"(pos), "r"(len));
      return ret;
#endif
    }

  static __device__ __forceinline__
    unsigned int setBitfield(unsigned int val, unsigned int toInsert, int pos, int len) {
#if defined(__HIP_PLATFORM_HCC__)
      pos &= 0xff;
      len &= 0xff;

      unsigned int m = (1u << len) - 1u;
      toInsert &= m;
      toInsert <<= pos;
      m <<= pos;

      return (val & ~m) | toInsert;
#else
      unsigned int ret;
      asm("bfi.b32 %0, %1, %2, %3, %4;" :
          "=r"(ret) : "r"(toInsert), "r"(val), "r"(pos), "r"(len));
      return ret;
#endif
    }
};

template <typename scalar_t,
         typename bitwise_t,
         typename index_t,
         typename CountType,
         int RadixSize,
         int RadixBits>
         __device__ void countRadixUsingMask(
             CountType counts[RadixSize],
             CountType* smem,
             bitwise_t desired,
             bitwise_t desiredMask,
             int radixDigitPos,
             index_t sliceSize,
             index_t withinSliceStride,
             scalar_t* data) {
           // Clear out per-thread counts from a previous round
#pragma unroll
           for (int i = 0; i < RadixSize; ++i) {
             counts[i] = 0;
           }

           if (threadIdx.x < RadixSize) {
             smem[threadIdx.x] = 0;
           }
           __syncthreads();

           // Scan over all the data. Upon a read, the warp will accumulate
           // counts per each digit in the radix using warp voting.
           for (index_t i = threadIdx.x; i < sliceSize; i += blockDim.x) {
             bitwise_t val =
               TopKTypeConfig<scalar_t>::convert(doLdg(&data[i * withinSliceStride]));

             bool hasVal = ((val & desiredMask) == desired);
             bitwise_t digitInRadix =
               Bitfield<bitwise_t>::getBitfield(val, radixDigitPos, RadixBits);

#pragma unroll
             for (uint32_t j = 0; j < RadixSize; ++j) {
               bool vote = hasVal && (digitInRadix == j);
#if defined(__HIP_PLATFORM_HCC__)
               counts[j] += __popcll(WARP_BALLOT(vote));
#else
               counts[j] += __popc(WARP_BALLOT(vote, ACTIVE_MASK()));
#endif
             }
           }

           // Now, for each warp, sum values
           //first thread of warp
           if (getLaneId() == 0) {
#pragma unroll
             for (uint32_t i = 0; i < RadixSize; ++i) {
               gpuAtomicAdd(&smem[i], counts[i]);
             }
           }

           __syncthreads();

           // For each thread, read in the total counts
#pragma unroll
           for (uint32_t i = 0; i < RadixSize; ++i) {
             counts[i] = smem[i];
             //printf("%u  ",counts[i]);
           }

           __syncthreads();
         }

template <typename scalar_t, typename bitwise_t, typename index_t, bool Order>
__device__ void radixSelect(
    scalar_t* data,
    index_t k,
    index_t sliceSize,
    index_t withinSliceStride,
    int* smem,
    scalar_t* topK) {
  // Per-thread buckets into which we accumulate digit counts in our
  // radix
  int counts[RADIX_SIZE];

  // We only consider elements x such that (x & desiredMask) == desired
  // Initially, we consider all elements of the array, so the above
  // statement is true regardless of input.
  bitwise_t desired = 0;
  bitwise_t desiredMask = 0;

  // We are looking for the top kToFind-th element when iterating over
  // digits; this count gets reduced by elimination when counting
  // successive digits
  int kToFind = k;

  // We start at the most signific,ant digit in our radix, scanning
  // through to the least significant digit
#pragma unroll
  for (int digitPos = sizeof(scalar_t) * 8 - RADIX_BITS; digitPos >= 0;
       digitPos -= RADIX_BITS) {
    // Count radix distribution for the current position and reduce
    // across all threads
    countRadixUsingMask<
        scalar_t,
        bitwise_t,
        index_t,
        int,
        RADIX_SIZE,
        RADIX_BITS>(
        counts,
        smem,
        desired,
        desiredMask,
        digitPos,
        sliceSize,
        withinSliceStride,
        data);

    auto found_unique = [&](int i, int count) -> bool {
      /* All threads have the same value in counts here, so all */
      /* threads will return from the function. */
      if (count == 1 && kToFind == 1) {
        /* There is a unique answer. */
        desired =
            Bitfield<bitwise_t>::setBitfield(desired, i, digitPos, RADIX_BITS);
        desiredMask = Bitfield<bitwise_t>::setBitfield(
            desiredMask, RADIX_MASK, digitPos, RADIX_BITS);

        /* The answer is now the unique element v such that: */
        /* (v & desiredMask) == desired */
        /* However, we do not yet know what the actual element is. We */
        /* need to perform a search through the data to find the */
        /* element that matches this pattern. */
        *topK = findPattern<scalar_t, bitwise_t, index_t>(
            (scalar_t*)smem,
            data,
            sliceSize,
            withinSliceStride,
            desired,
            desiredMask);
        return true;
      }
      return false;
    };
    auto found_non_unique = [&](int i, int count) -> bool {
      if (count >= kToFind) {
        desired =
            Bitfield<bitwise_t>::setBitfield(desired, i, digitPos, RADIX_BITS);
        desiredMask = Bitfield<bitwise_t>::setBitfield(
            desiredMask, RADIX_MASK, digitPos, RADIX_BITS);

        /* The top-Kth element v must now be one such that: */
        /* (v & desiredMask == desired) */
        /* but we haven't narrowed it down; we must check the next */
        /* least-significant digit */
        return true;
      }
      kToFind -= count;
      return false; // continue the loop
    };

    // All threads participate in the comparisons below to know the
    // final result
    if (Order) {
      // Process in descending order
#pragma unroll
      for (int i = RADIX_SIZE - 1; i >= 0; --i) {
        int count = counts[i];
        //
        if (found_unique(i, count)) {
          return;
        }
        if (found_non_unique(i, count)) {
          break;
        }
      }
    } else {
      // Process in ascending order
#pragma unroll
      for (int i = 0; i < RADIX_SIZE; ++i) {
        int count = counts[i];
        if (found_unique(i, count)) {
          return;
        }
        if (found_non_unique(i, count)) {
          break;
        }
      }
    }
  } // end digitPos for

  // There is no unique result, but there is a non-unique result
  // matching `desired` exactly
  *topK = TopKTypeConfig<scalar_t>::deconvert(desired);
}

__global__ void __test(float *data,unsigned int sliceSize, float *topk) {
    unsigned int withinSliceStride = 1;
    __shared__  int smem[64];
    radixSelect<float, unsigned int, unsigned int,order>(data, blockIdx.x + 1, sliceSize, withinSliceStride, smem, topk + blockIdx.x);
}
//__shared__ int smem[2];
int main() {
  int N = 1024;
  float *data_dev,data[N];
  float topk[K],*topk_dev;
  for(int i = 0;i < N;i++) {
    data[i] = rand()%1000;
  }
  data[N - 1] = 10000;
  cudaMalloc((void**)&topk_dev, sizeof(float)*K);
  cudaMalloc((void**)&data_dev, sizeof(float)*N);
  cudaMemcpy(data_dev,data,sizeof(data), cudaMemcpyHostToDevice);
  clock_t start ,end;
  start = clock();
  __test<<<K,1024>>>(data_dev, N, topk_dev);
  cudaDeviceSynchronize();
  end = clock();
  cout <<"time gpu:" << end - start << "us"<<endl;
  cudaMemcpy(topk,topk_dev,sizeof(float)*K, cudaMemcpyDeviceToHost);
  cudaDeviceSynchronize();
  start = clock();
  sort(data,data + N, [](float a, float b) {
        return a > b;
      });
  end = clock();
  cout <<"time cpu:" << end - start << "us"<<endl;
  cudaMemcpy(&topk,topk_dev,sizeof(float), cudaMemcpyDeviceToHost);
  for (int i = 0;i < K;i++) {
    if (data[i] != topk[i]) {
        cout <<"index:" << i <<"    "<< "failed !!!" << "cpu:" << data[i] << "gpu:" << topk[i] << endl;
    }
  }
  cout <<data[0] <<endl;
  return 0;
}
