#include<iostream>
#include<type_traits>
using namespace std;
template<typename... T>
auto sum(T... t) {
  typename common_type<T...>::type result{}; 
  initializer_list<int>a{ (result += t, 0)...};
  return result;
}
int main() {
  cout << sum(1,2,3.0,5.5) << '\n';
  return 0;
}
