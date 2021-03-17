#include<iostream>
#include<type_traits>
using namespace std;
//integral 
template<typename T, typename enable_if<is_integral<T>::value,int>::type* = nullptr>
T add(const T& a, const T& b) {
  return a + b;
}
//float
template<typename T, typename enable_if<is_floating_point<T>::value,int>::type* = nullptr>
T add(const T& a, const T& b) {
  return a + b;
}

template<typename T>
T add1z(const T& a, const T& b) {
  if constexpr(is_floating_point<T>::value) {
    return a + b;
  }
}
int main() {
  cout << add(1,2) << '\n';
  cout << add(1.1,2.2) << '\n';
  cout << add1z(1,2) << '\n';
  return 0;
}
