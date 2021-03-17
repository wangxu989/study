#include<iostream>
using namespace std;
struct val{
  int real;
  int vir;
  val(const int r,const int v):real(r), vir(v){}
  val(const val& v):real(v.real), vir(v.vir){}
  void operator += (const val* t) {
    this->real += t->real;
    this->vir += t->vir;
  }
};
class my_class {
  public:
    my_class(const my_class& c){
      value = new val(*c.value);
      cout<<"copy_constructor"<<"\n";
    }
     my_class(my_class&& c){
      value = c.value;
      c.value = nullptr;
      cout<<"rightinference_constructor"<<"\n";
    }

    my_class(const int r, const int v){
      value = new val(r,v);
      cout<<"constructor"<<"\n";
    }
    void operator += (const my_class& c) {
      *value += c.value;
    }
    my_class operator + (const my_class& c) {
      cout<<"add"<<'\n';
      return my_class(c.value->real + value->real, c.value->vir + value->vir);
    }
    void operator = (my_class&& c) {
      this->value = c.value;
      c.value = nullptr;
      cout<<"rightinference_copy"<<"\n";
    }
    void operator = (const my_class& c) {
      value = new val(*c.value);
      cout<<"copy"<<"\n";
    }
  val operator struct val() {
    return *value;
  }
  private:
    val* value;
};
int main() {
  my_class a(1,2);
  my_class b = a;
  my_class c = move(a + b);
  return 0;
}
