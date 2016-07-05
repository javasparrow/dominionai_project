load("featureMaker/BaseLearnDataMaker.rb")
#購入の教師データを作成
require 'rexml/document'

class PlayLearnDataMaker

  def initialize
    @buyCardIds = []
  end

  def eventCallback(eventData, core)
    if(core.currentPlayer != core.winner)
      return
    end

    baseMaker = BaseLearnDataMaker.new(core)
    if(eventData["type"] == "switch_phase" && eventData["phase"] == "buy")
      if core.playerData[core.currentPlayer].haveActionInHand && core.currentAction > 0
        File.open(core.outFolder + "/playFeature.txt", 'a'){|out|
          doc = REXML::Document.new
          play = doc.add_element("play")
          play.add_element("stateVec").add_text baseMaker.getStateVec(core.currentPlayer)
          play.add_element("answer").add_text "0"
          play.add_element("turn").add_text (core.currentTurn / 2).to_i.to_s
          play.add_element("isSente").add_text ((core.currentTurn + 1) % 2).to_s
          candidates = []
          core.playerData[core.currentPlayer].handArea.each{|id, num|
            if num > 0 && !candidates.include?(id)
              candidates << id
            end
          }
          play.add_element("candidates").add_text candidates.join(",")
          play.add_element("action").add_text core.currentAction.to_s

          play.add_element("filename").add_text core.fileName

          out.write(doc.to_s)
          out.write("\n")
        }
      end
    end
    if(eventData["type"] == "play")
      File.open(core.outFolder + "/playFeature.txt", 'a'){|out|
        doc = REXML::Document.new
        play = doc.add_element("play")
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
        play.add_element("action").add_text core.currentAction.to_s

        play.add_element("filename").add_text core.fileName

        out.write(doc.to_s)
        out.write("\n")
      }
    end
  end

end
