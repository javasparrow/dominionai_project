load("gokoLogParser.rb")


if(ARGV.length == 1)
  if(ARGV[0] == "gain")
    featureMode = GokoLogParser::MODE_BUY
    puts "gainMode"
  elsif(ARGV[0] == "action")
    featureMode = GokoLogParser::MODE_ACTION
    puts "actionMode"
  elsif(ARGV[0] == "cellar")
    featureMode = GokoLogParser::MODE_ACTION_CELLAR
    puts "cellarMode"
  elsif(ARGV[0] == "chapel")
    featureMode = GokoLogParser::MODE_ACTION_CHAPEL
    puts "chapelMode"
  elsif(ARGV[0] == "remodel")
    featureMode = GokoLogParser::MODE_ACTION_REMODEL
    puts "remodelMode"
  elsif(ARGV[0] == "throne")
    featureMode = GokoLogParser::MODE_ACTION_THRONE
    puts "throneMode"
  elsif(ARGV[0] == "throne")
    featureMode = GokoLogParser::MODE_ACTION_CHANCELLOR
    puts "chancellorMode"
  elsif(ARGV[0] == "militia")
    featureMode = GokoLogParser::MODE_ACTION_MILITIA
    puts "militiaMode"
  elsif(ARGV[0] == "mine")
    featureMode = GokoLogParser::MODE_ACTION_MINE
    puts "mineMode"
  else
    puts "unknown feature type"
    return
  end
else
  puts "usage: ruby parseLogs.rb featuretype"
  return
end

File.open("result_" + ARGV[0] + ".txt", 'w'){|out|

  Dir::glob("./logfiles/*").each{|f|
    parser = GokoLogParser.new
    File.open(f, 'r') {|file|
      puts f
      parser.parse(file, out, featureMode, nil)
    }
  }

}