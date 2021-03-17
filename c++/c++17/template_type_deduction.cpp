#include<iostream>
#include<tuple>
#include<string>
#include<functional>
#include<any>
#include<vector>
using namespace std;
namespace std {
//deduction ->
template<typename Ret, typename ... Arg>
function(Ret (*) (Arg...)) -> function<Ret (Arg...)>;
}
void fun(){
  cout << "i am fun" << endl;
}
int main() {
  tuple<string, int> t("hello",1);
  tuple t1(1,2.2);
  cout << get<0>(t) << endl;
  auto l_f = [&](int a)->void{
    cout << a << endl; 
  };
  function<void(int)> f = l_f;
  f(5);
  function f1 = fun;
  f1();
//test functional pointer array
  vector<any> fp{l_f,fun};
  function a = any_cast<decltype(l_f)>(fp[0]);
  a(10);
  function b = any_cast<void (*)()>(fp[1]);
  b();
  function c(l_f);
// old funtional pointer
  void (*of)() = &fun;
  (*of)();
  return 0;
}
