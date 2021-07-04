#include<iostream>
#include<cstring>
#include<algorithm>
#include<ctime>
using namespace std;
#define BS 5
void do_block(int* a, int* b, int* c) {
  for(int i = 0;i < BS;++i) {
    for(int k = 0;k < BS;++k) {
      for(int j = 0;j < BS;++j) {
        a[]
      }
    }
  }
}
void h_matmul(int *a, int* b,int* target, int height, int width, int width2, int n ) {
  for(int i = 0;i < height;i += BS) {
    for (int k = 0;k < width;k += BS) {
      for(int j = 0;j < width2;j += BS) {
        target[i * width2 + j] += a[i * width + k] * b[width2 * k + j];
        //fprintf(stderr,"i%dj%dk%d\n",i, j ,k);
      }
    }
  }
}
void matmul(int *a, int* b,int* target, int height, int width, int width2, int n ) {
  int N = 5;
  for(int i = 0;i < height;++i) {
    for(int j = 0;j < width2;++j) {
      for (int k = 0;k < width;++k) {
        target[i * width2 + j] += a[i * width + k] * b[width2 * k + j];
        //fprintf(stderr,"i%dj%dk%d\n",i, j ,k);
      }
    }
  }
}


int main(int argc, char* argv[]) {
  int N = 1 << 20;
  int n = 1 << 10;
  int *a;
  int *b;
  int *c;
  int *d;
  a = (int*)malloc(sizeof(int)*N);
  b = (int*)malloc(sizeof(int)*N);
  c = (int*)malloc(sizeof(int)*N);
  d = (int*)malloc(sizeof(int)*N);
  memset(c, 0, sizeof(int)*N);
  memset(d, 0, sizeof(int)*N);
  clock_t start, end;
  std::generate(a, a+N, []()->int{
      static int n = 1;
      return n++%10; 
      });
  std::generate(b, b+N, []()->int{
      static int n = 1;
      return n++%10; 
      });
  start = clock();
  h_matmul(a, b, c, n, n, n, 10000);
  end = clock();
  for_each(c, c+N, [](int a)->void {
    //cout<<a<<" ";
      });
  cout<< endl;
  cout << "time " << end - start <<" ms"<<endl; 
  start = clock();
  matmul(a, b, d, n, n, n, 10000);
  end = clock();
  cout << "time " << end - start <<" ms"<<endl; 
  for (int i = 0;i < N;++i) {
    if(c[i] != d[i]) {
      cout << "error:" <<i << endl;

    }
  }
  return 0;
}
