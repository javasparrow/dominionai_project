//
//  utility.cpp
//  parseptron
//
//  Created by Yuki Murakami on 2014/05/21.
//  Copyright (c) 2014年 yuki. All rights reserved.
//

#include "utility.h"
#include "card.h"
#include "sample.h"

#include <fstream>
#include <iostream>
#include <vector>
#include <stdlib.h>

using namespace std;

double getInnerProduct(const vector<double> &a,const vector<double> &b,const vector<int> &notZero) {
    if(a.size() != b.size()) {
        cout << "error: size of vector don't match @innerProduct" << endl;
        exit(0);
    }
    double sum = 0;
    int size = notZero.size();
    for(int i=0;i<size;i++) {
        sum += a[notZero[i]] * b[notZero[i]];
    }
    return sum;
}

void showVector(vector<double> a) {
    for(unsigned int i=0;i<a.size();i++) {
        cout << a[i] << ",";
    }
    cout << endl;
}

vector<double> addVector(const vector<double> &a,const vector<double> &b) {
    //cout << "addVector" << endl;
    if(a.size() != b.size()) {
        cout << "error: size of vector don't match (a= " << a.size() << ",b=" << b.size() << ")@add" << endl;
        exit(0);
    }
    const int size = a.size();
    vector<double> c(size);
    for(int i=0;i<size;i++) {
        c[i] = a[i]+b[i];
    }
//    if(a.size() != c.size()) {
//        cout << "error: size of vector don't match add c" << endl;
//        cout << a.size() << " " << c.size() << endl;
//        exit(0);
//    }
    return c;
}

vector<double> mulVector(const vector<double> &a,double b) {
    
    const int size = a.size();
    vector<double> c(size);
    for(int i=0;i<size;i++) {
        c[i] = a[i] * b;
    }
    return c;
}


int getMaxValuePlayCard(const vector< vector<double> > &weight, const vector<double> &feature,const vector<int> &notZero, vector<int> &hand) {
    if(hand.size() <= 0) return 0;
    
    vector<double> values;
    for(unsigned int i=0;i<hand.size();i++) {
        double value = getInnerProduct(weight[hand[i]-1],feature,notZero);
        values.push_back(value);
    }
    
    double maxValue = values[0];
    int index = -1;
    for(unsigned int i=0;i<values.size();i++) {
        if(values[i] >= maxValue) {
            maxValue = values[i];
            index = i;
        }
    }
    
    if(index == -1) {
        cout << "error: selected index = -1 @getMaxValuePlayCard" << endl;
        exit(0);
    }
    
    if(maxValue < 0) return 0;
    
    return hand[index];
}

int getMaxValuePlayCardWithMinus(const vector< vector<double> > &weight, const vector<double> &feature,const vector<int> &notZero, vector<int> &hand) {
    if(hand.size() <= 0) return 0;
    
    vector<double> values;
    for(unsigned int i=0;i<hand.size();i++) {
        double value = getInnerProduct(weight[hand[i]-1],feature,notZero);
        values.push_back(value);
    }
    
    double maxValue = values[0];
    int index = -1;
    for(unsigned int i=0;i<values.size();i++) {
        if(values[i] >= maxValue) {
            maxValue = values[i];
            index = i;
        }
    }
    if(index == -1) {
        cout << "error: selected index = -1 @getMaxValuePlayCardWithMinus" << endl;
        exit(0);
    }
    return hand[index];
}

bool getIsDiscardPile(const vector<double> &weight, const vector<double> &feature,const vector<int> &notZero) {
    bool flag = false;
    
    double value = getInnerProduct(weight,feature,notZero);
    if(value < 0)  {
        flag = false;
    } else {
        flag = true;
    }
    return flag;
}

