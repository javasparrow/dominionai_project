load("featureMaker/BaseLearnDataMaker.rb")
load(File.expand_path(__FILE__).sub(/[^\/]+$/,'')[0...-1].sub(/[^\/]+$/,'')[0...-1].sub(/[^\/]+$/,'') + "util/cardData.rb")

#購入の教師データを作成
require 'rexml/document'

class SpyLearnDataMaker

  def initialize
    @cardData = CardData.new()
  end

  def eventCallback(eventData, core)
    if(core.currentPlayer != core.winner)
      return
    end

    baseMaker = BaseLearnDataMaker.new(core)
    if(eventData["type"] == "placetop" && core.lastPlay.name == "Spy")
      File.open(core.outFolder + "/spyFeature.txt", 'a'){|out|
        doc = REXML::Document.new
        play = doc.add_element("spy")
        play.add_element("stateVec").add_text baseMaker.getStateVec(core.currentPlayer)
        play.add_element("answer").add_text "0"
        play.add_element("turn").add_text (core.currentTurn / 2).to_i.to_s
        play.add_element("isSente").add_text ((core.currentTurn + 1) % 2).to_s
        play.add_element("revealCard").add_text eventData["cardId"].to_s
        if eventData["player"] == core.currentPlayer
          play.add_element("otherFlag").add_text "1"
        else
          play.add_element("otherFlag").add_text "0"
        end
        play.add_element("filename").add_text core.fileName

        out.write(doc.to_s)
        out.write("\n")
      }
    end
    if(eventData["type"] == "discard" && core.lastPlay.name == "Spy")
      File.open(core.outFolder + "/spyFeature.txt", 'a'){|out|
        doc = REXML::Document.new
        play = doc.add_element("spy")
        play.add_element("stateVec").add_text baseMaker.getStateVec(core.currentPlayer)
        play.add_element("answer").add_text "1"
        play.add_element("turn").add_text (core.currentTurn / 2).to_i.to_s
        play.add_element("isSente").add_text ((core.currentTurn + 1) % 2).to_s
        play.add_element("revealCard").add_text eventData["cards"][0].id.to_s
        if eventData["player"] == core.currentPlayer
          play.add_element("otherFlag").add_text "1"
        else
          play.add_element("otherFlag").add_text "0"
        end
        play.add_element("filename").add_text core.fileName

        out.write(doc.to_s)
        out.write("\n")
      }
    end
  end

end
