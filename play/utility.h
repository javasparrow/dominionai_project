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


using namespace std;


int showMaxValuePlayCard(const vector< vector<double> > &weight, const vector<double> &feature, vector<int> &hand,int ordinal);
int showMaxValuePlayCardWithDummy(const vector< vector<double> > &weight, const vector<double> &feature, vector<int> &hand,int ordinal);

vector<int> getMaxValueGain( vector< vector<double> > weight,  vector<double> feature, vector<int> supply,int coin,int buy,int ordinal);
vector<int> getMaxValueMustGain( vector< vector<double> > weight, vector<double> feature,vector<int> supply,int coin,int buy,int ordinal);


int getMaxValueMustPlayCard(const vector< vector<double> > &weight, const vector<double> &feature, vector<int> &hand);
int getMaxValuePlayCardWithDummy(const vector< vector<double> > &weight, const vector<double> &feature, vector<int> &hand);

vector<int> getDiscardCardsByMilitia(const vector< vector<double> > &_weight, const vector<double> &_feature, vector<int> &_hand);
vector<int> getDiscardCardsByCellar(const vector< vector<double> > &_weight, const vector<double> &_feature, vector<int> &_hand);
vector<int> getTrashCardsByChapel(const vector< vector<double> > &_weight, const vector<double> &_feature, vector<int> &_hand);

bool getIsDiscard( vector<double> weight, vector<double> feature);


void showOutVector(vector<int> a);

void showOutCard(int a);


