#include<iostream>
using namespace std;
int main() {
  int b = 6;
  int c = 7;
  const int* a = &b;
  a = &c;
  //error:
  //int *const d = &b;
  //d = &c;
}
