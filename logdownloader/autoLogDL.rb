require "selenium-webdriver"
require 'net/http'
require 'rubygems'
require 'active_support'
require 'active_support/time'

open("name.txt") do |file|
  file.each do |name|
      puts name
    
if name.empty? || name == "\n"
	next
end

START_YEAR = 2015 #2015
START_DATE = 19 #19
START_MONTH = 5 #5

# Firefox用のドライバを使う
driver = Selenium::WebDriver.for :firefox

# Googleにアクセス
driver.navigate.to "http://gokosalvager.com/logsearch?p1name=Stef&p1score=any&p2name=&startdate=08%2F05%2F2012&enddate=05%2F02%2F2015&supply=&nonsupply=&rating=pro%2B&pcount=2&colony=any&bot=false&shelters=any&guest=false&minturns=&maxturns=&quit=false&resign=any&submitted=true&offset=0"



day = Time.gm(START_YEAR,START_MONTH,START_DATE)
startDay = Time.gm(START_YEAR,START_MONTH,START_DATE)

finalDay = Time.gm(2012,8,5)

while day > finalDay

# `q`というnameを持つ要素を取得
element_name = driver.find_element(:name, 'p1name')

# `Hello WebDriver!`という文字を、上記で取得したinput要素に入力
element_name.clear
element_name.send_keys name

element_score = driver.find_element(:name, 'p1score')

element_score.send_keys "Win"

element_startdate = driver.find_element(:name, 'startdate')

element_startdate.clear
element_startdate.send_keys (29.days.ago(day)).strftime("%m/%d/%Y") 

element_enddate = driver.find_element(:name, 'enddate')

element_enddate.clear
element_enddate.send_keys day.strftime("%m/%d/%Y") 

element_rating = driver.find_element(:name, 'rating')

element_rating.send_keys "Pro"

element_pcount = driver.find_element(:name, 'pcount')

element_pcount.send_keys "2"

element_root = driver.find_element(:id, 'searchform')

element_enddate.send_keys ""
driver.action.send_keys(:enter).perform
driver.action.send_keys(:enter).perform

sleep 10

elements = driver.find_elements(:link_text => "Log")
if(elements.size == 0)
	day = 30.days.ago(day)
	next
end

element_limit = driver.find_element(:name, 'limit')
element_limit.clear
element_limit.send_keys "1000"

driver.action.send_keys(:enter).perform

sleep 10

elements = driver.find_elements(:link_text => "Log")
puts elements.size
PLAYER_NAME = name
FileUtils.mkdir_p('./logs/' + PLAYER_NAME) unless FileTest.exist?('./logs/' + PLAYER_NAME)

elements.each{|element|
	href = element.attribute('href')
	uri = URI(href)
	r = Net::HTTP.get_response(uri)
	if(r.code == "301" || r.code == "302")
		r = Net::HTTP.get_response(URI.parse(r.header['location']))
	end
	File.write('./logs/' + PLAYER_NAME + "/" + href[href.rindex("/") + 1..-1], r.body)
}
File.write('./logs/' + PLAYER_NAME + "/.dateFile", startDay.strftime("%m/%d/%Y") + "-" + (29.days.ago(day)).strftime("%m/%d/%Y") )
day = 30.days.ago(day)
end

  end
end

