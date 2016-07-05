class BaseLearnDataMaker
  MAX_CARD_ID = 57

  def initialize(core)
    @core = core
  end

  def getStateVec(playerName)
    result = ""

    player = nil
    opponentPlayer = nil

    @core.playerData.each{|name, pl|
      if name == playerName
        player = pl
      else
        opponentPlayer = pl
      end
    }

    (0..MAX_CARD_ID).each{|id|
      if(player.deckArea[id])
        result += player.deckArea[id].to_s + ","
      else
        result += "0,"
      end
    }
    (0..MAX_CARD_ID).each{|id|
      if(player.handArea[id])
        result += player.handArea[id].to_s + ","
      else
        result += "0,"
      end
    }
    (0..MAX_CARD_ID).each{|id|
      if(player.discardArea[id])
        result += player.discardArea[id].to_s + ","
      else
        result += "0,"
      end
    }
    (0..MAX_CARD_ID).each{|id|
      if(player.playArea[id])
        result += player.playArea[id].to_s + ","
      else
        result += "0,"
      end
    }
    (0..MAX_CARD_ID).each{|id|
      result += (opponentPlayer.deckArea[id].to_i + opponentPlayer.handArea[id].to_i + opponentPlayer.discardArea[id].to_i + opponentPlayer.playArea[id].to_i + opponentPlayer.revealArea[id].to_i).to_s + ","
    }
    (0..MAX_CARD_ID).each{|id|
      if @core.supply[id]
        result += @core.supply[id].to_s + ","
      else
        result += "0,"
      end
    }
    (0..MAX_CARD_ID).each{|id|
      if @core.supply[id]
        result += "1,"
      else
        result += "0,"
      end
    }
    result[0...-1]
  end
end
