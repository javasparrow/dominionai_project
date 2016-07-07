load("featureMaker/BaseLearnDataMaker.rb")
#購入の教師データを作成
require 'rexml/document'

class StewardLearnDataMaker

  def initialize
    @stewardFlag = false
    @cardData = CardData.new()
  end

  def writeFeature(type, core, baseMaker)
    if !@stewardFlag
      return
    end
    File.open(core.outFolder + "/stewardFeature.txt", 'a'){|out|
      doc = REXML::Document.new
      play = doc.add_element("steward")
      play.add_element("stateVec").add_text baseMaker.getStateVec(core.currentPlayer)
      play.add_element("answer").add_text type
      play.add_element("turn").add_text (core.currentTurn / 2).to_i.to_s
      play.add_element("isSente").add_text ((core.currentTurn + 1) % 2).to_s
      play.add_element("action").add_text core.currentAction.to_s
      play.add_element("filename").add_text core.fileName

      out.write(doc.to_s)
      out.write("\n")
      @stewardFlag = false
    }
  end

  def eventCallback(eventData, core)
    if(core.currentPlayer != core.winner)
      return
    end

    baseMaker = BaseLearnDataMaker.new(core)

    if eventData["type"] == "play" && @cardData.getCardByNum(eventData["cardId"]).name == "Steward"
      @stewardFlag = true
    elsif eventData["type"] == "draw" && core.lastPlay && core.lastPlay.name == "Steward"
      writeFeature("1", core, baseMaker)
    elsif eventData["type"] == "trash" && core.lastPlay && core.lastPlay.name == "Steward"
      writeFeature("2", core, baseMaker)
    elsif eventData["type"] == "take" && core.lastPlay && core.lastPlay.name == "Steward"
      writeFeature("0", core, baseMaker)
    end
  end

end
