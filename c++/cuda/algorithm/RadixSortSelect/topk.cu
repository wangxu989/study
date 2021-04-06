#include<iostream>
#include<assert.h>
#include<algorithm>
#define N 10000
#define K 30
#define RadixBit 2
#define RadixSize 4//2 ^ RadixBit
#define RadixMask 3
using namespace std;

__device__ int get_Laneid() {
  int laneId;
  asm("mov.s32 %0, %%laneid;" : "=r"(laneId) );
  return laneId;
}

__device__ unsigned int getBitwise(unsigned int val,unsigned int pos,unsigned int bits) {
  unsigned int m = (1 << bits) - 1u;
  return (val >> pos) & m; 
}
__device__ unsigned int setBitwise(unsigned int val, unsigned int insertval,unsigned int pos, unsigned int bits) {
  unsigned int m = 1 << bits - 1u;
  insertval <<= pos;
  m <<= pos;
  return (val & ~m) | insertval;
}
__device__ void countingMaskedval(int *count,
    unsigned int *data, 
    unsigned int desired, 
    unsigned int mask,
    int pos,
    unsigned int *smem, 
    unsigned int n) {
  for(int i = 0;i < RadixSize;i++) {
    count[i] = 0;
  }
  //initializer
  if(threadIdx.x < RadixSize) {
    smem[threadIdx.x] = 0;
  }
  __syncthreads();

  for(unsigned int i = threadIdx.x;i < n;i += blockDim.x) {
    unsigned int valbit = getBitwise(data[i], pos, RadixBit);
    bool hasval = ((data[i] & mask) == desired);
    for(int j = 0;j < RadixSize;j++) {
      bool vote = hasval && (valbit == j);
      count[j] += __popc(__ballot_sync(0xffffffff,vote));
    }

  }
  if(get_Laneid() == 0) {
    for(int i = 0;i < RadixSize;i++) {
      atomicAdd(smem + i, count[i]);
    }
  }
  __syncthreads();
  for(int i = 0;i < RadixSize;i++) {
    count[i] = smem[i];
  }
  __syncthreads();

}
unsigned int __device__ findPattern(unsigned int *data,unsigned int *smem, unsigned int desired, unsigned int mask, unsigned int n) {
  if (threadIdx.x < 2) {
    smem[threadIdx.x] = 0;
  }
  __syncthreads();
  for(int i = threadIdx.x;i < n;i += blockDim.x) {
    if((data[i] & mask) == desired) {
      smem[0] = 1;
      smem[1] = data[i];
    }
  }
  __syncthreads();
  unsigned int found = smem[0];
  unsigned int val = smem[1];
  __syncthreads();
  if(found == 1) {
    //one thread find the unique data
    //and every return this value
    //printf("%u ",val);
    return val;
  }
  assert(false);
  //do not find the data
  printf("%u ",val);
  return 0;
}
void __device__ RadixSelect(unsigned int *data,unsigned int n,unsigned int *smem, int k, unsigned int *topk) {
  //every thread has mask,desired,count to deal N/blockDim.x datas
  int count[RadixSize];
  unsigned int desired = 0;
  unsigned int mask = 0;
  int ktofind = k;
  unsigned int ret;
  for(int pos = sizeof(unsigned int)*8 - RadixBit;pos >=0;pos -= RadixBit) {
    countingMaskedval(count, data, desired, mask, pos, smem, n);
    auto find_unique = [&](int i, int counts) {
      if(counts == 1 && ktofind == 1) {
        desired = setBitwise(desired, i, pos, RadixBit);
        mask = setBitwise(mask, RadixMask, pos, RadixBit);
        //in every thread's head
        //now we know somedata & mask = desired is unique,and we will find this data;
        *topk = findPattern(data, smem, desired, mask, n);
        return true;
      }
      return false;
    };
    auto find_non_unique = [&](int i, int counts) {
      if(counts >= ktofind) {
        desired = setBitwise(desired, i, pos, RadixBit);
        mask = setBitwise(mask, RadixMask, pos, RadixBit);
        //continue find and the topk is in which & mask = desired
        return true;
      }
      //continue find 
      ktofind -= counts;
      return false;
    };
    for(int i = RadixSize - 1;i >= 0;i--) {
      int c = count[i];
      if(find_unique(i, c)) {
        return;
      }
      if(find_non_unique(i, c)) {
        //continue
        break;
      }
    }

  }
  //the topk has some same data,we return the same data is ok
  *topk = desired;
}

void __global__ findtopK(unsigned int* data, unsigned int n, unsigned int *topk) {
  __shared__ unsigned int smem[64];
  RadixSelect(data, n, smem, blockIdx.x + 1, topk + blockIdx.x);
}
int main() {
  unsigned int data[N],*data_dev;
  unsigned int topk[K],*topk_dev;
  for(int i = 0;i < N;i++) {
    data[i] = random()%1000;
  }
  cudaMalloc((void**)&data_dev, sizeof(data));
  cudaMalloc((void**)&topk_dev, sizeof(topk));
  cudaMemcpy(data_dev, data ,sizeof(data), cudaMemcpyHostToDevice);
  findtopK<<<K,1024>>>(data_dev, N, topk_dev);
  cudaMemcpy(topk, topk_dev ,sizeof(topk), cudaMemcpyDeviceToHost);
  cudaDeviceSynchronize();
  sort(data, data + N, [](unsigned int a,unsigned int b) {
        return a > b;
      });
  for(int i = 0;i < K;i++) {
    if(data[i] != topk[i]) {
      cout << "faild !!!" << "index: " << i << "cpu:" << data[i] << " gpu: " << topk[i] <<endl; 
    }
  }
  return 0;
}
