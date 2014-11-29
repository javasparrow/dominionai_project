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

//ベクトルの内積を求める
double getInnerProduct(const vector<double> &a,const vector<double> &b,const vector<int> &notZero);
//ベクトルの足し算
vector<double> addVector(const vector<double> &a,const vector<double> &b);
//ベクトルの実数倍
vector<double> mulVector(const vector<double> &a,double b);
//ベクトルの表示
void showVector(vector<double> a);
//評価値が最大のカードIDを取得
//ただし、手札のカード評価値が全てマイナスの場合は０（アクションをうたない）を返す
int getMaxValuePlayCard(const vector< vector<double> > &weight, const vector<double> &feature,const vector<int> &notZero, vector<int> &hand);



//テストメソッド（正解できなかったデータを表示するかどうかをisOutputで指定する
//戻り値は全テストデータの正解率
double test(const vector< vector<double> > &weight, vector<Sample> testData ,bool isOutput,int learnCardId);

vector<string> SpritString(const string &src,const string &delim);

void writeWeightVector(vector< vector<double> > weight , string filename);

vector< vector<double> > readWeightVector(string filename);

int readRound(string filename);

void writeRound(int round ,string filename);

vector<int> getRandVec(int n);

void showProgress(int a,int b,string str);


#endif /* defined(__parseptron__utility__) */
