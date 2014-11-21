//
//  sample.cpp
//  parseptron
//
//  Created by Yuki Murakami on 2014/05/21.
//  Copyright (c) 2014年 yuki. All rights reserved.
//

#include "sample.h"
#include "card.h"
#include "utility.h"

Sample::Sample(int id,string str) {
    _feature.clear();
    _gain.clear();
    _supply.clear();
    _notZero.clear();
    _gainlist.clear();
    _sampleid = id;
  
    
    //TODO::ここからの初期化をデータからきちんと行う
    //   特徴ベクトル/ゲイン/サプライ/コイン/バイ
    //cout << endl;
    vector<string> out = SpritString(str,"/");
    if(out.size() != 5) {
        cout << "file reading error: not match format 1" << endl;
        cout << out.size() << endl;
        exit(0);
    }
    /*
    for(int i=0;i<out.size();i++) {
        cout << out[i] << endl;
    }
     */
    for(int i=0;i<5;i++) {
        vector<string> out2 = SpritString(out[i], ",");
        if((i==3 || i==4) && out2.size()!=1) {
            cout << "file reading error: not match format 2" << endl;
            exit(0);
        }
        if(i==0) {
            //feature
            double val=0.0;
            for(int j=0;j<out2.size();j++) {
                val = atof( out2[j].c_str() );
                _feature.push_back(val);
                if(val != 0) {
                    _notZero.push_back(j);
                }
            }
        }
        if(i==1) {
            //gainlist
            for(int j=0;j<out2.size();j++) {
                _gain.push_back(atoi(out2[j].c_str()));
            }
        }
        if(i==2) {
            //supply j=1なのはID0のデータを飛ばすため 銅貨は１
            for(int j=1;j<out2.size();j++) {
                _supply.push_back(atoi(out2[j].c_str()));
            }
        }
    }
    _coin = atoi(out[3].c_str());
    _buy = atoi(out[4].c_str());
    int answerBuy = 1;
    for(int i=0;i<_gain.size();i++) {
        if(_gain[i] != CARD_COPPER) {
            answerBuy++;
        }
    }
    if(answerBuy > _buy) answerBuy = _buy;
    if(answerBuy>5) answerBuy = 5;
    _gainlist = getGainList(_coin, answerBuy, _supply);
}

void Sample::show() {
    printf("teacherData id=%d :(",_sampleid);
    for(int i=0;i<_feature.size();i++) {
        printf("%3.1f",_feature[i]);
        if(i == _feature.size()-1) {
            printf(") (");
        } else {
            printf(",");
        }
    }
    for(int i=0;i<_gain.size();i++) {
        printf("%d",_gain[i]);
        if(i == _gain.size()-1) {
            printf(")");
        } else {
            printf(",");
        }
    }
    cout << "gainList:" << endl;
    //showGainList(_gainlist);
    cout << endl;
}

int Sample::getDimensionOfFeature() {
    return (int)_feature.size();
}
