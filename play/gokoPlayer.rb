load("../util/cardData.rb")
load("gokoRapper.rb")
require "open3"

class GokoPlayer

  DEBUGMODE = false
  DEBUG_PRINT = false

  BOT_NAME = "I am BOT"
  PLAY_PROGRAM = "./a.out play"
  BUY_PROGRAM = "./a.out gain"
  REMODEL_PROGRAM = "./a.out action 9"
  CELLAR_PROGRAM = "./a.out action 22"
  CHAPEL_PROGRAM = "./a.out action 32"
  THRONE_PROGRAM = "./a.out action 14"
  CHANCELLOR_PROGRAM = "./a.out action 18"
  MILITIA_PROGRAM = "./a.out action 29"
  MINE_PROGRAM = "./a.out action 16"
  BUREAUCRAT_PROGRAM = "./a.out action 31"
  THIEF_PROGRAM = "./a.out action 24"
  LIBRARY_PROGRAM = "./a.out action 21"
  SPY_PROGRAM = "./a.out action 28"
  SPY_OPPONENT_PROGRAM = "./a.out action 1028"

  PHASE_END = -1
  PHASE_ACTION = 0
  PHASE_BUY = 1
  PHASE_CLEANUP = 2

  MAX_CARDNUM = 33
  
  FEATURE_LENGTH = 233

  def parse(rawlog, output, outputAction, outputActionSelection, drawlog, autoPlay, ignore)
    puts "execute parse"

    @autoPlay = autoPlay

    @player = 0
    @opponent = 1

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
    @currentHand = Array.new(0)
    @lastBuy = Array.new(0)
    @currentPlayer = 0
    @supplyArray = Array.new(0)

    @currentTurn = 1

    @output = output
    @outputAction = outputAction
    @outputActionSelection = outputActionSelection

    @reveal = Array.new(2)
    @reveal[0] = Array.new(0)
    @reveal[1] = Array.new(0)

    #玉座の間処理用
    @throneStack = Array.new(0)
    
    @drawlog = drawlog
    @rawlog = rawlog

    @lastRevealCard = nil
    @doubleReveal = false

    #add pass text to log
    log = addPass(addDrawInfo(rawlog, drawlog))

    shuffleflag = false

    log.each{|line|
      
      puts "line:" + line

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
        if(@currentPlayer == @player)
          @currentHand = Array.new(0)
        end
        cleanup(nil)
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

      if(line.index("turn") != nil && line.index(": turn") != nil)
        if(line[11..line.index(":") - 1] == @playerName[1])
          @currentPlayer = 1
        elsif (line[11..line.index(":")- 1] == @playerName[0])
          @currentPlayer = 0
        elsif
          puts "error!"
        end
        @currentTurn = @currentTurn + 1
        puts("Turn#{@currentTurn / 2}")
        
        @currentCoin = 0
        @currentBuy = 1
        @currentAction = 1
        @lastPlay = nil
        @lastTrash = nil
        @currentPhase = PHASE_ACTION
        @lastBuy = Array.new(0)
      end

      if(line.index("plays") != nil)
        if(/\d/.match(line[line.index("-") .. -2]) != nil)
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

      #書庫のダミー回避
      if(line.index("draws") != nil && !line.include?("draws and discards"))
        #detect cleanup
        if(@currentPhase == PHASE_BUY)

          @currentPhase = PHASE_CLEANUP
          
          #generate ground data here
          generateGroundData(@lastBuy, @currentCoin, @currentBuy)
          
          #execute last buy
          executeBuy()


          if(@currentPlayer == @player)
            @currentHand = Array.new(0)
          end
          
          #cleanup
          cleanup(line)

          if(shuffleflag == true)
            reshuffle(line)
            shuffleflag = false
          end
        end
        parseDraw(line)
      end

      if(line.index("shuffles") != nil)
        puts "detect shuffle"
        if(@currentPhase == PHASE_BUY)
          shuffleflag = true
        else
          reshuffle(line)
        end
      end

      if(line.index("discards") != nil && !line.include?("draws and discards"))
        parseDiscard(line)
      end

      checkMinis
    }

    #reaction
    if(log.size > 2 && log[-1].include?("plays Militia") && @playerName[@currentPlayer] != BOT_NAME)
      generateMilitiaString()
    elsif(log.size > 2 && log[-2].include?("plays Bureaucrat") && @playerName[@currentPlayer] != BOT_NAME)
      generateBureaucratString()
    end

    if(@playerName[@currentPlayer] != BOT_NAME)
      return
    end

    if(@lastPlay != nil && @lastPlay.name == "Moneylender" && log[-1].include?("plays Moneylender") && @currentHand.include?(1))
      r = GokoRapper.new
      r.pointHand(getGokoHands.size, getGokoHands.index(1))
    elsif(@lastPlay != nil && @lastPlay.name == "Feast" && log[-1].include?("trashes Feast"))
      generateQuestionString(true)
    elsif(@lastPlay != nil && @lastPlay.name == "Workshop" && log[-1].include?("plays Workshop"))
      generateQuestionString(true)
    elsif(@lastPlay != nil && @lastPlay.name == "Remodel" && log[-1].include?("plays Remodel"))
      generateRemodelTrashString()
    elsif(@lastPlay != nil && @lastPlay.name == "Remodel" && log[-1].include?("trashes"))
      generateQuestionString(true)
    elsif(@lastPlay != nil && @lastPlay.name == "Cellar" && log[-1].include?("plays Cellar") && ignore != "Cellar")
      generateCellarString()
    elsif(@lastPlay != nil && @lastPlay.name == "Chapel" && log[-1].include?("plays Chapel") && ignore != "Chapel")
      generateChapelString()
    elsif(@lastPlay != nil && @lastPlay.name == "Throne Room" && log[-1].include?("plays Throne Room"))
      generateThroneString()
    elsif(@lastPlay != nil && @lastPlay.name == "Chancellor" && log[-1].include?("plays Chancellor"))
      generateChancellorString()
    elsif(@lastPlay != nil && @lastPlay.name == "Mine" && log[-1].include?("plays Mine"))
      generateMineString()
    elsif(@lastPlay != nil && @lastPlay.name == "Thief" && log[-1].include?("reveals") && !log[-1].include?("reaction Moat"))
      generateThiefString()
    elsif(@lastPlay != nil && @lastPlay.name == "Library" && @lastRevealCard != nil && @lastRevealCard.isAction)
      generateLibraryString()
    elsif(@lastPlay != nil && @lastPlay.name == "Spy" && @lastRevealCard != nil && (!log[-1].include?(@playerName[@opponent]) || log[-1].include?("shuffles deck")))
      generateSpyString()
    elsif(haveActionInHand() && @currentPhase == PHASE_ACTION && @currentAction != 0)
      generatePlayActionData()
    elsif(@currentPhase == PHASE_BUY || ((!haveActionInHand() || @currentAction == 0) && !haveTreasureInHand()))
      if(log[-1].include?("buys") || log[-2].include?("buys"))
        return
      end
      generateQuestionString(false)
    elsif((!haveActionInHand || @currentAction == 0) && haveTreasureInHand)
      r = GokoRapper.new
      r.pointLowerButton
    end

    #rescue => ex
      #puts ex.message
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

  def generateSpyString()
    resultString = generateFeatureString() + "/" + @lastRevealCard.num.to_s
    puts resultString
    @outputActionSelection.write(resultString + "\n")

    if(!@autoPlay)
      return
    end

    if(@doubleReveal)
      out, err, status = Open3.capture3(SPY_OPPONENT_PROGRAM)
    else
      out, err, status = Open3.capture3(SPY_PROGRAM)
    end
    puts out
    
    r = GokoRapper.new
    playLines = out.split("\n")
    playCard = playLines[-1].to_i
    if(playCard == 0)
      r.pointUpperButton
    else
      r.pointLowerButton
    end
  end

  def generateLibraryString()
    resultString = generateFeatureString() + "/" + @lastRevealCard.num.to_s
    puts resultString
    @outputActionSelection.write(resultString + "\n")

    if(!@autoPlay)
      return
    end

    out, err, status = Open3.capture3(LIBRARY_PROGRAM)
    puts out
    
    r = GokoRapper.new
    playLines = out.split("\n")
    playCard = playLines[-1].to_i
    if(playCard == 1)
      r.pointUpperButton
    else
      r.pointLowerButton
    end
  end

  def generateThiefString()

    revealString = ""
    if(@currentPlayer == 1)
      opponent = 0
    else
      opponent = 1
    end
    @reveal[opponent].each{|card|
      if(card.isTreasure)
        revealString = revealString + card.num.to_s + ","
      end
    }
    revealString = revealString[0...-1]

    resultString = generateFeatureString() + "/" + revealString

    puts resultString
    @outputActionSelection.write(resultString + "\n")

    feature = generateFeatureString();
    buyResult = @pastFeature[@currentPlayer][-3] + "," + @pastFeature[@currentPlayer][-2] + "," + @pastFeature[@currentPlayer][-1] + "," + feature

    @output.write(buyResult)

    if(!@autoPlay)
      return
    end

    out, err, status = Open3.capture3(THIEF_PROGRAM)
    puts out
    puts err
    puts status
  end

  def generateBureaucratString()
    resultString = generateOpponentFeatureString() + "/" + generateOpponentPlayerHandStringOnlyVictory()

    puts resultString
    @outputActionSelection.write(resultString + "\n")

    if(!@autoPlay)
      return
    end

    out, err, status = Open3.capture3(BUREAUCRAT_PROGRAM)
    puts out
    pointHand(out)
  end

  def generateMineString()
    resultString = generateFeatureString() + "/" + generateCurrentPlayerHandStringOnlyTreasyre()

    puts resultString
    @outputActionSelection.write(resultString + "\n")

    if(!@autoPlay)
      return
    end

    out, err, status = Open3.capture3(MINE_PROGRAM)
    puts out
    pointHand(out)
  end

  def generateMilitiaString()
    resultString = generateOpponentFeatureString() + "/" + generateOpponentPlayerHandString()

    puts resultString
    @outputActionSelection.write(resultString + "\n")

    if(!@autoPlay)
      return
    end

    out, err, status = Open3.capture3(MILITIA_PROGRAM)
    puts out
    
    pointHandMulti(out)
  end

  def generateChancellorString()
    resultString = generateFeatureString()

    puts resultString
    @outputActionSelection.write(resultString + "\n")

    if(!@autoPlay)
      return
    end

    out, err, status = Open3.capture3(CHANCELLOR_PROGRAM)
    puts out
    
    r = GokoRapper.new
    playLines = out.split("\n")
    playCard = playLines[-1].to_i
    if(playCard == 0)
      r.pointUpperButton
    else
      r.pointLowerButton
    end
  end

  def generateThroneString()

    if(@throneStack.include?(14) || @currentAction >= 1)
      active = 1
    else
      active = 0
    end

    resultString = generateFeatureString() + "/" + generateCurrentPlayerHandStringNoAction() + "/" + active.to_s 

    puts resultString
    @outputActionSelection.write(resultString + "\n")

    if(!@autoPlay)
      return
    end

    out, err, status = Open3.capture3(THRONE_PROGRAM)
    puts out
    pointHand(out)
  end

  def generateChapelString()
    resultString = generateFeatureString() + "/" + generateCurrentPlayerHandString()

    puts resultString
    @outputActionSelection.write(resultString + "\n")

    if(!@autoPlay)
      return
    end

    out, err, status = Open3.capture3(CHAPEL_PROGRAM)
    puts out
    
    if(pointHandMultiTimer(out) == 0)
      puts "no trash chapel"
      r = GokoRapper.new
      r.pointUpperButton
      GokoPlayer.new.parse(@rawlog, @output, @outputAction, @outputActionSelection, @drawlog, @autoPlay, "Chapel")
    else
      r = GokoRapper.new
      r.pointUpperButton
    end
  end

  def generateCellarString()
    resultString = generateFeatureString() + "/" + generateCurrentPlayerHandString()

    puts resultString
    @outputActionSelection.write(resultString + "\n")

    if(!@autoPlay)
      return
    end

    out, err, status = Open3.capture3(CELLAR_PROGRAM)
    puts out
    
    disCnt = pointHandMulti(out)

    if(@currentHand.size != 0)
      r = GokoRapper.new
      r.pointUpperButton
      if(disCnt == 0)
        GokoPlayer.new.parse(@rawlog, @output, @outputAction, @outputActionSelection, @drawlog, @autoPlay, "Cellar")
      end
    end
  end

  def generateRemodelTrashString()
    resultString = generateFeatureString() + "/" + generateCurrentPlayerHandString()

    puts resultString
    @outputActionSelection.write(resultString + "\n")

    if(!@autoPlay)
      return
    end

    out, err, status = Open3.capture3(REMODEL_PROGRAM)
    puts out
    pointHand(out)
  end

  def generatePlayActionData()
    
    # カード使用は敗者からも取っていい気がした
    #if(@playerName[@currentPlayer] != @winner)
    #    puts "#{@playerName[@currentPlayer]} is not #{@winner} he is loser"
    #    return
    #end
  
    feature = generateFeatureString();

    resultString = feature + "/" + @currentAction.to_s + "/" + generateCurrentPlayerHandStringNoAction()

    puts resultString
    @outputAction.write(resultString + "\n")

    if(!@autoPlay)
      return
    end

    out, err, status = Open3.capture3(PLAY_PROGRAM)
    puts out
    if(!pointHand(out))
      r = GokoRapper.new
      r.pointUpperButton
      sleep 4
      #財宝プレイ
      r.pointLowerButton
    end
  end

  def pointHandMulti(out)
    r = GokoRapper.new
    cardLines = out.split("\n")

    num = cardLines[-1].split(",").size

    cardLines[-1].split(",").each{|disCard|
      s = File.stat(@rawlog)
      disCard = disCard.to_i
      puts disCard
      if(disCard != 0)
        r.pointHand(getGokoHands.size, getGokoHands.index(disCard))
        @currentHand.delete_at(@currentHand.rindex(disCard))
      else
        return 0
      end
      while true
        sleep 1
        if(s.mtime != File.stat(@rawlog).mtime)
          break
        end
      end
    }
    return num
  end

  def pointHandMultiTimer(out)
    r = GokoRapper.new
    cardLines = out.split("\n")

    num = cardLines[-1].split(",").size

    cardLines[-1].split(",").each{|disCard|
      s = File.stat(@rawlog)
      disCard = disCard.to_i
      puts disCard
      if(disCard != 0)
        r.pointHand(getGokoHands.size, getGokoHands.index(disCard))
        @currentHand.delete_at(@currentHand.rindex(disCard))
      else
        return 0
      end
      sleep 4
    }
    return num
  end

  def pointHand(out)
    r = GokoRapper.new
    playLines = out.split("\n")
    playCard = playLines[-1].to_i
    if(playCard != 0)
      r.pointHand(getGokoHands.size, getGokoHands.index(playCard))
      return true
    else
      return false
    end
  end

  def getGokoHands()
    result = Array.new(0)
    @currentHand.each{|hand|
      if(!result.include?(hand))
        result.push(hand)
      end
    }
    result
  end

  def generateQuestionString(fromAction)
