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
    _hand.clear();
    _answerSelectCards.clear();
    vector<string> out = SpritString(str,"/");
    if(out.size() != 3) {
        cout << "reading teacherData error: not match format '/' " << endl;
        cout << out.size() << endl;
        exit(0);
    }
    for(int i=0;i<3;i++) {
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
}

militiaSample::militiaSample(int id,string str) {
    _sampleid = id;
    //feature/hand/answerSelectCards/filename
    _hand.clear();
    _answerSelectCards.clear();
    vector<string> out = SpritString(str,"/");
    if(out.size() != 4) {
        cout << "reading teacherData error: not match format '/' " << endl;
        cout << out.size() << endl;
        exit(0);
    }
    for(int i=0;i<4;i++) {
        if(i==3) _filename = out[i];
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
}
void militiaSample::show() {
    cout << "militiaLearnData id=" << _sampleid << endl;
    cout << "hand:";
    showGain(_hand);
    cout << "answerSelectCards:";
    showGain(_answerSelectCards);
}

void cellarSample::show() {
    cout << "cellerLearnData id=" << _sampleid << endl;
    cout << "hand:";
    showGain(_hand);
    cout << "answerSelectCards:";
    showGain(_answerSelectCards);
}

spySample::spySample(int id,string str) {
    _sampleid = id;
    //feature/reveal/isDiscard/isMine
    vector<string> out = SpritString(str,"/");
    if(out.size() != 4) {
        cout << "reading teacherData error: not match format '/' " << endl;
        cout << out.size() << endl;
        exit(0);
    }
    for(int i=0;i<4;i++) {
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
                //reveal
                if(out2.size() != 1) {
                    cout << "error: isGainFlag's size != 1" << endl;
                    exit(0);
                }
                _revealCard = atoi(out2[0].c_str());
            }
            if(i==2) {
                //isDiscardFlag
                if(out2.size() != 1) {
                    cout << "error: isGainFlag's size != 1" << endl;
                    exit(0);
                }
                if(atoi(out2[0].c_str()) == 0) {
                    _isDiscard = false;
                } else {
                    _isDiscard = true;
                }
            }
            if(i==3) {
                //isMineFlag
                if(out2.size() != 1) {
                    cout << "error: isMineFlag's size != 1" << endl;
                    exit(0);
                }
                if(atoi(out2[0].c_str()) == 0) {
                    _isMine = false;
                } else {
                    _isMine = true;
                }
            }
        }
    }
}

librarySample::librarySample(int id,string str) {
    _sampleid = id;
    //feature/reveal/isDiscard
    vector<string> out = SpritString(str,"/");
    if(out.size() != 3) {
        cout << "reading teacherData error: not match format '/' " << endl;
        cout << out.size() << endl;
        exit(0);
    }
    for(int i=0;i<3;i++) {
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
                //reveal
                if(out2.size() != 1) {
                    cout << "error: isGainFlag's size != 1" << endl;
                    exit(0);
                }
                _revealCard = atoi(out2[0].c_str());
            }
            if(i==2) {
                //isDiscardFlag
                if(out2.size() != 1) {
                    cout << "error: isGainFlag's size != 1" << endl;
                    exit(0);
                }
                if(atoi(out2[0].c_str()) == 0) {
                    _isDiscard = false;
                } else {
                    _isDiscard = true;
                }
            }
        }
    }
}

thiefSample::thiefSample(int id,string str) {
    _sampleid = id;
    _hand.clear();
    //feature/hand/answerSelectCard
    vector<string> out = SpritString(str,"/");
    if(out.size() != 4) {
        cout << "reading teacherData error: not match format '/' " << endl;
        cout << out.size() << endl;
        exit(0);
    }
    for(int i=0;i<4;i++) {
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
            if(i==3) {
                //isGainFlag
                if(out2.size() != 1) {
                    cout << "error: isGainFlag's size != 1" << endl;
                    exit(0);
                }
                if(atoi(out2[0].c_str()) == 0) {
                    _isDiscard = false;
                } else {
                    _isDiscard = true;
                }
            }
        }
    }
}

throneSample::throneSample(int id,string str) {
    _sampleid = id;
    //feature/hand/isAction2/answerSelectCard/filename
    vector<string> out = SpritString(str,"/");
    if(out.size() != 5) {
        cout << "reading teacherData error: not match format '/' " << endl;
        cout << out.size() << endl;
        exit(0);
    }
    for(int i=0;i<5;i++) {
        if(i==4) _filename = out[i];
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
        if(i==3) {
            //answerSelectCard
            if(out2.size() != 1) {
                cout << "error: size of answerSelectCard != 1" << endl;
                exit(0);
            }
            _answerSelectCard = atoi(out2[0].c_str());
        }
    }
    int action2 = atoi(out[2].c_str());
    if(action2 == 0) {
        _hasAction = false;
    } else {
        _hasAction = true;
    }
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

chancellorSample::chancellorSample(int id,string str) {
    _sampleid = id;
    //feature/isDiscard
    vector<string> out = SpritString(str,"/");
    if(out.size() != 2) {
        cout << "reading teacherData error: not match format '/' " << endl;
        cout << out.size() << endl;
        exit(0);
    }
    for(int i=0;i<2;i++) {
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
            //isDiscard
            if(out2.size() != 1) {
                cout << "error: isDiscardFlag's size != 1" << endl;
                exit(0);
            }
            if(atoi(out2[0].c_str()) == 0) {
                _isDiscard = false;
            } else {
                _isDiscard = true;
            }
        }
    }
}
void chancellorSample::show() {
    cout << "chancellorLearnData id=" << _sampleid << endl;
    cout << "isDiscard:";
    if(_isDiscard) {
        cout << "YES" << endl;
    } else {
        cout << "NO" << endl;
    }
}
