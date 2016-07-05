load("dominionCore.rb")
load("featureMaker/buyFeature.rb")
load("featureMaker/PLayLearnDataMaker.rb")
load("featureMaker/RemodelLearnDataMaker.rb")
load("featureMaker/ThroneroomLearnDataMaker.rb")
load("featureMaker/MineLearnDataMaker.rb")
load("featureMaker/CellarLearnDataMaker.rb")
load("featureMaker/ThiefLearnDataMaker.rb")
load("featureMaker/MilitiaLearnDataMaker.rb")
load("featureMaker/BureaucratLearnDataMaker.rb")
load("featureMaker/ChapelLearnDataMaker.rb")
load("featureMaker/ChancellorLearnDataMaker.rb")
load("featureMaker/LibraryLearnDataMaker.rb")
load("featureMaker/MoatLearnDataMaker.rb")
load("featureMaker/SpyLearnDataMaker.rb")

Dir::mkdir(ARGV[0])
File.open("result_" + ARGV[0] + ".txt", 'w'){|out|

  Dir::glob("./logfiles/*").each{|f|
    File.open(f, 'r') {|file|
      parser = DominionCore.new(file, ARGV[0])
      parser.addEventListener(BuyFeatureMaker.new())
      parser.addEventListener(PlayLearnDataMaker.new())
      parser.addEventListener(RemodelLearnDataMaker.new())
      parser.addEventListener(ThroneroomLearnDataMaker.new())
      parser.addEventListener(MineLearnDataMaker.new())
      parser.addEventListener(CellarLearnDataMaker.new())
      parser.addEventListener(ThiefLearnDataMaker.new())
      parser.addEventListener(MilitiaLearnDataMaker.new())
      parser.addEventListener(BureaucratLearnDataMaker.new())
      parser.addEventListener(ChapelLearnDataMaker.new())
      parser.addEventListener(ChancellorLearnDataMaker.new())
      parser.addEventListener(LibraryLearnDataMaker.new())
      parser.addEventListener(MoatLearnDataMaker.new())
      parser.addEventListener(SpyLearnDataMaker.new())
      parser.parseLog(out)
    }
  }

}
