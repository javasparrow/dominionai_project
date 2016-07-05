load("featureMaker/BaseLearnDataMaker.rb")
load(File.expand_path(__FILE__).sub(/[^\/]+$/,'')[0...-1].sub(/[^\/]+$/,'')[0...-1].sub(/[^\/]+$/,'') + "util/cardData.rb")

#購入の教師データを作成
require 'rexml/document'

class ChapelLearnDataMaker

  def initialize
    @chapelFlag = false
    @cardData = CardData.new()
  end

  def eventCallback(eventData, core)
    if(core.currentPlayer != core.winner)
      return
    end

    baseMaker = BaseLearnDataMaker.new(core)
    if eventData["type"] == "play" && @cardData.getCardByNum(eventData["cardId"]).name == "Chapel"
      @chapelFlag = true
    elsif eventData["type"] == "trash" && core.lastPlay.name == "Chapel"
      File.open(core.outFolder + "/chapelFeature.txt", 'a'){|out|
        doc = REXML::Document.new
        play = doc.add_element("chapel")
        play.add_element("stateVec").add_text baseMaker.getStateVec(core.currentPlayer)
        play.add_element("answer").add_text eventData["cards"].map{|card| card.id}.join(",")
        play.add_element("turn").add_text (core.currentTurn / 2).to_i.to_s
        play.add_element("isSente").add_text ((core.currentTurn + 1) % 2).to_s
        candidates = []
        core.playerData[core.currentPlayer].handArea.each{|id, num|
          num.times{
            candidates << id
          }
        }
        play.add_element("candidates").add_text candidates.join(",")
        play.add_element("filename").add_text core.fileName

        out.write(doc.to_s)
        out.write("\n")
      }
      @chapelFlag = false
    elsif @chapelFlag
      File.open(core.outFolder + "/chapelFeature.txt", 'a'){|out|
        doc = REXML::Document.new
        play = doc.add_element("chapel")
        play.add_element("stateVec").add_text baseMaker.getStateVec(core.currentPlayer)
        play.add_element("answer").add_text "0"
        play.add_element("turn").add_text (core.currentTurn / 2).to_i.to_s
        play.add_element("isSente").add_text ((core.currentTurn + 1) % 2).to_s
        candidates = []
        core.playerData[core.currentPlayer].handArea.each{|id, num|
          num.times{
            candidates << id
          }
        }
        play.add_element("candidates").add_text candidates.join(",")
        play.add_element("filename").add_text core.fileName

        out.write(doc.to_s)
        out.write("\n")
      }
      @chapelFlag = false
    end
  end

end
