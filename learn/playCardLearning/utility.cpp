//
//  utility.cpp
//  parseptron
//
//  Created by Yuki Murakami on 2014/05/21.
//  Copyright (c) 2014年 yuki. All rights reserved.
//

#include "utility.h"
#include "./../card.h"
#include "sample.h"

#include <fstream>
#include <iostream>
#include <vector>
#include <stdlib.h>

using namespace std;


double test(const vector< vector<double> > &weight, vector<Sample> testData,bool isOutput) {
    
    int count = 0;
    int correct = 0;
    
    if(isOutput) {
        cout << "-----can't fit data-----" << endl;
    }
    
    int tSize = testData.size();
    for(int i=0;i<tSize;i++) {
        showProgress(i,tSize,"test    ");
        int gotPlayCard = getMaxValuePlayCard(weight,testData[i]._feature,testData[i]._notZero,testData[i]._hand);
        if(gotPlayCard == testData[i]._answerPlayCard) {
            count++;
            correct++;
        } else {
            count++;
            if(isOutput) {
                testData[i].show();
                
                cout << "AnsPlayCard:" << getString(testData[i]._answerPlayCard) << "gotPlayCard:" << getString(gotPlayCard) << endl;
            }
        }
    }
    
    return (double)correct / (double)count ;
    
}


