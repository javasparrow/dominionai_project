#!/usr/bin/env python
#coding: utf-8

import sys
import re
import os
import os.path


def isAppropriateFile(filename,constraints,cardlist):#resignは無条件でのぞく
    filterBool = True

    if filename[-4:] != ".txt":return False
    f = open(filename)
    lines = f.readlines()
        
    #print filename
        
    supply = []
    players = []
    points = {}
    turns = {}
    winner = []
    resign = 0
    rating = "none"
        
    for line in lines:
        if filterBool == False: break
        if("supply cards:" in line) or ("Supply cards:" in line):
            supply = [m[1:].rstrip() for m in line.split(":")[1].split(",")]
                
            cardflag = True
            if "cardlist" in constraints.keys():
                for s in supply:
                    #print s
                    if (s in cardlist)==False:
                        cardflag = False
                        break
                if cardflag == False:
                    filterBool = False
            
        if("Rating system:" in line):
            rating = line.split(":")[1][1:].rstrip()
            
            if "rating" in constraints.keys():
                if (rating in constraints["rating"])==False:
                    filterBool = False
        if(re.search(".* - starting cards:",line) != None):
            players.append(re.search(".* -",line).group()[0:-2].rstrip())
                
            if "rating" in constraints.keys():
                if (rating in constraints["rating"])==False:
                    filterBool = False
        if(re.search(".* - total victory points",line) != None):
            name = line.split(" - ")[0].rstrip()
            point = int(line.split("total victory points: ")[1])
            points[name] = point
        if(re.search("-* .*: turn",line) != None):
            name = line.split(": turn")[0].split("-")[-1][1:].rstrip()
            turn = int(line.split("turn ")[1].split(" ")[0])
            turns[name] = turn

    
    if filterBool == False:return False
        
    maxPoint = -1000
    minTurn = 1000
    for k,v in points.items():
        if (k in turns.keys()) == False:
            resign = 1
            break
        if maxPoint < v:
            winner = [k]
            maxPoint = v
            minTurn = turns[k]
        else:
            if maxPoint == v:
                if minTurn > turns[k]:
                    winner = [k]
                    minTurn = turns[k]
                else:
                    if minTurn == turns[k]:
                        winner.append(k)
        
        
    #print hit,count
    if resign == 1:return False
    if "player" in constraints.keys():
        if constraints["player"] != len(players):return False

    if "rating" in constraints.keys():
        if (rating in constraints["rating"])==False:return False

    return True


if __name__ == "__main__":
    
    outputFilename = "filteredLogList/base_2player.txt"
    ofs = open(outputFilename,"w")
    #検索条件 (resignは無条件で排除)
    constraints = {"player":2,"cardlist":["useCard0.txt","useCard1.txt"],"rating":["pro"]}
    
    
    count = 0
    hit = 0
    
    cardlist = []
    if "cardlist" in constraints.keys():
        for listfile in constraints["cardlist"]:
            c = open("cardlists/" + listfile)
            cards = [m.rstrip() for m in c.readlines()]
            cardlist.extend(cards)
    #print cardlist

    print "now loading filename list"

    path = "./logs"
    for root, dir, files in os.walk(path):
        for file in files:
            filename = os.path.join(root,file)

            count += 1
            if isAppropriateFile(filename,constraints,cardlist):
                print filename

                ofs.write(filename+"\n")
                hit += 1
                print hit,count

    print hit,count
