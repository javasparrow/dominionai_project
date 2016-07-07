load("featureMaker/BaseLearnDataMaker.rb")
#購入の教師データを作成
require 'rexml/document'

class CourtyardLearnDataMaker

  def initialize
  end

  def eventCallback(eventData, core)
    if(core.currentPlayer != core.winner)
      return
    end

    baseMaker = BaseLearnDataMaker.new(core)
    if(eventData["type"] == "placetop" && core.lastPlay.name == "Courtyard")
      File.open(core.outFolder + "/courtyardFeature.txt", 'a'){|out|
        doc = REXML::Document.new
        play = doc.add_element("courtyard")
        play.add_element("stateVec").add_text baseMaker.getStateVec(core.currentPlayer)
        play.add_element("answer").add_text eventData["cardId"].to_s
        play.add_element("turn").add_text (core.currentTurn / 2).to_i.to_s
        play.add_element("isSente").add_text ((core.currentTurn + 1) % 2).to_s
        candidates = []
        core.playerData[core.currentPlayer].handArea.each{|id, num|
          if num > 0 && !candidates.include?(id)
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
