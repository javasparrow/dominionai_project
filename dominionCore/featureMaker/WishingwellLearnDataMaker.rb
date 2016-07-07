load("featureMaker/BaseLearnDataMaker.rb")
#購入の教師データを作成
require 'rexml/document'

class WishingwellLearnDataMaker

  def initialize
  end

  def eventCallback(eventData, core)
    if(core.currentPlayer != core.winner)
      return
    end

    baseMaker = BaseLearnDataMaker.new(core)
    if(eventData["type"] == "namecard" && core.lastPlay.name == "Wishing Well")
      File.open(core.outFolder + "/wishingwellFeature.txt", 'a'){|out|
        doc = REXML::Document.new
        play = doc.add_element("wishingwell")
        play.add_element("stateVec").add_text baseMaker.getStateVec(core.currentPlayer)
        play.add_element("answer").add_text eventData["cardId"].to_s
        play.add_element("turn").add_text (core.currentTurn / 2).to_i.to_s
        play.add_element("isSente").add_text ((core.currentTurn + 1) % 2).to_s
        play.add_element("filename").add_text core.fileName

        out.write(doc.to_s)
        out.write("\n")
      }
    end
  end

end
