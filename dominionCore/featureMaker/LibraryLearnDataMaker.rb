load("featureMaker/BaseLearnDataMaker.rb")
load(File.expand_path(__FILE__).sub(/[^\/]+$/,'')[0...-1].sub(/[^\/]+$/,'')[0...-1].sub(/[^\/]+$/,'') + "util/cardData.rb")

#購入の教師データを作成
require 'rexml/document'

class LibraryLearnDataMaker

  def initialize
    @cardData = CardData.new()
  end

  def eventCallback(eventData, core)
    if(core.currentPlayer != core.winner)
      return
    end

    baseMaker = BaseLearnDataMaker.new(core)
    if eventData["type"] == "movecardtohand" && core.lastPlay && core.lastPlay.name == "Library"
      if @cardData.getCardByNum(eventData["cardId"]).isAction
        File.open(core.outFolder + "/libraryFeature.txt", 'a'){|out|
          doc = REXML::Document.new
          play = doc.add_element("library")
          play.add_element("stateVec").add_text baseMaker.getStateVec(core.currentPlayer)
          play.add_element("answer").add_text "0"
          play.add_element("revealCard").add_text eventData["cardId"].to_s
          play.add_element("turn").add_text (core.currentTurn / 2).to_i.to_s
          play.add_element("isSente").add_text ((core.currentTurn + 1) % 2).to_s
          play.add_element("action").add_text core.currentAction.to_s
          play.add_element("filename").add_text core.fileName
          out.write(doc.to_s)
          out.write("\n")
        }
      end
    end
    if eventData["type"] == "discard" && core.lastPlay && core.lastPlay.name == "Library"
      card = eventData["cards"][0]
      if eventData["handcount"] != 7
        File.open(core.outFolder + "/libraryFeature.txt", 'a'){|out|
          doc = REXML::Document.new
          play = doc.add_element("library")
          play.add_element("stateVec").add_text baseMaker.getStateVec(core.currentPlayer)
          play.add_element("answer").add_text "1"
          play.add_element("revealCard").add_text card.id.to_s
          play.add_element("turn").add_text (core.currentTurn / 2).to_i.to_s
          play.add_element("isSente").add_text ((core.currentTurn + 1) % 2).to_s
          play.add_element("action").add_text core.currentAction.to_s
          play.add_element("filename").add_text core.fileName
          out.write(doc.to_s)
          out.write("\n")
        }
      end
    end
  end

end
