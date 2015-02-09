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



//テストメソッド（正解できなかったデータを表示するかどうかをisOutputで指定する
//戻り値は全テストデータの正解率
double test(const vector< vector<double> > &weight, vector<Sample> testData ,bool isOutput,int learnCardId);

