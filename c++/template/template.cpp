#include<iostream>
#include<type_traits>
using namespace std;
template<class T> struct Point{
    template <typename NewType> Point<NewType> cast() const{
        return Point<NewType>();
    }
};

template <class T> struct PointContainer{
    void test(){
        Point<T> p1;
        Point<double> p2;
        p2 = p1.template cast<double>(); //compilation error
    }
};
int main(){
    Point<float> p1;
    Point<double> p2;
    p2 = p1.cast<double>();
    return 0;
}
