
load_image = (src, callback)->
	image = new Image
	image.onload = callback
	image.src = src
	image


tile_types =
	"rgb(32, 140, 179)": "water"
	"rgb(218, 204, 153)": "sand"
	"rgb(254, 203, 49)": "grass"
	"rgb(211, 148, 92)": "wood"
	"rgb(255, 255, 255)": "rock1"
	"rgb(253, 253, 254)": "rock1" # XXX: slightly different colors of white for this type
	"rgb(226, 226, 226)": "rock2"
	"rgb(171, 171, 171)": "rock3"
	"rgb(100, 100, 100)": "rock4"
	"rgb(8, 3, 5)": "rock5"
	"rgb(207, 38, 85)": "gum"
	"rgb(211, 28, 24)": "lava"
	"rgb(254, 67, 25)": "orange"
	"rgb(69, 30, 56)": "purple"

level = []

level_image = load_image "images/map/level.png", ->
# level_image = load_image "images/map/overworld.png", ->
	level_canvas = document.createElement "canvas"
	level_ctx = level_canvas.getContext "2d"
	level_ctx.drawImage(level_image, 0, 0)
	id = level_ctx.getImageData(0, 0, level_canvas.width, level_canvas.height)
	level =
		for y in [0..id.height]
			for x in [0..id.width]
				offset = (y * id.width + x) * 4
				color = "rgb(#{id.data[offset + 0]}, #{id.data[offset + 1]}, #{id.data[offset + 2]})"
				tile_type = tile_types[color]
				{type: tile_type, color, uncovered: no, cover_checked: no, uncovered_anim: 0}

tile_size = 32

class KeyboardController
	constructor: ->
		@keys = {}
		@prev_keys = {}
		window.addEventListener "keydown", (e)=>
			@keys[e.keyCode] = on
		window.addEventListener "keyup", (e)=>
			delete @keys[e.keyCode]
	
	justPressed: (keyCode)=>
		@keys[keyCode]? and not @prev_keys[keyCode]?
	
	step: ->
		@moveX = Math.min(1, Math.max(-1, @keys[39]? - @keys[37]? + @keys[68]? - @keys[65]?))
		@moveY = Math.min(1, Math.max(-1, @keys[40]? - @keys[38]? + @keys[83]? - @keys[87]?))
		@enter = @justPressed(13) or @justPressed(32)
		
		@prev_keys = {}
		for k, v of @keys
			@prev_keys[k] = v

tileAt = (x, y)->
	level[~~y]?[~~x]

collisionAt = (x, y)->
	tile = tileAt(x, y)
	if tile?
		if tile.type in ["rock1", "rock2", "rock3", "rock4", "rock5"]
			yes
		else
			no
	else
		yes

forEachPointOnLine = (x0, y0, x1, y1, callback)->
	dx = Math.abs(x1 - x0)
	dy = Math.abs(y1 - y0)
	sx = if (x0 < x1) then 1 else -1
	sy = if (y0 < y1) then 1 else -1
	err = dx-dy
	loop
		break if callback(x0, y0) is "break"
		break if ((x0 is x1) and (y0 is y1))
		e2 = 2*err
		if (e2 >-dy) then (err -= dy; x0 += sx)
		if (e2 < dx) then (err += dx; y0 += sy)


collisionLine = (x1, y1, x2, y2)->
	collided = no
	forEachPointOnLine x1, y1, x2, y2, (x, y)->
		if collisionAt(x, y)
			collided = yes
			"break"
	collided

class Player
	constructor: ({@controller, @x=0, @y=0, @z=0})->
		@moveTimer = 0
		@x_anim = @x
		@y_anim = @y
		@z_anim = 0
	step: ->
		@controller.step()
		# console.log tileAt(@x, @y)?.type, tileAt(@x, @y)?.color
		in_water = tileAt(@x, @y)?.type is "water"
		move_period = if in_water then 10 else 5
		if @moveTimer++ > move_period
			@moveTimer = 0
			unless collisionAt(@x + @controller.moveX, @y)
				@x += @controller.moveX
			unless collisionAt(@x, @y + @controller.moveY)
				@y += @controller.moveY
		movement_smoothing = if in_water then 5 else 3
		@x_anim += (@x - @x_anim) / movement_smoothing
		@y_anim += (@y - @y_anim) / movement_smoothing

keyboard_controller = new KeyboardController
player = new Player {x: 184, y: 49, controller: keyboard_controller}

view = {center_x: 0, center_y: 0, center_x_to: 0, center_y_to: 0}
view.center_x = view.center_x_to = player.x
view.center_y = view.center_y_to = player.y

draw_world = ->
	for level_row, y in level
		for tile, x in level_row
			unless tile.cover_checked
				if hypot(y - player.y, x - player.x) < 15
					unless collisionLine(player.x, player.y, x, y)
						tile.uncovered = yes
						tile.cover_checked = yes
						level[y - 1]?[x]?.uncovered = yes
						level[y]?[x - 1]?.uncovered = yes
						level[y + 1]?[x]?.uncovered = yes
						level[y]?[x + 1]?.uncovered = yes
						level[y - 1]?[x - 1]?.uncovered = yes
						level[y - 1]?[x + 1]?.uncovered = yes
						level[y + 1]?[x - 1]?.uncovered = yes
						level[y + 1]?[x + 1]?.uncovered = yes
			if tile.uncovered
				ctx.save()
				tile.uncovered_anim += (1 - tile.uncovered_anim) / 10
				ctx.globalAlpha = tile.uncovered_anim
				switch tile.type
					when "water"
						ctx.fillStyle = tile.color
					when "sand"
						ctx.fillStyle = tile.color
					when "grass"
						ctx.fillStyle = "#205120"
					when "wood"
						ctx.fillStyle = "#B16A36"
					when "gum"
						ctx.fillStyle = "#954F35"
					when "rock1"
						ctx.fillStyle = "rgb(128, 128, 128)"
					when "rock2"
						ctx.fillStyle = "rgb(100, 100, 100)"
					when "rock3"
						ctx.fillStyle = "rgb(70, 70, 70)"
					when "rock4"
						ctx.fillStyle = "rgb(50, 50, 50)"
					when "rock5"
						ctx.fillStyle = "rgb(20, 20, 20)"
					when "lava"
						ctx.fillStyle = "#500"
					else
						ctx.fillStyle = tile.color
				ctx.fillRect(x * tile_size, y * tile_size, tile_size, tile_size)
				ctx.restore()
	ctx.fillStyle = "#66CC77"
	ctx.fillRect(player.x_anim * tile_size, player.y_anim * tile_size, tile_size, tile_size)

