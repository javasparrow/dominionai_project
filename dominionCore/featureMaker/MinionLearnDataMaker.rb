load("featureMaker/BaseLearnDataMaker.rb")
#購入の教師データを作成
require 'rexml/document'

class MinionLearnDataMaker

  def initialize
    @minionFlag = false
    @cardData = CardData.new()
  end

  def writeFeature(type, core, baseMaker)
    if !@minionFlag
      return
    end
    File.open(core.outFolder + "/minionFeature.txt", 'a'){|out|
      doc = REXML::Document.new
      play = doc.add_element("minion")
      play.add_element("stateVec").add_text baseMaker.getStateVec(core.currentPlayer)
      play.add_element("answer").add_text type
      play.add_element("turn").add_text (core.currentTurn / 2).to_i.to_s
      play.add_element("isSente").add_text ((core.currentTurn + 1) % 2).to_s
      play.add_element("action").add_text core.currentAction.to_s
      play.add_element("filename").add_text core.fileName

      out.write(doc.to_s)
      out.write("\n")
    }
    @minionFlag = false
  end

  def eventCallback(eventData, core)
    if(core.currentPlayer != core.winner)
      return
    end

    baseMaker = BaseLearnDataMaker.new(core)

    if eventData["type"] == "play" && @cardData.getCardByNum(eventData["cardId"]).name == "Minion"
      @minionFlag = true
    elsif eventData["type"] == "discard" && core.lastPlay && core.lastPlay.name == "Minion"
      writeFeature("0", core, baseMaker)
    elsif eventData["type"] == "take" && core.lastPlay && core.lastPlay.name == "Minion"
      writeFeature("1", core, baseMaker)
    end
  end

end