feature = generateFeatureString();
result = @pastFeature[@currentPlayer][-3] + "," + @pastFeature[@currentPlayer][-2] + "," + @pastFeature[@currentPlayer][-1] + "," + feature + "/"
if(@currentPhase != PHASE_ACTION)
    @pastFeature[@currentPlayer] << feature
end

      @supplyCnt.each{|cnt|
          result = result + cnt.to_s + ","
      }
      
      result = result[0..-2] + "/"
      
      if(!fromAction)
        coin = @currentCoin
        buy = @currentBuy
      elsif(@lastPlay.name == "Feast")
        coin = 5
        buy = 1
      elsif(@lastPlay.name == "Remodel")
        coin = @lastTrash.cost + 2
        buy = 1
      elsif(@lastPlay.name == "Workshop")
        coin = 4
        buy = 1
      end
      
      result = result + coin.to_s + "/" + buy.to_s
      
      puts result
      @output.write(result + "\n")

      if(!@autoPlay)
      return
    end

    if(DEBUGMODE)
      puts "debug"
      if(!File.exist?("./debug/turn" + (@currentTurn/2).to_s + "_buy_draw"))
      File.open("./debug/turn" + (@currentTurn/2).to_s + "_buy_draw", 'w'){|draw|
        FileUtils.cp( @drawlog, draw)
      }
      File.open("./debug/turn" + (@currentTurn/2).to_s + "_buy_log", 'w'){|log|
        FileUtils.cp(@rawlog, log)
      }
      end
    end

    out, err, status = Open3.capture3(BUY_PROGRAM)
    puts out
    r = GokoRapper.new
    buyLines = out.split("\n")

    buyLines[-1].split(",").each{|buyCard|
      s = File.stat(@rawlog)
      buyCard = buyCard.to_i
      puts buyCard
      if(buyCard != 0)
        if(buyCard == 1 || buyCard == 2 || buyCard == 3 || buyCard == 4 || buyCard == 5 || buyCard == 6)
          r.pointBasicCard(buyCard)
        else
          r.pointSupply(@supplyArray.index(buyCard))
        end
      else
        break
      end
      while true
        sleep 0.5
        if(s.mtime != File.stat(@rawlog).mtime)
          break
        end
      end
    }

    if(!fromAction)
      r.pointUpperButton
    end

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
    if(@currentPlayer == 1)
      player = 0
    else
      player = 1
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

  def verifyResult(data)
    if(@canVerify == false)
      puts "cannot verify because of quit or resign"
      return
    end
    
    if(data[0..data.index("-") - 2] == @playerName[0])
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
      end
    }
  end

  def addDrawInfo(rawlog, rdrawlog)
    log = rawlog.readlines
    drawlog = rdrawlog.readlines
    drawline = 0
    playerName = nil

    resultlog = Array.new(0)

    log.each{|line|
      if(line.include?(" - starting cards:") && playerName == nil)
        playerName = line[0..line.index(" - starting cards:") - 1]
      end
      if(playerName != nil && line.include?(playerName + " - draws ") &&  !line.include?(playerName + " - draws and discards"))
        lineStr = line[0..line.index("draws") + 5]
        while(drawlog[drawline].include?("#"))
          drawline = drawline + 1
        end
        drawlog[drawline].split(":").each{|str|
          if(str.include?("."))
            if(str[0...str.index(".")] == "throneRoom")
                lineStr = lineStr + "Throne Room" + ", "
            elsif(str[0...str.index(".")] == "councilRoom")
                lineStr = lineStr + "Council Room" + ", "
            else
                lineStr = lineStr + str[0...str.index(".")].capitalize + ", "
            end
          end
        }
        lineStr = lineStr[0..-3] + "\n"
        resultlog << lineStr
        drawline = drawline + 1
      else
        resultlog << line
      end
    }

    if(drawlog.size > 2 && drawlog[-1].include?("reveal") && !drawlog[-1].include?("back"))
      drawlog[-1].split(":").each{|str|
        if(str.include?("."))
          if(str[str.index("reveal")+7...str.index(".")] == "throneRoom")
            @lastRevealCard = @cardData.getCard("Throne Room") 
          elsif(str[str.index("reveal")+7...str.index(".")] == "councilRoom")
            @lastRevealCard = @cardData.getCard("Council Room") 
          else
            @lastRevealCard = @cardData.getCard(str[str.index("reveal")+7...str.index(".")].capitalize) 
          end
        end
      }
      if(drawlog[-2].include?("reveal")&& !drawlog[-2].include?("back"))
        @doubleReveal = true
      end
    end
    resultlog
  end

  def addPass(rawlog)
    lineCnt = 0
    buyflag = false
    log = rawlog
    resultlog = Array.new(0)

    sepCnt = 0

    log.each{|line|
      if(line.include?(" - resigned"))
        @canVerify = false
      end
      if(line.include?(" - quit"))
        @canVerify = false
      end
      if(line.include?("---"))
        sepCnt = sepCnt + 1
        if(sepCnt > 2)
          if(buyflag == false)
            drawCnt = 0
            rLineCnt = lineCnt - 1
            drawflag = false
            while drawCnt != 5 do
              rLineCnt = rLineCnt - 1
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

    resultlog
  end

  def generateGroundData(gain, coin, buy)
  feature = generateFeatureString();
  if(@currentPhase != PHASE_ACTION)
      @pastFeature[@currentPlayer] << feature
  end
    return
  
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

    puts result
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

    for i in 0...MAX_CARDNUM do
      result = result + (@playerDeck[other][i] + @playerHand[other][i] + @playerDiscard[other][i] + @playerPlay[other][i]).to_s + ","
    end

    for i in 0...MAX_CARDNUM do
      result = result + @supplyCnt[i].to_s + ","
    end

    for i in 0...MAX_CARDNUM do
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
      if(data[0..data.index("-") - 2] == @playerName[0])
        currentPlayer = 0
      else currentPlayer = 1
      end
    end

    for i in 0...MAX_CARDNUM do
      @playerDiscard[currentPlayer][i] = @playerDiscard[currentPlayer][i] + @playerHand[currentPlayer][i] + @playerPlay[currentPlayer][i]
      @playerPlay[currentPlayer][i] = 0
      @playerHand[currentPlayer][i] = 0
    end

    if(DEBUG_PRINT)
      puts "cleanup"
    end
  end

  def moveDeckIntoDiscards(data)
    if(data[0..data.index("-") - 2] == @playerName[0])
      currentPlayer = 0
    else currentPlayer = 1
    end
    
    for i in 1 ... MAX_CARDNUM do
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
  
    if(data[0..data.index("-") - 2] == @playerName[0])
      currentPlayer = 0
    else currentPlayer = 1
    end
  
    if(currentPlayer == 1)
        return
    end
  
    for i in 1 ... MAX_CARDNUM do
      @playerDeck[currentPlayer][i] = @playerDiscard[currentPlayer][i] + @playerDeck[currentPlayer][i]
      @playerDiscard[currentPlayer][i] = 0
    end
    
    if(DEBUG_PRINT)
      puts "reshuffle"
    end
  end

  def parseMoveCardInHand(data)
    if(data[0..data.index("-") - 2] == @playerName[0])
      currentPlayer = 0
    else currentPlayer = 1
    end
    if(@lastPlay.name == "Library")
      currentCard = @cardData.getCard(data[data.index("moves") + 6..data.index("to hand") - 2])
      if(currentPlayer == @player)
        @currentHand.push(currentCard.num)
      end
      @playerHand[currentPlayer][currentCard.num] = @playerHand[currentPlayer][currentCard.num] + 1
      @playerDeck[currentPlayer][currentCard.num] = @playerDeck[currentPlayer][currentCard.num] - 1
    end
  end
  
  def parsePutCardInHand(data)
    if(data[0..data.index("-") - 2] == @playerName[0])
      currentPlayer = 0
    else currentPlayer = 1
    end
    if(@lastPlay.name == "Adventurer")
      data[data.index("hand:") + 7..-2].split(", ").each{|card|
        currentCard = @cardData.getCard(card)
        if(currentPlayer == @player)
          @currentHand.push(currentCard.num)
        end
        @playerHand[currentPlayer][currentCard.num] = @playerHand[currentPlayer][currentCard.num] + 1
        @reveal[currentPlayer] = Array.new(0)
      }
    end
  end

  def parsePlaceTop(data)
    if(data[0..data.index("-") - 2] == @playerName[0])
      currentPlayer = 0
    else currentPlayer = 1
    end
    if(@lastPlay.name == "Bureaucrat")
      currentCard = @cardData.getCard(data[data.index("places") + 7 .. data.index("on top of deck") - 2])
      if(currentPlayer == @player)
        @currentHand.delete_at(@currentHand.rindex(currentCard.num))
      end
      @playerHand[currentPlayer][currentCard.num] = @playerHand[currentPlayer][currentCard.num] - 1
      @playerDeck[currentPlayer][currentCard.num] = @playerDeck[currentPlayer][currentCard.num] + 1
    end
  end

  def parseReveal(data)
    if(data[0..data.index("-") - 2] == @playerName[0])
      currentPlayer = 0
    else currentPlayer = 1
    end

    #掘
    if(data.include?("Moat"))
      if(currentPlayer == @player)
        @currentHand.delete_at(@currentHand.rindex(26))
        @currentHand.push(26)
      end
      return
    end

    if(@lastPlay.name == "Thief")
      data[data.index("reveals") + 9..-2].split(", ").each{|card|
        currentCard = @cardData.getCard(card)
        @playerDeck[currentPlayer][currentCard.num] = @playerDeck[currentPlayer][currentCard.num] - 1
        @reveal[currentPlayer] << currentCard
      }
    elsif(@lastPlay.name == "Adventurer")
      data[data.index("reveals") + 8..-2].split(", ").each{|card|
        currentCard = @cardData.getCard(card)
        
        if(@playerDeck[currentPlayer][currentCard.num] == 0)
            if(DEBUG_PRINT)
              puts "actual reshuffle is here"
            end

            for i in 1 ... MAX_CARDNUM do
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
    if(data[0..data.index("-") - 2] == @playerName[0])
      currentPlayer = 0
    else currentPlayer = 1
    end
    
    if(currentPlayer == 1)
        return
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
        @playerDeck[currentPlayer][currentCard.num] = @playerDeck[currentPlayer][currentCard.num] - 1
        @playerDiscard[currentPlayer][currentCard.num] = @playerDiscard[currentPlayer][currentCard.num] + 1
      elsif(@lastPlay.name == "Adventurer")
        @playerDiscard[currentPlayer][currentCard.num] = @playerDiscard[currentPlayer][currentCard.num] + 1
      elsif(@lastPlay.name == "Library")
        @playerDiscard[currentPlayer][currentCard.num] = @playerDiscard[currentPlayer][currentCard.num] + 1
        @playerDeck[currentPlayer][currentCard.num] = @playerDeck[currentPlayer][currentCard.num] - 1
      else
        if(currentPlayer == @player)
          @currentHand.delete_at(@currentHand.rindex(currentCard.num))
        end
        @playerHand[currentPlayer][currentCard.num] = @playerHand[currentPlayer][currentCard.num] - 1
        @playerDiscard[currentPlayer][currentCard.num] = @playerDiscard[currentPlayer][currentCard.num] + 1
      end
    }
  end
  
  def parseDraw(data)
    if(data[0..data.index("-") - 2] == @playerName[0])
      currentPlayer = 0
    else currentPlayer = 1
    end

    if(currentPlayer != @player)
      return
    end

    data[data.index("draws") + 6..-2].split(", ").each{|card|

      currentCard = @cardData.getCard(card)
      
      if(DEBUG_PRINT)
        puts "#{@playerName[currentPlayer]} drawes #{currentCard.name}"
      end

      @currentHand.push(currentCard.num)
      @playerDeck[currentPlayer][currentCard.num] = @playerDeck[currentPlayer][currentCard.num] - 1
      @playerHand[currentPlayer][currentCard.num] = @playerHand[currentPlayer][currentCard.num] + 1

    }
  end

  def parseTrash(data)
    if(data[0..data.index("-") - 2] == @playerName[0])
      currentPlayer = 0
    else currentPlayer = 1
    end
    

    data[data.index("trashes") + 8..-2].split(", ").each{|card|

      currentCard = @cardData.getCard(card)
      
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
        @reveal[currentPlayer].each{|rCard|
          if(rCard.num == currentCard.num)
            @reveal.delete(rCard)
            break
          end
        }
      else
        if(currentPlayer == @player)
          @currentHand.delete_at(@currentHand.rindex(currentCard.num))
        end
        @playerHand[currentPlayer][currentCard.num] = @playerHand[currentPlayer][currentCard.num] - 1
      end

      @lastTrash = currentCard
    }
  end

  def parseBuy(data)
    if(data[0..data.index("-") - 2] == @playerName[0])
      currentPlayer = 0
    else currentPlayer = 1
    end
    gainCard = @cardData.getCard(data[data.index("gains") + 6 .. -2])

    @lastBuy << gainCard

    if(DEBUG_PRINT)
      puts "#{@playerName[currentPlayer]} buys #{gainCard.name} coin is #{@currentCoin} buy is #{@currentBuy}"
    end

    
  end

  def parseGain(data)
    if(data[0..data.index("-") - 2] == @playerName[0])
      currentPlayer = 0
    else currentPlayer = 1
    end
    gainCard = @cardData.getCard(data[data.index("gains") + 6 .. -2])

    if(@lastPlay.name == "Feast")
      generateGroundData(Array.new(1, gainCard), 5, 1)
    elsif(@lastPlay.name == "Remodel")
      generateGroundData(Array.new(1, gainCard), @lastTrash.cost + 2, 1)
    elsif(@lastPlay.name == "Workshop")
      generateGroundData(Array.new(1, gainCard), 4, 1)
    end

    if(@lastPlay.name == "Mine")
      if(currentPlayer == @player)
        @currentHand.push(currentCard.num)
      end
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
    if(data[0..data.index("-") - 2] == @playerName[0])
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
      
      if(currentPlayer == @player)
        (playCard[0].to_i).times{
          @currentHand.delete_at(@currentHand.rindex(currentCard.num))
        }
      end

      @playerHand[currentPlayer][currentCard.num] = @playerHand[currentPlayer][currentCard.num] - 1
      @playerPlay[currentPlayer][currentCard.num] = @playerPlay[currentPlayer][currentCard.num] + 1
      
    }
  
  end

  def parsePlayAction(data)
    if(data[0..data.index("-") - 2] == @playerName[0])
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

    #ほりのこうかいしょり
    if(currentPlayer != @player && pCard.isAttack && @currentHand.include?(26))
      r = GokoRapper.new
      r.pointHand(getGokoHands.size, getGokoHands.index(26))
      @currentHand.delete_at(@currentHand.rindex(26))
      @currentHand.push(26)
      if(DEBUG_PRINT || true)
        puts "ほり　以下手札"
        puts @currentHand
      end
    end

    if(DEBUG_PRINT)
      if(DEBUG_PRINT)
        puts "#{@playerName[currentPlayer]} uses action #{data[data.index("plays") + 6 .. -2]}"
      end
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
      if(currentPlayer == @player)
        @currentHand.delete_at(@currentHand.rindex(pCard.num))
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
        if(@player == currentPlayer)
          @currentAction = @currentAction - 1
          if(@currentAction < 0)
            puts "action minus error"
            raise
          end
          @currentHand.delete_at(@currentHand.rindex(pCard.num))
        end
        @playerHand[currentPlayer][pCard.num] = @playerHand[currentPlayer][pCard.num] - 1
        @playerPlay[currentPlayer][pCard.num] = @playerPlay[currentPlayer][pCard.num] + 1
      end
    end
    
    @lastPlay = pCard

    #この処理要らなくね？（玉座は強制使用のため）
    if(pCard.name == "Throne Room" || true)
	   if(haveActionInHand() == false)
	     @lastPlay = nil
       if(DEBUG_PRINT)
          puts "uses throne but have no action"
	     end
     end
    end

  end

  def haveActionInHand()
    for i in 0...MAX_CARDNUM do
      if(@playerHand[@currentPlayer][i] > 0 && @cardData.getCardByNum(i).isAction)
        return true
      end
    end
    return false
  end

  def haveTreasureInHand()
    for i in 0...MAX_CARDNUM do
      if(@playerHand[@currentPlayer][i] > 0 && @cardData.getCardByNum(i).isTreasure)
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
      
    @playerName[plNum] = data[0..data.index("-") - 2]

    data[data.index(":") + 2..-2].split(", ").each{|card|
      
      currentCard = @cardData.getCard(card)
      
      @playerDiscard[plNum][currentCard.num] = @playerDiscard[plNum][currentCard.num] + 1
    }
  end

  def parseSupply(data)
    data[1..-2].split(", ").each{|card|
      supCard = @cardData.getCard(card)
      @supplyArray.push(supCard.num)
      @supplyCnt[supCard.num] = supCard.pilenum
      @supplyExist[supCard.num] = 1
    }
  end

end
