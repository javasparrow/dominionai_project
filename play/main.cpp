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
#include <ctype.h>

#include "utility.h"
#include "card.h"


#define GAIN_MODE 0
#define PLAY_MODE 1
#define ACTION_MODE 2

#define GAIN_WEIGHT "gainWeight.txt"
#define PLAY_WEIGHT "playWeight.txt"
#define GAIN_FEATURE "gainFeature.txt"
#define PLAY_FEATURE "playFeature.txt"
#define ACTION_FEATURE "actionFeature.txt"
#define OPTION_FEATURE "optionFeature.txt"

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
            int i;
            for( i = 0; argv[2][i] != NULL && isdigit( *(argv[2]+i)) ; ++i) ;
            if( argv[2][i] != NULL) {//数値でない
                PlayActionId = getIdFromEnglishString(string(argv[2]));
            } else {
                PlayActionId = atoi(argv[2]);
            }
        }
    }
    
    string weightfile,featurefile;
    if(Mode == GAIN_MODE) {
        cout << "GainMode" << endl;
        weightfile = GAIN_WEIGHT;//獲得時の重みベクトルデータ
        featurefile = GAIN_FEATURE;//特徴ベクトルデータ
    }
    if(Mode == PLAY_MODE) {
        cout << "PlayMode" << endl;
        weightfile = PLAY_WEIGHT;//プレイするカード選択時の重みベクトルデータ
        featurefile = PLAY_FEATURE;
    }
    if(Mode == ACTION_MODE) {
        cout << "ActionMode:" << getString(PlayActionId) << endl;
        weightfile = "./../learn/ActionLearning/" + getEnglishString(PlayActionId) + "TeacherData/weight.txt";
        featurefile = ACTION_FEATURE;
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
   
    //書庫
    int revealCard;
    
    
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
        if(PlayActionId == CARD_REMODEL || PlayActionId == CARD_THRONEROOM || PlayActionId == CARD_CHAPEL || PlayActionId == CARD_MILITIA || PlayActionId == CARD_CELLAR || PlayActionId == CARD_MINE || PlayActionId == CARD_THIEF || PlayActionId == CARD_LIBRARY || PlayActionId == CARD_BUREAUCRAT || PlayActionId == CARD_SPY) {
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
            if(PlayActionId == CARD_LIBRARY || PlayActionId == CARD_SPY) {
                revealCard = atoi(out1[0].c_str());
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
    weight = readWeightVector(weightfile,nWeight,dimensionOfFeature);
    
    
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
        if(PlayActionId == CARD_REMODEL || PlayActionId == CARD_THRONEROOM || PlayActionId == CARD_MINE || PlayActionId == CARD_THIEF || PlayActionId == CARD_BUREAUCRAT || PlayActionId == CARD_SPY) {
            if(PlayActionId == CARD_REMODEL) {
                cout << "select trash card /REMODEL" << endl;
            }
            if(PlayActionId == CARD_THRONEROOM) {
                cout << "select throneroom action /THRONEROOM" << endl;
            }
            if(PlayActionId == CARD_BUREAUCRAT) {
                cout << "select victory put on deck /BUREAUCRAT" << endl;
            }
            if(PlayActionId == CARD_THIEF) {
                cout << "select trash treasure /THIEF" << endl;
                //泥棒用のGain用意
                vector<double> gainFeature;
                vector< vector<double> > gainWeight;
                ifstream ifs3(GAIN_FEATURE);
                if(!ifs3) {
                    cout << "error: not found featureFile" << endl;
                    exit(0);
                }
                string gainTestFeature;
                getline(ifs3,gainTestFeature);
                vector<string> out = SpritString(gainTestFeature,"/");
                
                vector<string> out0 = SpritString(out[0],",");
                for(int i=0;i<out0.size();i++) {
                    gainFeature.push_back(atof(out0[i].c_str()));
                }
                gainWeight = readWeightVector(GAIN_WEIGHT,CARD_MAX,gainFeature.size());
                
                int trashTreasure = getMaxValuePlayCard(weight,feature,hand);
                cout << "trash :" << getString(trashTreasure) << endl;
                double value = getInnerProduct(gainWeight[trashTreasure-1],gainFeature);
                if(value >= 0) {
                    cout << "isGain: YES (" << value << ")" << endl;
                } else {
                    cout << "isGain: NO (" << value << ")" << endl;
                }
            }
            if(PlayActionId == CARD_SPY) {
                //密偵相手用のweight,featureを用意
                vector< vector<double> > enemyWeight;
                string enemyWeightFile = "./../learn/ActionLearning/" + getEnglishString(PlayActionId) + "TeacherData/enemy/weight.txt";
                enemyWeight = readWeightVector(enemyWeightFile,CARD_MAX,dimensionOfFeature);
                
                vector<double> optionFeature;
                int optionReveal;
                ifstream ifs3(OPTION_FEATURE);
                if(!ifs3) {
                    cout << "error: not found featureFile" << endl;
                    exit(0);
                }
                string enemyFeature;
                getline(ifs3,enemyFeature);
                vector<string> out = SpritString(enemyFeature,"/");
                if(out.size() != 2) {
                    cout << "file reading error: not match format '/' " << endl;
                    exit(0);
                }
                vector<string> out0 = SpritString(out[0],",");
                for(int i=0;i<out0.size();i++) {
                    optionFeature.push_back(atof(out0[i].c_str()));
                }
                vector<string> out1 = SpritString(out[1],",");
                optionReveal = atoi(out1[0].c_str());
                
                
                cout << "select which discard or not /SPY" << endl;
                cout << "ME" << endl;
                cout << "revealCard:" << getString(revealCard) << endl;
                cout << "isDiscard:";
                getIsDiscard(weight[revealCard-1],feature);
                cout << "ENEMY" << endl;
                cout << "revealCard:" << getString(optionReveal) << endl;
                cout << "isDiscard:";
                getIsDiscard(enemyWeight[optionReveal-1],optionFeature);
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
        if(PlayActionId == CARD_LIBRARY) {
            cout << "select which discard or not /LIBRARY" << endl;
            cout << "action:" << getString(revealCard) << endl;
            cout << "isDiscard:";
            getIsDiscard(weight[revealCard-1],feature);
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

