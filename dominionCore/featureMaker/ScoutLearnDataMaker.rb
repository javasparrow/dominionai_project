load("featureMaker/BaseLearnDataMaker.rb")
load(File.expand_path(__FILE__).sub(/[^\/]+$/,'')[0...-1].sub(/[^\/]+$/,'')[0...-1].sub(/[^\/]+$/,'') + "util/cardData.rb")

#購入の教師データを作成
require 'rexml/document'

class ScoutLearnDataMaker

  def initialize
    @scoutStack = []
    @cardData = CardData.new()
  end

  def eventCallback(eventData, core)
    if(core.currentPlayer != core.winner)
      return
    end

    baseMaker = BaseLearnDataMaker.new(core)
    if(eventData["type"] == "placetop" && core.lastPlay.name == "Scout")
      if @scoutStack.length == 0
        @stateVec = baseMaker.getStateVec(eventData["player"])
      end
      @scoutStack << eventData["cardId"]
    elsif @scoutStack.length != 0
      File.open(core.outFolder + "/scoutFeature.txt", 'a'){|out|
        doc = REXML::Document.new
        play = doc.add_element("scout")
        play.add_element("stateVec").add_text @stateVec
        play.add_element("answer").add_text @scoutStack.join(",")
        play.add_element("turn").add_text (core.currentTurn / 2).to_i.to_s
        play.add_element("isSente").add_text ((core.currentTurn + 1) % 2).to_s
        play.add_element("candidates").add_text @scoutStack.join(",")
        play.add_element("action").add_text core.currentAction.to_s
        play.add_element("filename").add_text core.fileName

        out.write(doc.to_s)
        out.write("\n")
      }
      @scoutStack = []
    end
  end

end
