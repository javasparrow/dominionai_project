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



void Sample::show() {
    printf("teacherData id=%d :(",_sampleid);
}

int Sample::getDimensionOfFeature() {
    return (int)_feature.size();
}


cellarSample::cellarSample(int id,string str) {
    _sampleid = id;
    //feature/hand/answerSelectCards
    vector<string> out = SpritString(str,"/");
    if(out.size() != 3) {
        cout << "reading teacherData error: not match format '/' " << endl;
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
                _hand.push_back(atoi(out2[j].c_str()));
            }
        }
        if(i==2) {
            //answerSelectCards
            for(unsigned int j=0;j<out2.size();j++) {
                _answerSelectCards.push_back(atoi(out2[j].c_str()));
            }
        }
    }
}
void cellarSample::show() {
    cout << "cellerLearnData id=" << _sampleid << endl;
    cout << "hand:";
    showGain(_hand);
    cout << "answerSelectCards:";
    showGain(_answerSelectCards);
}

remodelSample::remodelSample(int id,string str) {
    _sampleid = id;
    //feature/hand/answerSelectCard
    vector<string> out = SpritString(str,"/");
    if(out.size() != 3) {
        cout << "reading teacherData error: not match format '/' " << endl;
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
                _hand.push_back(atoi(out2[j].c_str()));
            }
        }
        if(i==2) {
            //answerSelectCard
            if(out2.size() != 1) {
                cout << "error: size of answerSelectCard != 1" << endl;
                exit(0);
            }
            _answerSelectCard = atoi(out2[0].c_str());
        }
    }
}
void remodelSample::show() {
    cout << "remodelLearnData id=" << _sampleid << endl;
    cout << "hand:";
    showGain(_hand);
    cout << "answerSelectCard:";
    cout << getString(_answerSelectCard) << endl;
}
