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
    
    bool _isDiscard;
};

class cellarSample :public Sample{
public:
    cellarSample(int id,string str);
    void show();
};

class remodelSample :public Sample {
public:
    remodelSample(int id,string str);
    void show();
};

class chancellorSample :public Sample {
public:
    chancellorSample(int id,string str);
    void show();
    
    
};

#endif /* defined(__parseptron__sample__) */
