#include<iostream>
#include<stdio.h>
namespace prints{
  void print_v(){
  }
  template<typename T, typename... types>
  void print_v(const T& t1, const types&... t) {
    std::cout<<t1<<std::endl;
    print_v(t...);
  }
}
