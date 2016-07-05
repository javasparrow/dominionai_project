load("featureMaker/BaseLearnDataMaker.rb")
load(File.expand_path(__FILE__).sub(/[^\/]+$/,'')[0...-1].sub(/[^\/]+$/,'')[0...-1].sub(/[^\/]+$/,'') + "util/cardData.rb")

#購入の教師データを作成
require 'rexml/document'

class ChancellorLearnDataMaker

  def initialize
    @chancellorFlag = false
    @cardData = CardData.new()
  end

  def eventCallback(eventData, core)
    if(core.currentPlayer != core.winner)
      return
    end

    baseMaker = BaseLearnDataMaker.new(core)
    if eventData["type"] == "play" && @cardData.getCardByNum(eventData["cardId"]).name == "Chancellor"
      @chancellorFlag = true
    elsif eventData["type"] == "movedeckintodiscards" && core.lastPlay.name == "Chancellor"
      File.open(core.outFolder + "/chancellorFeature.txt", 'a'){|out|
        doc = REXML::Document.new
        play = doc.add_element("chancellor")
        play.add_element("stateVec").add_text baseMaker.getStateVec(core.currentPlayer)
        play.add_element("answer").add_text "1"
        play.add_element("turn").add_text (core.currentTurn / 2).to_i.to_s
        play.add_element("isSente").add_text ((core.currentTurn + 1) % 2).to_s
        play.add_element("filename").add_text core.fileName

        out.write(doc.to_s)
        out.write("\n")
      }
      @chancellorFlag = false
    elsif @chancellorFlag
      File.open(core.outFolder + "/chancellorFeature.txt", 'a'){|out|
        doc = REXML::Document.new
        play = doc.add_element("chancellor")
        play.add_element("stateVec").add_text baseMaker.getStateVec(core.currentPlayer)
        play.add_element("answer").add_text "0"
        play.add_element("turn").add_text (core.currentTurn / 2).to_i.to_s
        play.add_element("isSente").add_text ((core.currentTurn + 1) % 2).to_s
        play.add_element("filename").add_text core.fileName

        out.write(doc.to_s)
        out.write("\n")
      }
      @chancellorFlag = false
    end
  end

end
