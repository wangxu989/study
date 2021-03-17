#include<iostream>
#include<string>
using namespace std;
int main() {
	auto fun = [&](auto x,auto y) {
		return x + y;
	};
	cout<<fun(string("s"),string("x"));
}
