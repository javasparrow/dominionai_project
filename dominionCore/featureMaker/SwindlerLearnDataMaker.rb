load("featureMaker/BaseLearnDataMaker.rb")
load(File.expand_path(__FILE__).sub(/[^\/]+$/,'')[0...-1].sub(/[^\/]+$/,'')[0...-1].sub(/[^\/]+$/,'') + "util/cardData.rb")

#購入の教師データを作成
require 'rexml/document'

class SwindlerLearnDataMaker

  def initialize
    @trashedCard = nil
    @cardData = CardData.new()
  end

  def eventCallback(eventData, core)
    if(core.currentPlayer != core.winner)
      return
    end

    baseMaker = BaseLearnDataMaker.new(core)
    if eventData["type"] == "trash" && core.lastPlay.name == "Swindler"
      @trashedCard = eventData["cards"][0]
    elsif eventData["type"] == "gain" && core.lastPlay.name == "Swindler"
      File.open(core.outFolder + "/swindlerFeature.txt", 'a'){|out|
        doc = REXML::Document.new
        play = doc.add_element("swindler")
        play.add_element("stateVec").add_text baseMaker.getStateVec(core.currentPlayer)
        play.add_element("answer").add_text eventData["cardId"].to_s
        play.add_element("turn").add_text (core.currentTurn / 2).to_i.to_s
        play.add_element("isSente").add_text ((core.currentTurn + 1) % 2).to_s
        candidates = []
        trashedCost = @trashedCard.cost - core.discount
        if trashedCost < 0
          trashedCost = 0
        end
        core.supply.each{|id, num|
          supcost = @cardData.getCardByNum(id).cost - core.discount
          if supcost < 0
            supcost = 0
          end
          if supcost == trashedCost && num > 0
            candidates << id
          end
        }
        play.add_element("candidates").add_text candidates.join(",")
        play.add_element("filename").add_text core.fileName

        out.write(doc.to_s)
        out.write("\n")
      }
    end
  end

end
