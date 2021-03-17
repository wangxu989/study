#include<iostream>
#include<functional>
using namespace std;
class my_class{
  public:
    int do_something(const int a) {
      return j + a; 
    }
    int do_something_2(const int a) {
      return j + a;
    }
  private:
    int j = 5;
};
int do_something_3(const int a) {
  return a + 0;
}
int main() {
  int (*fp0)(int) = &do_something_3;
  cout << (*fp0)(1) << '\n';
  my_class s;
  auto fp1 = &my_class::do_something;
  cout << (s.*fp1)(5) << '\n';
  int (my_class::*fp2)(int) = &my_class::do_something_2;
  cout << (s.*fp2)(10) << '\n';
  cout << invoke(&my_class::do_something, s , 15) << '\n';
  cout << invoke(&do_something_3, 15) << '\n';
  return 0;
}
