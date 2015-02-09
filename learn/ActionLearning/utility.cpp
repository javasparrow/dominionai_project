//
//  utility.cpp
//  parseptron
//
//  Created by Yuki Murakami on 2014/05/21.
//  Copyright (c) 2014年 yuki. All rights reserved.
//


#include <fstream>
#include <iostream>
#include <vector>
#include <stdlib.h>

#include "utility.h"
#include "./../card.h"


using namespace std;




double test(const vector< vector<double> > &weight, vector<Sample> testData,bool isOutput,int learnCardId) {
    
    int count = 0;
    int correct = 0;
    
    if(isOutput) {
        cout << "-----can't fit data-----" << endl;
    }
    
    int tSize = testData.size();
    for(int i=0;i<tSize;i++) {
        showProgress(i,tSize,"test    ");
        if(learnCardId == CARD_REMODEL || learnCardId == CARD_THRONEROOM || learnCardId == CARD_MINE || learnCardId == CARD_THIEF || learnCardId == CARD_BUREAUCRAT) {
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
        if(learnCardId == CARD_LIBRARY || learnCardId == CARD_SPY) {
            int revealCardId = testData[i]._revealCard;
            bool isDiscardPile = getIsDiscardPile(weight[revealCardId-1],testData[i]._feature,testData[i]._notZero);
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





