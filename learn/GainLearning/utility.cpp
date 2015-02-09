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



vector<int> getMaxValueGain(const vector< vector<double> > &weight, const vector<double> &feature,const vector<int> &notZero, vector<int> supply,int coin,int buy) {
    
    map<int,double> cardValues;
    int sSize = supply.size();
    for(int i=0;i<sSize;i++) {
        double value = getInnerProduct(weight[i],feature,notZero);
        cardValues.insert(map<int,double>::value_type(i+1,value));
    }
    
    vector< vector<int> > gainList = getGainList(coin, buy, supply);
    double maxValue = -999999;
    int maxindex = 0;
    int gSize = gainList.size();
    for(int i=0;i<gSize;i++) {
        double sumValue = 0.0;
        int ggSize = gainList[i].size();
        for(int j=0;j<ggSize;j++) {
            sumValue += cardValues[gainList[i][j]];
        }
        //showGain(gainList[i]); cout << "Value:" << sumValue << endl;
        if(maxValue < sumValue) {
            maxValue = sumValue;
            maxindex = i;
        }
    }
    
    vector<int> maxGain = gainList[maxindex];
    if(cardValues[CARD_COPPER] > 0) {
        int gainCount = gainList[maxindex].size();
        if(gainList[maxindex].size() == 1 && gainList[maxindex][0] == 0) gainCount = 0;
        for(int i=0;i<buy - gainCount;i++) {
            if(maxGain[0] == CARD_DUMMY) {
                maxGain.clear();
            }
            maxGain.push_back(CARD_COPPER);
        }
    }
    
    //showGain(maxGain); cout << "maxValue:" << maxValue << endl;
    
    return maxGain;
}

double test(const vector< vector<double> > &weight, vector<Sample> testData,bool isOuput) {
    
    int count = 0;
    int correct = 0;
    
    if(isOuput) {
        cout << "-----can't fit data-----" << endl;
    }
    
    int tSize = testData.size();
    for(int i=0;i<tSize;i++) {
        showProgress(i,tSize,"test    ");
       
        if(isEqualGain(  getMaxValueGainFromSample(weight, testData[i])  , testData[i]._gain )) {
            count++;
            correct++;
        } else {
            count++;
            if(isOuput) {
                testData[i].show();
                cout << "supply:";
                vector<int>tmpsupply;
                int tsSize = testData[i]._supply.size();
                for(int j=0;j<tsSize;j++) {
                    if(testData[i]._supply[j] > 0) {
                        tmpsupply.push_back(j+1);
                    }
                }
                showGain(tmpsupply);
                cout << "coin:" << testData[i]._coin << endl;
                cout << "buy:" << testData[i]._buy << endl;
                cout << "AnsGain:";
                showGain(testData[i]._gain);
                cout << "gotGain:";
                showGain( getMaxValueGainFromSample(weight, testData[i]) );
            }
        }
    }
    
    return (double)correct / (double)count ;
    
}





vector<int> getMaxValueGainFromSample(const vector< vector<double> > &weight, Sample teacher) {
    
    
    map<int,double> cardValues;
    int sSize = teacher._supply.size();
    for(int i=0;i<sSize;i++) {
        double value = getInnerProduct(weight[i],teacher._feature,teacher._notZero);
        cardValues.insert(map<int,double>::value_type(i+1,value));
    }
    
    double maxValue = -999999;
    int maxindex = 0;
    int gSize = teacher._gainlist.size();
    for(int i=0;i<gSize;i++) {
        double sumValue = 0.0;
        int ggSize = teacher._gainlist[i].size();
        for(int j=0;j<ggSize;j++) {
            sumValue += cardValues[teacher._gainlist[i][j]];
        }
        if(maxValue < sumValue) {
            maxValue = sumValue;
            maxindex = i;
        }
    }
    
    vector<int> maxGain = teacher._gainlist[maxindex];
    if(cardValues[CARD_COPPER] > 0) {
        int nloop = teacher._buy - teacher._gainlist[maxindex].size();
        for(int i=0;i<nloop;i++) {
            if(maxGain[0] == CARD_DUMMY) {
                maxGain.clear();
            }
            maxGain.push_back(CARD_COPPER);
        }
    }
    
    //showGain(maxGain); cout << "maxValue:" << maxValue << endl;
    
    return maxGain;
}


vector< vector<int> >getGainList(int coin,int buy,vector<int>supply) {
    vector< vector<int> > gainList;
    vector<int> pass;
    pass.push_back(CARD_DUMMY);
    gainList.push_back(pass);
    vector<int> tmp;
    
    for(int j=1;j<=buy;j++) {
        int size = supply.size();
        for(int i=0;i<size;i++) {
            if(supply[i] <= 0) continue;
            int cardid = i+1;
            if(getCost(cardid) == 0) continue;
            if(getCost(cardid) <= coin) {
                supply[i]--;
                makeList(coin - getCost(cardid),j - 1,cardid,tmp,&gainList,supply);
                supply[i]++;
            }
        }
    }
    return gainList;
}

void makeList(int coin,int buy,int id,vector<int>tmp,vector< vector<int> >*gainlist,vector<int>supply) {
    tmp.push_back(id);
    if(buy <= 0 ) {
        gainlist->push_back(tmp);
        return;
    }
    int sSize = supply.size();
    for(int i=0;i<sSize;i++) {
        if(supply[i] <= 0) continue;
        int cardid = i+1;
        if(getCost(cardid) == 0) continue;
        if(getCost(cardid) <= coin) {
            supply[i]--;
            makeList(coin - getCost(cardid),buy - 1,cardid,tmp,gainlist,supply);
            supply[i]++;
        }
    }
}

void showGainList(vector< vector<int> >gainList) {
    int size = gainList.size();
    for(int i=0;i<size;i++) {
        showGain(gainList[i]);
    }
    cout << "組み合わせ：" << gainList.size() << "通り" << endl;
}


