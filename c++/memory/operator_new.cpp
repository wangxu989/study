#include<iostream>
using namespace std;
template<typename T, unsigned int Size = 12>
class pool_allocator{
  union ceil{
    T val;
    ceil * next;
  };
  public:
    void de_alloc() {

    }
    T* alloc() {
      ceil *ret_pointer;
      if(now_pointer == nullptr) {
        now_pointer = (ceil *)malloc(Size*sizeof(T));
        for(int i = 0;i < Size - 1;i++) {
          (now_pointer + i)->next = (now_pointer + i + 1);
        }
        (now_pointer + Size - 1)->next = nullptr;
      } 
      ret_pointer = now_pointer++;
      return &ret_pointer->val;
    }
  private:
    ceil * now_pointer = nullptr;
};
//template<typename T = std::allocator>
class my_class{
  public:
    void *operator new(size_t size) {
      return alloc.alloc();
    }
  private:
    float val1;
    int val2;
  static  pool_allocator<my_class> alloc;
};
pool_allocator<my_class> my_class::alloc = pool_allocator<my_class>();
#define N 20
int main() {
  my_class *container[N];
  for (int i = 0;i < N;i++) {
    container[i] = new my_class();
    cout << (long long)container[i] << endl;
  }
  std::allocator<my_class> a;
  cout << (long long)a.allocate(sizeof(my_class)) << endl;
  cout << (long long)a.allocate(sizeof(my_class)) << endl;
  cout << (long long)a.allocate(sizeof(my_class)) << endl;
  //cout << (long long)a.allocate();
  //cout << (long long)a.allocate();
  return 0;
}