vector<int> removeSameElementVector(const vector<int> &v) {
    vector<int> already;
    for(unsigned int i=0;i<v.size();i++) {
        bool flag = false;
        for(unsigned int j=0;j<already.size();j++) {
            if(already[j] == v[i]) {
                flag = true;
                break;
            }
        }
        if(!flag) {//重複してない要素
            already.push_back(v[i]);
        }
    }
    return already;
}

double test(const vector< vector<double> > &weight, vector<Sample> testData,bool isOutput,int learnCardId) {
    
    int count = 0;
    int correct = 0;
    
    if(isOutput) {
        cout << "-----can't fit data-----" << endl;
    }
    
    int tSize = testData.size();
    for(int i=0;i<tSize;i++) {
        showProgress(i,tSize,"test    ");
        if(learnCardId == CARD_REMODEL || learnCardId == CARD_THRONEROOM || learnCardId == CARD_MINE || learnCardId == CARD_THIEF) {
            int gotPlayCard = getMaxValuePlayCard(weight,testData[i]._feature,testData[i]._notZero,testData[i]._hand);
            if(gotPlayCard == testData[i]._answerSelectCard) {
                count++;
                correct++;
            } else {
                count++;
                if(isOutput) {
                    testData[i].show();
                    
                    cout << "AnsPlayCard:" << getString(testData[i]._answerSelectCard) << "gotPlayCard:" << getString(gotPlayCard) << endl;
                }
            }
        }
        if(learnCardId == CARD_CHAPEL || learnCardId == CARD_CELLAR) {
            vector<int> gotSelectCards;
            vector<double> feature;
            copy(testData[i]._feature.begin(),testData[i]._feature.end(),back_inserter(feature));
            if(learnCardId == CARD_CELLAR) {
                feature.push_back(0.0);
            }
            vector<int> notZero;
            copy(testData[i]._notZero.begin(),testData[i]._notZero.end(),back_inserter(notZero));
            vector<int> hand;
            copy(testData[i]._hand.begin(),testData[i]._hand.end(),back_inserter(hand));
            int limitCount = 0;
            while(true) {
                limitCount++;
                int gotSelectCard = getMaxValuePlayCard(weight,feature,notZero,hand);
                if(gotSelectCard != 0) {
                    if(learnCardId == CARD_CHAPEL && limitCount > 4) break;
                    gotSelectCards.push_back(gotSelectCard);
                } else {
                    break;
                }
                for(unsigned int i=0;i<hand.size();i++) {
                    if(hand[i] == gotSelectCard) {
                        hand.erase(hand.begin()+i);
                        break;
                    }
                }
                if(learnCardId == CARD_CHAPEL) {
                    //礼拝堂廃棄なので対象カードを手札から削除
                    feature[(CARD_MAX+1) + gotSelectCard]--;
                }
                if(learnCardId == CARD_CELLAR) {
                    //ちかちょは、対象カードが手札から捨て札に移り、何枚目かの特徴量をインクリメント
                    feature[(CARD_MAX+1) + gotSelectCard]--;//手札から削除
                    feature[(CARD_MAX+1)*2 + gotSelectCard]++;//捨て札に追加
                    feature[feature.size()-1]++;//何枚目のdiscardか、をインクリメント
                }
                continue;
            }
            if(isEqualGain(gotSelectCards,testData[i]._answerSelectCards)) {
                count++;
                correct++;
            } else {
                count++;
                if(isOutput) {
                    testData[i].show();
                    cout << "AnsSelectCards:";
                    showGain(testData[i]._answerSelectCards);
                    cout << "GotSelectCards:";
                    showGain(gotSelectCards);
                }
            }
        }
        if(learnCardId == CARD_MILITIA) {
            vector<int> hand;
            copy(testData[i]._hand.begin(),testData[i]._hand.end(),back_inserter(hand));
            vector<int> discardCards;
            while(hand.size() > 3) {
                int gotSelectCard = getMaxValuePlayCardWithMinus(weight,testData[i]._feature,testData[i]._notZero,hand);
                discardCards.push_back(gotSelectCard);
                for(unsigned int j=0;j<hand.size();j++) {
                    if(hand[j] == gotSelectCard) {
                        hand.erase(hand.begin()+j);
                        break;
                    }
                }
            }
            if(isEqualGain(discardCards,testData[i]._answerSelectCards)) {
                count++;
                correct++;
            } else {
                count++;
                if(isOutput) {
                    testData[i].show();
                    cout << "AnsSelectCards:";
                    showGain(testData[i]._answerSelectCards);
                    cout << "GotSelectCards:";
                    showGain(discardCards);
                }
            }
        }
        if(learnCardId == CARD_CHANCELLOR) {
            bool isDiscardPile = getIsDiscardPile(weight[0],testData[i]._feature,testData[i]._notZero);
            bool answerIsDiscardPile = testData[i]._isDiscard;
           
            if(isDiscardPile == answerIsDiscardPile) {
                count++;
                correct++;
            } else {
                count++;
                if(isOutput) {
                    testData[i].show();
                    
                    cout << "answerDiscard:";
                    if(answerIsDiscardPile) {
                        cout << "true" << endl;
                    } else {
                        cout << "false" << endl;
                    }
                    cout << "gotDiscard:";
                    if(isDiscardPile) {
                        cout << "true" << endl;
                    } else {
                        cout << "false" << endl;
                    }
                }
            }
        }
    }
    
    return (double)correct / (double)count ;
    
}


