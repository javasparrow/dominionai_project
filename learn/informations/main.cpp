#include <iostream>
#include <fstream>
#include <string>
#include <vector>

#include <stdlib.h>
#include <time.h>

#include "card.h"

using namespace std;

int main() {
    srand((unsigned)time(NULL));
    
    int cards[13] = {-1,
                    -2,
                    CARD_CELLAR,
                    CARD_CHAPEL,
                    CARD_CHANCELLOR,
                    CARD_SPY,
                    CARD_THIEF,
                    CARD_THRONEROOM,
                    CARD_BUREAUCRAT,
                    CARD_REMODEL,
                    CARD_MILITIA,
                    CARD_LIBRARY,
                    CARD_MINE  };
    
    ofstream ofs("informations.csv");
    ofs << "CardName,Accuracy,learnData,testData" << endl;
    
    for(int i=0;i<13;i++) {
        int id = cards[i];
        string maxRateFilename = "";
        string testFilename = "";
        string learnFilename = "";
        string cardName = "";
        if(id==-1) {
            maxRateFilename = "./../GainLearning/maxRate.txt";
            testFilename = "./../GainLearning/testSize.txt";
            learnFilename = "./../GainLearning/learnSize.txt";
            cardName = "Gain";
        } else if(id==-2) {
            maxRateFilename = "./../playCardLearning/maxRate.txt";
            testFilename = "./../playCardLearning/testSize.txt";
            learnFilename = "./../playCardLearning/learnSize.txt";
            cardName = "Play";
        } else {
            maxRateFilename = "./../ActionLearning/" + getEnglishString(id) + "TeacherData/correctRate.txt";
            testFilename = "./../ActionLearning/" + getEnglishString(id) + "TeacherData/testSize.txt";
            learnFilename = "./../ActionLearning/" + getEnglishString(id) + "TeacherData/learningSize.txt";
            cardName = getEnglishString(id);
        }
        ifstream ifs(maxRateFilename.c_str());
        string buf;
        getline(ifs,buf);
        double rate = atof(buf.c_str());
        ifstream ifs2(learnFilename);
        getline(ifs2,buf);
        int learn = atoi(buf.c_str());
        ifstream ifs3(testFilename);
        getline(ifs3,buf);
        int test = atoi(buf.c_str());
        
        ifs.close();
        ifs2.close();
        ifs3.close();
        
        ofs << cardName << "," << rate << "," << learn << "," << test << "" << endl;
    }
    
    ofs.close();
    
    return 0;
}