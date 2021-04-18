#include<iostream>
using namespace std;
int main() {
  cudaSharedMemConfig config;
  cudaDeviceGetSharedMemConfig(&config);
  switch(config) {
    case cudaSharedMemBankSizeDefault:
      cout << "default SharedConfig" << endl;
      break;
    case cudaSharedMemBankSizeFourByte:
      cout << "fourbyte SharedConfig" << endl;
      break;
    case cudaSharedMemBankSizeEightByte:
      cout << "eightbyte SharedConfig" << endl;
      break;
  }
  return 0;
}
