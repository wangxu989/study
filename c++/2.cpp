#include<iostream>
#include<string>
using namespace std;
template<typename T,typename S>
void add(const T& t,const S& s){
	cout<<typeid(t).name()<<":"<<t<<endl;
}

template<typename S> void add(const int& t,const S&s){
	cout<<"i am int"<<t<<" "<<s<<endl;
}
int main(){
	add(string("s"),"ssss");
	add(5,"haha");	
}
