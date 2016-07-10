load("featureMaker/BaseLearnDataMaker.rb")
#購入の教師データを作成
require 'rexml/document'

class IronworksLearnDataMaker

  def initialize
    @trashId = nil
    @cardData = CardData.new()
  end

  def eventCallback(eventData, core)
    if(core.currentPlayer != core.winner)
      return
    end

    baseMaker = BaseLearnDataMaker.new(core)
    if(eventData["type"] == "gain" && core.lastPlay.name == "Ironworks")
      File.open(core.outFolder + "/ironworksFeature.txt", 'a'){|out|
        doc = REXML::Document.new
        play = doc.add_element("ironworks")
        play.add_element("stateVec").add_text baseMaker.getStateVec(core.currentPlayer)
        play.add_element("answer").add_text eventData["cardId"].to_s
        play.add_element("turn").add_text (core.currentTurn / 2).to_i.to_s
        play.add_element("isSente").add_text ((core.currentTurn + 1) % 2).to_s
        candidates = []
        core.supply.each{|id, num|
          supcost = @cardData.getCardByNum(id).cost - core.discount
          if supcost < 0
            supcost = 0
          end
          if supcost <= 4 && num > 0
            candidates << id
          end
        }
        play.add_element("candidates").add_text candidates.join(",")
        play.add_element("filename").add_text core.fileName
        play.add_element("action").add_text core.currentAction.to_s

        out.write(doc.to_s)
        out.write("\n")
      }
    end
  end

end
