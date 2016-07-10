load(File.expand_path(__FILE__).sub(/[^\/]+$/,'')[0...-1].sub(/[^\/]+$/,'') + "util/cardData.rb")
load("dominonPlayer.rb")

class DominionCore
	attr_accessor :currentCoin, :currentBuy, :currentAction, :playerData, :supply, :currentPlayer,
								:currentTurn, :fileName, :winner, :outFolder, :lastPlay, :currentPhase, :discount,
								:lastReaction, :copperSmithCount


	#各フェーズの管理
	PHASE_END = -1
	PHASE_ACTION = 0
	PHASE_BUY = 1
	PHASE_CLEANUP = 2

	DEBUG_PRINT = false

	def initialize(rawlog, outFolder)

		@fileName = File.basename(rawlog.path)
		@rawlog = rawlog

		@outFolder = outFolder

		# プレイヤーのデータの管理する変数
		# データ構造は [String] player_nameがキーでPlayer型が帰ってくる
		@playerData = Hash.new

		#サプライはカードid, 残り枚数のハッシュ
		@supply = {}

		@lastPlay = nil
		@lastTrash = nil
		@currentCoin = 0
		@currentBuy = 1
		@currentAction = 1
		@currentPlayer = nil
		@currentTurn = 1
		#玉座の間処理用
		@throneStack = Array.new(0)
		#値引き
		@discount = 0
		@firstPlayer = nil
		@finalScore = {}
		@cardData = CardData.new()
		@eventListener = []

	end

	# eventlistenerはlistenerメソッドを定義してね
	# eventCallback(eventData, self)
	# eventの発火は効果が発生する直前とする
	def addEventListener(listener)
		@eventListener << listener
	end

	def getOpponent(playerName)
		@playerData.each{|name, pl|
      if name != playerName
        return pl
      end
    }
	end


	def parseLog(output)
		#add pass text to log
		log = addPass(@rawlog)

		@currentPhase = PHASE_ACTION
		shuffleflag = false

		log.each{|line|

			p @fileName

			if(line.include?("Game Over"))
				@currentPhase = PHASE_END
			end

			if(line.include?(" - cards:"))
				verifyResult(line)
			end

			if(@currentPhase == PHASE_END)
				next
			end

			if(line.include?("moves deck to discards"))
				moveDeckIntoDiscards(line)
			end

			if(line[0..12] == "Supply cards:")
				parseSupply(line[13..-1])
			end

			if(line.index("starting cards:") != nil)
				if(parseStartingDeck(line) == "error")
					puts "error this is not 2 player game"
					break
				end
			end

			if(line == "pass")
				cleanup(nil)
			end

			if(line.include?("reveals"))
				parseReveal(line)
			end

			if(line.include?("on top of deck"))
				parsePlaceTop(line)
			end

			if(line.include?("places cards in hand"))
				parsePutCardInHand(line)
			elsif(line.include?("places ") && line.include?(" in hand"))
				parsePutCardInHand(line)
			end

			if(line.include?("moves") && line.include?("to hand"))
				parseMoveCardInHand(line)
			end

			if(line.index("turn") != nil && line.index("----------") != nil)
				@currentPlayer = line[11..line.index(":") - 1]

				if(@firstPlayer == nil)
					@firstPlayer = @currentPlayer
				end

				@currentTurn = @currentTurn + 1
				if(DEBUG_PRINT)
					puts("Turn#{@currentTurn / 2}")
				end
				@currentCoin = 0
				@currentBuy = 1
				@currentAction = 1
				@discount = 0
				@chamberCount = 0
				@lastPlay = nil
				@lastTrash = nil
				@lastBuy = Array.new(0)
				@copperSmithCount = 0

			end

			if(line.index("plays") != nil)
				if(/\d/.match(line[getLastIndex(line, "-") .. -2]) != nil)
					#TODO generate data
					#if(haveActionInHand() && @currentAction >= 1)
					#	generatePlayActionData(nil)
					#end
					parsePlayTreasure(line)
				else parsePlayAction(line)
				end
			end

			if(line.index("buys") != nil)
				switch_phase(PHASE_BUY)
			end

			if(line.index("gains") != nil)
				if(@currentPhase == PHASE_BUY)
					parseBuy(line)
				else parseGain(line)
				end
			end

			if(line.index("trashes") != nil)
				parseTrash(line)
			end

			if(line.index("draws") != nil)
				#detect cleanup
				if(@currentPhase == PHASE_BUY)

					switch_phase(PHASE_CLEANUP)

					#cleanup
					cleanup(line)

					if(shuffleflag == true)
						reshuffle(line)
						shuffleflag = false
					end
				end
				parseDraw(line)
			end

			if(line.index("shuffles") != nil)
				if(DEBUG_PRINT)
					puts "detect shuffle"
				end
				if(@currentPhase == PHASE_BUY)
					shuffleflag = true
				else
					reshuffle(line)
				end
			end

			if(line.index("discards") != nil)
				parseDiscard(line)
			end

			if(line.index("takes") != nil)
				parseTake(line)
			end

			if(line.include?("receives"))
				parseReceive(line)
			end

			if(line.index("passes") != nil)
				parsePassCard(line)
			end

			if(line.index("names") != nil)
				parseNameCard(line)
			end

			if(line.include?("total victory points"))
				parseScore(line)
			end
			checkMinus
		}

	end

	private

	def checkMinus()
    @supply.each{|sup, cnt|
			if cnt < 0
				puts "supply minus error!"
				puts sup
        raise
			end
		}
  end

	# プレイヤーの初期化.二人戦にのみ対応しているので2人分を登録
	# @param [String] player_name 名前
	# @param [Card[]] starting_deck 初期デッキ
	# @param [int] position 0が一番手1が二番手
	def initPlayer(player_name, starting_deck, position)
		@playerData[player_name] = DominionPlayer.new(player_name, starting_deck)
	end

	def addPass(rawlog)
		lineCnt = 0
		buyflag = false
		log = rawlog.readlines
		resultlog = Array.new(0)

		sepCnt = 0

		log.each{|line|
			if(line.include?(" - resigned"))
				@canVerify = false
			end
			if(line.include?(" - quit"))
				@canVerify = false
			end
			if(line.include?("1st place"))
				@winner = line[11..-2]
			end
			if(line.include?("---"))
				sepCnt = sepCnt + 1
				if(sepCnt > 2)
					if(buyflag == false)
						drawCnt = 0
						rLineCnt = lineCnt - 1
						drawflag = false
						while drawCnt != 5
							rLineCnt = rLineCnt - 1
							if(DEBUG_PRINT)
								puts log[rLineCnt]
								puts rLineCnt
							end
							if(log[rLineCnt].include?("draws"))
								drawCnt = drawCnt + 1 + log[rLineCnt].count(",")
								drawflag = true
								if(drawCnt > 5)
									rLineCnt = rLineCnt + 1
									break
								end
							end
							if(log[rLineCnt].include?("---"))
								drawflag = false
								break
							end
							if(!log[rLineCnt].include?("draws") && !log[rLineCnt].include?("shuffles"))
								if(DEBUG_PRINT)
									puts rLineCnt
									puts lineCnt
									puts resultlog
								end

								rLineCnt = rLineCnt + 1
								drawflag = true
								break
							end
						end
						if(drawflag == true)
							if(resultlog[-(lineCnt - rLineCnt)-1].include?(" - shuffles"))
								resultlog[-(lineCnt - rLineCnt)-1, 0] = "pass"
							else
								resultlog[-(lineCnt - rLineCnt), 0] = "pass"
							end
						end
					end
					buyflag = false
				end
			end
			if(line.include?("buys"))
				buyflag = true
			end
			lineCnt = lineCnt + 1
			resultlog << line
		}

		if(DEBUG_PRINT)
			puts resultlog
		end

		resultlog
	end

	def parseSupply(data)
		data[1..-2].split(", ").each{|card|
			supCard = @cardData.getCard(card)
			@supply[supCard.id] = supCard.pilenum
		}
	end

	def parseStartingDeck(data)

		@playerData[data[0..getLastIndex(data, "-") - 2]] = DominionPlayer.new(data[0..getLastIndex(data, "-") - 2])

		data[data.index(":") + 2..-2].split(", ").each{|card|
			currentCard = @cardData.getCard(card)
			@playerData[data[0..getLastIndex(data, "-") - 2]].gainCard(currentCard)
		}
	end

	def moveDeckIntoDiscards(data)
		player = @playerData[data[0..getLastIndex(data, "-") - 2]]

		eventData = {}
		eventData["type"] = "movedeckintodiscards"
		eventData["player"] = player.getName()
		fireEvents(eventData)

		player.discardDeck
	end

	def cleanup(data)
		if(data == nil)
			player = @playerData[@currentPlayer]
		else
			player = @playerData[data[0..getLastIndex(data, "-") - 2]]
		end

		player.cleanup
	end

	def parsePlaceTop(data)
    player = @playerData[data[0..getLastIndex(data, "-") - 2]]
		currentCard = @cardData.getCard(data[data.index("places") + 7 .. data.index("on top of deck") - 2])

		eventData = {}
		eventData["type"] = "placetop"
		eventData["cardId"] = currentCard.id
		eventData["player"] = player.getName()
		fireEvents(eventData)

    if(@lastPlay.name == "Bureaucrat")
			player.putDeckFromHand(currentCard)
		elsif @lastReaction && @lastReaction.name == "Secret Chamber" && player.countHandTotal != 0 && @chamberCount > 0
			player.putDeckFromHand(currentCard)
			@chamberCount -= 1
		elsif @lastPlay.name == "Courtyard"
			player.putDeckFromHand(currentCard)
		elsif @lastPlay.name == "Scout"
			player.putDeckFromReveal(currentCard)
		end
  end

	def parseMoveCardInHand(data)
    player = @playerData[data[0..getLastIndex(data, "-") - 2]]
		currentCard = @cardData.getCard(data[data.index("moves") + 6..data.index("to hand") - 2])

		eventData = {}
		eventData["type"] = "movecardtohand"
		eventData["cardId"] = currentCard.id
		eventData["player"] = player.getName()
		fireEvents(eventData)

    if(@lastPlay.name == "Library")
			player.drawCard(currentCard)
		end
  end

	def parseReveal(data)
    player = @playerData[data[0..getLastIndex(data, "-") - 2]]

    if(data[getLastIndex(data, "-")..-1].include?("reaction"))
			eventData = {}
			eventData["type"] = "reaction"
			eventData["cardId"] = @cardData.getCard(data[data.index("reaction") + 9..-2]).id
			eventData["player"] = player.getName()
			fireEvents(eventData)
			@lastReaction = @cardData.getCard(data[data.index("reaction") + 9..-2])
			if @lastReaction.name == "Secret Chamber"
				@chamberCount = 2
			end
			return
    end

    if(@lastPlay.name == "Thief")
      data[data.index("reveals") + 9..-2].split(", ").each{|card|
        currentCard = @cardData.getCard(card)
				player.revealCardFromDeck(currentCard)
      }
    elsif(@lastPlay.name == "Adventurer")
      data[data.index("reveals") + 8..-2].split(", ").each{|card|
        currentCard = @cardData.getCard(card)
        if(player.countDeck(currentCard) == 0)
          if(DEBUG_PRINT)
            puts "actual reshuffle is here"
          end
					player.reshuffle
        end
        player.revealCardFromDeck(currentCard)
      }
		elsif @lastPlay.name == "Saboteur"
			data[data.index("reveals") + 8..-2].split(", ").each{|card|
        currentCard = @cardData.getCard(card)
        player.revealCardFromDeck(currentCard)
      }
		elsif @lastPlay.name == "Scout"
			data[data.index("reveals") + 9..-2].split(", ").each{|card|
        currentCard = @cardData.getCard(card)
				player.revealCardFromDeck(currentCard)
      }
		elsif @lastPlay.name == "Tribute"
			data[data.index("reveals") + 9..-2].split(", ").each{|card|
        currentCard = @cardData.getCard(card)
				player.revealCardFromDeck(currentCard)
      }
		elsif @lastPlay.name == "Swindler"
			# すぐに廃棄されるので何もしなくていいっぽい
    end
  end

	def parsePutCardInHand(data)
    player = @playerData[data[0..getLastIndex(data, "-") - 2]]
    if(@lastPlay.name == "Adventurer")
      data[data.index("hand:") + 7..-2].split(", ").each{|card|
        currentCard = @cardData.getCard(card)
        player.putHandFromReveal(currentCard)
      }
		elsif @lastPlay.name == "Scout"
			data[data.index("hand:") + 7..-2].split(", ").each{|card|
        currentCard = @cardData.getCard(card)
        player.putHandFromReveal(currentCard)
      }
		elsif @lastPlay.name == "Wishing Well"
			player.drawCard(@cardData.getCard(data[data.index("places") + 7.. data.index("in hand") - 2]))
    end
  end

	def parsePlayTreasure(data)
    player = @playerData[data[0..getLastIndex(data, "-") - 2]]
		switch_phase(PHASE_BUY)
    playList = data[data.index("plays") + 6 .. -2].split(", ")
    playList.each{|playCard|
      currentCard = @cardData.getCard(playCard[2..-1])
      if(DEBUG_PRINT)
        puts "#{player.getName()} uses #{playCard[2..-1]} num is #{playCard[0]}"
      end
      @currentCoin = @currentCoin + currentCard.coin * playCard[0].to_i
      if(DEBUG_PRINT)
        puts "gain #{currentCard.coin * playCard[0].to_i} coins"
      end
			if currentCard.name == "Copper"
				@currentCoin = @currentCoin + currentCard.coin * playCard[0].to_i * @copperSmithCount
				if @copperSmithCount > 0
					puts "gain #{currentCard.coin * playCard[0].to_i * @copperSmithCount} coins from coppersmith"
				end
			end
      @currentBuy = @currentBuy + currentCard.buy * playCard[0].to_i
      if(DEBUG_PRINT)
        puts "gain #{currentCard.buy * playCard[0].to_i} buy"
      end
			playCard[0].to_i.times{
      	player.playCard(currentCard)
			}
    }
  end

	def parsePlayAction(data)
    player = @playerData[data[0..getLastIndex(data, "-") - 2]]
    pCard = @cardData.getCard(data[data.index("plays") + 6 .. -2])

    if(!pCard.isAction)
      if(DEBUG_PRINT)
        puts "this is treasure!"
      end
      parsePlayTreasure(data.gsub(pCard.name, "1 " + pCard.name))
      return
    end

    if(DEBUG_PRINT)
      puts "#{player.getName()} uses action #{data[data.index("plays") + 6 .. -2]}"
    end

		if pCard.name == "Bridge"
			@discount += 1
		elsif pCard.name == "Conspirator"
			actionNum = 0
			player.playArea.each{|id, num|
				if @cardData.getCardByNum(id).isAction
					actionNum += num
				end
			}
			if actionNum >= 2
				@currentAction += 1
			end
		elsif pCard.name == "Coppersmith"
			@copperSmithCount += 1
		end

		if(@lastPlay != nil && @lastPlay.name == "Throne Room")
			eventData = {}
			eventData["type"] = "throne"
			eventData["cardId"] = pCard.id
			eventData["player"] = player.getName()
			fireEvents(eventData)

      player.playCard(pCard)
      @throneStack.push(pCard.id)
		else
      #玉座二回目
      if(@throneStack.include?(pCard.id))
        @throneStack.delete_at(@throneStack.find_index(pCard.id))
        #玉座祝宴の特殊処理
        if(pCard.name == "Feast")
          player.addCardToPlay(pCard)
        end
      else
				eventData = {}
				eventData["type"] = "play"
				eventData["cardId"] = pCard.id
				eventData["player"] = player.getName()
				fireEvents(eventData)

        @currentAction = @currentAction - 1
				if(DEBUG_PRINT)
					puts "action is #{@currentAction}"
				end
				if(@currentAction < 0)
          puts "action minus error"
          raise
        end
        player.playCard(pCard)
			end
    end

		@currentCoin = @currentCoin + pCard.coin
    if(DEBUG_PRINT)
      puts "gain #{pCard.coin} coins"
    end
    @currentBuy = @currentBuy + pCard.buy
    if(DEBUG_PRINT)
      puts "gain #{pCard.buy} buy"
    end
    @currentAction = @currentAction + pCard.action

    @lastPlay = pCard
		@lastReaction = nil

    if(pCard.name == "Throne Room")
      if(player.haveActionInHand() == false)
        @lastPlay = nil
        if(DEBUG_PRINT)
          puts "uses throne but have no action"
        end
      end
    end
  end

	def parseBuy(data)

		player = @playerData[data[0..getLastIndex(data, "-") - 2]]
    gainCard = @cardData.getCard(data[data.index("gains") + 6 .. -2])

		eventData = {}
		eventData["type"] = "buy"
		eventData["cardId"] = gainCard.id
		eventData["player"] = player.getName()
		fireEvents(eventData)

		player.gainCard(gainCard)
		@supply[gainCard.id] = @supply[gainCard.id] - 1
		@currentBuy -= 1
		if (gainCard.cost - @discount > 0)
			@currentCoin -= (gainCard.cost - @discount)
		end
    if(DEBUG_PRINT)
      puts "#{player.getName()} buys #{gainCard.name} coin is #{@currentCoin} buy is #{@currentBuy}"
    end
		if @currentBuy < 0
			puts "buy minus error"
			raise
		end
		if @currentCoin < 0
			puts "coin minus error"
			raise
		end
  end

	def parseGain(data)
    player = @playerData[data[0..getLastIndex(data, "-") - 2]]
    gainCard = @cardData.getCard(data[data.index("gains") + 6 .. -2])

		eventData = {}
		eventData["type"] = "gain"
		eventData["cardId"] = gainCard.id
		eventData["player"] = player.getName()
		fireEvents(eventData)

    if(@lastPlay.name == "Mine")
      player.addCardToHand(gainCard)
      @supply[gainCard.id] = @supply[gainCard.id] - 1
    elsif @lastPlay.name == "Thief"
      player.gainCard(gainCard)
    elsif(@lastPlay.name == "Bureaucrat")
      player.addCardToDeck(gainCard)
      @supply[gainCard.id] = @supply[gainCard.id] - 1
		elsif(@lastPlay.name == "Trading Post")
      player.addCardToHand(gainCard)
      @supply[gainCard.id] = @supply[gainCard.id] - 1
		elsif @lastPlay.name == "Torturer"
			player.addCardToHand(gainCard)
      @supply[gainCard.id] = @supply[gainCard.id] - 1
		elsif @lastPlay.name == "Ironworks"
			if gainCard.isAction
				@currentAction += 1
			end
			if gainCard.isTreasure
				@currentCoin += 1
			end
			player.gainCard(gainCard)
      @supply[gainCard.id] = @supply[gainCard.id] - 1
    else
      player.gainCard(gainCard)
      @supply[gainCard.id] = @supply[gainCard.id] - 1
    end
    if(DEBUG_PRINT)
      puts "#{player.getName()} gains #{gainCard.name}"
    end
  end

	def parseTrash(data)
    player = @playerData[data[0..getLastIndex(data, "-") - 2]]
		cards = data[data.index("trashes") + 8..-2].split(", ").map { |card| @cardData.getCard(card)}

		eventData = {}
		eventData["type"] = "trash"
		eventData["cards"] = cards
		eventData["player"] = player.getName()
		fireEvents(eventData)

    cards.each{|currentCard|
      if(@lastPlay.name == "Moneylender" && currentCard.name == "Copper")
        @currentCoin = @currentCoin + 3
        if(DEBUG_PRINT)
          puts "Moneylender generates 3coins"
        end
      end
      if(DEBUG_PRINT)
        puts "#{player.getName()} trashes #{currentCard.name}"
      end
      if(currentCard.name == "Feast" && @lastPlay.name == "Feast")
        player.trashCardFromPlay(currentCard)
			elsif currentCard.name == "Mining Village" && @lastPlay.name == "Mining Village"
			  player.trashCardFromPlay(currentCard)
				@currentCoin += 2
      elsif(@lastPlay.name == "Thief")
        player.trashCardFromReveal(currentCard)
			elsif @lastPlay.name == "Swindler"
				player.trashCardFromDeck(currentCard)
			elsif @lastPlay.name == "Saboteur"
				player.trashCardFromReveal(currentCard)
      else
        player.trashCardFromHand(currentCard)
      end
    }
  end

	def reshuffle(data)
    #adventurer has bug in goko
    #when we use adventurer and it causes reshuffle, the timing of reshuffle of log become strange

    if(@lastPlay != nil && @lastPlay.name == "Adventurer" && @currentPhase == PHASE_ACTION)
      if(DEBUG_PRINT)
        puts "adventurer bug shuffle"
      end
      #return
    end

    player = @playerData[data[0..getLastIndex(data, "-") - 2]]
		player.reshuffle()
    if(DEBUG_PRINT)
      puts "reshuffle"
    end
  end

	def parseDiscard(data)
    player = @playerData[data[0..getLastIndex(data, "-") - 2]]
    handCount = 0

    #check library
    if(@lastPlay.name == "Library")
      handCount = player.countHandTotal
      if(player.countDeckTotal == 0)
        handCount = 7
      end
    end

    data = data.delete(":")
		cards = data[data.index("discards") + 9..-2].split(", ").map { |card| @cardData.getCard(card) }

		eventData = {}
		eventData["type"] = "discard"
		eventData["cards"] = cards
		eventData["player"] = player.getName()
		eventData["handcount"] = handCount
		fireEvents(eventData)

    cards.each{|currentCard|
      if(@lastPlay.name == "Thief")
        player.discardFromReveal(currentCard)
      elsif(@lastPlay.name == "Spy")
        player.discardFromDeck(currentCard)
      elsif(@lastPlay.name == "Adventurer")
        player.discardFromReveal(currentCard)
			elsif @lastPlay.name == "Baron"
				player.discardFromHand(currentCard)
				@currentCoin += 4
			elsif @lastPlay.name == "Saboteur"
				player.discardFromReveal(currentCard)
			elsif @lastPlay.name == "Secret Chamber"
				player.discardFromHand(currentCard)
				@currentCoin += 1
			elsif @lastPlay.name == "Tribute"
				player.discardFromReveal(currentCard)
      elsif(@lastPlay.name == "Library")
				#library has bug? set aside assumed as discard wtf
        if(handCount >= 7)
					if(DEBUG_PRINT)
	          puts "discard #{currentCard.name} by library hand count is #{handCount}"
	        end
          player.discardFromReveal(currentCard)
        else
					if(DEBUG_PRINT)
	          puts "reveal #{currentCard.name} by library"
	        end
          player.revealCardFromDeck(currentCard)
        end
      else
        player.discardFromHand(currentCard)
      end
    }
  end

	def parseReceive(data)
		player = @playerData[data[0..getLastIndex(data, "-") - 2]]
		amount = data[data.index("receives") + 9 .. data.index("receives") + 9].to_i

		if data.include?("actions")
			@currentAction += amount
		elsif data.include?("coins")
			@currentCoin += amount
		end

	end

	def parseTake(data)
		player = @playerData[data[0..getLastIndex(data, "-") - 2]]
		amount = data[data.index("takes") + 6 .. data.index("takes") + 6].to_i
		event = ""

		eventData = {}
		eventData["type"] = "take"
		eventData["content"] = event
		eventData["player"] = player.getName()
		fireEvents(eventData)

		if data.include?("action")
			event = "action"
		elsif data.include?("coin")
			event = "coin"
		elsif data.include?("buy")
			event = "buy"
		end

		eventData = {}
		eventData["type"] = "take"
		eventData["content"] = event
		eventData["player"] = player.getName()
		fireEvents(eventData)

		if data.include?("action")
			@currentAction += amount
		elsif data.include?("coin")
			@currentCoin += amount
		elsif data.include?("buy")
			@currentBuy += amount
		end

	end

	def parsePassCard(data)
		player = @playerData[data[0..getLastIndex(data, "-") - 2]]
		passCard = @cardData.getCard(data[data.index("passes") + 7 .. -2])

		eventData = {}
		eventData["type"] = "passcard"
		eventData["cardId"] = passCard.id
		eventData["player"] = player.getName()
		fireEvents(eventData)

		player.trashCardFromHand(passCard)
		getOpponent(player.name).addCardToHand(passCard)

	end

	def parseNameCard(data)
		player = @playerData[data[0..getLastIndex(data, "-") - 2]]
		print "|" + data[data.index("names") + 6 .. -2] + "|"
		nameCard = @cardData.getCard(data[data.index("names") + 6 .. -2])



		eventData = {}
		eventData["type"] = "namecard"
		if nameCard
			eventData["cardId"] = nameCard.id
		#存在しないカードを宣言
		else
			eventData["cardId"] = 0
		end
		eventData["player"] = player.getName()
		fireEvents(eventData)

	end

	def parseDraw(data)
    player = @playerData[data[0..getLastIndex(data, "-") - 2]]
		cards = data[data.index("draws") + 6..-2].split(", ").map{|card| @cardData.getCard(card)}

		eventData = {}
		eventData["type"] = "draw"
		eventData["cards"] = cards
		eventData["player"] = player.getName()
		fireEvents(eventData)

    cards.each{|currentCard|
      if(DEBUG_PRINT)
        puts "#{player.getName()} drawes #{currentCard.name}"
      end
    	player.drawCard(currentCard)
    }
  end

	def parseScore(data)
    score = data[getLastIndex(data, " ")..-1].to_i
    @finalScore[data[0..getLastIndex(data, "-") - 2]] = score.to_s
    puts "score" + currentPlayer.to_s + ":" + score.to_s
  end

	def verifyResult(data)
		if(@canVerify == false)
			puts "cannot verify because of quit or resign"
			return
		end

		player = @playerData[data[0..getLastIndex(data, "-") - 2]]
		totalCard = player.getTotalCard

		data[data.index(" - ") + 10 .. -2].split(", ").each{|pair|
			cardId = pair[pair.index(" ") + 1..-1]
			num = pair.split(" ")[0].to_i
			if(totalCard[cardId] = num)
				puts "#{cardId} correct"
			else
				puts "#{cardId} incorrect i estimate #{totalCard[cardId]} but it was #{num}"
				raise
			end
		}
	end

	def getLastIndex(str, target)
    #で地上げ対応
    if(str.include?(" place:"))
      return nil
    end
    pos = -1
    while(true)
      if(str.index(target, pos + 1) != nil)
        pos = str.index(target, pos + 1)
      else
        return pos
      end
    end
  end

	def fireEvents(eventData)
		@eventListener.each{|listener|
			listener.eventCallback(eventData, self)
		}
	end

	def switch_phase(phase)
		if(@currentPhase != phase)

			#buyをすっ飛ばした場合buyもfireする
			if(@currentPhase == PHASE_ACTION && phase == PHASE_CLEANUP)
				eventData = {}
				eventData["type"] = "switch_phase"
				eventData["phase"] = "buy"
				fireEvents(eventData)
			end

			@currentPhase = phase

			eventData = {}
			eventData["type"] = "switch_phase"
			eventData["player"] = @currentPlayer
			case phase
			when PHASE_BUY then
				eventData["phase"] = "buy"
			when PHASE_ACTION then
				eventData["phase"] = "action"
			when PHASE_CLEANUP then
				eventData["phase"] = "cleanup"
			end
			fireEvents(eventData)
		end
	end

end
