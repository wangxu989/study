#include<atomic>
#include<iostream>
using namespace std;
#include<thread>
atomic<bool>a(true);
int main() {
  std::atomic_thread_fence(std::memory_order_release);
  auto fun = [&]()->void{
    //if(a.exchange(false)) {
      // i am the first thread calling this function
      std::atomic_thread_fence(std::memory_order_acquire);
      cout << "i am first thread" <<endl;
    //}
    //else {
      std::atomic_thread_fence(std::memory_order_release);
      //cout << "i am not first thread and we will wait for the first" << endl;
   // }
  };
  thread t[10];
  for(int i = 0;i < 10;i++) {
    t[i] = thread(fun);
  }
  for(int i = 0;i < 10;i++) {
    t[i].join();
  }
  return 0;
}
