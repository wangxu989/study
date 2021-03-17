# 本文件夹内的测试代码针对CUDA中的全局内存
## cudaMallocHost :主机端分配固定内存，用于减少hosttodevice的性能损失。但会降低主机端性能。
## cudaHostAlloc：零拷贝（设备直接通过PCIE访问主机内存（页锁））省去copy过程，但性能会下降适用于小内存数据的处理
对应文件：HostAlloc.cu，计算1<<20，sum时速度大约为700ms ~ 800ms（通常方式为100ms左右）

## AoS and SoA
1. global memory load&store efficency metrics : nvprof --metrics gld_efficiency,gst_efficiency ./a.out
2. global memort load&store transactions nvprof --metrics gld_transactions,gst_transactions
AoS: (140ms)
``` 
struct arraystruct {
  float x,y;
}
arraystruct a[N];
```
SoA: (85ms)
```
struct structarry {
  float x[N],y[N];
}
```
==SIMD:Single Instruction Multiple Data==
the advantage of unroll is:The number of concurrent memory operations






