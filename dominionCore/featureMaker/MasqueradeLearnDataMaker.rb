load("featureMaker/BaseLearnDataMaker.rb")
#購入の教師データを作成
require 'rexml/document'

class MasqueradeLearnDataMaker

  def initialize
    @trashId = nil
    @masqueradeFlag = false
    @cardData = CardData.new()
  end

  def eventCallback(eventData, core)
    if(eventData["player"] != core.winner)
      return
    end

    baseMaker = BaseLearnDataMaker.new(core)
    if eventData["type"] == "play" && @cardData.getCardByNum(eventData["cardId"]).name == "Masquerade"
      @masqueradeFlag = true
    elsif(eventData["type"] == "trash" && core.lastPlay.name == "Masquerade")
      File.open(core.outFolder + "/masqueradeFeature.txt", 'a'){|out|
        doc = REXML::Document.new
        play = doc.add_element("masquerade")
        play.add_element("stateVec").add_text baseMaker.getStateVec(eventData["player"])
        play.add_element("answer").add_text eventData["cards"][0].id.to_s
        play.add_element("turn").add_text (core.currentTurn / 2).to_i.to_s
        play.add_element("isSente").add_text ((core.currentTurn + 1) % 2).to_s
        candidates = []
        core.playerData[eventData["player"]].handArea.each{|id, num|
          if num > 0 && !candidates.include?(id)
            candidates << id
          end
        }
        play.add_element("candidates").add_text candidates.join(",")
        play.add_element("minusCost").add_text core.discount.to_s
        play.add_element("filename").add_text core.fileName
        play.add_element("otherFlag").add_text "1"

        out.write(doc.to_s)
        out.write("\n")
      }
      @masqueradeFlag = false
    elsif(eventData["type"] == "passcard" && core.lastPlay.name == "Masquerade")
      File.open(core.outFolder + "/masqueradeFeature.txt", 'a'){|out|
        doc = REXML::Document.new
        play = doc.add_element("masquerade")
        play.add_element("stateVec").add_text baseMaker.getStateVec(eventData["player"])
        play.add_element("answer").add_text eventData["cardId"].to_s
        play.add_element("turn").add_text (core.currentTurn / 2).to_i.to_s
        play.add_element("isSente").add_text ((core.currentTurn + 1) % 2).to_s
        candidates = []
        core.playerData[eventData["player"]].handArea.each{|id, num|
          if num > 0 && !candidates.include?(id)
            candidates << id
          end
        }
        play.add_element("candidates").add_text candidates.join(",")
        play.add_element("minusCost").add_text core.discount.to_s
        play.add_element("filename").add_text core.fileName
        play.add_element("otherFlag").add_text "0"

        out.write(doc.to_s)
        out.write("\n")
      }
    #廃棄されなかった場合
    elsif @masqueradeFlag && eventData["type"] == "draw"
      File.open(core.outFolder + "/masqueradeFeature.txt", 'a'){|out|
        doc = REXML::Document.new
        play = doc.add_element("masquerade")
        play.add_element("stateVec").add_text baseMaker.getStateVec(eventData["player"])
        play.add_element("answer").add_text "0"
        play.add_element("turn").add_text (core.currentTurn / 2).to_i.to_s
        play.add_element("isSente").add_text ((core.currentTurn + 1) % 2).to_s
        candidates = []
        core.playerData[eventData["player"]].handArea.each{|id, num|
          if num > 0 && !candidates.include?(id)
            candidates << id
          end
        }
        play.add_element("candidates").add_text candidates.join(",")
        play.add_element("minusCost").add_text core.discount.to_s
        play.add_element("filename").add_text core.fileName
        play.add_element("otherFlag").add_text "1"

        out.write(doc.to_s)
        out.write("\n")
      }
      @masqueradeFlag = false
    end
  end

end
