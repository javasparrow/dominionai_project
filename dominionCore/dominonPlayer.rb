load(File.expand_path(__FILE__).sub(/[^\/]+$/,'')[0...-1].sub(/[^\/]+$/,'') + "util/cardData.rb")

class DominionPlayer
	attr_accessor :deckArea, :discardArea, :handArea, :playArea, :revealArea, :name

	def initialize(name)
		@cardData = CardData.new()
		@deckArea = {}
		@discardArea = {}
		@handArea = {}
		@playArea = {}
		@revealArea = {}
		@name = name
	end

	def getName
		@name
	end

	#カードを捨て札に獲得
	# @param [Card] card 獲得したカード
	def gainCard(card)
		addCardToArea(@discardArea, card)
	end

	# 李シャッフルする
	def reshuffle
		mergeArea(@discardArea, @deckArea)
	end

	# クリーンアップ
	def cleanup
		mergeArea(@handArea, @discardArea)
		mergeArea(@playArea, @discardArea)
		puts @handArea

	end

	def drawCard(card)
		moveCard(@deckArea, @handArea, card)
		puts @handArea
	end

	def playCard(card)
		moveCard(@handArea, @playArea, card)
	end

	def getTotalCard
		result = {}
		mergeArea(@handArea, result)
		mergeArea(@playArea, result)
		mergeArea(@deckArea, result)
		mergeArea(@discardArea, result)
		mergeArea(@revealArea, result)
		return result
	end

	def discardDeck
		mergeArea(@deckArea, @discardArea)
	end

	def trashCardFromHand(card)
		removeCardFromArea(@handArea, card)
	end

	def trashCardFromPlay(card)
		removeCardFromArea(@playArea, card)
	end

	def trashCardFromReveal(card)
		removeCardFromArea(@revealArea, card)
	end

	def trashCardFromDeck(card)
		removeCardFromArea(@deckArea, card)
	end

	def discardFromReveal(card)
		moveCard(@revealArea, @discardArea, card)
	end

	def discardFromDeck(card)
		moveCard(@deckArea, @discardArea, card)
	end

	def discardFromHand(card)
		moveCard(@handArea, @discardArea, card)
	end

	def revealCardFromDeck(card)
		moveCard(@deckArea, @revealArea, card)
	end

	def putHandFromReveal(card)
		moveCard(@revealArea, @handArea, card)
	end

	def putDeckFromHand(card)
		moveCard(@handArea, @deckArea, card)
	end

	def putDeckFromReveal(card)
		moveCard(@revealArea, @deckArea, card)
	end

	def addCardToPlay(card)
		addCardToArea(@playArea, card)
	end

	def addCardToHand(card)
		addCardToArea(@handArea, card)
	end

	def addCardToDeck(card)
		addCardToArea(@deckArea, card)
	end

	def countDeck(card)
		return @deckArea[card.id]
	end

	def countDeckTotal()
		total = 0
		@deckArea.each{|card, num|
			total += num
		}
		return total
	end

	def countHandTotal()
		total = 0
		@handArea.each{|card, num|
			total += num
		}
		puts @handArea
		return total
	end

	def haveActionInHand()
		@handArea.each{|id, num|
			if(@cardData.getCardByNum(id).isAction && num > 0)
        return true
      end
		}
    return false
  end

	private

	#エリアをfromからdistにマージする
	def mergeArea(areaFrom, areaDist)
		areaFrom.each{|id, num|
			if areaDist[id]
				areaDist[id] = areaDist[id] + num
			else
				areaDist[id] = num
			end
			areaFrom.delete(id)
		}
	end

	#カードをエリアに追加
	def addCardToArea(area, card)
		if area[card.id]
			area[card.id] = area[card.id] + 1
		else
			area[card.id] = 1
		end
	end

	#カードをエリアから消す
	def removeCardFromArea(area, card)
		if area[card.id] && area[card.id] > 0
			area[card.id] = area[card.id] - 1
		else
			raise "no card found in area remove"
		end
	end

	#カードを移動
	def moveCard(areaFrom, areaDist, card)
		removeCardFromArea(areaFrom, card)
		addCardToArea(areaDist, card)
	end

end
