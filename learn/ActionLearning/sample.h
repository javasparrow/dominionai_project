//
//  sample.h
//  parseptron
//
//  Created by Yuki Murakami on 2014/05/21.
//  Copyright (c) 2014年 yuki. All rights reserved.
//

#ifndef __parseptron__sample__
#define __parseptron__sample__

#include <iostream>
#include <vector>

using namespace std;

class Sample {
public:
   // Sample(int id,string str);
    void show();
    int getDimensionOfFeature();
    
    vector<double> _feature;
    vector<int> _notZero;
    vector<int> _hand;
    vector<int> _answerSelectCards;
    int _answerSelectCard;
    int _sampleid;
    int _revealCard;
    string _filename;
    
    bool _isDiscard;
    bool _isGain;
    bool _isMine;
    bool _hasAction;
};

class cellarSample :public Sample{
public:
    cellarSample(int id,string str);
    void show();
};

class militiaSample :public Sample{
public:
    militiaSample(int id,string str);
    void show();
};

class remodelSample :public Sample {
public:
    remodelSample(int id,string str);
    void show();
};

class throneSample :public Sample {
public:
    throneSample(int id,string str);
    //void show();
};

class chancellorSample :public Sample {
public:
    chancellorSample(int id,string str);
    void show();
};

class thiefSample :public Sample {
public:
    thiefSample(int id,string str);
};

class librarySample :public Sample {
public:
    librarySample(int id,string str);
};

class spySample :public Sample {
public:
    spySample(int id,string str);
};

#endif /* defined(__parseptron__sample__) */
