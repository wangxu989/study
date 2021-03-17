#include <iostream>
#include<string>
#include<cstring>
using namespace std;
class my_string{
public:
  my_string(const char *t) {
    s = new char(strlen(t) + 1);
    memcpy(s,t,strlen(t) + 1);
  }
  my_string& operator+(const my_string& t) {
    char * temp = new char(strlen(s) + strlen(t.s) + 1);
    memcpy(temp,s,strlen(s));
    memcpy(temp + strlen(s),t.s,strlen(t.s) + 1);
    free(s);
    s = temp;
    return *this;
  }
private:
  char *s;  
};

int main()
{
    my_string s = "xxx";
    cout<<s.s;
    my_string s1 = s + s;
    cout << s1.s << endl;
    return 0;
}
