#include<iostream>
#include<algorithm>
using namespace std;
int main(const int argc, const char* argv[]) {
  cout << clamp(argc, 2 , 5) << endl;
  return 0;
}
