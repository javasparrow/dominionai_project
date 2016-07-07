load("featureMaker/BaseLearnDataMaker.rb")
#購入の教師データを作成
require 'rexml/document'

class NoblesLearnDataMaker

  def initialize
    @nobelsFlag = false
    @cardData = CardData.new()
  end

  def eventCallback(eventData, core)
    if(core.currentPlayer != core.winner)
      return
    end

    baseMaker = BaseLearnDataMaker.new(core)

    if eventData["type"] == "play" && @cardData.getCardByNum(eventData["cardId"]).name == "Nobles"
      @nobelsFlag = true
    elsif(eventData["type"] == "take" && core.lastPlay.name == "Nobles")
      if !@nobelsFlag
        return
      end
      File.open(core.outFolder + "/noblesFeature.txt", 'a'){|out|
        doc = REXML::Document.new
        play = doc.add_element("nobles")
        play.add_element("stateVec").add_text baseMaker.getStateVec(core.currentPlayer)
        play.add_element("answer").add_text "0"
        play.add_element("turn").add_text (core.currentTurn / 2).to_i.to_s
        play.add_element("isSente").add_text ((core.currentTurn + 1) % 2).to_s
        play.add_element("action").add_text core.currentAction.to_s
        play.add_element("filename").add_text core.fileName

        out.write(doc.to_s)
        out.write("\n")
      }
      @nobelsFlag = false
    elsif eventData["type"] == "draw" && core.lastPlay && core.lastPlay.name == "Nobles"
      if !@nobelsFlag
        return
      end
      File.open(core.outFolder + "/noblesFeature.txt", 'a'){|out|
        doc = REXML::Document.new
        play = doc.add_element("nobles")
        play.add_element("stateVec").add_text baseMaker.getStateVec(core.currentPlayer)
        play.add_element("answer").add_text "1"
        play.add_element("turn").add_text (core.currentTurn / 2).to_i.to_s
        play.add_element("isSente").add_text ((core.currentTurn + 1) % 2).to_s
        play.add_element("action").add_text core.currentAction.to_s
        play.add_element("filename").add_text core.fileName

        out.write(doc.to_s)
        out.write("\n")
        @nobelsFlag = false
      }
    end
  end

end
