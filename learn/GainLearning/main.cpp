//
//  main.cpp
//  parseptron
//
//  Created by Yuki Murakami on 2014/05/16.
//  Copyright (c) 2014年 yuki. All rights reserved.
//

#include <iostream>
#include <stdio.h>
#include <stdlib.h>
#include <vector>
#include <time.h>
#include <fstream>

#include <unistd.h>

#include "utility.h"
#include "sample.h"
#include "card.h"

#define KIND_OF_CARD 32

using namespace std;

int main(int argc, const char * argv[])
{
    srand((unsigned)time(NULL));
    bool readFlag = false;
    
    if(argc >= 2) {
        if(argv[1][0] == 'r') {
            readFlag = true;
            cout << "loading Mode" << endl;
        }
    }
    
    if(!readFlag) {
        cout << "Warning!! :This mode will make new weight vector." << endl;
    }
    
    int dimensionOfFeature;
    int nSample;
    int roundlimit = 100000000;//学習回数上限
    int roundtest = 100000;//テスト実施の間隔学習回数
    string studyfile = "result.txt";//インプット教師データ
    
    
    //--------------------------------------教師信号ベクトルの初期化--------
    cout << "load teacher data" << endl;
    
    
    ifstream ifs(studyfile);
    string buf;
    vector<Sample> teachers;
    int count = 0;
    while(getline(ifs, buf)) {
            fprintf(stderr,"now loading teacher data:%d \r",count+1);
            Sample teacher(count++,buf);
            dimensionOfFeature = teacher.getDimensionOfFeature();
            //teacher.show();
            //cout << buf << endl;
            teachers.push_back(teacher);
        
        
    }
    nSample = count;
    
    //--------------------------------------重みベクトルの初期化-------
    cout << "init weight vector" << endl;
    vector< vector<double> > weight;
    //vector< vector<double> > start;
    vector< vector<double> > averageWeight;
    for(int i=0;i<KIND_OF_CARD;i++) {
        vector<double> tmpVector1,tmpVector2,tmpVector3;
        for(int j=0;j<dimensionOfFeature;j++) {
            tmpVector1.push_back(0.0);
            tmpVector2.push_back(0.0);
            tmpVector3.push_back(0.0);
        }
        weight.push_back(tmpVector1);
        averageWeight.push_back(tmpVector2);
        //start.push_back(tmpVector3);
    }
    vector< vector<double> > testWeight;
    
    int round = 0;//ラウンド数
    
    if(readFlag) {
        cout << "load weight vector" << endl;
        weight = readWeightVector("w_weight.txt");
        averageWeight = readWeightVector("u_weight.txt");
        round = readRound("round.txt");
        //start = readWeightVector("weight.txt");
    }
    
    //---------------------------------------学習----------------------
    cout << "start learning" << endl;
    vector<int> indexs = getRandVec((int)teachers.size());
    
    while(round < roundlimit) {
        
        showProgress(round%roundtest,roundtest,"learning");
        
        if(round%teachers.size() == 0) {
            indexs = getRandVec((int)teachers.size());
        }
        int sampleIndex = indexs[round%teachers.size()];
        round++;
//        vector<int> gotGain = getMaxValueGain(weight, teachers[sampleIndex]._feature,teachers[sampleIndex]._notZero, teachers[sampleIndex]._supply, teachers[sampleIndex]._coin, teachers[sampleIndex]._buy);
        
        vector<int> gotGain = getMaxValueGainFromSample(weight, teachers[sampleIndex]);
        
        vector<int> answerGain = teachers[sampleIndex]._gain;
        //showGain(answerGain);
        
        
        
        if(!isEqualGain(gotGain, answerGain)) {
            
            //間違えたものの重みを引く
            for(int i=0;i<gotGain.size();i++) {
                if(gotGain[i] == CARD_DUMMY) break;
                int wid = gotGain[i] - 1;
                weight[wid] = addVector(weight[wid], mulVector(teachers[sampleIndex]._feature , -1) );
                averageWeight[wid] = addVector(averageWeight[wid], mulVector(teachers[sampleIndex]._feature, round*-1));
            }
            //正解の重みを足す
            for(int i=0;i<answerGain.size();i++) {
                if(answerGain[i] == CARD_DUMMY) break;
                int wid = answerGain[i] - 1;
                weight[wid] = addVector(weight[wid],teachers[sampleIndex]._feature );
                averageWeight[wid] = addVector(averageWeight[wid], mulVector(teachers[sampleIndex]._feature, round));
            }
        }
        
        if(round % roundtest == 0) {
            testWeight.clear();
            for(int i=0;i<averageWeight.size();i++) {
                testWeight.push_back( addVector(weight[i], mulVector(averageWeight[i], -1.0/(double)round)));
            }
            
            double correct = test(testWeight, teachers,false);
            cout << "round:" << round << "/正解率：" << correct * 100 << "%" << endl;
            writeWeightVector(testWeight,"weight.txt");
            writeWeightVector(weight,"w_weight.txt");
            writeWeightVector(averageWeight,"u_weight.txt");
            writeRound(round,"round.txt");
            if(correct >= 1) {
                break;
            }
        }
    }
    writeWeightVector(testWeight,"weight.txt");
    test(testWeight, teachers,true);
    
    cout << "number of sample:" << nSample << endl;
    cout << "number of dimension:" << dimensionOfFeature << endl;
    
    
    
    return 0;
}

