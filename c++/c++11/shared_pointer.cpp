#include<iostream>
#include<memory>
using namespace std;
#pragma pack(1)
struct my_class {
  char c;
  short a;
  int b;
};
#pragma pack()
int main() {
  shared_ptr<my_class>p = shared_ptr<my_class>(make_shared<my_class>());
  cout << sizeof(my_class) << endl;
  return 0;
}
