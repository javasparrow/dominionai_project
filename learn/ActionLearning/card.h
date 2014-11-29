//
//  card.h
//  parseptron
//
//  Created by Yuki Murakami on 2014/05/22.
//  Copyright (c) 2014年 yuki. All rights reserved.
//

#ifndef __parseptron__card__
#define __parseptron__card__

#include <iostream>
#include <vector>

#define CARD_MAX 32

#define CARD_DUMMY 0

#define CARD_COPPER 1
#define CARD_SILVER 2
#define CARD_GOLD 3
#define CARD_ESTATE 4
#define CARD_DUCHY 5
#define CARD_PROVINCE 6
#define CARD_CURSE 7

#define CARD_MARKET 8
#define CARD_REMODEL 9
#define CARD_SMITHY 10
#define CARD_MONEYLENDER 11
#define CARD_WOODCUTTER 12
#define CARD_COUNCILROOM 13
#define CARD_THRONEROOM 14
#define CARD_LABORATRY 15
#define CARD_MINE 16
#define CARD_WORKSHOP 17
#define CARD_CHANCELLOR 18
#define CARD_FEAST 19
#define CARD_FESTIVAL 20
#define CARD_LIBRARY 21
#define CARD_CELLAR 22
#define CARD_GARDENS 23
#define CARD_THIEF 24
#define CARD_ADVENTURE 25
#define CARD_MOAT 26
#define CARD_WITCH 27
#define CARD_SPY 28
#define CARD_MILITIA 29
#define CARD_VILLAGE 30
#define CARD_BUREAUCRAT 31
#define CARD_CHAPEL 32

using namespace std;

int getCost(int id);
string getString(int id);
string getEnglishString(int id);

vector< vector<int> > getGainList(int coin,int buy,vector<int>supply);

void makeList(int coin,int buy,int id,vector<int>tmp,vector< vector<int> >*gainlist,vector<int>supply);

void showGainList(vector< vector<int> > gainList);
void showGain(vector<int>gain);

bool isEqualGain(vector<int> a,vector<int> b);

#endif /* defined(__parseptron__card__) */
