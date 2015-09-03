#!/usr/bin/env python
#coding: utf-8

import sys
import re

if __name__ == "__main__":
    argv = sys.argv
    argc = len(argv)
    if argc < 2:
        print "\nformat: python leaderboard_parser.py 'filename'\n"
        sys.exit()

    filename = argv[1]

    try:
        f = open(filename)
    except IOError as e:
        print e.strerror + " '" + filename + "'"
        sys.exit()

    goodplayers = []

    lines = f.readlines()
    for line in lines:
        words = line.rstrip().split("\t")
        if re.search('Level.*',words[0]) == None:
            goodplayers.append(words[-1])
        else:
            if len(words) != 1 and words[1] != "μ":
                goodplayers.append(words[-1])

    print goodplayers
    print "output %d goodPlayers list" % len(goodplayers)

    ff = open("goodPlayers.txt","w")
    for player in goodplayers:
        ff.write(player+"\n")