load("featureMaker/BaseLearnDataMaker.rb")
load(File.expand_path(__FILE__).sub(/[^\/]+$/,'')[0...-1].sub(/[^\/]+$/,'')[0...-1].sub(/[^\/]+$/,'') + "util/cardData.rb")

#購入の教師データを作成
require 'rexml/document'

class TradingpostLearnDataMaker

  def initialize
    @chapelFlag = false
    @cardData = CardData.new()
  end

  def eventCallback(eventData, core)
    if(core.currentPlayer != core.winner)
      return
    end

    baseMaker = BaseLearnDataMaker.new(core)
    if eventData["type"] == "trash" && core.lastPlay.name == "Trading Post"
      File.open(core.outFolder + "/tradingpostFeature.txt", 'a'){|out|
        doc = REXML::Document.new
        play = doc.add_element("tradingpost")
        play.add_element("stateVec").add_text baseMaker.getStateVec(core.currentPlayer)
        play.add_element("answer").add_text eventData["cards"].map{|card| card.id}.join(",")
        play.add_element("turn").add_text (core.currentTurn / 2).to_i.to_s
        play.add_element("isSente").add_text ((core.currentTurn + 1) % 2).to_s
        candidates = []
        core.playerData[core.currentPlayer].handArea.each{|id, num|
          num.times{
            candidates << id
          }
        }
        play.add_element("candidates").add_text candidates.join(",")
        play.add_element("filename").add_text core.fileName

        out.write(doc.to_s)
        out.write("\n")
      }
    end
  end

end
