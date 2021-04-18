#include<iostream>
using namespace std;
class screen{
  public:
    screen(int t):a(t) {
    }
    const screen& display() const {
      return *this;
    }

    void set()const {
      
    }

  private:
    int a = 0;
};
int main() {
  int b = 5;
  int *a = &b;
  const int *c = &b;
  b = 6;
  cout << *a << endl;
  cout << *c << endl;
  return 0;
}
