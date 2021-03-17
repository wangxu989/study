#include<iostream>
using namespace std;
template<typename T>
const T add() {
  return T(1);
}

template<>
const float add(){
  cout<<"i am float"<<endl;
  return 1.1;
}
template<>
const int add(){
  cout<<"i am int"<<endl;
  return 1;
}
int main() {
  int a = add<int>();
  float b = add<float>();
  return 0;
}
