#include<iostream>
using namespace std;
template<typename F>
class fun {
  public:
  void operator()() {
  }
  private:
};
int main() {

  fun<void ()>f;
  f();
  return 0;
}
