#include<iostream>
using namespace std;

__global__ void add(uint32_t *ret){
        uint32_t idx = threadIdx.x;
        __shared__ uint32_t sum;
        if(idx == 0) {
                sum = 0;
        }
        __syncthreads();
        atomicAdd(&sum,idx);
        __syncthreads();
        if(idx == 0) {
                *ret = sum;

        }
}
int main() {
        dim3 block(64,1);
        dim3 grid(1,1);
        uint32_t *ret;
        cudaMalloc((void**)&ret, sizeof(uint32_t));
        add<<<grid, block>>>(ret);
        cudaDeviceSynchronize();
        uint32_t ans = 0;
        cudaMemcpy(&ans, ret, sizeof(uint32_t) ,cudaMemcpyDeviceToHost);
        cout <<"gpu ans:" << ans << endl;
        cout <<"cpu ans:" << (0 + 63)*64/2 << endl;
}

