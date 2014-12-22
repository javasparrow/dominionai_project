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
    Sample(int id,string str);
    void show();
    int getDimensionOfFeature();
    
    vector<double> _feature;
    vector<int> _notZero;
    vector<int> _gain;
    vector<int> _supply;
    vector< vector<int> > _gainlist;
    int _coin;
    int _buy;
    int _sampleid;
    string _filename;
};

#endif /* defined(__parseptron__sample__) */
