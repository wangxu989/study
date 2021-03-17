#include<iostream>
void f(int n) {
  void g(), h(), i();
  switch (n) {
    case 1:
    case 2:
      g();
     [[fallthrough]];
    case 3: // no warning on fallthrough
      h();
    case 4: // compiler may warn on fallthrough
      if(n < 3) {
          i();
          [[fallthrough]]; // OK
      }
      else {
          return;
      }
    case 5:
      while (false) {
        [[fallthrough]]; // ill-formed: next statement is not part of the same iteration
      }
    case 6:
      [[fallthrough]]; // ill-formed, no subsequent case or default label
  }
}
int main() {
  f(5);
  return 0;
}
