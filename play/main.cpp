//
//  main.cpp
//  parseptron
//
//  Created by Yuki Murakami on 2014/05/16.
//  Copyright (c) 2014年 yuki. All rights reserved.
//

#include <iostream>
#include <stdio.h>
#include <stdlib.h>
#include <vector>
#include <time.h>
#include <fstream>

#include "utility.h"
#include "card.h"


#define GAIN_MODE 0
#define PLAY_MODE 1
#define ACTION_MODE 2


using namespace std;

int main(int argc, const char * argv[])
{
    srand((unsigned)time(NULL));
    
    int Mode = GAIN_MODE;
    int PlayActionId = 0;
    
    if(argc >= 2) {
        if(argv[1][0] == 'g') {
            Mode = GAIN_MODE;
        }
        if(argv[1][0] == 'p') {
            Mode = PLAY_MODE;
        }
        if(argv[1][0] == 'a') {
            Mode = ACTION_MODE;
        }
        if(Mode == ACTION_MODE) {
            PlayActionId = atoi(argv[2]);
        }
    }
    
    string weightfile,featurefile;
    if(Mode == GAIN_MODE) {
        cout << "GainMode" << endl;
        weightfile = "gainWeight.txt";//獲得時の重みベクトルデータ
        featurefile = "gainFeature.txt";//特徴ベクトルデータ
    }
    if(Mode == PLAY_MODE) {
        cout << "PlayMode" << endl;
        weightfile = "playWeight.txt";//プレイするカード選択時の重みベクトルデータ
        featurefile = "playFeature.txt";
    }
    if(Mode == ACTION_MODE) {
        cout << "ActionMode:" << getString(PlayActionId) << endl;
        weightfile = "./../learn/ActionLearning/" + getEnglishString(PlayActionId) + "TeacherData/weight.txt";
        featurefile = "actionFeature.txt";
    }
    
    //共通
    int nWeight,dimensionOfFeature;
    vector<double> feature;
    vector< vector<double> > weight;
    //GainModeのみ
    int coin,buy;
    vector<int> supply;
    //PlayModeのみ
    vector<int> hand;
   
    
    
    
    
    //-----------------------特徴ベクトルの生成-------------------------
    ifstream ifs2(featurefile);
    if(!ifs2) {
        cout << "error: not found featureFile" << endl;
        exit(0);
    }
    string testFeature;
    getline(ifs2,testFeature);
    
    if(Mode == GAIN_MODE) {
        vector<string> out = SpritString(testFeature,"/");
        if(out.size() != 4) {
            cout << "error: feature's format don't match" << endl;
            exit(0);
        }
        coin = atoi(out[2].c_str());
        buy = atoi(out[3].c_str());
        vector<string> out0 = SpritString(out[0],",");
        for(int i=0;i<out0.size();i++) {
            feature.push_back(atof(out0[i].c_str()));
        }
        vector<string> out1 = SpritString(out[1],",");
        for(int i=1;i<out1.size();i++) {
            supply.push_back(atoi(out1[i].c_str()));
        }
        
        nWeight = supply.size();
        dimensionOfFeature = feature.size();
    }
    if(Mode == PLAY_MODE) {
        vector<string> out = SpritString(testFeature,"/");
        if(out.size() != 2) {
            cout << "file reading error: not match format '/' " << endl;
            exit(0);
        }
        vector<string> out0 = SpritString(out[0],",");
        for(int i=0;i<out0.size();i++) {
            feature.push_back(atof(out0[i].c_str()));
        }
        vector<string> out1 = SpritString(out[1],",");
        for(int i=0;i<out1.size();i++) {
            hand.push_back(atoi(out1[i].c_str()));
        }
        dimensionOfFeature = feature.size();
        nWeight = 32;//基本セットのみのカード種類数
    }
    if(Mode == ACTION_MODE) {
        nWeight = 32;//基本セットのみのカード種類数
        vector<string> out = SpritString(testFeature,"/");
        if(PlayActionId == CARD_REMODEL || PlayActionId == CARD_THRONEROOM || PlayActionId == CARD_CHAPEL || PlayActionId == CARD_MILITIA || PlayActionId == CARD_CELLAR || PlayActionId == CARD_MINE) {
            if(out.size() != 2) {
                cout << "file reading error: not match format '/' " << endl;
                exit(0);
            }
            vector<string> out0 = SpritString(out[0],",");
            for(int i=0;i<out0.size();i++) {
                feature.push_back(atof(out0[i].c_str()));
            }
            if(PlayActionId == CARD_CELLAR) {
                feature.push_back(0.0);
            }
            vector<string> out1 = SpritString(out[1],",");
            for(int i=0;i<out1.size();i++) {
                hand.push_back(atoi(out1[i].c_str()));
            }
            dimensionOfFeature = feature.size();
        }
        if(PlayActionId == CARD_CHANCELLOR) {
            if(out.size() != 1) {
                cout << "file reading error: not match format '/' " << endl;
                exit(0);
            }
            vector<string> out0 = SpritString(out[0],",");
            for(int i=0;i<out0.size();i++) {
                feature.push_back(atof(out0[i].c_str()));
            }
            dimensionOfFeature = feature.size();
        }
    }
    
    
    
    //--------------------------------------重みベクトルの読み込み-------
    ifstream ifs(weightfile);
    if(!ifs) {
        cout << "error: not found weightFile" << endl;
        exit(0);
    }
    string buf;
    while(ifs && getline(ifs,buf)) {
        vector<string> output = SpritString(buf,",");
        vector<double> tmpVector;
        for(int i=0;i<output.size();i++) {
            double val = atof(output[i].c_str());
            tmpVector.push_back(val);
        }
        weight.push_back(tmpVector);
    }
    
    if(weight.size() != nWeight) {
        cout << "error: the number of weightVectors don't match" << endl;
        exit(0);
    }
    if(weight[0].size() != dimensionOfFeature) {
        cout << "error: the number of dimension don't match" << endl;
        exit(0);
    }
    
    
    //----------------------------------重みベクトルによる分類----------------------
    if(Mode == GAIN_MODE) {
        vector<int> tmpSupply;
        for(int i=0;i<supply.size();i++) {
            if(supply[i] > 0) tmpSupply.push_back(i+1);
        }
        showGain(tmpSupply);
        cout << "coin:" << coin << " buy:" << buy << endl;
        
        vector<int> gotGain = getMaxValueGain(weight, feature, supply, coin, buy ,10);
    }
    if(Mode == PLAY_MODE) {
        cout << "play card list" << endl;
        cout << "hand:";
        showGain(hand);
        showMaxValuePlayCard(weight,feature,hand,10);
    }
    if(Mode == ACTION_MODE) {
        if(PlayActionId == CARD_REMODEL || PlayActionId == CARD_THRONEROOM || PlayActionId == CARD_MINE) {
            if(PlayActionId == CARD_REMODEL) {
                cout << "select trash card /REMODEL" << endl;
            }
            if(PlayActionId == CARD_THRONEROOM) {
                cout << "select throneroom action /THRONEROOM" << endl;
            }
            if(PlayActionId == CARD_MINE) {
                cout << "select trash treasure /MINE" << endl;
                int trashTreasure = getMaxValuePlayCard(weight,feature,hand);
                int gainTreasure = trashTreasure+1;
                if(gainTreasure > CARD_GOLD) gainTreasure = CARD_GOLD;
                cout << "trash :" << getString(trashTreasure) << endl;
                cout << "gain :" << getString(gainTreasure) << endl;
            }
            cout << "hand:";
            showGain(hand);
            showMaxValuePlayCard(weight,feature,hand,10);
        }
        if(PlayActionId == CARD_CHANCELLOR) {
            cout << "select which discard or not /CHANCELLOR" << endl;
            cout << "isDiscard:";
            getIsDiscard(weight[0],feature);
        }
        if(PlayActionId == CARD_CHAPEL) {
            cout << "select trash cards /CHAPEL" << endl;
            cout << "hand:";
            showGain(hand);
            cout << "trash Cards:";
            showGain(getTrashCardsByChapel(weight,feature,hand));
        }
        if(PlayActionId == CARD_MILITIA) {
            cout << "select discard cards /MILITIA" << endl;
            cout << "hand:";
            showGain(hand);
            cout << "discard Cards:";
            showGain(getDiscardCardsByMilitia(weight,feature,hand));
        }
        if(PlayActionId == CARD_CELLAR) {
            cout << "select discard cards /CELLAR" << endl;
            cout << "hand:";
            showGain(hand);
            cout << "discard Cards:";
            showGain(getDiscardCardsByCellar(weight,feature,hand));
        }
    }
   
    
    return 0;
}

