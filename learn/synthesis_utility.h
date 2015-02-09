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
#include <string>


using namespace std;

#pragma mark - string

//文字列を区切る
vector<string> SpritString(const string &src,const string &delim);

#pragma mark - vector

double getInnerProduct(const vector<double> &a,const vector<double> &b,const vector<int> &notZero);
vector<double> addVector(const vector<double> &a,const vector<double> &b);
vector<double> mulVector(const vector<double> &a,double b);
void showVector(vector<double> a);

#pragma mark - getMaxValue
//評価値が最大のカードIDを取得
//ただし、手札のカード評価値が全てマイナスの場合は０（アクションをうたない）を返す
int getMaxValuePlayCard(const vector< vector<double> > &weight, const vector<double> &feature,const vector<int> &notZero, vector<int> &hand);
//手札が全てマイナスでも最大の者を返す
int getMaxValuePlayCardWithMinus(const vector< vector<double> > &weight, const vector<double> &feature,const vector<int> &notZero, vector<int> &hand);

#pragma mark - getIsDiscardPile
//内積が正ならtrue,負ならfalse 　宰相とか
bool getIsDiscardPile(const vector<double> &weight, const vector<double> &feature,const vector<int> &notZero);

#pragma mark - removeVector
//重複した要素を一つにまとめる　(1,3,3,5,5,7) -> (1,3,5,7)
vector<int> removeSameElementVector(const vector<int> &v);


#pragma mark - inputOutput

void writeWeightVector(vector< vector<double> > weight , string filename);

vector< vector<double> > readWeightVector(string filename);

int readRound(string filename);

void writeRound(int round ,string filename);

void writeRate(double rate,string filename);

#pragma mark - getVector

vector<int> getRandVec(int n);

#pragma mark - show

void showProgress(int a,int b,string str);

void showGain(vector<int>gain);

