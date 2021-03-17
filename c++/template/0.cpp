#include<iostream>
using namespace std;
template<typename... Types>
class my_tuple;
template<>
class my_tuple<>{};
template<typename T,typename... Types>
class my_tuple<T,Types...> : public my_tuple<Types...>{
 typedef my_tuple<Types...> ftype;
  public:
  my_tuple(const T& t1,const Types&... t2):val(t1),ftype(t2...){
  }
    T& get_val() {
      return val;
    }
    ftype& get_f() {
      return *static_cast<ftype*>(this);
    }
  private:
      T val;
};
int main() {
  my_tuple<int,float,double>a(1,2.2,3.3);
  cout<<a.get_val()<<endl;
  cout<<a.get_f().get_val()<<endl;
  cout<<a.get_f().get_f().get_val()<<endl;

}
