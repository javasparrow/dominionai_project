load("featureMaker/BaseLearnDataMaker.rb")
load(File.expand_path(__FILE__).sub(/[^\/]+$/,'')[0...-1].sub(/[^\/]+$/,'')[0...-1].sub(/[^\/]+$/,'') + "util/cardData.rb")

#購入の教師データを作成
require 'rexml/document'

class MilitiaLearnDataMaker

  def initialize
    @discardStack = []
  end

  def eventCallback(eventData, core)
    # 公開している人でない人の判断であるため逆になる
    if(core.currentPlayer == core.winner)
      return
    end

    baseMaker = BaseLearnDataMaker.new(core)
    if(eventData["type"] == "discard" && core.lastPlay.name == "Militia")
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
    elsif @discardStack.length > 0
      File.open(core.outFolder + "/militiaFeature.txt", 'a'){|out|
        doc = REXML::Document.new
        play = doc.add_element("militia")
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
