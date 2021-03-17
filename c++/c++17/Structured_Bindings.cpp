#include<iostream>
#include<map>
using namespace std;
int main() {
  map<string, int>p;
  if(auto [iter, success] = p.insert({"helloword", 5}); success) {
    cout << "insert successfully !" << endl;
  }
  else {
    cout << "insert failed !" << endl;
  }
  if(auto [iter, success] = p.insert(make_pair("helloword", 5)); success) {
    cout << "insert successfully !" << endl;
  }
  else {
    cout << "insert failed !" << endl;
  }


}
