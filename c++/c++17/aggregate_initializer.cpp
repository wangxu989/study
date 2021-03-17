#include<iostream>
#include<type_traits>
using namespace std;
struct A{
  int a;
};
struct B : public A{
  float b;
};
int main() {
  B b{{1},0};
  cout << b.a << " " << b.b <<endl;
  return 0;
}
