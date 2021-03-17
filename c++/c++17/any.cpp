#include<iostream>
#include<any>
#include<vector>
#include<string>
using namespace std;
struct my_class{
  my_class(const my_class& m)=default;
  my_class()=default;
};
int main() {
  vector<any> v{1,5.0,string("helloworld"), my_class()};
  cout<<any_cast<string>(v[2])<<'\n';
  cout<<v[0].type().name()<<'\n';
  cout<<v[3].type().name()<<'\n';
  return 0;
}
