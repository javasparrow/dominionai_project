load("featureMaker/BaseLearnDataMaker.rb")
#購入の教師データを作成
require 'rexml/document'

class PawnLearnDataMaker

  def initialize
    @pawnFlag = false
    @selectedMode = []
    @cardData = CardData.new()
    @stateVec = nil
  end

  def writeFeature(core, baseMaker)
    if !@stateVec
      @stateVec = baseMaker.getStateVec(core.currentPlayer)
    end
    if !@currentAction
      @currentAction = core.currentAction.to_s
    end
    if !@pawnFlag || @selectedMode.length != 2
      return
    end
    File.open(core.outFolder + "/pawnFeature.txt", 'a'){|out|
      doc = REXML::Document.new
      play = doc.add_element("pawn")
      play.add_element("stateVec").add_text @stateVec
      play.add_element("answer").add_text @selectedMode.join(",")
      play.add_element("turn").add_text (core.currentTurn / 2).to_i.to_s
      play.add_element("isSente").add_text ((core.currentTurn + 1) % 2).to_s
      play.add_element("action").add_text @currentAction
      play.add_element("filename").add_text core.fileName

      out.write(doc.to_s)
      out.write("\n")
      @pawnFlag = false
      @selectedMode = []
    }
  end

  def eventCallback(eventData, core)
    if(core.currentPlayer != core.winner)
      return
    end

    baseMaker = BaseLearnDataMaker.new(core)

    if eventData["type"] == "play" && @cardData.getCardByNum(eventData["cardId"]).name == "Pawn"
      @pawnFlag = true
      @selectedMode = []
    elsif eventData["type"] == "draw" && core.lastPlay && core.lastPlay.name == "Pawn"
      @selectedMode << 1
      writeFeature(core, baseMaker)
    elsif eventData["type"] == "take" && eventData["content"] == "coin" && core.lastPlay && core.lastPlay.name == "Pawn"
      @selectedMode << 0
      writeFeature(core, baseMaker)
    elsif eventData["type"] == "take" && eventData["content"] == "buy" && core.lastPlay && core.lastPlay.name == "Pawn"
      @selectedMode << 3
      writeFeature(core, baseMaker)
    elsif eventData["type"] == "take" && eventData["content"] == "action" && core.lastPlay && core.lastPlay.name == "Pawn"
      @selectedMode << 2
      writeFeature(core, baseMaker)
    end
  end

end
