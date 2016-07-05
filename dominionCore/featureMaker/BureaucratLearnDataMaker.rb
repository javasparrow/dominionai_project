load("featureMaker/BaseLearnDataMaker.rb")
load(File.expand_path(__FILE__).sub(/[^\/]+$/,'')[0...-1].sub(/[^\/]+$/,'')[0...-1].sub(/[^\/]+$/,'') + "util/cardData.rb")

#購入の教師データを作成
require 'rexml/document'

class BureaucratLearnDataMaker

  def initialize
    @cardData = CardData.new()
  end

  def eventCallback(eventData, core)
    # 公開している人でない人の判断であるため逆になる
    if(core.currentPlayer == core.winner)
      return
    end

    baseMaker = BaseLearnDataMaker.new(core)
    if(eventData["type"] == "placetop" && core.lastPlay.name == "Bureaucrat")
      File.open(core.outFolder + "/BureaucratFeature.txt", 'a'){|out|
        doc = REXML::Document.new
        play = doc.add_element("bureaucrat")
        play.add_element("stateVec").add_text baseMaker.getStateVec(eventData["player"])
        play.add_element("answer").add_text eventData["cardId"].to_s
        play.add_element("turn").add_text (core.currentTurn / 2).to_i.to_s
        play.add_element("isSente").add_text (core.currentTurn % 2).to_s
        candidates = []
        core.playerData[eventData["player"]].handArea.each{|id, num|
          if num > 0 && @cardData.getCardByNum(id).isVictory
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
      @discardStack = []
    end
  end

end
