#include<iostream>
using namespace std;
int main() {
  for (int i = 0;i < 4;i++) {
    for(int j = 0;j <=n;j++) {
      dp[i][j] = max(dp[i - 1][j],dp[i - 1][j - val[i]]);
    }
    //
    //for (int j = n;j > 0;j--) {
    //  dp[j] = max(dp[j],dp[j - val[i])
    //}
  }

}
