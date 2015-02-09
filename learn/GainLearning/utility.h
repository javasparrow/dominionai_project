//
//  utility.h
//  parseptron
//
//  Created by Yuki Murakami on 2014/05/21.
//  Copyright (c) 2014年 yuki. All rights reserved.
//

#pragma once

#include <iostream>
#include <vector>
#include <map>
#include "sample.h"

using namespace std;



vector<int> getMaxValueGain(const vector< vector<double> > &weight,const vector<double> &feature, const vector<int> &notZero ,vector<int> supply,int coin,int buy);

double test(const vector< vector<double> > &weight, vector<Sample> testData ,bool isOutput);


vector<int> getMaxValueGainFromSample(const vector< vector<double> > &weight, Sample teacher);


vector< vector<int> > getGainList(int coin,int buy,vector<int>supply);

void makeList(int coin,int buy,int id,vector<int>tmp,vector< vector<int> >*gainlist,vector<int>supply);

void showGainList(vector< vector<int> > gainList);
