#include <iostream>
#include <fstream>
#include <string>
#include <vector>

#include <stdlib.h>
#include <time.h>

using namespace std;

int main(int argc, const char * argv[]) {
    srand((unsigned)time(NULL));
    
    if(argc != 2) {
        cout << "format: ./a.out filename" << endl;
        exit(0);
    }
    
    
    
    string resultFile = argv[1];
    string learnFile = "learn.txt";
    string testFile = "test.txt";
    
    double testRate = 0.2; //全体から抽出するテストデータの割合
    
    int randInt = (int)(1.0 / testRate + 0.001);
    cout << randInt << endl;
    ifstream ifs(resultFile);
    if(!ifs) {
        cout << "not found resultFile" << endl;
        exit(0);
    }
    
    vector<string> learnV;
    vector<string> testV;
    
    string buf;
    while(getline(ifs,buf)) {
        if(rand()%randInt == 0) {
            testV.push_back(buf);
        } else {
            learnV.push_back(buf);
        }
    }
    ifs.close();
    
    ofstream ofs(testFile);
    for(unsigned int i=0;i<testV.size();i++) {
        ofs << testV[i] << endl;
    }
    ofs.close();
    
    ofstream ofs2(learnFile);
    for(unsigned int i=0;i<learnV.size();i++) {
        ofs2 << learnV[i] << endl;
    }
    ofs2.close();
    
    
    return 0;
}