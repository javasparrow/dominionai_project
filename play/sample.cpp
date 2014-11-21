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
    _sampleid = id;
  
    
    //TODO::ここからの初期化をデータからきちんと行う
    //   特徴ベクトル/ゲイン/サプライ/コイン/バイ
    vector<string> out = SpritString(str,"/");
    if(out.size() != 5) {
        cout << "file reading error: not match format" << endl;
        exit(0);
    }
    for(int i=0;i<5;i++) {
        vector<string> out2 = SpritString(out[i], ",");
        if((i==3 || i==4) && out2.size()!=1) {
            cout << "file reading error: not match format" << endl;
            exit(0);
        }
        if(i==0) {
            //feature
            for(int j=0;j<out2.size();j++) {
                _feature.push_back(atof(out2[j].c_str()));
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
    cout << endl;
}

int Sample::getDimensionOfFeature() {
    return (int)_feature.size();
}
