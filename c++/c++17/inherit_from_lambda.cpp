#include<iostream>
#include<memory>
#include<utility>
using namespace std;
template<typename... T>
class my_class : T...{
  public:
    template<typename... M>
    my_class(M&&... t1): T(std::forward<M>(t1))...
    {

    }
    using T::operator()...;
};
//deduction
template<typename... T>
my_class(T...)-> my_class<decay_t<T>...>;
int main() {
  int total = 0;
  double d_total = 0.0;
  my_class t{[&total](const int i) {total += i;},
    [&d_total](const double i){d_total += i;}};
  t(1);
  t(1.1);
  cout << total << endl;
  cout << d_total << endl;
  return 0;
}
