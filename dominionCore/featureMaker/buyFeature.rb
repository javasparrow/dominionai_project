load("featureMaker/BaseLearnDataMaker.rb")
#購入の教師データを作成
require 'rexml/document'

class BuyFeatureMaker

  def initialize
    @buyCardIds = []
  end

  def eventCallback(eventData, core)
    if(core.currentPlayer != core.winner)
      return
    end

    baseMaker = BaseLearnDataMaker.new(core)
    if(eventData["type"] == "buy")
      if(@buyCardIds.length == 0)
        @currentCoin = core.currentCoin
        @currentBuy = core.currentBuy
        @stateVec = baseMaker.getStateVec(core.currentPlayer)
      end
      @buyCardIds << eventData["cardId"]
    end
    if(eventData["type"] == "switch_phase" && eventData["phase"] == "cleanup")
      File.open(core.outFolder + "/buyFeature.txt", 'a'){|out|
        doc = REXML::Document.new
        gain = doc.add_element("gain")
        if @stateVec
          gain.add_element("stateVec").add_text @stateVec
        else
          gain.add_element("stateVec").add_text baseMaker.getStateVec(core.currentPlayer)
        end
        if @buyCardIds.length == 0
          gain.add_element("answer").add_text "0"
        else
          gain.add_element("answer").add_text @buyCardIds.join(",")
        end
        gain.add_element("turn").add_text (core.currentTurn / 2).to_i.to_s
        gain.add_element("isSente").add_text ((core.currentTurn + 1) % 2).to_s
        candidates = ""
        (0..BaseLearnDataMaker::MAX_CARD_ID).each{|id|
          if core.supply[id]
            candidates += core.supply[id].to_s + ","
          else
            candidates += "0,"
          end
        }
        gain.add_element("candidates").add_text candidates[0...-1]
        if @currentCoin
          gain.add_element("coin").add_text @currentCoin.to_s
        else
          gain.add_element("coin").add_text core.currentCoin.to_s
        end

        if @currentBuy
          gain.add_element("buy").add_text @currentBuy.to_s
        else
          gain.add_element("buy").add_text core.currentBuy.to_s
        end

        gain.add_element("minusCost").add_text core.discount.to_s
        gain.add_element("filename").add_text core.fileName

        out.write(doc.to_s)
        out.write("\n")
      }

      @buyCardIds = []
      @currentCoin = nil
      @currentBuy = nil
      @stateVec = nil
    end
  end

end
