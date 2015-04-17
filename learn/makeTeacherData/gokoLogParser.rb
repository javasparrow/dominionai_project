load(File.expand_path(__FILE__).sub(/[^\/]+$/,'')[0...-1].sub(/[^\/]+$/,'')[0...-1].sub(/[^\/]+$/,'') + "util/cardData.rb")

class GokoLogParser

  DEBUG_PRINT = true

  #action使用に対する特徴料にするかbuyにたい汁物にするか
  MODE_BUY = 1
  MODE_ACTION = 2
  MODE_ACTION_CELLAR = 3
  MODE_ACTION_CHAPEL = 5
  MODE_ACTION_REMODEL = 7
  MODE_ACTION_THRONE = 9
  MODE_ACTION_CHANCELLOR = 10
  MODE_ACTION_MILITIA = 12
  MODE_ACTION_MINE = 14
  MODE_ACTION_THIEF = 16
  MODE_ACTION_LIBRARY = 20
  MODE_ACTION_SPY = 22
  MODE_ACTION_BUREAUCRAT = 24
  #チカチョが使われたフラグなので最初から4を入れては行けない
  #チカチョ学習なら3を指定してください
  #他カードも同様
  MODE_ACTION_CELLAR_ACTIVE = 4
  MODE_ACTION_CHAPEL_ACTIVE = 6
  MODE_ACTION_REMODEL_ACTIVE = 8
  MODE_ACTION_CHANCELLOR_ACTIVE = 11
  MODE_ACTION_MILITIA_ACTIVE = 13
  MODE_ACTION_MINE_ACTIVE = 15
  MODE_ACTION_THIEF_ACTIVE_1 = 17
  MODE_ACTION_THIEF_ACTIVE_2 = 18
  MODE_ACTION_THIEF_ACTIVE_3 = 19
  MODE_ACTION_LIBRARY_ACTIVE = 21
  MODE_ACTION_SPY_ACTIVE = 23

  MODE_ARAI = 25

  PHASE_END = -1
  PHASE_ACTION = 0
  PHASE_BUY = 1
  PHASE_CLEANUP = 2

  MAX_CARDNUM = 33

  FEATURE_LENGTH = 233

  def parse(rawlog, output, featureMode, playerName)
    @canVerify = true

    @fileName = File.basename(rawlog.path)
    @featureMode = featureMode

    @focusPlayerName = playerName


    @playerName = Array.new(2)

    @playerDeck = Array.new(2)
    @playerDeck[0] = Array.new(MAX_CARDNUM, 0)
    @playerDeck[1] = Array.new(MAX_CARDNUM, 0)

    @playerDiscard = Array.new(2)
    @playerDiscard[0] = Array.new(MAX_CARDNUM, 0)
    @playerDiscard[1] = Array.new(MAX_CARDNUM, 0)

    @playerHand = Array.new(2)
    @playerHand[0] = Array.new(MAX_CARDNUM, 0)
    @playerHand[1] = Array.new(MAX_CARDNUM, 0)

    @playerPlay = Array.new(2)
    @playerPlay[0] = Array.new(MAX_CARDNUM, 0)
    @playerPlay[1] = Array.new(MAX_CARDNUM, 0)

    @supplyCnt = Array.new(MAX_CARDNUM, 0)
    @supplyExist = Array.new(MAX_CARDNUM, 0)

    @pastFeature = Array.new(2)
    @pastFeature[0] = Array.new(0)
    @pastFeature[1] = Array.new(0)

    @pastCellarDiscard = Array.new(0)
    @pastCellarFeature = ""

    @pastChapelTrash = Array.new(0)
    @pastChapelFeature = ""

    @pastMilitiaDiscard = Array.new(0)
    @pastMilitiaFeature = ""

    @pastThiefReveal = Array.new(0)
    @pastThiefTrash = nil
    @pastThiefFeature = ""

    #玉座の間処理用
    @throneStack = Array.new(0)

    #generate zero Feature
    3.times{
      tempFeature = ""
      FEATURE_LENGTH.times{
        tempFeature = tempFeature + "0,"
      }
      @pastFeature[0] << tempFeature[0..-2]
      @pastFeature[1] << tempFeature[0..-2]
    }

    @lastPlay = nil
    @lastTrash = nil
    @currentPhase = PHASE_ACTION
    @currentCoin = 0
    @currentBuy = 1
    @currentAction = 1
    @cardData = CardData.new()
    @lastBuy = Array.new(0)
    @currentPlayer = 0

    @currentTurn = 1

    @output = output

    @reveal = Array.new(2)
    @reveal[0] = Array.new(0)
    @reveal[1] = Array.new(0)

    @winner = nil

    @gainHistoryString = Array.new(2)
    @gainHistoryString[0] = ""
    @gainHistoryString[1] = ""
    @trashHistoryString = Array.new(2)
    @trashHistoryString[0] = ""
    @trashHistoryString[1] = ""

    @finalScore = Array.new(2)

    #add pass text to log
    log = addPass(rawlog)

    shuffleflag = false

    log.each{|line|

      if(@featureMode == MODE_ACTION_CELLAR_ACTIVE && !line.include?("discards"))
        generateUseCellarFeature()
        @featureMode = MODE_ACTION_CELLAR
      end
      if(@featureMode == MODE_ACTION_MILITIA_ACTIVE && !line.include?("discards"))
        if(line.include?("reveals reaction Moat"))
          @featureMode = MODE_ACTION_MILITIA
        else
          generateUseMilitiaFeature()
          @featureMode = MODE_ACTION_MILITIA
        end
      end
      if(@featureMode == MODE_ACTION_CHAPEL_ACTIVE && !line.include?("trashes"))
        generateUseChapelFeature()
        @featureMode = MODE_ACTION_CHAPEL
      end
      #改築使ったけど廃棄しなかった場合
      if(@featureMode == MODE_ACTION_REMODEL_ACTIVE && !line.include?("trashes"))
        @featureMode = MODE_ACTION_REMODEL
      end
      #最小使ったけど捨てしなかった場合
      if(@featureMode == MODE_ACTION_CHANCELLOR_ACTIVE && !line.include?("moves deck to discards"))
        generateUseChancellorFeature(false)
        @featureMode = MODE_ACTION_CHANCELLOR
      end
      #鉱山使ったけど廃棄しなかった場合
      if(@featureMode == MODE_ACTION_MINE_ACTIVE && !line.include?("trashes"))
        @featureMode = MODE_ACTION_MINE
      end
      #泥簿yが何らかの理由で中断された場合
      if(@featureMode == MODE_ACTION_THIEF_ACTIVE_1 && !line.include?("reveals") && !line.include?("reshuffle"))
        @featureMode = MODE_ACTION_THIEF
      end
      if(@featureMode == MODE_ACTION_THIEF_ACTIVE_2 && !line.include?("trashes"))
        @featureMode = MODE_ACTION_THIEF
      end
      if(@featureMode == MODE_ACTION_THIEF_ACTIVE_3 && !line.include?("discards") && !line.include?("gains"))
        generateUseThiefFeature(false)
        @featureMode = MODE_ACTION_THIEF
      end
      if(@featureMode == MODE_ACTION_THIEF_ACTIVE_3 && line.include?("gains"))
        generateUseThiefFeature(true)
        @featureMode = MODE_ACTION_THIEF
      end
      #書庫のドローが終わったとき
      #check library
      if(@lastPlay != nil && @lastPlay.name == "Library")
        handCount = 0
        @playerHand[@currentPlayer].each{|num|
          handCount = handCount + num
        }

        emptyflag = true
        @playerDeck[@currentPlayer].each{|num|
          if(num != 0)
            emptyflag = false
            break
          end
        }
        if(emptyflag == true)
          handCount = 7
        end
      end
      if(@featureMode == MODE_ACTION_LIBRARY_ACTIVE && handCount >= 7)
        @featureMode = MODE_ACTION_LIBRARY
      end
      #何故か密偵がキャンセルされたとき
      if(@featureMode == MODE_ACTION_SPY_ACTIVE && !line.include?("discards") && !line.include?("places") && !line.include?("draws"))
        @featureMode = MODE_ACTION_SPY
      end


      if(line.include?("Game Over"))
        currentPhase = PHASE_END
      end

      if(line.include?(" - cards:"))
        verifyResult(line)
      end

      if(currentPhase == PHASE_END)
        next
      end

      if(line.include?("moves deck to discards"))
        moveDeckIntoDiscards(line)
      end

      if(line[0..12] == "Supply cards:")
        parseSupply(line[13..-1])
      end

      if(line.index("starting cards:") != nil)
        if(parseStartingDeck(line) == "error")
          puts "error this is not 2 player game"
          break
        end
      end

      if(line.index("pass") !=  nil)
        cleanup(nil)
        if(haveActionInHand() && @currentAction >= 1)
          generatePlayActionData(nil)
        end
        generateGroundData(nil, @currentCoin, @currentBuy)
      end

      if(line.include?("reveals"))
        parseReveal(line)
      end

      if(line.include?("on top of deck"))
        parsePlaceTop(line)
      end

      if(line.include?("places cards in hand"))
        parsePutCardInHand(line)
      end

      if(line.include?("moves"))
        parseMoveCardInHand(line)
      end

      if(line.index("turn") != nil && line.index("----------") != nil)
        if(line[11..line.index(":") - 1] == @playerName[1])
          @currentPlayer = 1
        elsif (line[11..line.index(":")- 1] == @playerName[0])
          @currentPlayer = 0
        elsif
          puts "error!"
        end
        @currentTurn = @currentTurn + 1
        if(DEBUG_PRINT)
          puts("Turn#{@currentTurn / 2}")
        end
        @currentCoin = 0
        @currentBuy = 1
        @currentAction = 1
        @lastPlay = nil
        @lastTrash = nil
        @currentPhase = PHASE_ACTION
        @lastBuy = Array.new(0)

        @gainHistory
      end

      if(line.index("plays") != nil)
        if(/\d/.match(line[getLastIndex(line, "-") .. -2]) != nil)
          if(haveActionInHand() && @currentAction >= 1)
            generatePlayActionData(nil)
          end
          parsePlayTreasure(line)
        else parsePlayAction(line)
        end
      end

      if(line.index("buys") != nil)
        @currentPhase = PHASE_BUY
      end

      if(line.index("gains") != nil)
        if(@currentPhase == PHASE_BUY)
          parseBuy(line)
        else parseGain(line)
        end
      end

      if(line.index("trashes") != nil)
        parseTrash(line)
      end

      if(line.index("draws") != nil)
        #detect cleanup
        if(@currentPhase == PHASE_BUY)

          @currentPhase = PHASE_CLEANUP

          #generate ground data here
          generateGroundData(@lastBuy, @currentCoin, @currentBuy)

          #execute last buy
          executeBuy()

          #cleanup
          cleanup(line)

          #UpdateHistory
          if(@trashHistoryString[@currentPlayer][-1] == ",")
            @trashHistoryString[@currentPlayer] = @trashHistoryString[@currentPlayer][0...-1]
          end
          @trashHistoryString[@currentPlayer] << "/"
          if(@gainHistoryString[@currentPlayer][-1] == ",")
            @gainHistoryString[@currentPlayer] = @gainHistoryString[@currentPlayer][0...-1]
          end
          @gainHistoryString[@currentPlayer] << "/"

          if(shuffleflag == true)
            reshuffle(line)
            shuffleflag = false
          end
        end
        parseDraw(line)
      end

      if(line.index("shuffles") != nil)
        if(DEBUG_PRINT)
          puts "detect shuffle"
        end
        if(@currentPhase == PHASE_BUY)
          shuffleflag = true
        else
          reshuffle(line)
        end
      end

      if(line.index("discards") != nil)
        parseDiscard(line)
      end

      if(line.include?("total victory points"))
        parseScore(line)
      end
      checkMinis
    }

    if(@featureMode == MODE_ARAI && @canVerify == true)
      generateTacticsData
    end

  end

  def checkMinis()

    for player in 0..1
      @playerDeck[player].each{|cardNum|
        if(cardNum < 0)
          puts "deck minus error!"
          raise
        end
      }

      @playerHand[player].each{|cardNum|
        if(cardNum < 0)
          puts "hand minus error!"
          raise
        end
      }
      @playerDiscard[player].each{|cardNum|
        if(cardNum < 0)
          puts "discard minus error!"
          raise
        end
      }
      @playerPlay[player].each{|cardNum|
        if(cardNum < 0)
          puts "play minus error!" + player.to_s
          puts @playerPlay[player]
          raise
        end
      }
    end

    for i in 0...MAX_CARDNUM
      if(@supplyCnt[i] < 0)
        puts "supply minus error!"
        raise
      end
    end
  end

  def verifyResult(data)
    if(@canVerify == false)
      puts "cannot verify because of quit or resign"
      return
    end

    if(data[0..getLastIndex(data, "-") - 2] == @playerName[0])
      currentPlayer = 0
    else currentPlayer = 1
    end
    data[data.index(" - ") + 10 .. -2].split(", ").each{|pair|
      card = @cardData.getCard(pair[pair.index(" ") + 1..-1])
      num = pair.split(" ")[0].to_i
      if(num == (@playerDeck[currentPlayer][card.num] + @playerHand[currentPlayer][card.num] + @playerDiscard[currentPlayer][card.num] + @playerPlay[currentPlayer][card.num]))
        puts "#{card.name} correct"
      else
        puts "#{card.name} incorrect i estimate #{@playerDeck[currentPlayer][card.num] + @playerHand[currentPlayer][card.num] + @playerDiscard[currentPlayer][card.num] + @playerPlay[currentPlayer][card.num]} but it was #{num}"
        raise
      end
    }
  end

  def addPass(rawlog)
    lineCnt = 0
    buyflag = false
    log = rawlog.readlines
    resultlog = Array.new(0)

    sepCnt = 0

    log.each{|line|
      if(line.include?(" - resigned"))
        @canVerify = false
      end
      if(line.include?(" - quit"))
        @canVerify = false
      end
      if(line.include?("1st place"))
        @winner = line[11..-2]
      end
      if(line.include?("---"))
        sepCnt = sepCnt + 1
        if(sepCnt > 2)
          if(buyflag == false)
            drawCnt = 0
            rLineCnt = lineCnt - 1
            drawflag = false
            while drawCnt != 5
              rLineCnt = rLineCnt - 1
              if(DEBUG_PRINT)
                puts log[rLineCnt]
                puts rLineCnt
              end
              if(log[rLineCnt].include?("draws"))
                drawCnt = drawCnt + 1 + log[rLineCnt].count(",")
                drawflag = true
                if(drawCnt > 5)
                  rLineCnt = rLineCnt + 1
                  break
                end
              end
              if(log[rLineCnt].include?("---"))
                drawflag = false
                break
              end
              if(!log[rLineCnt].include?("draws") && !log[rLineCnt].include?("shuffles"))
                if(DEBUG_PRINT)
                  puts rLineCnt
                  puts lineCnt
                  puts resultlog
                end

                rLineCnt = rLineCnt + 1
                drawflag = true
                break
              end
            end
            if(drawflag == true)
              if(resultlog[-(lineCnt - rLineCnt)-1].include?(" - shuffles"))
                resultlog[-(lineCnt - rLineCnt)-1, 0] = "pass"
              else
                resultlog[-(lineCnt - rLineCnt), 0] = "pass"
              end
            end
          end
          buyflag = false
        end
      end
      if(line.include?("buys"))
        buyflag = true
      end
      lineCnt = lineCnt + 1
      resultlog << line
    }

    if(DEBUG_PRINT)
      puts resultlog
    end

    resultlog
  end

  def generateTacticsData()
    result = ""

    for i in 0...MAX_CARDNUM
      if(@supplyExist[i] > 0)
        result << i.to_s + ","
      end
    end
    result = result[0...-1]
    result << "\n"
    result << @gainHistoryString[0]
    result << "\n"
    result << @gainHistoryString[1]
    result << "\n"
    result << @trashHistoryString[0]
    result << "\n"
    result << @trashHistoryString[1]
    result << "\n"
    result << @finalScore[0]
    result << "\n"
    result << @finalScore[1]

    @output.write(result)
  end

  def generateGroundData(gain, coin, buy)
    if(@featureMode != MODE_BUY)
      if(DEBUG_PRINT)
        puts "this is not buy mode"
      end
      return
    end
    if(@focusPlayerName != nil && @playerName[@currentPlayer] != @focusPlayerName)
      if(DEBUG_PRINT)
        puts "#{@playerName[@currentPlayer]} is not #{@focusPlayerName} not focused"
      end
      return
    elsif(@playerName[@currentPlayer] != @winner && @focusPlayerName == nil)
      if(DEBUG_PRINT)
        puts "#{@playerName[@currentPlayer]} is not #{@winner} he is loser"
      end
      return
    end

    if(gain != nil && gain.length == 0)
      return
    end

    feature = generateFeatureString();
    result = @pastFeature[@currentPlayer][-3] + "," + @pastFeature[@currentPlayer][-2] + "," + @pastFeature[@currentPlayer][-1] + "," + feature + "/"
    if(@currentPhase != PHASE_ACTION)
      @pastFeature[@currentPlayer] << feature
    end

    if(gain != nil)
      gain.each{|card|
        result = result + card.num.to_s + ","
      }
      result = result[0..-2] + "/"
    else
      result = result + "/"
    end

    @supplyCnt.each{|cnt|
      result = result + cnt.to_s + ","
    }

    result = result[0..-2] + "/" + coin.to_s + "/" + buy.to_s

    if(DEBUG_PRINT)
      puts result
    end
    @output.write(result + "\n")
  end

  def generateFeatureString()
    result = ""
    @playerDeck[@currentPlayer].each{|cardNum|
      result = result + cardNum.to_s + ","
    }

    @playerHand[@currentPlayer].each{|cardNum|
      result = result + cardNum.to_s + ","
    }
    @playerDiscard[@currentPlayer].each{|cardNum|
      result = result + cardNum.to_s + ","
    }
    @playerPlay[@currentPlayer].each{|cardNum|
      result = result + cardNum.to_s + ","
    }

    #TODO teban
    if(@currentPlayer == 0)
      other = 1
    else other = 0
    end

    for i in 0...MAX_CARDNUM
      result = result + (@playerDeck[other][i] + @playerHand[other][i] + @playerDiscard[other][i] + @playerPlay[other][i]).to_s + ","
    end

    for i in 0...MAX_CARDNUM
      result = result + @supplyCnt[i].to_s + ","
    end

    for i in 0...MAX_CARDNUM
      result = result + @supplyExist[i].to_s + ","
    end

    result = result + (@currentTurn / 2).to_s + ","

    result = result + @currentPlayer.to_s

    result
  end

  def generateOpponentFeatureString()
    if(@currentPlayer == 0)
      other = 1
    else other = 0
    end

    result = ""
    @playerDeck[other].each{|cardNum|
      result = result + cardNum.to_s + ","
    }

    @playerHand[other].each{|cardNum|
      result = result + cardNum.to_s + ","
    }
    @playerDiscard[other].each{|cardNum|
      result = result + cardNum.to_s + ","
    }
    @playerPlay[other].each{|cardNum|
      result = result + cardNum.to_s + ","
    }

    for i in 0...MAX_CARDNUM
      result = result + (@playerDeck[@currentPlayer][i] + @playerHand[@currentPlayer][i] + @playerDiscard[@currentPlayer][i] + @playerPlay[@currentPlayer][i]).to_s + ","
    end

    for i in 0...MAX_CARDNUM
      result = result + @supplyCnt[i].to_s + ","
    end

    for i in 0...MAX_CARDNUM
      result = result + @supplyExist[i].to_s + ","
    end

    result = result + (@currentTurn / 2).to_s + ","

    result = result + other.to_s

    result
  end

  def executeBuy()
    @lastBuy.each{|card|
      @playerDiscard[@currentPlayer][card.num] = @playerDiscard[@currentPlayer][card.num] + 1
      @supplyCnt[card.num] = @supplyCnt[card.num] - 1

      if(DEBUG_PRINT)
        puts "#{@playerName[@currentPlayer]} buy #{card.name}"
      end
    }
  end

  def cleanup(data)
    if(data == nil)
      currentPlayer = @currentPlayer
    else
      if(data[0..getLastIndex(data, "-") - 2] == @playerName[0])
        currentPlayer = 0
      else currentPlayer = 1
      end
    end

    for i in 0...MAX_CARDNUM
      @playerDiscard[currentPlayer][i] = @playerDiscard[currentPlayer][i] + @playerHand[currentPlayer][i] + @playerPlay[currentPlayer][i]
      @playerPlay[currentPlayer][i] = 0
      @playerHand[currentPlayer][i] = 0
    end
    if(DEBUG_PRINT)
      puts "cleanup"
    end
  end

  def moveDeckIntoDiscards(data)
    if(data[0..getLastIndex(data, "-") - 2] == @playerName[0])
      currentPlayer = 0
    else currentPlayer = 1
    end

    if(@featureMode == MODE_ACTION_CHANCELLOR_ACTIVE)
      generateUseChancellorFeature(true)
      @featureMode = MODE_ACTION_CHANCELLOR
    end

    for i in 1 ... MAX_CARDNUM
      @playerDiscard[currentPlayer][i] = @playerDeck[currentPlayer][i] + @playerDiscard[currentPlayer][i]
      @playerDeck[currentPlayer][i] = 0
    end
    if(DEBUG_PRINT)
      puts "doooon"
    end
  end

  def reshuffle(data)
    #adventurer has bug in goko
    #when we use adventurer and it causes reshuffle, the timing of reshuffle of log become strange

    if(@lastPlay != nil && @lastPlay.name == "Adventurer" && @currentPhase == PHASE_ACTION)
      if(DEBUG_PRINT)
        puts "adventurer bug shuffle"
      end
      return
    end

    if(data[0..getLastIndex(data, "-") - 2] == @playerName[0])
      currentPlayer = 0
    else currentPlayer = 1
    end

    for i in 1 ... MAX_CARDNUM
      @playerDeck[currentPlayer][i] = @playerDiscard[currentPlayer][i]
      @playerDiscard[currentPlayer][i] = 0
    end
    if(DEBUG_PRINT)
      puts "reshuffle"
    end
  end

  def parseScore(data)
    if(data[0..getLastIndex(data, "- ") - 2] == @playerName[0])
      currentPlayer = 0
    else currentPlayer = 1
    end

    score = data[getLastIndex(data, " ")..-1].to_i
    @finalScore[currentPlayer] = score.to_s
    puts "score" + currentPlayer.to_s + ":" + score.to_s
  end

  def parseMoveCardInHand(data)
    if(data[0..getLastIndex(data, "-") - 2] == @playerName[0])
      currentPlayer = 0
    else currentPlayer = 1
    end
    if(@lastPlay.name == "Library")
      currentCard = @cardData.getCard(data[data.index("moves") + 6..data.index("to hand") - 2])
      if(@featureMode == MODE_ACTION_LIBRARY_ACTIVE)
        generateUseLibraryFeature(currentCard, true)
      end
      @playerHand[currentPlayer][currentCard.num] = @playerHand[currentPlayer][currentCard.num] + 1
      @playerDeck[currentPlayer][currentCard.num] = @playerDeck[currentPlayer][currentCard.num] - 1
    end
  end

  def parsePutCardInHand(data)
    if(data[0..getLastIndex(data, "-") - 2] == @playerName[0])
      currentPlayer = 0
    else currentPlayer = 1
    end
    if(@lastPlay.name == "Adventurer")
      data[data.index("hand:") + 7..-2].split(", ").each{|card|
        currentCard = @cardData.getCard(card)
        @playerHand[currentPlayer][currentCard.num] = @playerHand[currentPlayer][currentCard.num] + 1
        @reveal[currentPlayer] = Array.new(0)
      }
    end
  end

  def parsePlaceTop(data)
    if(data[0..getLastIndex(data, "-") - 2] == @playerName[0])
      currentPlayer = 0
    else currentPlayer = 1
    end
    if(@lastPlay.name == "Bureaucrat")
      currentCard = @cardData.getCard(data[data.index("places") + 7 .. data.index("on top of deck") - 2])
      if(@featureMode == MODE_ACTION_BUREAUCRAT)
        generateUseBureaucratFeature(currentCard)
      end
      @playerHand[currentPlayer][currentCard.num] = @playerHand[currentPlayer][currentCard.num] - 1
      @playerDeck[currentPlayer][currentCard.num] = @playerDeck[currentPlayer][currentCard.num] + 1
    end

    if(@lastPlay.name == "Spy" && @featureMode == MODE_ACTION_SPY_ACTIVE)
      currentCard = @cardData.getCard(data[data.index("places") + 7 .. data.index("on top of deck") - 2])
      if(@currentPlayer == currentPlayer)
        generateUseSpyFeature(currentCard, false, true)
        else
        generateUseSpyFeature(currentCard, false, false)
      end
    end
  end

  def parseReveal(data)
    if(data[0..getLastIndex(data, "-") - 2] == @playerName[0])
      currentPlayer = 0
    else currentPlayer = 1
    end

    if(data[getLastIndex(data, "-")..-1].include?("reaction"))
      return
    end

    if(@lastPlay.name == "Thief")
      data[data.index("reveals") + 9..-2].split(", ").each{|card|
        currentCard = @cardData.getCard(card)
        @playerDeck[currentPlayer][currentCard.num] = @playerDeck[currentPlayer][currentCard.num] - 1
        @reveal[currentPlayer] << currentCard
        if(@featureMode == MODE_ACTION_THIEF_ACTIVE_1)
          @pastThiefReveal.push(currentCard)
        end
      }
      if(@featureMode == MODE_ACTION_THIEF_ACTIVE_1)
        @featureMode = MODE_ACTION_THIEF_ACTIVE_2
      end
    elsif(@lastPlay.name == "Adventurer")
      data[data.index("reveals") + 8..-2].split(", ").each{|card|
        currentCard = @cardData.getCard(card)

        if(@playerDeck[currentPlayer][currentCard.num] == 0)
          if(DEBUG_PRINT)
            puts "actual reshuffle is here"
          end
          for i in 1 ... MAX_CARDNUM
            @playerDeck[currentPlayer][i] = @playerDiscard[currentPlayer][i]
            @playerDiscard[currentPlayer][i] = 0
          end

        end

        @playerDeck[currentPlayer][currentCard.num] = @playerDeck[currentPlayer][currentCard.num] - 1
        @reveal[currentPlayer] << currentCard
      }
    end

  end

  def parseDiscard(data)
    if(data[0..getLastIndex(data, "-") - 2] == @playerName[0])
      currentPlayer = 0
    else currentPlayer = 1
    end

    handCount = 0

    #check library
    if(@lastPlay.name == "Library")
      @playerHand[currentPlayer].each{|num|
        handCount = handCount + num
      }

      emptyflag = true
      @playerDeck[currentPlayer].each{|num|
        if(num != 0)
          emptyflag = false
          break
        end
      }
      if(emptyflag == true)
        handCount = 7
      end
    end

    data = data.delete(":")
    data[data.index("discards") + 9..-2].split(", ").each{|card|

      currentCard = @cardData.getCard(card)

      if(DEBUG_PRINT)
        puts "#{@playerName[currentPlayer]} discards #{currentCard.name}"
      end

      if(@lastPlay.name == "Thief")
        @reveal[currentPlayer].each{|rCard|
          if(rCard.num == currentCard.num)
            @reveal.delete(rCard)
            break
          end
        }
        @playerDiscard[currentPlayer][currentCard.num] = @playerDiscard[currentPlayer][currentCard.num] + 1
      elsif(@lastPlay.name == "Spy")
        if(@featureMode == MODE_ACTION_SPY_ACTIVE)
          if(@currentPlayer == currentPlayer)
            generateUseSpyFeature(currentCard, true, true)
          else
            generateUseSpyFeature(currentCard, true, false)
          end
        end
        @playerDeck[currentPlayer][currentCard.num] = @playerDeck[currentPlayer][currentCard.num] - 1
        @playerDiscard[currentPlayer][currentCard.num] = @playerDiscard[currentPlayer][currentCard.num] + 1
      elsif(@lastPlay.name == "Adventurer")
        @playerDiscard[currentPlayer][currentCard.num] = @playerDiscard[currentPlayer][currentCard.num] + 1
      elsif(@lastPlay.name == "Library")
        if(handCount >= 7)
          @playerDiscard[currentPlayer][currentCard.num] = @playerDiscard[currentPlayer][currentCard.num] + 1
        else
          if(@featureMode == MODE_ACTION_LIBRARY_ACTIVE)
            generateUseLibraryFeature(currentCard, false)
          end
          @playerDeck[currentPlayer][currentCard.num] = @playerDeck[currentPlayer][currentCard.num] - 1
        end
      else
        @playerHand[currentPlayer][currentCard.num] = @playerHand[currentPlayer][currentCard.num] - 1
        @playerDiscard[currentPlayer][currentCard.num] = @playerDiscard[currentPlayer][currentCard.num] + 1
      end

      #チカチョめも
      if(@featureMode == MODE_ACTION_CELLAR_ACTIVE)
        @pastCellarDiscard.push(currentCard)
      end

      #民兵めも
      if(@featureMode == MODE_ACTION_MILITIA_ACTIVE)
        @pastMilitiaDiscard.push(currentCard)
      end
    }
  end

  def parseDraw(data)
    if(data[0..getLastIndex(data, "-") - 2] == @playerName[0])
      currentPlayer = 0
    else currentPlayer = 1
    end

    data[data.index("draws") + 6..-2].split(", ").each{|card|

      currentCard = @cardData.getCard(card)

      if(DEBUG_PRINT)
        puts "#{@playerName[currentPlayer]} drawes #{currentCard.name}"
      end

      @playerDeck[currentPlayer][currentCard.num] = @playerDeck[currentPlayer][currentCard.num] - 1
      @playerHand[currentPlayer][currentCard.num] = @playerHand[currentPlayer][currentCard.num] + 1

    }
  end

  def parseTrash(data)
    if(data[0..getLastIndex(data, "-") - 2] == @playerName[0])
      currentPlayer = 0
    else currentPlayer = 1
    end

    data[data.index("trashes") + 8..-2].split(", ").each{|card|

      currentCard = @cardData.getCard(card)

      @trashHistoryString[currentPlayer] << (currentCard.num.to_s + ",")

      if(@featureMode == MODE_ACTION_REMODEL_ACTIVE)
        generateUseRemodelFeature(currentCard)
        @featureMode = MODE_ACTION_REMODEL
      end
      if(@featureMode == MODE_ACTION_MINE_ACTIVE)
        generateUseMineFeature(currentCard)
        @featureMode = MODE_ACTION_MINE
      end

      if(@lastPlay.name == "Moneylender" && currentCard.name == "Copper")
        @currentCoin = @currentCoin + 3
        if(DEBUG_PRINT)
          puts "Moneylender generates 3coins"
        end
      end

      if(DEBUG_PRINT)
        puts "#{@playerName[currentPlayer]} trashes #{currentCard.name}"
      end

      if(currentCard.name == "Feast" && @lastPlay.name == "Feast")
        @playerPlay[currentPlayer][currentCard.num] = @playerPlay[currentPlayer][currentCard.num] - 1
      elsif(@lastPlay.name == "Thief")
        if(@featureMode == MODE_ACTION_THIEF_ACTIVE_2)
          @pastThiefTrash = currentCard
          @featureMode = MODE_ACTION_THIEF_ACTIVE_3
        end
        @reveal[currentPlayer].each{|rCard|
          if(rCard.num == currentCard.num)
            @reveal.delete(rCard)
            break
          end
        }
      else
        @playerHand[currentPlayer][currentCard.num] = @playerHand[currentPlayer][currentCard.num] - 1
      end

      @lastTrash = currentCard

      #チカチョめも
      if(@featureMode == MODE_ACTION_CHAPEL_ACTIVE)
        @pastChapelTrash.push(currentCard)
      end
    }
  end

  def parseBuy(data)
    if(data[0..getLastIndex(data, "-") - 2] == @playerName[0])
      currentPlayer = 0
    else currentPlayer = 1
    end
    gainCard = @cardData.getCard(data[data.index("gains") + 6 .. -2])

    @gainHistoryString[currentPlayer] << (gainCard.num.to_s + ",")
    @lastBuy << gainCard

    if(DEBUG_PRINT)
      puts "#{@playerName[currentPlayer]} buys #{gainCard.name} coin is #{@currentCoin} buy is #{@currentBuy}"
    end

  end

  def parseGain(data)
    if(data[0..getLastIndex(data, "-") - 2] == @playerName[0])
      currentPlayer = 0
    else currentPlayer = 1
    end
    gainCard = @cardData.getCard(data[data.index("gains") + 6 .. -2])

    @gainHistoryString[currentPlayer] << (gainCard.num.to_s + ",")

    if(@lastPlay.name == "Feast")
      generateGroundData(Array.new(1, gainCard), 5, 1)
    elsif(@lastPlay.name == "Remodel")
      generateGroundData(Array.new(1, gainCard), @lastTrash.cost + 2, 1)
    elsif(@lastPlay.name == "Workshop")
      generateGroundData(Array.new(1, gainCard), 4, 1)
    end

    if(@lastPlay.name == "Mine")
      @playerHand[currentPlayer][gainCard.num] = @playerHand[currentPlayer][gainCard.num] + 1
      @supplyCnt[gainCard.num] = @supplyCnt[gainCard.num] - 1
    elsif(@lastPlay.name == "Bureaucrat")
      @playerDeck[currentPlayer][gainCard.num] = @playerDeck[currentPlayer][gainCard.num] + 1
      @supplyCnt[gainCard.num] = @supplyCnt[gainCard.num] - 1
    else
      @playerDiscard[currentPlayer][gainCard.num] = @playerDiscard[currentPlayer][gainCard.num] + 1
      @supplyCnt[gainCard.num] = @supplyCnt[gainCard.num] - 1
    end
    if(DEBUG_PRINT)
      puts "#{@playerName[currentPlayer]} gains #{gainCard.name}"
    end
  end

  def parsePlayTreasure(data)
    if(data[0..getLastIndex(data, "-") - 2] == @playerName[0])
      currentPlayer = 0
    else currentPlayer = 1
    end

    @currentPhase = PHASE_BUY

    playList = data[data.index("plays") + 6 .. -2].split(", ")

    playList.each{|playCard|

      currentCard = @cardData.getCard(playCard[2..-1])

      if(DEBUG_PRINT)
        puts "#{@playerName[currentPlayer]} uses #{playCard[2..-1]} num is #{playCard[0]}"
      end
      @currentCoin = @currentCoin + currentCard.coin * playCard[0].to_i
      if(DEBUG_PRINT)
        puts "gain #{currentCard.coin * playCard[0].to_i} coins"
      end
      @currentBuy = @currentBuy + currentCard.buy * playCard[0].to_i
      if(DEBUG_PRINT)
        puts "gain #{currentCard.buy * playCard[0].to_i} buy"
      end

      @playerHand[currentPlayer][currentCard.num] = @playerHand[currentPlayer][currentCard.num] - 1
      @playerPlay[currentPlayer][currentCard.num] = @playerPlay[currentPlayer][currentCard.num] + 1

    }

  end

  def generatePlayActionData(card)
    if(@featureMode != MODE_ACTION)
      if(DEBUG_PRINT)
        puts "this is not action mode"
      end
      return
    end

    if(@focusPlayerName != nil && @playerName[@currentPlayer] != @focusPlayerName)
      if(DEBUG_PRINT)
        puts "#{@playerName[@currentPlayer]} is not #{@focusPlayerName} not focused"
      end
      return
    end

    feature = generateFeatureString();

    handString = generateCurrentPlayerHandStringNoAction()

    if(card == nil)
      cardString = "0"
      realAction = @currentAction
    else
      cardString = card.num.to_s
      realAction = @currentAction - card.action
    end

    resultString = feature + "/" + realAction.to_s + "/" + handString + "/" + cardString + "/" + @fileName

    if(DEBUG_PRINT)
      puts resultString
    end
    @output.write(resultString + "\n")
  end

  def generateUseBureaucratFeature(card)

    resultString = generateOpponentFeatureString() + "/" + generateOpponentPlayerHandStringOnlyVictory() + "/" + card.num.to_s

    if(DEBUG_PRINT)
      puts resultString
    end
    @output.write(resultString + "\n")
  end

  def generateUseSpyFeature(card, discardFlag, selfFlag)

    if(discardFlag)
      answer = "1"
    else
      answer = "0"
    end

    if(selfFlag)
      selfString = "1"
    else
      selfString = "0"
    end
    resultString = generateFeatureString() + "/" + card.num.to_s + "/" + answer + "/" + selfString

    if(DEBUG_PRINT)
      puts resultString
    end
    @output.write(resultString + "\n")
  end

  def generateUseLibraryFeature(card, drawflag)
    if(@focusPlayerName != nil && @playerName[@currentPlayer] != @focusPlayerName)
      puts "#{@playerName[@currentPlayer]} is not #{@focusPlayerName} not focused"
      return
    end

    if(drawflag)
      answer = "1"
    else
      answer = "0"
    end

    resultString = generateFeatureString() + "/" + card.num.to_s + "/" + answer

    if(DEBUG_PRINT)
      puts resultString
    end
    @output.write(resultString + "\n")
  end

  def generateUseThiefFeature(gain)
    if(@focusPlayerName != nil && @playerName[@currentPlayer] != @focusPlayerName)
      puts "#{@playerName[@currentPlayer]} is not #{@focusPlayerName} not focused"
      return
    end

    discardString = ""
    @pastThiefReveal.each{|card|
      if(card.isTreasure)
        discardString = discardString + card.num.to_s + ","
      end
    }
    discardString = discardString[0...-1]

    trashString = @pastThiefTrash.num.to_s

    if(gain)
      gainString = "1"
    else
      gainString = "0"
    end

    resultString = @pastThiefFeature + "/" + discardString + "/" + trashString + "/" + gainString

    if(DEBUG_PRINT)
      puts resultString
    end
    @output.write(resultString + "\n")
  end

  def generateUseMineFeature(card)
    if(@focusPlayerName != nil && @playerName[@currentPlayer] != @focusPlayerName)
      puts "#{@playerName[@currentPlayer]} is not #{@focusPlayerName} not focused"
      return
    end

    resultString = generateFeatureString() + "/" + generateCurrentPlayerHandStringOnlyTreasyre() + "/" + card.num.to_s

    if(DEBUG_PRINT)
      puts resultString
    end
    @output.write(resultString + "\n")
  end

  def generateUseMilitiaFeature()

    if(@focusPlayerName != nil && @playerName[@currentPlayer] != @focusPlayerName)
      puts "#{@playerName[@currentPlayer]} is not #{@focusPlayerName} not focused"
      return
    end

    cardString = ""
    @pastMilitiaDiscard.each{|card|
      cardString = cardString + card.num.to_s + ","
    }
    cardString = cardString[0...-1]

    resultString = @pastMilitiaFeature + "/" + cardString + "/" + @fileName

    if(DEBUG_PRINT)
      puts resultString
    end
    @output.write(resultString + "\n")
  end

  def generateUseCellarFeature()

    if(@focusPlayerName != nil && @playerName[@currentPlayer] != @focusPlayerName)
      puts "#{@playerName[@currentPlayer]} is not #{@focusPlayerName} not focused"
      return
    end

    cardString = ""
    @pastCellarDiscard.each{|card|
      cardString = cardString + card.num.to_s + ","
    }
    cardString = cardString[0...-1]

    resultString = @pastCellarFeature + "/" + cardString

    if(DEBUG_PRINT)
      puts resultString
    end
    @output.write(resultString + "\n")
  end

  def generateUseChapelFeature()

    if(@focusPlayerName != nil && @playerName[@currentPlayer] != @focusPlayerName)
      if(DEBUG_PRINT)
        puts "#{@playerName[@currentPlayer]} is not #{@focusPlayerName} not focused"
      end
      return
    end

    cardString = ""
    @pastChapelTrash.each{|card|
      cardString = cardString + card.num.to_s + ","
    }
    cardString = cardString[0...-1]

    resultString = @pastChapelFeature + "/" + cardString

    if(DEBUG_PRINT)
      puts resultString
    end
    @output.write(resultString + "\n")
  end

  def generateUseRemodelFeature(card)
    if(@focusPlayerName != nil && @playerName[@currentPlayer] != @focusPlayerName)
      if(DEBUG_PRINT)
        puts "#{@playerName[@currentPlayer]} is not #{@focusPlayerName} not focused"
      end
      return
    end

    resultString = generateFeatureString() + "/" + generateCurrentPlayerHandString() + "/" + card.num.to_s

    if(DEBUG_PRINT)
      puts resultString
    end
    @output.write(resultString + "\n")
  end

  def generateUseThroneFeature(card)
    if(@focusPlayerName != nil && @playerName[@currentPlayer] != @focusPlayerName)
      if(DEBUG_PRINT)
        puts "#{@playerName[@currentPlayer]} is not #{@focusPlayerName} not focused"
      end
      return
    end

    if(@throneStack.include?(14) || (@currentAction - card.action) >= 1)
      active = 1
    else
      active = 0
    end

    resultString = generateFeatureString() + "/" + generateCurrentPlayerHandStringNoAction() + "/" + active.to_s +  "/" + card.num.to_s + "/" + @fileName

    if(DEBUG_PRINT)
      puts resultString
    end
    @output.write(resultString + "\n")
  end

  def generateUseChancellorFeature(used)
    if(used)
      ans = "1"
    else
      ans = "0"
    end

    if(@focusPlayerName != nil && @playerName[@currentPlayer] != @focusPlayerName)
      if(DEBUG_PRINT)
        puts "#{@playerName[@currentPlayer]} is not #{@focusPlayerName} not focused"
      end
      return
    end

    resultString = generateFeatureString() + "/" + ans

    if(DEBUG_PRINT)
      puts resultString
    end
    @output.write(resultString + "\n")
  end

  def parsePlayAction(data)
    if(data[0..getLastIndex(data, "-") - 2] == @playerName[0])
      currentPlayer = 0
    else currentPlayer = 1
    end

    pCard = @cardData.getCard(data[data.index("plays") + 6 .. -2])

    if(!pCard.isAction)
      if(DEBUG_PRINT)
        puts "this is treasure!"
      end
      parsePlayTreasure(data.gsub(pCard.name, "1 " + pCard.name))
      return
    end

    if(DEBUG_PRINT)
      puts "#{@playerName[currentPlayer]} uses action #{data[data.index("plays") + 6 .. -2]}"
    end
    @currentCoin = @currentCoin + pCard.coin
    if(DEBUG_PRINT)
      puts "gain #{pCard.coin} coins"
    end
    @currentBuy = @currentBuy + pCard.buy
    if(DEBUG_PRINT)
      puts "gain #{pCard.buy} buy"
    end
    @currentAction = @currentAction + pCard.action


    if(@lastPlay != nil && @lastPlay.name == "Throne Room")
      if(@featureMode == MODE_ACTION_THRONE)
        generateUseThroneFeature(pCard)
      end
      @playerHand[currentPlayer][pCard.num] = @playerHand[currentPlayer][pCard.num] - 1
      @playerPlay[currentPlayer][pCard.num] = @playerPlay[currentPlayer][pCard.num] + 1
      @throneStack.push(pCard.num)
    end

    if(@lastPlay == nil || @lastPlay.name != "Throne Room")
      #玉座二回目
      if(@throneStack.include?(pCard.num))
        @throneStack.delete_at(@throneStack.find_index(pCard.num))
        #玉座祝宴の特殊処理
        if(pCard.name == "Feast")
          @playerPlay[currentPlayer][pCard.num] = @playerPlay[currentPlayer][pCard.num] + 1
        end
      else
        generatePlayActionData(pCard)
        @currentAction = @currentAction - 1
        if(@currentAction < 0)
          puts "action minus error"
          raise
        end
        @playerHand[currentPlayer][pCard.num] = @playerHand[currentPlayer][pCard.num] - 1
        @playerPlay[currentPlayer][pCard.num] = @playerPlay[currentPlayer][pCard.num] + 1
      end
    end

    @lastPlay = pCard

    if(pCard.name == "Throne Room")
      if(haveActionInHand() == false)
        @lastPlay = nil
        if(DEBUG_PRINT)
          puts "uses throne but have no action"
        end
      end
    end

    #アクションしようログ生成
    if(@featureMode == MODE_ACTION_CELLAR && pCard.name == "Cellar")
      @featureMode = MODE_ACTION_CELLAR_ACTIVE
      @pastCellarDiscard.clear()
      feature = generateFeatureString();
      @pastCellarFeature = feature + "/" + generateCurrentPlayerHandString()
    end
    if(@featureMode == MODE_ACTION_MILITIA && pCard.name == "Militia")
      @featureMode = MODE_ACTION_MILITIA_ACTIVE
      @pastMilitiaDiscard.clear()
      feature = generateOpponentFeatureString();
      @pastMilitiaFeature = feature + "/" + generateOpponentPlayerHandString()
    end
    if(@featureMode == MODE_ACTION_CHAPEL && pCard.name == "Chapel")
      @featureMode = MODE_ACTION_CHAPEL_ACTIVE
      @pastChapelTrash.clear()
      feature = generateFeatureString();
      @pastChapelFeature = feature + "/" + generateCurrentPlayerHandString()
    end
    if(@featureMode == MODE_ACTION_REMODEL && pCard.name == "Remodel")
      @featureMode = MODE_ACTION_REMODEL_ACTIVE
    end
    if(@featureMode == MODE_ACTION_CHANCELLOR && pCard.name == "Chancellor")
      @featureMode = MODE_ACTION_CHANCELLOR_ACTIVE
    end
    if(@featureMode == MODE_ACTION_MINE && pCard.name == "Mine")
      @featureMode = MODE_ACTION_MINE_ACTIVE
    end
    if(@featureMode == MODE_ACTION_THIEF && pCard.name == "Thief")
      @featureMode = MODE_ACTION_THIEF_ACTIVE_1
      @pastThiefReveal.clear()
      @pastThiefFeature = generateFeatureString();
    end
    if(@featureMode == MODE_ACTION_LIBRARY && pCard.name == "Library")
      @featureMode = MODE_ACTION_LIBRARY_ACTIVE
    end
    if(@featureMode == MODE_ACTION_SPY && pCard.name == "Spy")
      @featureMode = MODE_ACTION_SPY_ACTIVE
    end
  end

  def generateCurrentPlayerHandStringNoAction()
    handString = ""
    for i in 1...MAX_CARDNUM
      if(!@cardData.getCardByNum(i).isAction)
        next
      end
      for n in 0...@playerHand[@currentPlayer][i]
        handString = handString + i.to_s + ","
      end
    end
    handString = handString[0...-1]

    handString
  end

  def generateCurrentPlayerHandStringOnlyTreasyre()
    handString = ""
    for i in 1...MAX_CARDNUM
      if(!@cardData.getCardByNum(i).isTreasure)
        next
      end
      for n in 0...@playerHand[@currentPlayer][i]
        handString = handString + i.to_s + ","
      end
    end
    handString = handString[0...-1]

    handString
  end

  def generateCurrentPlayerHandString()
    handString = ""
    for i in 0...MAX_CARDNUM
      for n in 0...@playerHand[@currentPlayer][i]
        handString = handString + i.to_s + ","
      end
    end
    handString = handString[0...-1]

    handString
  end

  def generateOpponentPlayerHandString()
    if(@currentPlayer == 0)
      player = 1
    else
      player = 0
    end
    handString = ""
    for i in 0...MAX_CARDNUM
      for n in 0...@playerHand[player][i]
        handString = handString + i.to_s + ","
      end
    end
    handString = handString[0...-1]

    handString
  end

  def generateOpponentPlayerHandStringOnlyVictory()
    if(@currentPlayer == 0)
      player = 1
    else
      player = 0
    end
    handString = ""
    for i in 1...MAX_CARDNUM
      if(!@cardData.getCardByNum(i).isVictory)
        next
      end
      for n in 0...@playerHand[player][i]
        handString = handString + i.to_s + ","
      end
    end
    handString = handString[0...-1]

    handString
  end

  def haveActionInHand()
    for i in 0...MAX_CARDNUM
      if(@playerHand[@currentPlayer][i] > 0 && @cardData.getCardByNum(i).isAction)
        return true
      end
    end
    return false
  end

  def parseStartingDeck(data)
    if(@playerName[0] == nil)
      plNum = 0
    elsif(@playerName[1] == nil)
      plNum = 1
    else
      return "error"
    end

    @playerName[plNum] = data[0..getLastIndex(data, "-") - 2]

    data[data.index(":") + 2..-2].split(", ").each{|card|
      currentCard = @cardData.getCard(card)

      @playerDiscard[plNum][currentCard.num] = @playerDiscard[plNum][currentCard.num] + 1
    }
  end

  def parseSupply(data)
    data[1..-2].split(", ").each{|card|
      supCard = @cardData.getCard(card)
      @supplyCnt[supCard.num] = supCard.pilenum
      @supplyExist[supCard.num] = 1
    }
  end

  def getLastIndex(str, target)
    #で地上げ対応
    if(str.include?(" place:"))
      return nil
    end
    pos = -1
    while(true)
      if(str.index(target, pos + 1) != nil)
        pos = str.index(target, pos + 1)
      else
        return pos
      end
    end
  end

end

