#include<iostream>
#include<vector>
#include<algorithm>
#include<functional>
using namespace std;
using namespace placeholders;
bool cmp(int a,int b) {
  return a  > b;//high to low
}
int main() {
  vector<int>a{5,4,2,9,4,6};
  auto f = bind(cmp, _1, _2);
  sort(a.begin(),a.end(),f);
  for (auto&v:a) {
    cout << v << " ";
  }
  cout << endl;
  return 0;
}
