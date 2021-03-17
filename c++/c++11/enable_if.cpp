#include<iostream>
using namespace std;
template<bool,typename T=void>
class my_enable_if {
};
template<typename T>
struct my_enable_if<true,T> {
  typedef T type;
};
template<typename T,typename my_enable_if<is_integral<T>::value,int>::type* = nullptr>
void print(const T& t1) {
  cout<<"i am int:"<<endl;
}
template<typename T,typename  my_enable_if<is_floating_point<T>::value,float>::type* = nullptr>
void print(const T& t1) {
  cout<<"i am float:"<<endl;
}

template<typename T,typename T2>
void special(const T&t,const T2&t2) {
  cout<<"i am fun 1"<<endl;
}
template<typename T2>
void special(const int&t,const T2&t2) {
  cout<<"i am fun 2"<<endl;
}
int main() {
  int a = 5;
  float b = 5.5;
  print(a);
  print(b);
  special(5.5,6.5);
  special(5,6.5);
  return 0;
}
