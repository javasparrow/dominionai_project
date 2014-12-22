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

#include <stdio.h>
#include <stdlib.h>

Sample::Sample(int id,string str) {
    _feature.clear();
    _notZero.clear();
    _hand.clear();
    _sampleid = id;
    _answerPlayCard = 0;
  
    
    //TODO::ここからの初期化をデータからきちんと行う
    //   特徴ベクトル/アクション数/手札/正解カード/ファイル名
    //アクション数は特徴ベクトルの末尾に加える
    //cout << endl;
    vector<string> out = SpritString(str,"/");
    if(out.size() != 5) {
        cout << "file reading error: not match format '/' " << endl;
        cout << out.size() << endl;
        exit(0);
    }
    
    for(int i=0;i<5;i++) {
        if(i==4) {
            _filename = out[i];
        }
        if(out[i] != "") {
            vector<string> out2 = SpritString(out[i], ",");
       
            if(i==0) {
                //feature
                double val=0.0;
                for(unsigned int j=0;j<out2.size();j++) {
                    val = atof( out2[j].c_str() );
                    _feature.push_back(val);
                    if(val != 0) {
                        _notZero.push_back(j);
                    }
                }
            }
            if(i==1) {
                //nAction
            //    double val = atof( out2[0].c_str() );
            //    _feature.push_back(val);
            }
            if(i==2) {
                //hand
                for(unsigned int j=0;j<out2.size();j++) {
                    int cardId = atoi(out2[j].c_str());
                    bool hasAlready = false;
                    for(unsigned int k=0;k<_hand.size();k++) {
                        if(_hand[k] == cardId) {
                            hasAlready = true;
                            break;
                        }
                    }
                    if(!hasAlready) {
                        _hand.push_back(atoi(out2[j].c_str()));
                    }
                }
            }
            if(i==3) {
                //correct
                if(out2.size() != 1) {
                    cout << "file reading error: there are many correct data or nothing " << endl;
                    exit(0);
                }
                _answerPlayCard = atoi(out2[0].c_str());
            }
        }
    }
}

void Sample::show() {
    
    printf("teacherData id=%d :(",_sampleid);
  
    showGain(_hand);
  
}

int Sample::getDimensionOfFeature() {
    return (int)_feature.size();
}
