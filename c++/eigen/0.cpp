#include<iostream>
#include<Eigen/Dense>
using namespace Eigen;
using namespace std;
int main() {
  Matrix<float,2,2>m1;
  m1<<2.1,1.1,3.3,4.4;
  cout<<m1(0)<<endl;
  m1(0) = 5;
  cout<<m1(0)<<endl;
  cout<<m1.size();
  return 0;
}
