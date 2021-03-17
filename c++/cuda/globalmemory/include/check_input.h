#ifndef CHECK_INPUT
#define CHECK_INPUT
#include<stdio.h>
#include<string.h>
namespace check{
  struct device_conf{
    unsigned int blocksize;
    unsigned int gridsize;
    template<typename T>
    device_conf(std::initializer_list<T> a) {
      if(a.size() > 2) {
        fprintf(stderr,"error: initializer_list<%s> size is not match\n", typeid(T).name());
        exit(-3);
      }
      int n = -1;
      for(auto&val:a) {
        this->operator []<unsigned int>(++n) = val;
      }
    }
    template<typename T>
    T& operator[](unsigned int n) {
      switch(n) {
        case 0:
          return blocksize;
        case 1:
          return gridsize;
      }
    }
  };
  void check_input(unsigned int argc, char* argv[], device_conf& dev) {
    if(argc < 2) {
      fprintf(stderr,"invalid Usager,-c blocksize -g gridsize\n");
      exit(-1);
    }
    int flag = 0;
    //default
    dev.blocksize = 1;
    dev.gridsize = 1;
    while(++flag < argc) {
      if(flag < argc &&  strlen(argv[flag]) == 2 && argv[flag][0] == '-') {
        if (flag + 1 > argc) {
          fprintf(stderr,"invalid Usager! input should be:``-c blocksize -g gridsize\n");
          exit(-2);
        }
        switch(argv[flag][1] - 'a') {
          case 'c' - 'a':
            //protected 
            dev.blocksize = atoi(argv[++flag]);
            break;
          case ('g' - 'a'):
            dev.gridsize = atoi(argv[++flag]);
            break;
          default:
            fprintf(stderr, "no match\n");
        }
      }
    }
  }
}
#endif


