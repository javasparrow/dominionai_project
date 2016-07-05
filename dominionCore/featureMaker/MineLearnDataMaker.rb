load("featureMaker/BaseLearnDataMaker.rb")
load(File.expand_path(__FILE__).sub(/[^\/]+$/,'')[0...-1].sub(/[^\/]+$/,'')[0...-1].sub(/[^\/]+$/,'') + "util/cardData.rb")

#購入の教師データを作成
require 'rexml/document'

class MineLearnDataMaker

  def initialize
    @trashId = nil
    @cardData = CardData.new()
  end

  def eventCallback(eventData, core)
    if(core.currentPlayer != core.winner)
      return
    end

    baseMaker = BaseLearnDataMaker.new(core)
    if(eventData["type"] == "trash" && core.lastPlay.name == "Mine")
      File.open(core.outFolder + "/mineFeature.txt", 'a'){|out|
        doc = REXML::Document.new
        play = doc.add_element("mine")
        play.add_element("stateVec").add_text baseMaker.getStateVec(core.currentPlayer)
        play.add_element("answer").add_text eventData["cards"][0].id.to_s
        play.add_element("turn").add_text (core.currentTurn / 2).to_i.to_s
        play.add_element("isSente").add_text ((core.currentTurn + 1) % 2).to_s
        candidates = []
        core.playerData[core.currentPlayer].handArea.each{|id, num|
          if num > 0 && !candidates.include?(id) && @cardData.getCardByNum(id).isTreasure
            candidates << id
          end
        }
        play.add_element("candidates").add_text candidates.join(",")
        play.add_element("filename").add_text core.fileName

        #TODO think about bridge
        play.add_element("minusCost").add_text "0"

        out.write(doc.to_s)
        out.write("\n")
      }
    end
  end

end
