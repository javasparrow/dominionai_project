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

using namespace std;

int getCost(int id) {
    switch(id) {
        case CARD_COPPER: return 0;
        case CARD_SILVER: return 3;
        case CARD_GOLD: return 6;
        case CARD_ESTATE: return 2;
        case CARD_DUCHY: return 5;
        case CARD_PROVINCE: return 8;
        case CARD_CURSE: return 0;
            
        case CARD_CELLAR: return 2;
        case CARD_MOAT: return 2;
        case CARD_CHAPEL: return 2;
        case CARD_VILLAGE: return 3;
        case CARD_WOODCUTTER: return 3;
        case CARD_WORKSHOP: return 3;
        case CARD_CHANCELLOR: return 3;
        case CARD_GARDENS: return 4;
        case CARD_SPY: return 4;
        case CARD_THIEF: return 4;
        case CARD_THRONEROOM: return 4;
        case CARD_BUREAUCRAT: return 4;
        case CARD_REMODEL: return 4;
        case CARD_FEAST: return 4;
        case CARD_MILITIA: return 4;
        case CARD_FESTIVAL: return 5;
        case CARD_LIBRARY: return 5;
        case CARD_LABORATRY: return 5;
        case CARD_COUNCILROOM: return 5;
        case CARD_MARKET: return 5;
        case CARD_MINE: return 5;
        case CARD_WITCH: return 5;
        case CARD_MONEYLENDER: return 4;
        case CARD_SMITHY: return 4;
        case CARD_ADVENTURE: return 6;
    }
    return 1000;
}

string getString(int id) {
    switch(id) {
        case CARD_DUMMY: return "  ";
        case CARD_COPPER: return "銅";
        case CARD_SILVER: return "銀";
        case CARD_GOLD: return "金";
        case CARD_ESTATE: return "屋";
        case CARD_DUCHY: return "領";
        case CARD_PROVINCE: return "属";
        case CARD_CURSE: return "呪";
            
        case CARD_CELLAR: return "貯";
        case CARD_MOAT: return "堀";
        case CARD_CHAPEL: return "礼";
        case CARD_VILLAGE: return "村";
        case CARD_WOODCUTTER: return "木";
        case CARD_WORKSHOP: return "工";
        case CARD_CHANCELLOR: return "宰";
        case CARD_GARDENS: return "庭";
        case CARD_SPY: return "密";
        case CARD_THIEF: return "泥";
        case CARD_THRONEROOM: return "玉";
        case CARD_BUREAUCRAT: return "役";
        case CARD_REMODEL: return "改";
        case CARD_FEAST: return "宴";
        case CARD_MILITIA: return "民";
        case CARD_FESTIVAL: return "祝";
        case CARD_LIBRARY: return "書";
        case CARD_LABORATRY: return "研";
        case CARD_COUNCILROOM: return "議";
        case CARD_MARKET: return "市";
        case CARD_MINE: return "鉱";
        case CARD_WITCH: return "魔";
        case CARD_MONEYLENDER: return "貸";
        case CARD_SMITHY: return "鍛";
        case CARD_ADVENTURE: return "冒";
    }
    return "";
}

string getEnglishString(int id) {
    switch(id) {
        case CARD_DUMMY: return "  ";
        case CARD_COPPER: return "copper";
        case CARD_SILVER: return "silver";
        case CARD_GOLD: return "gold";
        case CARD_ESTATE: return "estate";
        case CARD_DUCHY: return "dutch";
        case CARD_PROVINCE: return "province";
        case CARD_CURSE: return "curse";
            
        case CARD_CELLAR: return "cellar";
        case CARD_MOAT: return "moat";
        case CARD_CHAPEL: return "chapel";
        case CARD_VILLAGE: return "village";
        case CARD_WOODCUTTER: return "woodcutter";
        case CARD_WORKSHOP: return "workshop";
        case CARD_CHANCELLOR: return "chancellor";
        case CARD_GARDENS: return "gardens";
        case CARD_SPY: return "spy";
        case CARD_THIEF: return "thief";
        case CARD_THRONEROOM: return "throneroom";
        case CARD_BUREAUCRAT: return "bureaucrat";
        case CARD_REMODEL: return "remodel";
        case CARD_FEAST: return "feast";
        case CARD_MILITIA: return "militia";
        case CARD_FESTIVAL: return "festival";
        case CARD_LIBRARY: return "library";
        case CARD_LABORATRY: return "laboratry";
        case CARD_COUNCILROOM: return "councilroom";
        case CARD_MARKET: return "market";
        case CARD_MINE: return "mine";
        case CARD_WITCH: return "witch";
        case CARD_MONEYLENDER: return "moneylender";
        case CARD_SMITHY: return "smithy";
        case CARD_ADVENTURE: return "adventure";
    }
    return "";
}

vector< vector<int> >getGainList(int coin,int buy,vector<int>supply) {
    vector< vector<int> > gainList;
    vector<int> pass;
    pass.push_back(CARD_DUMMY);
    gainList.push_back(pass);
    vector<int> tmp;
    
    for(int j=1;j<=buy;j++) {
        int size = supply.size();
        for(int i=0;i<size;i++) {
            if(supply[i] <= 0) continue;
            int cardid = i+1;
            if(getCost(cardid) == 0) continue;
            if(getCost(cardid) <= coin) {
                supply[i]--;
                makeList(coin - getCost(cardid),j - 1,cardid,tmp,&gainList,supply);
                supply[i]++;
            }
        }
    }
    return gainList;
}

void makeList(int coin,int buy,int id,vector<int>tmp,vector< vector<int> >*gainlist,vector<int>supply) {
    tmp.push_back(id);
    if(buy <= 0 ) {
        gainlist->push_back(tmp);
        return;
    }
    int sSize = supply.size();
    for(int i=0;i<sSize;i++) {
        if(supply[i] <= 0) continue;
        int cardid = i+1;
        if(getCost(cardid) == 0) continue;
        if(getCost(cardid) <= coin) {
            supply[i]--;
            makeList(coin - getCost(cardid),buy - 1,cardid,tmp,gainlist,supply);
            supply[i]++;
        }
    }
}

void showGainList(vector< vector<int> >gainList) {
    int size = gainList.size();
    for(int i=0;i<size;i++) {
        showGain(gainList[i]);
    }
    cout << "組み合わせ：" << gainList.size() << "通り" << endl;
}

void showGain(vector<int> gain) {
    sort(gain.begin(),gain.end());
    cout << "(";
    int size = gain.size();
    for(int i=0;i<size;i++) {
        cout << getString(gain[i]);
        if(i == size-1) {
            cout << ")" << endl;
        } else {
            cout << ",";
        }
    }
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