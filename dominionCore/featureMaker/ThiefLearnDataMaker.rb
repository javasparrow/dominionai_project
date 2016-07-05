load("featureMaker/BaseLearnDataMaker.rb")
load(File.expand_path(__FILE__).sub(/[^\/]+$/,'')[0...-1].sub(/[^\/]+$/,'')[0...-1].sub(/[^\/]+$/,'') + "util/cardData.rb")

#購入の教師データを作成
require 'rexml/document'

class ThiefLearnDataMaker

  def initialize
    @trashCard = nil
    @cardData = CardData.new()
  end

  def eventCallback(eventData, core)
    if(core.currentPlayer != core.winner)
      return
    end

    thiefPlayer = core.currentPlayer

    baseMaker = BaseLearnDataMaker.new(core)
    if(eventData["type"] == "trash" && core.lastPlay.name == "Thief")
      File.open(core.outFolder + "/thiefFeature.txt", 'a'){|out|
        doc = REXML::Document.new
        play = doc.add_element("thief")
        play.add_element("stateVec").add_text baseMaker.getStateVec(thiefPlayer)
        play.add_element("answer").add_text eventData["cards"][0].id.to_s
        play.add_element("turn").add_text (core.currentTurn / 2).to_i.to_s
        play.add_element("isSente").add_text ((core.currentTurn + 1) % 2).to_s

        candidates = []
        core.playerData[eventData["player"]].revealArea.each{|id, num|
          if @cardData.getCardByNum(id).isTreasure
            num.times{
              candidates << id
            }
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
