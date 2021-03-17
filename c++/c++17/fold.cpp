#include<iostream>
using namespace std;
template<typename R, typename... T>
R sum(const T&... t) {
  return (t + ...); 
}
template<typename R, typename... T>
R div(const T&... t) {
  return (... / t);//from begin to end 
}


int main() {
  cout << sum<float>(1,1.0,2.2) << endl;
  cout << div<float>(1,1.0,2.2) << endl;
  return 0;
}
