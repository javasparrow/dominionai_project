require 'osx/cocoa'
include Math
class GokoRapper
	WINDOW_X = 10
	WINDOW_Y = 22
	WINDOW_OUTER_WIDTH = 1106
	WINDOW_OUTER_HEIGHT = 717
	WINDOW_INNER_WIDTH = 1106
	WINDOW_INNER_HEIGHT = 645

	CANVAS_X = WINDOW_X + (WINDOW_INNER_WIDTH - WINDOW_INNER_HEIGHT * 3 / 2) / 2
	CANVAS_Y = WINDOW_Y + WINDOW_OUTER_HEIGHT - WINDOW_INNER_HEIGHT
	CANVAS_WIDTH = WINDOW_INNER_HEIGHT * 3 / 2
	CANVAS_HEIGHT = WINDOW_INNER_HEIGHT

	GOKO_WIDTH = 1920
	GOKO_HEIGHT = 1280
	ESTATE_X = 286
	ESTATE_Y = 450
	VICTORY_DISRANCE = 160
	SUPPLY_X = 570
	SUPPLY_Y = 218
	SUPPLY_DISTANCE_X = 281
	SUPPLY_DISTANCE_Y = 241
	CURSE_X = 1882
	CURSE_Y = 609
	MONEY_DISTANCE = 157
	HAND_CIRCLE = 2205
	CIRCLE_X = 960
	CIRCLE_Y = 3300

	#番号と位置の関係は
	# 01234
	# 56789
	def pointSupply(num)
		x = (num % 5) * SUPPLY_DISTANCE_X * CANVAS_WIDTH / GOKO_WIDTH + SUPPLY_X * CANVAS_WIDTH / GOKO_WIDTH + CANVAS_X
		y = (num / 5) * SUPPLY_DISTANCE_Y * CANVAS_HEIGHT / GOKO_HEIGHT + SUPPLY_Y * CANVAS_HEIGHT / GOKO_HEIGHT + CANVAS_Y
		move_mouse(x,y)
	end

	#銅貨とかをポイント
	def pointBasicCard(id)
		#サプライ右側
		if(id == 1 || id == 2 || id == 3 || id == 7)
			if(id == 7)
				pos = 0
			else
				pos = id
			end
			x = CURSE_X * CANVAS_WIDTH / GOKO_WIDTH + CANVAS_X
			y = -pos * MONEY_DISTANCE * CANVAS_HEIGHT / GOKO_HEIGHT + CURSE_Y * CANVAS_HEIGHT / GOKO_HEIGHT + CANVAS_Y
		#左側
		elsif(id == 4 || id == 5 || id || 6)
			pos = id - 4;
			x = ESTATE_X * CANVAS_WIDTH / GOKO_WIDTH + CANVAS_X
			y = -pos * VICTORY_DISRANCE * CANVAS_HEIGHT / GOKO_HEIGHT + ESTATE_Y * CANVAS_HEIGHT / GOKO_HEIGHT + CANVAS_Y
		end
		move_mouse(x, y)
	end

	def pointHand(total, pos)
		r = HAND_CIRCLE * CANVAS_WIDTH / GOKO_WIDTH
		center_x = CIRCLE_X * CANVAS_WIDTH / GOKO_WIDTH
		center_y = CIRCLE_Y * CANVAS_WIDTH / GOKO_WIDTH

		start_rad = -(total - 1) / 2.0 * PI / 40 - PI / 2

		x =  center_x + r * Math.cos(start_rad + PI/40 * pos) + CANVAS_X
		y =  center_y + r * Math.sin(start_rad + PI/40 * pos) + CANVAS_Y
		move_mouse(x, y)
	end

	def move_mouse(x, y)
   		OSX::CGWarpMouseCursorPosition(OSX::CGPointMake(x, y))
 	end
end

r = GokoRapper.new
r.pointHand(4, 3)
