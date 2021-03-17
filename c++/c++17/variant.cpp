#include<iostream>
#include<variant>
// this new traits is due to replace union, and variant support more 
// attributions than union which is defined in c++ 
using namespace std;
int main() {
  variant<int , float>v;
  v = 12;
  cout << std::get<int>(v) << endl; 
  v.emplace<float>(12.2);
  cout << std::get<float>(v) << endl; 
  return 0;
}
