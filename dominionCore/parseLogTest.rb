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
load("featureMaker/UpgradeLearnDataMaker.rb")
load("featureMaker/MasqueradeLearnDataMaker.rb")
load("featureMaker/NoblesLearnDataMaker.rb")
load("featureMaker/TradingpostLearnDataMaker.rb")
load("featureMaker/MiningvillageLearnDataMaker.rb")
load("featureMaker/TorturerLearnDataMaker.rb")
load("featureMaker/SwindlerLearnDataMaker.rb")
load("featureMaker/StewardLearnDataMaker.rb")
load("featureMaker/BaronLearnDataMaker.rb")
load("featureMaker/MinionLearnDataMaker.rb")
load("featureMaker/ScoutLearnDataMaker.rb")
load("featureMaker/PawnLearnDataMaker.rb")
load("featureMaker/IronworksLearnDataMaker.rb")
load("featureMaker/CourtyardLearnDataMaker.rb")
load("featureMaker/WishingwellLearnDataMaker.rb")
load("featureMaker/SecretchamberLearnDataMaker.rb")

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
      parser.addEventListener(UpgradeLearnDataMaker.new())
      parser.addEventListener(MasqueradeLearnDataMaker.new())
      parser.addEventListener(NoblesLearnDataMaker.new())
      parser.addEventListener(TradingpostLearnDataMaker.new())
      parser.addEventListener(MiningvillageLearnDataMaker.new())
      parser.addEventListener(TorturerLearnDataMaker.new())
      parser.addEventListener(SwindlerLearnDataMaker.new())
      parser.addEventListener(StewardLearnDataMaker.new())
      parser.addEventListener(BaronLearnDataMaker.new())
      parser.addEventListener(MinionLearnDataMaker.new())
      parser.addEventListener(ScoutLearnDataMaker.new())
      parser.addEventListener(PawnLearnDataMaker.new())
      parser.addEventListener(IronworksLearnDataMaker.new())
      parser.addEventListener(CourtyardLearnDataMaker.new())
      parser.addEventListener(WishingwellLearnDataMaker.new())
      parser.addEventListener(SecretchamberLearnDataMaker.new())
      parser.parseLog(out)
    }
  }

}
