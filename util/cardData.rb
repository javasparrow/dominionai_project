# -*- coding: utf-8 -*-

class Card
  attr_accessor :name, :coin, :buy, :num, :pilenum, :cost, :isAction

  def initialize(name, coin, buy, num, pilenum, cost, isAction)
    @name = name
    @coin = coin
    @buy = buy
    @num = num
    @pilenum = pilenum
    @cost = cost
    @isAction = isAction
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
        

        @data.store(data[3], Card.new(data[3], data[9].to_i + data[14].to_i, data[13].to_i, data[0].to_i, pilenum, data[5].to_i, isAction))
      }
    }
  end

  def getCard(name)
    @data[name]
  end
  
  def getCardByNum(num)
      @data.each_value{|card|
          if(card.num == num)
              return card
          end
      }
      nil
  end
  
end

