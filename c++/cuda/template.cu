#include<stdio.h>
#include<iostream>
using namespace std;
void __global__ test() {


}
//struct false_usage{
//  enum{
//    
//  }
//}
int main(int argc ,char* argv[]) {
    if(argc < 2) {
      fprintf(stderr,"invalid Usager,-c blocksize -g gridsize\n");
      exit(-1);
    }
    int flag = 0;
    unsigned int blocksize;
    unsigned int gridsize;
    while(++flag < argc) {
      if(flag < argc &&  strlen(argv[flag]) == 2 && argv[flag][0] == '-') {
        if (flag + 1 > argc) {
          fprintf(stderr,"invalid Usager! input should be:``-c blocksize -g gridsize\n");
          exit(-2);
        }
        switch(argv[flag][1] - 'a') {
          case 'c' - 'a':
            //protected 
            blocksize = atoi(argv[++flag]);
            break;
          case ('g' - 'a'):
            gridsize = atoi(argv[++flag]);
            break;
          default:
            fprintf(stderr, "no match\n");
        }
      }
    }
    dim3 block(blocksize, 1);
    //dim3 grid(, 1);

}

