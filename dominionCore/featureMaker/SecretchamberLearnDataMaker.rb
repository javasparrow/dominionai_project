load("featureMaker/BaseLearnDataMaker.rb")
load(File.expand_path(__FILE__).sub(/[^\/]+$/,'')[0...-1].sub(/[^\/]+$/,'')[0...-1].sub(/[^\/]+$/,'') + "util/cardData.rb")

#購入の教師データを作成
require 'rexml/document'

class SecretchamberLearnDataMaker

  def initialize
    @attackCard = nil
    @secretFlag = false
    @placeStack = []
    @discardStack = []
    @cardData = CardData.new()
  end

  def eventCallback(eventData, core)


    baseMaker = BaseLearnDataMaker.new(core)

    if(core.currentPlayer == core.winner)
      # play
      if eventData["type"] == "play" && @cardData.getCardByNum(eventData["cardId"]).name == "Secret Chamber"
        @secretFlag = true
        @discardStack = []
        @stateVec = baseMaker.getStateVec(core.currentPlayer)
        @candidates = []
        core.playerData[core.currentPlayer].handArea.each{|id, num|
          num.times{
            @candidates << id
          }
        }
      elsif @secretFlag && eventData["type"] == "discard"
        @discardStack << eventData["cards"][0].id
      elsif @secretFlag
        File.open(core.outFolder + "/secretchamberFeature.txt", 'a'){|out|
          doc = REXML::Document.new
          play = doc.add_element("secretchamber")
          play.add_element("stateVec").add_text @stateVec
          play.add_element("answer").add_text @discardStack.join(",")
          play.add_element("turn").add_text (core.currentTurn / 2).to_i.to_s
          play.add_element("isSente").add_text (core.currentTurn % 2).to_s
          play.add_element("candidates").add_text @candidates.join(",")
          play.add_element("filename").add_text core.fileName
          play.add_element("otherFlag").add_text "2"

          out.write(doc.to_s)
          out.write("\n")
        }
        @discardStack = []
        @secretFlag = false
      end
    end

    moatPlayer = core.getOpponent(core.currentPlayer)

    # reactions
    if eventData["type"] == "play" && @cardData.getCardByNum(eventData["cardId"]).isAttack
      if moatPlayer.handArea.keys.include?(@cardData.getCard("Secret Chamber").id)
        @stateVec = baseMaker.getStateVec(moatPlayer.name)
        @attackCard = eventData["cardId"]
      end
    elsif eventData["type"] == "reaction" && @cardData.getCardByNum(eventData["cardId"]).name == "Secret Chamber"
      # 堀無限公開
      if !@attackCard
        return
      end
      File.open(core.outFolder + "/secretchamberFeature.txt", 'a'){|out|
        doc = REXML::Document.new
        play = doc.add_element("secretchamber")
        play.add_element("stateVec").add_text @stateVec
        play.add_element("answer").add_text "1"
        play.add_element("turn").add_text (core.currentTurn / 2).to_i.to_s
        play.add_element("isSente").add_text (core.currentTurn % 2).to_s
        play.add_element("filename").add_text core.fileName
        play.add_element("attackCard").add_text @attackCard.to_s
        play.add_element("otherFlag").add_text "0"
        out.write(doc.to_s)
        out.write("\n")
      }
      @placeStack = []
    elsif eventData["type"] == "placetop" && @attackCard
      if @placeStack.length == 0
        @stateVec = baseMaker.getStateVec(moatPlayer.name)
        @candidates = []
        moatPlayer.handArea.each{|id, num|
          num.times{
            @candidates << id
          }
        }
      end
      if @placeStack.length < 2
        @placeStack << eventData["cardId"]
      end
    elsif @attackCard && (eventData["type"] == "play" || eventData["type"] == "switch_phase")
      if @placeStack.length != 0
        #カード戻し
        File.open(core.outFolder + "/secretchamberFeature.txt", 'a'){|out|
          doc = REXML::Document.new
          play = doc.add_element("secretchamber")
          play.add_element("stateVec").add_text @stateVec
          play.add_element("answer").add_text @placeStack.join(",")
          play.add_element("turn").add_text (core.currentTurn / 2).to_i.to_s
          play.add_element("isSente").add_text (core.currentTurn % 2).to_s
          play.add_element("filename").add_text core.fileName
          play.add_element("attackCard").add_text @attackCard.to_s
          play.add_element("candidates").add_text @candidates.join(",")
          play.add_element("otherFlag").add_text "1"
          out.write(doc.to_s)
          out.write("\n")
        }
        @attackCard = nil
        @placeStack = []
      else
        #公開されなかった
        File.open(core.outFolder + "/seacretchamberFeature.txt", 'a'){|out|
          doc = REXML::Document.new
          play = doc.add_element("secretchamber")
          play.add_element("stateVec").add_text @stateVec
          play.add_element("answer").add_text "0"
          play.add_element("turn").add_text (core.currentTurn / 2).to_i.to_s
          play.add_element("isSente").add_text (core.currentTurn % 2).to_s
          play.add_element("filename").add_text core.fileName
          play.add_element("attackCard").add_text @attackCard.to_s
          play.add_element("otherFlag").add_text "0"
          out.write(doc.to_s)
          out.write("\n")
        }
        @attackCard = nil
      end
    end
  end

end
