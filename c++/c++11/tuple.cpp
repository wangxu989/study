#include<iostream>
#include<string>
using namespace std;
template<typename... types >class my_tuple;//原始定义
template<>class my_tuple<>{};//无参特化
template<typename T,typename... T1>
class my_tuple<T,T1...>:public my_tuple<T1...> {//带参特化
  typedef my_tuple<T1...> f_type;
public:
  template<typename V,typename... types>
  my_tuple<T,T1...>(const V& v,const types&... v2):val(v),f_type(v2...) {
  }
  T& get_val() {
    return val;
  }
  f_type& get_f() {
    return *static_cast<f_type*>(this);
  }
private:
  T val;
};
int main() {
  my_tuple<string,int,double,float>a("hh",1,2.2,3.3);
  std::cout<<a.get_val()<<a.get_f().get_val()<<endl;
}
