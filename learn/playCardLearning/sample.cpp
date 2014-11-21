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
    //   特徴ベクトル/手札/正解カード
    //cout << endl;
    vector<string> out = SpritString(str,"/");
    if(out.size() != 3) {
        cout << "file reading error: not match format '/' " << endl;
        cout << out.size() << endl;
        exit(0);
    }
    
    for(int i=0;i<3;i++) {
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
        if(i==2) {
            //correct
            if(out2.size() != 1) {
                cout << "file reading error: there are many correct data or nothing " << endl;
                exit(0);
            }
            _answerPlayCard = atoi(out2[0].c_str());
        }
    }
}

void Sample::show() {
    
    printf("teacherData id=%d :(",_sampleid);
    /*
    for(unsigned int i=0;i<_feature.size();i++) {
        printf("%3.1f",_feature[i]);
        if(i == _feature.size()-1) {
            printf(") (");
        } else {
            printf(",");
        }
    }
     */
    showGain(_hand);
    /*
    for(unsigned int i=0;i<_hand.size();i++) {
        printf("%d",_hand[i]);
        if(i == _hand.size()-1) {
            printf(")");
        } else {
            printf(",");
        }
    }
     */
   // cout << "correctData:" << getString(_answerPlayCard) << endl;
}

int Sample::getDimensionOfFeature() {
    return (int)_feature.size();
}
