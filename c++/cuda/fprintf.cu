#include<iostream>
using namespace std;
__global__ void test() {
  fprintf(stderr,"xxx");

}
int main() {
  test<<<1,1>>>();
  return 0;
}
