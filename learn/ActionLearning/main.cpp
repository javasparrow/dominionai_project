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

#include <unistd.h>

#include "utility.h"
#include "sample.h"
#include "card.h"

#define KIND_OF_CARD 32

using namespace std;

int main(int argc, const char * argv[])
{
    srand((unsigned)time(NULL));
    bool readFlag = false;
    
    //コマンドライン引数からモードを決定
    if(argc != 3 && argc != 2) {
        cout << "format: ./a.out cardid (r)" << endl;
        cout << "r : loading Mode" << endl;
        exit(0);
    }
    
    if(argc == 3) {
        if(argv[2][0] == 'r') {
            readFlag = true;
            cout << "loading Mode" << endl;
        } else {
            cout << "format: ./a.out cardid (r)" << endl;
            cout << "r : loading Mode" << endl;
            exit(0);
        }
    }
    
    bool optionFlag = false;
    int num;
    int numCheckerI;
    for( numCheckerI = 0; argv[1][numCheckerI] != NULL && isdigit( *(argv[1]+numCheckerI)) ; ++numCheckerI) ;
    if( argv[1][numCheckerI] != NULL) {//数値でない
        num = getIdFromEnglishString(string(argv[1]));
    } else {
        num = atoi(argv[1]);
    }
    
    if(num > 1000) {
        num = num % 1000;
        optionFlag = true;
    }
    
    
    if(num != CARD_REMODEL && num != CARD_THRONEROOM && num != CARD_CHANCELLOR && num != CARD_CHAPEL && num != CARD_MILITIA && num != CARD_CELLAR && num != CARD_MINE && num != CARD_THIEF && num != CARD_LIBRARY && num != CARD_BUREAUCRAT && num != CARD_SPY) {/////
        cout << "Can't learn this cardid" << endl;
        exit(0);
    }
    
    int learningCardId = num;
    
    cout << "select action learning" << endl;
    cout << "MODE:" << getString(learningCardId) << endl;
    if(learningCardId == CARD_SPY) {
        if(optionFlag) {
            cout << "option:enemy" << endl;
        } else {
            cout << "option:me" << endl;
        }
    }
    
    if(!readFlag) {
        cout << "Warning!! :This mode will make NEW weight vector." << endl;
        cout << "Are you OK ? (ok/no)" << endl;
        string ans;
        cin >> ans;
        if(ans == "no") exit(0);
    }
    
    int dimensionOfFeature = 0;
    int nSample;   
    int roundlimit = 2000000000;//学習回数上限
    int roundtest = 50000;//テスト実施の間隔学習回数
    string dataDirectory = getEnglishString(learningCardId) + "TeacherData/";
    
    string studyfile = dataDirectory + "result.txt";//インプット教師データ
    
    
    //--------------------------------------教師信号ベクトルの初期化--------
    cout << "load teacher data" << endl;
    ifstream ifs(studyfile.c_str());
    if(!ifs) {
        cout << "not found teacher data file" << endl;
        exit(0);
    }
    
    string buf;
    vector<Sample> teachers;
    int count = 0;
    while(getline(ifs, buf)) {
        fprintf(stderr,"loading teacher data:%d \r",count+1);
        if(learningCardId == CARD_REMODEL || learningCardId == CARD_THRONEROOM || learningCardId == CARD_MINE || learningCardId == CARD_BUREAUCRAT) {
            remodelSample teacher(count++,buf);
            dimensionOfFeature = teacher.getDimensionOfFeature();
            teachers.push_back(teacher);
        }
        if(learningCardId == CARD_CHANCELLOR) {
            chancellorSample teacher(count++,buf);
            dimensionOfFeature = teacher.getDimensionOfFeature();
            teachers.push_back(teacher);
        }
        if(learningCardId == CARD_SPY) {
            vector<string> out = SpritString(buf,"/");
            if(atoi(out[3].c_str()) == 1 && !optionFlag) {//自分の密偵
                spySample teacher(count++,buf);
                dimensionOfFeature = teacher.getDimensionOfFeature();
                teachers.push_back(teacher);
            }
            if(atoi(out[3].c_str()) == 0 && optionFlag) {//相手の密偵
                spySample teacher(count++,buf);
                dimensionOfFeature = teacher.getDimensionOfFeature();
                teachers.push_back(teacher);
            }
        }
        if(learningCardId == CARD_LIBRARY) {
            librarySample teacher(count++,buf);
            dimensionOfFeature = teacher.getDimensionOfFeature();
            teachers.push_back(teacher);
        }
        if(learningCardId == CARD_THIEF) {
            thiefSample teacher(count++,buf);
            dimensionOfFeature = teacher.getDimensionOfFeature();
            teachers.push_back(teacher);
        }
        if(learningCardId == CARD_CHAPEL || learningCardId == CARD_MILITIA || learningCardId == CARD_CELLAR) {
            cellarSample teacher(count++,buf);
            if(learningCardId == CARD_CELLAR) {
                dimensionOfFeature = teacher.getDimensionOfFeature() + 1;//地下貯は何枚目のdiscardかを判別するため１次元増やす
            } else {
                dimensionOfFeature = teacher.getDimensionOfFeature();
            }
            teachers.push_back(teacher);
        }
    }
    nSample = count;
    
    cout << teachers.size() << " teachers data                                        " << endl;
    
    //--------------------------------------重みベクトルの初期化-------
    cout << "init weight vector                             " << endl;
    cout << "dimension of vector = " << dimensionOfFeature << endl;
    vector< vector<double> > weight;
    vector< vector<double> > averageWeight;
    for(int i=0;i<KIND_OF_CARD;i++) {
        vector<double> tmpVector1,tmpVector2;
        for(int j=0;j<dimensionOfFeature;j++) {
            tmpVector1.push_back(0.0);
            tmpVector2.push_back(0.0);
        }
        weight.push_back(tmpVector1);
        averageWeight.push_back(tmpVector2);
    }
    vector< vector<double> > testWeight;
    
    int round = 0;//ラウンド数
    
    if(learningCardId == CARD_SPY && optionFlag) {
        dataDirectory += "enemy/";
    }
    
    if(readFlag) {
        
        cout << "load weight vector" << endl;
        weight = readWeightVector(dataDirectory + "w_weight.txt");
        averageWeight = readWeightVector(dataDirectory + "u_weight.txt");
        round = readRound(dataDirectory + "round.txt");
        //start = readWeightVector("weight.txt");
    }
    
    //---------------------------------------学習----------------------
    cout << "start learning" << endl;
    vector<int> indexs = getRandVec((int)teachers.size());
    
    while(round < roundlimit) {
        
        showProgress(round%roundtest,roundtest,"learning");
        
        if(round%teachers.size() == 0) {
            indexs = getRandVec((int)teachers.size());
        }
        int sampleIndex = indexs[round%teachers.size()];
        round++;

        if(learningCardId == CARD_REMODEL || learningCardId == CARD_THRONEROOM || learningCardId == CARD_MINE || learningCardId == CARD_THIEF || learningCardId == CARD_BUREAUCRAT) {
            int gotPlayCard = getMaxValuePlayCard(weight,teachers[sampleIndex]._feature,teachers[sampleIndex]._notZero,teachers[sampleIndex]._hand);
            int answerPlayCard = teachers[sampleIndex]._answerSelectCard;
            if(gotPlayCard != answerPlayCard) {
                //間違えたものの重みを引く
                if(gotPlayCard != 0) {
                    int wid = gotPlayCard - 1;
                    weight[wid] = addVector(weight[wid], mulVector(teachers[sampleIndex]._feature , -1) );
                    averageWeight[wid] = addVector(averageWeight[wid], mulVector(teachers[sampleIndex]._feature, round*-1));
                }
                //正解の重みを足す
                if(answerPlayCard != 0) {
                    int wid = answerPlayCard - 1;
                    weight[wid] = addVector(weight[wid],teachers[sampleIndex]._feature );
                    averageWeight[wid] = addVector(averageWeight[wid], mulVector(teachers[sampleIndex]._feature, round));
                }
            }
        }
        if(learningCardId == CARD_MILITIA) {
            vector<int> hand;
            copy(teachers[sampleIndex]._hand.begin(), teachers[sampleIndex]._hand.end(), back_inserter(hand) );
            vector<int> answerSelectCards;
            copy(teachers[sampleIndex]._answerSelectCards.begin(), teachers[sampleIndex]._answerSelectCards.end(), back_inserter(answerSelectCards) );
            vector<int> discardCards;
            while(hand.size() > 3) {
                int gotSelectCard = getMaxValuePlayCardWithMinus(weight,teachers[sampleIndex]._feature,teachers[sampleIndex]._notZero,hand);

                discardCards.push_back(gotSelectCard);
                for(unsigned int j=0;j<hand.size();j++) {
                    if(hand[j] == gotSelectCard) {
                        hand.erase(hand.begin()+j);
                        break;
                    }
                }
            }
            if(discardCards.size() > 0) {
                vector<int> errorCards;
                while(discardCards.size() > 0) {
                    int gotCard = discardCards[0];
                    bool flag = false;
                    for(unsigned int i=0;i<answerSelectCards.size();i++) {
                        if(gotCard == answerSelectCards[i]) {
                            flag = true;
                            answerSelectCards.erase(answerSelectCards.begin()+i);
                            break;
                        }
                    }
                    if(!flag) {//正解になかった（間違って選んだ）重みを減らす
                        errorCards.push_back(gotCard);
                    }
                    discardCards.erase(discardCards.begin());
                }
                //answerSelectCardsに残っているものは正解なのに選ばれなかった　重みを増やす
                vector<int> CanswerSelectCards = removeSameElementVector(answerSelectCards);
                for(unsigned int i=0;i<CanswerSelectCards.size();i++) {
                    int wid = CanswerSelectCards[i] - 1;
                    weight[wid] = addVector(weight[wid],teachers[sampleIndex]._feature );
                    averageWeight[wid] = addVector(averageWeight[wid], mulVector(teachers[sampleIndex]._feature, round));
                }
                //errorCardsにはいっているものは不正解を選んだ　重みを減らす
                vector<int> CerrorCards = removeSameElementVector(errorCards);
                for(unsigned int i=0;i<CerrorCards.size();i++) {
                    int wid = CerrorCards[i] - 1;
                    weight[wid] = addVector(weight[wid], mulVector(teachers[sampleIndex]._feature , -1) );
                    averageWeight[wid] = addVector(averageWeight[wid], mulVector(teachers[sampleIndex]._feature, round*-1));
                }
            }
        }
        if(learningCardId == CARD_CHANCELLOR) {
            bool isDiscardPile = getIsDiscardPile(weight[0],teachers[sampleIndex]._feature,teachers[sampleIndex]._notZero);
            bool answerIsDiscardPile = teachers[sampleIndex]._isDiscard;
            if(isDiscardPile != answerIsDiscardPile) {//不正解の場合
                if(answerIsDiscardPile) {//正例
                    int wid = 0;
                    weight[wid] = addVector(weight[wid],teachers[sampleIndex]._feature );
                    averageWeight[wid] = addVector(averageWeight[wid], mulVector(teachers[sampleIndex]._feature, round));
                } else {//負例
                    int wid = 0;
                    weight[wid] = addVector(weight[wid], mulVector(teachers[sampleIndex]._feature , -1) );
                    averageWeight[wid] = addVector(averageWeight[wid], mulVector(teachers[sampleIndex]._feature, round*-1));
                }
            }
        }
        if(learningCardId == CARD_LIBRARY || learningCardId == CARD_SPY) {
            int wid = teachers[sampleIndex]._revealCard - 1;
            bool isDiscardPile = getIsDiscardPile(weight[wid],teachers[sampleIndex]._feature,teachers[sampleIndex]._notZero);
            bool answerIsDiscardPile = teachers[sampleIndex]._isDiscard;
            if(isDiscardPile != answerIsDiscardPile) {//不正解の場合
                if(answerIsDiscardPile) {//正例
                    weight[wid] = addVector(weight[wid],teachers[sampleIndex]._feature );
                    averageWeight[wid] = addVector(averageWeight[wid], mulVector(teachers[sampleIndex]._feature, round));
                } else {//負例
                    weight[wid] = addVector(weight[wid], mulVector(teachers[sampleIndex]._feature , -1) );
                    averageWeight[wid] = addVector(averageWeight[wid], mulVector(teachers[sampleIndex]._feature, round*-1));
                }
            }
        }
        if(learningCardId == CARD_CHAPEL || learningCardId == CARD_CELLAR) {
            vector<int> hand;
            copy(teachers[sampleIndex]._hand.begin(), teachers[sampleIndex]._hand.end(), back_inserter(hand) );
            vector<int> answerSelectCards;
            copy(teachers[sampleIndex]._answerSelectCards.begin(), teachers[sampleIndex]._answerSelectCards.end(), back_inserter(answerSelectCards) );
            vector<int> notZero;
            copy(teachers[sampleIndex]._notZero.begin(), teachers[sampleIndex]._notZero.end(), back_inserter(notZero) );
            vector<double> feature;
            copy(teachers[sampleIndex]._feature.begin(), teachers[sampleIndex]._feature.end(), back_inserter(feature) );
            if(learningCardId == CARD_CELLAR) {
                feature.push_back(0.0);//ちかちょは何枚目のdiscardを管理する特徴量を増やす
            }
            while(true) {
                int gotSelectCard = getMaxValuePlayCard(weight,feature,notZero,hand);
                
                if(answerSelectCards.size() == 0) {
                    if(gotSelectCard == 0) {
                        //完答（学習の必要なし）
                        break;
                    } else {
                        //よけいに多く選択している間違い（選んだカードの重みを減らす）
                        int wid = gotSelectCard - 1;
                    //    cout << "a" << wid << " " << endl;
                        weight[wid] = addVector(weight[wid], mulVector(feature , -1) );
                        averageWeight[wid] = addVector(averageWeight[wid], mulVector(feature, round*-1));
                        break;
                    }
                } else {
                    if(gotSelectCard == 0) {
                        //まだ選択すべきなのに、もう選択しない間違い（リストに残ったカードの種類全ての重みを増やす）
                        vector<int> already;
                        for(unsigned int i=0;i<answerSelectCards.size();i++) {
                            bool flag = true;//リストのかぶりを消す
                            for(unsigned int j=0;j<already.size();j++) {
                                if(already[j] == answerSelectCards[i]) {
                                    flag = false;
                                    break;
                                }
                            }
                            if(flag) {
                                already.push_back(answerSelectCards[i]);
                                
                                int wid = answerSelectCards[i] - 1;
                              //  cout << "b" << wid << " " << endl;
                                weight[wid] = addVector(weight[wid],feature );
                                averageWeight[wid] = addVector(averageWeight[wid], mulVector(feature, round));
                            }
                        }
                        break;
                    } else {
                        //選択が正解リストに有るかどうか調べる
                        bool find = false;
                        for(unsigned int i=0;i<answerSelectCards.size();i++) {
                            if(answerSelectCards[i] == gotSelectCard) {
                                find = true;
                                break;
                            }
                        }
                        if(!find){
                            //選択ミス（選んだカードの重みを減らし、リストに残ったカードの種類全ての重みを増やす）
                            int wid = gotSelectCard - 1;
                         //   cout << "c" << wid << " " << endl;
                            weight[wid] = addVector(weight[wid], mulVector(feature , -1) );
                            averageWeight[wid] = addVector(averageWeight[wid], mulVector(feature, round*-1));
                            
                            vector<int> already;
                            for(unsigned int i=0;i<answerSelectCards.size();i++) {
                                bool flag = true;//リストのかぶりを消す
                                for(unsigned int j=0;j<already.size();j++) {
                                    if(already[j] == answerSelectCards[i]) {
                                        flag = false;
                                        break;
                                    }
                                }
                                if(flag) {
                                    already.push_back(answerSelectCards[i]);
                                    int wid = answerSelectCards[i] - 1;
                                 //   cout << "d" << wid << " " << endl;
                                    weight[wid] = addVector(weight[wid],feature );
                                    averageWeight[wid] = addVector(averageWeight[wid], mulVector(feature, round));
                                }
                            }
                            break;
                        } else {
                            //選択正解　正解リストと手札リストから対象カードをのぞき、特徴量を更新してcontinue
                            for(unsigned int i=0;i<answerSelectCards.size();i++) {
                                if(answerSelectCards[i] == gotSelectCard) {
                                    answerSelectCards.erase(answerSelectCards.begin()+i);
                                    break;
                                }
                            }
                            for(unsigned int i=0;i<hand.size();i++) {
                                if(hand[i] == gotSelectCard) {
                                    hand.erase(hand.begin()+i);
                                    break;
                                }
                            }
                            if(learningCardId == CARD_CHAPEL) {
                                //礼拝堂廃棄なので対象カードを手札から削除
                                feature[(KIND_OF_CARD+1) + gotSelectCard]--;
                            }
                            if(learningCardId == CARD_CELLAR) {
                                //ちかちょは、対象カードが手札から捨て札に移り、何枚目かの特徴量をインクリメント
                                feature[(KIND_OF_CARD+1) + gotSelectCard]--;//手札から削除
                                feature[(KIND_OF_CARD+1)*2 + gotSelectCard]++;//捨て札に追加
                                feature[feature.size()-1]++;//何枚目のdiscardか、をインクリメント
                            }
                            continue;
                        }
                    }
                }
            }
        }
     
        
        if(round % roundtest == 0) {
            testWeight.clear();
            for(unsigned int i=0;i<averageWeight.size();i++) {
                testWeight.push_back( addVector(weight[i], mulVector(averageWeight[i], -1.0/(double)round)));
            }
            
            double correct = test(testWeight, teachers,false,learningCardId);
            cout << "round:" << round << "/正解率：" << correct * 100 << "%" << endl;
            writeWeightVector(testWeight,dataDirectory + "weight.txt");
            writeWeightVector(weight,dataDirectory + "w_weight.txt");
            writeWeightVector(averageWeight,dataDirectory + "u_weight.txt");
            writeRound(round,dataDirectory + "round.txt");
            writeRate(correct,dataDirectory + "correctRate.txt");
            if(correct >= 1) {
                break;
            }
        }
    }
    writeWeightVector(testWeight,dataDirectory + "weight.txt");
    test(testWeight, teachers,true,learningCardId);
    
    cout << "number of sample:" << nSample << endl;
    cout << "number of dimension:" << dimensionOfFeature << endl;
    
    
    
    return 0;
}

