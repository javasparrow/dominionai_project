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

double getInnerProduct(const vector<double> &a,const vector<double> &b,const vector<int> &notZero) {
    if(a.size() != b.size()) {
        cout << "error: size of vector don't match @innerProduct" << endl;
        exit(0);
    }
    double sum = 0;
    int size = notZero.size();
    for(int i=0;i<size;i++) {
        sum += a[notZero[i]] * b[notZero[i]];
    }
    return sum;
}

void showVector(vector<double> a) {
    for(unsigned int i=0;i<a.size();i++) {
        cout << a[i] << ",";
    }
    cout << endl;
}

vector<double> addVector(const vector<double> &a,const vector<double> &b) {
    //cout << "addVector" << endl;
    if(a.size() != b.size()) {
        cout << "error: size of vector don't match (a= " << a.size() << ",b=" << b.size() << ")@add" << endl;
        exit(0);
    }
    const int size = a.size();
    vector<double> c(size);
    for(int i=0;i<size;i++) {
        c[i] = a[i]+b[i];
    }
//    if(a.size() != c.size()) {
//        cout << "error: size of vector don't match add c" << endl;
//        cout << a.size() << " " << c.size() << endl;
//        exit(0);
//    }
    return c;
}

vector<double> mulVector(const vector<double> &a,double b) {
    
    const int size = a.size();
    vector<double> c(size);
    for(int i=0;i<size;i++) {
        c[i] = a[i] * b;
    }
    return c;
}


int getMaxValuePlayCard(const vector< vector<double> > &weight, const vector<double> &feature,const vector<int> &notZero, vector<int> &hand) {
    
    vector<double> values;
    for(unsigned int i=0;i<hand.size();i++) {
        double value = getInnerProduct(weight[hand[i]],feature,notZero);
        values.push_back(value);
    }
    values.push_back(getInnerProduct(weight[0],feature,notZero));
    
    if(values.size() <= 0) return 0;
    
    double maxValue = values[0];
    int index = -1;
    for(unsigned int i=0;i<values.size();i++) {
        if(values[i] >= maxValue) {
            maxValue = values[i];
            index = i;
        }
    }
    if(index >= hand.size()) return 0;
    //if(maxValue < 0) return 0;
    
    return hand[index];
}

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




void writeWeightVector(vector< vector<double> > weight , string filename) {
    ofstream ofs(filename.c_str());
    for(unsigned int i=0;i<weight.size();i++) {
        for(unsigned int j=0;j<weight[i].size();j++) {
            if(j == weight[i].size()-1)  {
                ofs << weight[i][j] << endl;
            } else {
                ofs << weight[i][j] << ",";
            }
        }
    }
    ofs.close();
}

vector< vector<double> > readWeightVector(string filename) {
    vector< vector<double> > weight;
    ifstream ifs(filename.c_str());
    string buf;
    while(ifs && getline(ifs,buf)) {
        vector<double> tmp;
        vector<string> out = SpritString(buf,",");
        for(unsigned int i=0;i<out.size();i++) {
            double val = atof(out[i].c_str());
            tmp.push_back(val);
        }
        weight.push_back(tmp);
    }
    return weight;
}

void writeRound(int round ,string filename) {
    ofstream ofs(filename.c_str());
    ofs << round << endl;
    ofs.close();
}

void writeRate(double rate ,string filename) {
    ofstream ofs(filename.c_str());
    ofs << rate << endl;
    ofs.close();
}

int readRound(string filename) {
    int round = 0;
    ifstream ifs(filename.c_str());
    string buf;
    while(ifs && getline(ifs,buf)) {
        round = atoi(buf.c_str());
    }
    return round;
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


void showProgress(int a,int b,string str) {
    
    double progress = (double)a / (double) b * 100;
    int d = (int)(progress/2);
    string para;
    for(int i=0;i<50;i++) {
        if(i == d) {
            para += ">";
        } else {
            para += ".";
        }
    }
    fprintf(stderr,"%s:%s\r",str.c_str(),para.c_str());
    //fprintf(stderr,"%3.0f / 100\r",progress);
    if(a>=b) {
        fprintf(stderr,"                                                     \r");
    }
    
}