boat_image = load_image "images/story/boat.png"
wave_image = load_image "images/story/wave.png"
fist_image = load_image "images/story/water-fist.png"

screen = null
go_to_screen = (name)->
	screen = screens[name]
	screen.init?()

screens = {
	"Title": {
		draw: ->
			ctx.fillStyle = "black"
			ctx.fillRect 0, 0, canvas.width, canvas.height
			
			ctx.save()
			ctx.fillStyle = "white"
			ctx.font = "80px Arial"
			ctx.textAlign = "center"
			ctx.fillText("Macrosergeon", canvas.width/2, 150)
			ctx.font = "20px Arial"
			ctx.fillText("NOTE: There's no actual game, so set your expectations ⇝ LO.", canvas.width/2, 250)
			ctx.font = "30px Arial"
			ctx.fillStyle = "rgba(255, 255, 255, 0.5)"
			ctx.fillText("Press the Any key to be kin.", canvas.width/2, 350)
			ctx.restore()
			
			keyboard_controller.step()
			if Object.keys(keyboard_controller.keys).length > 0
				go_to_screen "Story"
	}
	"Story": {
		init: ->
			@boat = {x: 0, y: 0, r: 0, xv: 0, yv: 0, rv: 0, opacity: 0}
			@wave = {x: 0, y: 0, r: 0, xv: 0, yv: 0, rv: 0, opacity: 0}
			@fist = {x: 0, y: 0, r: 0, xv: 0, yv: 0, rv: 0, opacity: 0}
		frames: [
			{
				text: "Sure is a fine day for sailing."
				boat: {x: 0, y: 0}
			}
			{
				text: "I'm glad we brought this sailboat out here for sailing."
				boat: {x: 0, y: 0}
			}
			{
				text: "Oh no, the waves! The waves are attacking the ship, almost antagonistically!"
				boat: {x: -150, y: 0}
				wave: {x: 200, y: 0}
			}
			{
				text: "..."
				boat: {x: -150, y: 0, xv: -5, r: 0, rv: -0.1}
				wave: {x: 200, y: 0}
				fist: {x: 150, y: 0}
			}
			{
				text: "Yep, that's the story line."
				# XXX the way this is done because it constantly sets the properties
				# boat: {x: -150, y: 0}
				boat: {y: 0}
				wave: {x: 200, y: 0}
				fist: {x: -20, y: 0}
			}
			{
				text: "Yep, that's the story line."
				# boat: {x: 550, y: 0, xv: -5}
				boat: {y: 0, xv: -5}
			}
			{
				text: "And there also isn't a game."
			}
		]
		step_index: 0
		draw: ->
			ctx.fillStyle = "#28484E"
			ctx.fillRect 0, 0, canvas.width, canvas.height
			
			keyboard_controller.step()
			if keyboard_controller.enter
				@step_index += 1
				if @step_index >= @frames.length
					@step_index = 0
					go_to_screen "Game"
					return
			
			frame = @frames[@step_index]
			
			draw_actor = (name, image)=>
				actor_frame = frame[name]
				actor = @[name]
				actor.x += actor.xv
				actor.y += actor.yv
				actor.r += actor.rv
				if actor_frame
					for k, v of actor_frame
						actor[k] = v
				opacity_to = +(actor_frame?)
				actor.opacity += (opacity_to - actor.opacity) / 5
				ctx.save()
				ctx.translate(actor.x, actor.y)
				scale = 0.5
				ctx.scale(scale, scale)
				ctx.rotate(actor.r)
				ctx.globalAlpha = actor.opacity
				ctx.drawImage(image, -image.width/2, -image.height/2)
				ctx.restore()
			
			ctx.save()
			ctx.translate(~~(canvas.width / 2), ~~(canvas.height / 2))
			draw_actor("wave", wave_image)
			draw_actor("boat", boat_image)
			draw_actor("fist", fist_image)
			ctx.restore()
			
			ctx.save()
			ctx.fillStyle = "white"
			ctx.font = "30px Arial"
			ctx.textAlign = "center"
			ctx.fillText(frame.text ? "", canvas.width/2, canvas.height*5/6)
			ctx.restore()
	}
	"Game": {
		draw: ->
			ctx.fillStyle = "black"
			ctx.fillRect 0, 0, canvas.width, canvas.height
			
			return unless level_image.complete
			
			player.step()
			
			view.center_x_to = player.x
			view.center_y_to = player.y
			view.center_x += (view.center_x_to - view.center_x) / 10
			view.center_y += (view.center_y_to - view.center_y) / 10
			
			ctx.save()
			ctx.translate(~~(canvas.width / 2), ~~(canvas.height / 2))
			ctx.translate(~~(-view.center_x * tile_size), ~~(-view.center_y * tile_size))
			draw_world()
			ctx.restore()
	}
}
go_to_screen "Title"

animate ->
	screen.draw()
