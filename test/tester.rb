load("../learn/makeTeacherData/gokoLogParser.rb")
load("../play/GokoPlayer.rb")

FEATUREPLAYER = "I am BOT"

BUYFEATURE_DIR = "./result/log1/gainFeature.txt"
PLAYFEATURE_DIR = "./result/log1/playFeature.txt"
ACTIONFEATURE_DIR = "./result/log1/actionFeature.txt"

File.open("./result/log1/gainFeature_full.txt", 'w'){|out|
	parser = GokoLogParser.new
	out.sync = true
	File.open("./testLogs/log1/log", 'r') {|file|
		parser.parse(file, out, GokoLogParser::MODE_BUY, FEATUREPLAYER)
	}
}

File.open(BUYFEATURE_DIR, 'w'){|out|
	File.open(PLAYFEATURE_DIR, 'w'){|outAction|
		File.open(ACTIONFEATURE_DIR, 'w'){|outAction2|

			out.sync = true
      		outAction.sync = true
      		outAction2.sync = true

			for i in 1..23
				#でっちあげ
				if(i == 13)
					out.puts "hoge"
					next
				end
				parser = GokoPlayer.new
				File.open("./testLogs/log1/turn" + i.to_s + "_buy_draw", 'r') {|drawFile|
					File.open("./testLogs/log1/turn" + i.to_s + "_buy_log", 'r') {|logFile|
						parser.parse(logFile, out, outAction, outAction2, drawFile, false)
					}
				}
			end

		}
	}
}

puts "parse Done"

File.open("./result/log1/gainFeature_full.txt", 'r'){|full|
	File.open("./result/log1/gainFeature.txt", 'r'){|play|
		log1 = full.readlines
		log2 = play.readlines
		for i in 0..23
			puts i
			if(log1[i].split("/")[0] != log2[i].split("/")[0])
				puts "mismatch"
				log1s = log1[i].split("/")[0].split(",")
				log2s = log2[i].split("/")[0].split(",")
				for i in 0..log1s.length
					if(log1s[i] != log2s[i])
						puts "raw" + i.to_s
						puts log1s[i]
						puts log2s[i]
					end
				end
			end
		end
	}
}