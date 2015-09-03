require 'net/http'
require 'rubygems'
require 'active_support'
require 'active_support/time'
require 'open-uri'
require 'nokogiri'

player_name = "stefff"

open("name.txt") do |file|
  file.each do |name|
    
if name.empty? || name == "\n"
	next
end

name = name[0..-2].gsub(" ", '%20')
puts name

START_YEAR = 2015
START_DATE = 19
START_MONTH = 5

day = Time.gm(START_YEAR,START_MONTH,START_DATE)
startDay = Time.gm(START_YEAR,START_MONTH,START_DATE)

finalDay = Time.gm(2012,8,5)

while day > finalDay
puts day
charset = nil
url = URI.parse("http://gokosalvager.com/logsearch?p1name=" + name + "&p1score=any&p2name=&startdate=" + sprintf("%02d", 29.days.ago(day).month) + "%2F" + sprintf("%02d", 29.days.ago(day).day) + "%2F" + 29.days.ago(day).year.to_s + "&enddate=" + sprintf("%02d", day.month) + "%2F" + sprintf("%02d", day.day) + "%2F" + day.year.to_s + "&supply=&nonsupply=&rating=pro%2B&pcount=2&colony=any&bot=false&shelters=any&guest=false&minturns=&maxturns=&quit=false&resign=any&limit=1000&submitted=true&offset=0")
html = open(url) do |f|
  charset = f.charset # 文字種別を取得
  f.read # htmlを読み込んで変数htmlに渡す
end

# htmlをパース(解析)してオブジェクトを生成
doc = Nokogiri::HTML.parse(html, nil, charset)

FileUtils.mkdir_p('./logs/' + name) unless FileTest.exist?('./logs/' + name)

#puts doc
doc.xpath('//a').each do |node|
	if(node.inner_text == "Log")
		href = node.attribute('href').to_s
		uri = URI(href)
		r = Net::HTTP.get_response(uri)
		if(r.code == "301" || r.code == "302")
			r = Net::HTTP.get_response(URI.parse(r.header['location']))
		end
		File.write('./logs/' + name + "/" + href[href.rindex("/") + 1..-1], r.body)
	end
end
day = 30.days.ago(day)
end

end
end