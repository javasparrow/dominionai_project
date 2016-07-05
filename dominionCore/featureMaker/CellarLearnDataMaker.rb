load("featureMaker/BaseLearnDataMaker.rb")
load(File.expand_path(__FILE__).sub(/[^\/]+$/,'')[0...-1].sub(/[^\/]+$/,'')[0...-1].sub(/[^\/]+$/,'') + "util/cardData.rb")

#購入の教師データを作成
require 'rexml/document'

class CellarLearnDataMaker

  def initialize
    @trashId = nil
    @cardData = CardData.new()
    @discardStack = nil
  end

  def eventCallback(eventData, core)
    if(core.currentPlayer != core.winner)
      return
    end

    baseMaker = BaseLearnDataMaker.new(core)
    if eventData["type"] == "play" && @cardData.getCardByNum(eventData["cardId"]).name == "Cellar"
      @discardStack = []
      @stateVec = baseMaker.getStateVec(core.currentPlayer)
      @candidates = []
      core.playerData[core.currentPlayer].handArea.each{|id, num|
        num.times{
          @candidates << id
        }
      }
    else
      if core.lastPlay && core.lastPlay.name == "Cellar" && @discardStack
        if eventData["type"] == "discard"
          @discardStack << eventData["cards"][0].id
        else
          File.open(core.outFolder + "/cellarFeature.txt", 'a'){|out|
            doc = REXML::Document.new
            play = doc.add_element("cellar")
            play.add_element("stateVec").add_text @stateVec
            if @discardStack.length == 0
              play.add_element("answer").add_text "0"
            else
              play.add_element("answer").add_text @discardStack.join(",")
            end
            play.add_element("turn").add_text (core.currentTurn / 2).to_i.to_s
            play.add_element("isSente").add_text ((core.currentTurn + 1) % 2).to_s
            play.add_element("candidates").add_text @candidates.join(",")
            play.add_element("filename").add_text core.fileName

            out.write(doc.to_s)
            out.write("\n")
            @discardStack = nil
          }
        end
      end
    end
  end

end
