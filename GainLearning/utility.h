//
//  utility.h
//  parseptron
//
//  Created by Yuki Murakami on 2014/05/21.
//  Copyright (c) 2014年 yuki. All rights reserved.
//

#ifndef __parseptron__utility__
#define __parseptron__utility__

#include <iostream>
#include <vector>
#include <map>
#include "sample.h"

using namespace std;

double getInnerProduct(const vector<double> &a,const vector<double> &b,const vector<int> &notZero);

vector<double> addVector(const vector<double> &a,const vector<double> &b);

vector<double> mulVector(const vector<double> &a,double b);

void showVector(vector<double> a);

vector<int> getMaxValueGain(const vector< vector<double> > &weight,const vector<double> &feature, const vector<int> &notZero ,vector<int> supply,int coin,int buy);

double test(const vector< vector<double> > &weight, vector<Sample> testData ,bool isOutput);

vector<string> SpritString(const string &src,const string &delim);

void writeWeightVector(vector< vector<double> > weight , string filename);

vector< vector<double> > readWeightVector(string filename);

int readRound(string filename);

void writeRound(int round ,string filename);

vector<int> getRandVec(int n);

void showProgress(int a,int b,string str);

vector<int> getMaxValueGainFromSample(const vector< vector<double> > &weight, Sample teacher);

#endif /* defined(__parseptron__utility__) */
