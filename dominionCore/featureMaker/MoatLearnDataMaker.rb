load("featureMaker/BaseLearnDataMaker.rb")
load(File.expand_path(__FILE__).sub(/[^\/]+$/,'')[0...-1].sub(/[^\/]+$/,'')[0...-1].sub(/[^\/]+$/,'') + "util/cardData.rb")

#購入の教師データを作成
require 'rexml/document'

class MoatLearnDataMaker

  def initialize
    @attackCard = nil
    @cardData = CardData.new()
  end

  def eventCallback(eventData, core)
    if(core.currentPlayer == core.winner)
      return
    end

    moatPlayer = core.getOpponent(core.currentPlayer)

    baseMaker = BaseLearnDataMaker.new(core)
    if eventData["type"] == "play" && @cardData.getCardByNum(eventData["cardId"]).isAttack
      if moatPlayer.handArea.keys.include?(@cardData.getCard("Moat").id)
        @attackCard = eventData["cardId"]
      end
    elsif eventData["type"] == "reaction" && @cardData.getCardByNum(eventData["cardId"]).name == "Moat"
      # 堀無限公開
      if !@attackCard
        return
      end
      File.open(core.outFolder + "/moatFeature.txt", 'a'){|out|
        doc = REXML::Document.new
        play = doc.add_element("moat")
        play.add_element("stateVec").add_text baseMaker.getStateVec(eventData["player"])
        play.add_element("answer").add_text "1"
        play.add_element("turn").add_text (core.currentTurn / 2).to_i.to_s
        play.add_element("isSente").add_text ((core.currentTurn + 1) % 2).to_s
        play.add_element("filename").add_text core.fileName
        play.add_element("attackCard").add_text @attackCard.to_s
        out.write(doc.to_s)
        out.write("\n")
      }
      @attackCard = nil
    elsif @attackCard
      File.open(core.outFolder + "/moatFeature.txt", 'a'){|out|
        doc = REXML::Document.new
        play = doc.add_element("moat")
        play.add_element("stateVec").add_text baseMaker.getStateVec(eventData["player"])
        play.add_element("answer").add_text "0"
        play.add_element("turn").add_text (core.currentTurn / 2).to_i.to_s
        play.add_element("isSente").add_text ((core.currentTurn + 1) % 2).to_s
        play.add_element("filename").add_text core.fileName
        play.add_element("attackCard").add_text @attackCard.to_s
        out.write(doc.to_s)
        out.write("\n")
      }
      @attackCard = nil
    end
  end

end
