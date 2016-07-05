# -*- coding: utf-8 -*-

class Card
  attr_accessor :name, :coin, :buy, :id, :pilenum, :cost, :isAction, :isTreasure, :isVictory, :action, :isAttack

  def initialize(name, coin, buy, id, pilenum, cost, isAction, isTreasure, isVictory, action, isAttack)
    @name = name
    @coin = coin
    @buy = buy
    @id = id
    @pilenum = pilenum
    @cost = cost
    @isAction = isAction
    @isTreasure = isTreasure
    @isVictory = isVictory
    @action = action
    @isAttack = isAttack
  end
end

class CardData

  def initialize()

    cuDir = File.expand_path(__FILE__).sub(/[^\/]+$/,'')

    @data = Hash.new

    File.open(cuDir + "/" + "cardData.csv", 'r') {|file|
      file.each_line{|line|
        data = line.split(",")
        pilenum = 10
        if(data[8].include?("勝利点"))
          pilenum = 8
        elsif(data[1] == "銅貨")
          pilenum = 46
        elsif(data[1] == "銀貨")
          pilenum = 30
        elsif(data[1] == "金貨")
          pilenum = 20
        end
	isAction = false
	if(data[8].include?("アクション"))
	    isAction = true
	end
  isTreasure = false
  if(data[8].include?("財宝"))
      isTreasure = true
  end
  isVictory = false
  if(data[8].include?("勝利点"))
      isVictory = true
  end
  if(data[8].include?("アタック"))
      isAttack = true
  end


        @data.store(data[3], Card.new(data[3], data[9].to_i + data[14].to_i, data[13].to_i, data[0].to_i, pilenum, data[5].to_i, isAction, isTreasure, isVictory, data[12].to_i, isAttack))
      }
    }
  end

  def getCard(name)
    @data[name]
  end

  def getCardByNum(num)
      @data.each_value{|card|
          if(card.id == num)
              return card
          end
      }
      nil
  end

end
