load("featureMaker/BaseLearnDataMaker.rb")
load(File.expand_path(__FILE__).sub(/[^\/]+$/,'')[0...-1].sub(/[^\/]+$/,'')[0...-1].sub(/[^\/]+$/,'') + "util/cardData.rb")

#購入の教師データを作成
require 'rexml/document'

class TorturerLearnDataMaker

  def initialize
    @discardStack = []
  end

  def eventCallback(eventData, core)
    # 公開している人でない人の判断であるため逆になる
    if(core.currentPlayer == core.winner)
      return
    end

    baseMaker = BaseLearnDataMaker.new(core)
    if(eventData["type"] == "discard" && core.lastPlay.name == "Torturer")
      if @discardStack.length == 0
        @stateVec = baseMaker.getStateVec(eventData["player"])
        @candidates = []
        core.playerData[eventData["player"]].handArea.each{|id, num|
          num.times{
            @candidates << id
          }
        }
      end
      @discardStack << eventData["cards"][0].id
    elsif eventData["type"] == "gain" && core.lastPlay.name == "Torturer"
      File.open(core.outFolder + "/torturerFeature.txt", 'a'){|out|
        doc = REXML::Document.new
        play = doc.add_element("torturer")
        play.add_element("stateVec").add_text baseMaker.getStateVec(eventData["player"])
        play.add_element("answer").add_text "0"
        play.add_element("turn").add_text (core.currentTurn / 2).to_i.to_s
        play.add_element("isSente").add_text (core.currentTurn % 2).to_s
        candidates = []
        core.playerData[eventData["player"]].handArea.each{|id, num|
          num.times{
            candidates << id
          }
        }
        play.add_element("candidates").add_text candidates.join(",")
        play.add_element("filename").add_text core.fileName

        out.write(doc.to_s)
        out.write("\n")
      }
    elsif @discardStack.length > 0
      File.open(core.outFolder + "/torturerFeature.txt", 'a'){|out|
        doc = REXML::Document.new
        play = doc.add_element("torturer")
        play.add_element("stateVec").add_text @stateVec
        play.add_element("answer").add_text @discardStack.join(",")
        play.add_element("turn").add_text (core.currentTurn / 2).to_i.to_s
        play.add_element("isSente").add_text (core.currentTurn % 2).to_s
        play.add_element("candidates").add_text @candidates.join(",")
        play.add_element("filename").add_text core.fileName

        out.write(doc.to_s)
        out.write("\n")
      }
      @discardStack = []
    end
  end

end
