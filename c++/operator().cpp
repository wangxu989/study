#include<iostream>
using namespace std;
int main() {
  int b = 1,c = 3;
  int a = (b += c,2);
  cout << a << '\n';
  cout << b << '\n';
}
