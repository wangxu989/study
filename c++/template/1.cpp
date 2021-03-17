#include<iostream>
using namespace std;
struct c{
  int val;
  int img;
};
struct integral{
  int val;
};
struct device{
 operator c() {
  cout<<"i am complex"<<endl;
  return {1,-1};
 }
 operator integral() {
  cout<<"i am integral"<<endl;
  return {1};
 }
};
c call() {
  return device();
}
integral call() {
  return device();
}
int main() {
}
