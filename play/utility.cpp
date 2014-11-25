//
//  utility.cpp
//  parseptron
//
//  Created by Yuki Murakami on 2014/05/21.
//  Copyright (c) 2014年 yuki. All rights reserved.
//

#include "utility.h"
#include "card.h"
#include "sample.h"

#include <fstream>
#include <iostream>
#include <vector>
#include <stdlib.h>

using namespace std;

double getInnerProduct(const vector<double> &a, const vector<double> &b) {
    if(a.size() != b.size()) {
        cout << "error: size of vector don't match" << endl;
        exit(0);
    }
    double sum = 0;
    for(int i=0;i<a.size();i++) {
        sum += a[i] * b[i];
    }
    return sum;
}

void showVector(const vector<double> &a) {
    for(int i=0;i<a.size();i++) {
        cout << a[i] << ",";
    }
    cout << endl;
}

vector<double> addVector(const vector<double> &a,const vector<double> &b) {
    if(a.size() != b.size()) {
        cout << "error: size of vector don't match" << endl;
        exit(0);
    }
    vector<double> c;
    for(int i=0;i<a.size();i++) {
        c.push_back(a[i]+b[i]);
    }
    return c;
}

vector<double> mulVector(const vector<double> &a,double b) {
    vector<double> c;
    for(int i=0;i<a.size();i++) {
        c.push_back(a[i] * b);
    }
    return c;
}


void showMaxValuePlayCard(const vector< vector<double> > &weight, const vector<double> &feature, vector<int> &hand,int ordinal) {
    
    int nHand = hand.size();
    if(ordinal > nHand) {
        ordinal = nHand;
    }
    
    vector<double> values;
    for(int i=0;i<hand.size();i++) {
        double value = getInnerProduct(weight[hand[i]-1],feature);
        values.push_back(value);
    }
    
    vector<int> already;
    for(int i=0;i<ordinal;i++) {
        double maxValue = -99999999;
        int index = -1;
        for(int i=0;i<values.size();i++) {
            bool isAlreadyIndex = false;
            for(int j=0;j<already.size();j++) {
                if(already[j] == i) {
                    isAlreadyIndex = true;
                    break;
                }
            }
            if(isAlreadyIndex) continue;
            if(values[i] > maxValue) {
                maxValue = values[i];
                index = i;
            }
        }
        
        if(index != -1) {
            already.push_back(index);
            cout << i+1 << "位 :(" << getString(hand[index]) << ") " << maxValue << endl;
        }
    }
    
    
    return;
}


vector<int> getMaxValueGain( vector< vector<double> > weight, vector<double> feature,vector<int> supply,int coin,int buy,int ordinal) {
    
    map<int,double> cardValues;
    for(int i=0;i<supply.size();i++) {
        double value = getInnerProduct(weight[i],feature);
        cardValues.insert(map<int,double>::value_type(i+1,value));
    }
    
    vector< vector<int> > gainList = getGainList(coin, buy, supply);
    
    vector<int> already;
    vector<int> maxGain;
    
    for(int k=0;k<ordinal;k++) {
    
        double maxValue = -99999999;
        int maxindex = 0;
        for(int i=0;i<gainList.size();i++) {
            double sumValue = 0.0;
            for(int j=0;j<gainList[i].size();j++) {
                sumValue += cardValues[gainList[i][j]];
            }
            //showGain(gainList[i]); cout << "Value:" << sumValue << endl;
            if(maxValue < sumValue) {
                int flag = 0;
                for(int n=0;n<already.size();n++) {
                    if(already[n] == i) {
                        flag = 1;
                        break;
                    }
                }
                if(flag == 0) {
                    maxValue = sumValue;
                    maxindex = i;
                }
            }
        }
    
        maxGain = gainList[maxindex];
        if(cardValues[CARD_COPPER] > 0) {
            for(int i=0;i<buy - gainList[maxindex].size();i++) {
                maxGain.push_back(CARD_COPPER);
            }
        }
        
        cout << k+1 << "位 :" << maxValue << endl;
        showGain(maxGain);
        already.push_back(maxindex);
    }
    
    //showGain(maxGain); cout << "maxValue:" << maxValue << endl;
    
    return maxGain;
}




vector<string> SpritString(string src,string delim) {
    string::size_type start = 0;
    vector<string> dest;
    while(true){
        string::size_type end = src.find(delim, start);
        if(end != string::npos){
            dest.push_back(src.substr(start, end - start));
        }
        else{
            dest.push_back(src.substr(start, src.length() - start));
            break;
        }
        start = end + delim.length();
    }
    return dest;
}


void writeWeightVector(vector< vector<double> > weight , string filename) {
    ofstream ofs(filename);
    for(int i=0;i<weight.size();i++) {
        for(int j=0;j<weight[i].size();j++) {
            if(j == weight[i].size()-1)  {
                ofs << weight[i][j] << endl;
            } else {
                ofs << weight[i][j] << ",";
            }
        }
    }
    ofs.close();
}


vector<int> getRandVec(int n) {
    vector<int> v;
    
    for(int i=0;i<n;i++) {
        v.push_back(i);
    }
    
    for(int i=0;i<n*10;i++) {
        int f1 = rand()%n;
        int f2 = rand()%n;
        int a = v[f1];
        v[f1] = v[f2];
        v[f2] = a;
    }
    
    return v;
}