vector<string> SpritString(const string &src,const string &delim) {
    string::size_type start = 0;
    vector<string> dest;
    while(true){
        string::size_type end = src.find(delim, start);
        if(end != string::npos){
            dest.push_back(src.substr(start, end - start));
        }
        else{
            dest.push_back(src.substr(start, src.length() - start));
            break;
        }
        start = end + delim.length();
    }
    return dest;
}


void writeWeightVector(vector< vector<double> > weight , string filename) {
    ofstream ofs(filename.c_str());
    for(unsigned int i=0;i<weight.size();i++) {
        for(unsigned int j=0;j<weight[i].size();j++) {
            if(j == weight[i].size()-1)  {
                ofs << weight[i][j] << endl;
            } else {
                ofs << weight[i][j] << ",";
            }
        }
    }
    ofs.close();
}

vector< vector<double> > readWeightVector(string filename) {
    vector< vector<double> > weight;
    ifstream ifs(filename.c_str());
    string buf;
    while(ifs && getline(ifs,buf)) {
        vector<double> tmp;
        vector<string> out = SpritString(buf,",");
        for(unsigned int i=0;i<out.size();i++) {
            double val = atof(out[i].c_str());
            tmp.push_back(val);
        }
        weight.push_back(tmp);
    }
    return weight;
}

void writeRound(int round ,string filename) {
    ofstream ofs(filename.c_str());
    ofs << round << endl;
    ofs.close();
}

int readRound(string filename) {
    int round = 0;
    ifstream ifs(filename.c_str());
    string buf;
    while(ifs && getline(ifs,buf)) {
        round = atoi(buf.c_str());
    }
    return round;
}


vector<int> getRandVec(int n) {
    vector<int> v;
    
    for(int i=0;i<n;i++) {
        v.push_back(i);
    }
    
    for(int i=0;i<n*10;i++) {
        int f1 = rand()%n;
        int f2 = rand()%n;
        int a = v[f1];
        v[f1] = v[f2];
        v[f2] = a;
    }
    
    return v;
}


void showProgress(int a,int b,string str) {
    
    double progress = (double)a / (double) b * 100;
    int d = (int)(progress/2);
    string para;
    for(int i=0;i<50;i++) {
        if(i == d) {
            para += ">";
        } else {
            para += ".";
        }
    }
    fprintf(stderr,"%s:%s\r",str.c_str(),para.c_str());
    //fprintf(stderr,"%3.0f / 100\r",progress);
    if(a>=b) {
        fprintf(stderr,"                                                     \r");
    }
    
}




