//
//  card.cpp
//  parseptron
//
//  Created by Yuki Murakami on 2014/05/22.
//  Copyright (c) 2014年 yuki. All rights reserved.
//

#include "card.h"

#include <unistd.h>

#include <algorithm>

#include <string>
#include <vector>
#include <fstream>



#define CARDDATA_FILENAME "./../../util/cardData.csv"

using namespace std;

string removeReturnSymbol(string s) {
    if(s.c_str()[s.length()-1] == 13) {
        return s.substr(0,s.length()-1);
    }
    return s;
}

string removeCapital(string name) {
    transform(name.begin(), name.end(), name.begin(), ::tolower);
    return name;
}

string removeSpace(string name) {
    vector<string> divString = SpritString(name," ");
    name = "";
    for(unsigned int i=0;i<divString.size();i++) {
        name += divString[i];
    }
    return name;
}



int getCost(int id) {
    int cost = -1;
    if(id == 0) return 1000;
    ifstream ifs(CARDDATA_FILENAME);
    if(!ifs) {
        cout << "error: not found file '" << CARDDATA_FILENAME << "'  @getCost  in card.cpp" << endl;
        exit(0);
    }
    string buf;
    while(getline(ifs,buf)) {
        vector<string> out = SpritString(buf,",");
        int index = atoi(out[0].c_str());
        if(index == id) {
            cost = atoi(out[5].c_str());
            break;
        }
    }
    if(cost < 0 || cost > 999999) {
        cout << "error: cost is not correct @getCost  in card.cpp" << endl;
        exit(0);
    }
    return cost;
}



string getString(int id) {
    string name = "";
    if(id == 0) return "ダ";
    ifstream ifs(CARDDATA_FILENAME);
    if(!ifs) {
        cout << "error: not found file '" << CARDDATA_FILENAME << "'  @getString  in card.cpp" << endl;
        exit(0);
    }
    string buf;
    while(getline(ifs,buf)) {
        vector<string> out = SpritString(buf,",");
        int index = atoi(out[0].c_str());
        if(index == id) {
            name = removeReturnSymbol(out[16]);
            break;
        }
    }
    return name;
}


string getEnglishString(int id) {
    //すべて小文字で統一
    //２語以上はくっつける throne room -> throneroom
    string name = "";
    if(id == 0) return "dummy";
    ifstream ifs(CARDDATA_FILENAME);
    if(!ifs) {
        cout << "error: not found file '" << CARDDATA_FILENAME << "'  @getEnglishString  in card.cpp" << endl;
        exit(0);
    }
    string buf;
    while(getline(ifs,buf)) {
        vector<string> out = SpritString(buf,",");
        int index = atoi(out[0].c_str());
        if(index == id) {
            name = removeReturnSymbol( out[3] );
            name = removeSpace(name);
            name = removeCapital(name);
            break;
        }
    }
    return name;
}

int getIdFromEnglishString(string str) {
    int id = -1;
    if(str == "dummy") return 0;
    if(str == "spy_enemy") return 28+1000;
    if(str == "throne_action") return 14+1000;
    
    ifstream ifs(CARDDATA_FILENAME);
    if(!ifs) {
        cout << "error: not found file '" << CARDDATA_FILENAME << "'  @getIdFromEnglishString  in card.cpp" << endl;
        exit(0);
    }
    string buf;
    while(getline(ifs,buf)) {
        vector<string> out = SpritString(buf,",");
        string name = removeSpace( removeCapital( removeReturnSymbol( out[3] ) ) );
        if(name == str) {
            id = atoi(out[0].c_str());
            break;
        }
    }
    
    if(id <= -1 || id > 32) {
        cout << "error: id is not correct @getIdFromEnglishString  in card.cpp" << endl;
        cout << "id:" << id << endl;
        cout << "str:" << str << endl;
        exit(0);
    }
    cout << str << "," << id << endl;
    return id;
}


bool isEqualGain(vector<int> a,vector<int> b) {
    sort(a.begin(),a.end());
    sort(b.begin(),b.end());
    if(a.size() != b.size()) return false;
    int size = a.size();
    for(int i=0;i<size;i++) {
        if(a[i] != b[i]) {
            return false;
        }
    }
    return true;
}
