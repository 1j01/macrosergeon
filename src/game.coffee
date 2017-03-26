
level_image = new Image
level_image.src = "level.png"

tile_types = [
	"water"
	"sand"
	"rock"
	"low"
	"idk"
	"etc"
]

level = []
level_image.onload = ->
	level_canvas = document.createElement "canvas"
	level_ctx = level_canvas.getContext "2d"
	level_ctx.drawImage(level_image, 0, 0)
	id = level_ctx.getImageData(0, 0, level_canvas.width, level_canvas.height)
	colors = []
	level =
		for y in [0..id.height]
			for x in [0..id.width]
				offset = (y * id.width + x) * 4
				color = "rgb(#{id.data[offset + 0]}, #{id.data[offset + 1]}, #{id.data[offset + 2]})"
				if colors.indexOf(color) is -1
					colors.push(color)
				tile_type = tile_types[colors.indexOf(color)]
				{type: tile_type, color: color, uncovered: no}

tile_size = 32

class KeyboardController
	constructor: ->
		@keys = {}
		@prev_keys = {}
		window.addEventListener "keydown", (e)=>
			console.log e.keyCode
			@keys[e.keyCode] = on
		window.addEventListener "keyup", (e)=>
			delete @keys[e.keyCode]
	
	justPressed: (keyCode)=>
		@keys[keyCode]? and not @prev_keys[keyCode]?
	
	step: ->
		@moveX = Math.min(1, Math.max(-1, @keys[39]? - @keys[37]? + @keys[68]? - @keys[65]?))
		@moveY = Math.min(1, Math.max(-1, @keys[40]? - @keys[38]? + @keys[83]? - @keys[87]?))
		@enter = @justPressed(13)
		
		@prev_keys = {}
		for k, v of @keys
			@prev_keys[k] = v

class Player
	constructor: ({@controller, @x, @y})->
		
	step: ->
		@controller.step()
		@x += @controller.moveX
		@y += @controller.moveY
		# @x -= 0.1

player = new Player {x: 200, y: 50, controller: new KeyboardController}

view = {center_x: 0, center_y: 0, center_x_to: 0, center_y_to: 0}
view.center_x = view.center_x_to = player.x
view.center_y = view.center_y_to = player.y

animate ->
	
	player.step()
	
	view.center_x_to = player.x
	view.center_y_to = player.y
	view.center_x += (view.center_x_to - view.center_x) / 10
	view.center_y += (view.center_y_to - view.center_y) / 10
	
	{width: w, height: h} = canvas
	
	ctx.fillStyle = "black"
	ctx.fillRect 0, 0, w, h

	ctx.fillStyle = "white"
	
	ctx.save()
	ctx.translate(~~(w / 2), ~~(h / 2))
	ctx.translate(~~(-view.center_x * tile_size), ~~(-view.center_y * tile_size))
	for level_row, y in level
		for tile, x in level_row
			if not tile.uncovered
				if hypot(y - player.y, x - player.x) < 5
					tile.uncovered = yes
			if tile.uncovered
				ctx.fillStyle = tile.color
				ctx.fillRect(x * tile_size, y * tile_size, tile_size, tile_size)
			# else
			# 	ctx.fillStyle = "black"
			# 	ctx.fillRect(x * tile_size, y * tile_size, tile_size, tile_size)
	# ctx.drawImage(level_image, 0, 0)
	ctx.restore()
