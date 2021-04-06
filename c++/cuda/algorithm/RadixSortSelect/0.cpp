#include<iostream>
using namespace std;
int main() {
  int a[10];
  int * t = &a[5];
  t[-1] = 10;
  return 0;
}
