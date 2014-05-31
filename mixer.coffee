readline = require 'readline'
spawn = require('child_process').spawn
gm = require('gm').subClass({ imageMagick: true }) 

input_file = process.argv[2]
output_file = process.argv[3]

find_square_size_possibilities = (width, height) ->

	area = width * height
	possibilities = []

	if width < height
		smaller = width
	else 
		smaller = height

	limit = Math.ceil(smaller/ 3)

	for n in [3..limit]
		if check_divisibility(width, n) and check_divisibility(height, n)
			possibilities.push n 

	return possibilities


check_divisibility = (num, div) ->

	return check_integer((num/div))

check_integer = (number) ->

	if number % 1 is 0
		return true
	else 
		return false

find_num_squares = (possibilities, width, height) ->

	squares = []

	for p in possibilities

		w = (width / p)
		h = (height/ p)
		sqr = 
			square_pixels: p
			w: w
			h: h
			total: w * h 

		squares.push sqr

	return squares

pick_one = (squares, cb) ->

	rl = readline.createInterface({
		input: process.stdin,
		output: process.stdout
	})

	question = "\nWhich square size would you prefer?\nWarning: The more squares the longer this will take. (It takes anywhere from 30sec to 30min)\n\n"
	options = []
	index = 0
	for squ in squares
		question += (++index) + ". square width: " + squ['square_pixels'] + ' px. total squares: ' + squ['total'] + '\n'
		options.push index

	console.log options
	question += '\nEnter the number corresponding to your choice: ' 

	rl.question question, (answer)  => 
		if (parseFloat(answer)) in options
			rl.close()
			console.log "\n\n\n"
			cb(null, squares[(answer - 1)])
		else 
			console.log "Bad answer, please try again."
			rl.close()
			pick_one(squares, cb)

	# return squares[0]
	# return squares[squares.length - 1]

shuffle = (array) ->
	currentIndex = array.length

	while 0 isnt currentIndex

    	randomIndex = Math.floor(Math.random() * currentIndex)
    	currentIndex -= 1

    	temporaryValue = array[currentIndex]
    	array[currentIndex] = array[randomIndex]
    	array[randomIndex] = temporaryValue

	return array;

# index should start at 1
create_image = (final_name, square, file_names, column_num, columns, cb) ->

	if column_num < square['w']
		column_name = 'workspace/column_' + column_num + '.jpg'
		columns.push column_name
		base_block_index = (column_num * square['h'])
		func = 'gm("' + file_names[base_block_index] + '").append(' 

		for i in [1..(square['h'] - 1)]
			func += '"' + file_names[(base_block_index + i)] + '",'

		func += 'false).write("' + column_name + '", function(err){ if(err){ console.log(err) } create_image(final_name, square, file_names, ++column_num, columns, cb)})'

		eval(func)
	else
		# now join columns
		file_name = 'final/' + final_name + '.jpg'
		console.log file_name
		func = 'gm("' + columns[0] + '").append(' 

		for i in [1..(columns.length - 1)]
			func += '"' + columns[i] + '",'

		func += 'true).write("' + file_name + '", cb)'

		eval(func)


make_squares = (square, index, w, h, file_names, cb) ->
	# console.log index
	square_pixels = square['square_pixels']
	file_name =  'workspace/' + index + '.jpg'
	file_names.push file_name

	gm(picture).crop(square_pixels, square_pixels, (w * square_pixels), (h * square_pixels)).write(file_name, (err) =>
		if err?
			console.log err

		else 
			# console.log "index: " + index
			# console.log "h: " + h
			# console.log "w: " + w + '\n'
			if h < square['h'] - 1
				make_squares(square, ++index, w, ++h, file_names, cb)
				
			else if w < square['w'] - 1
				make_squares(square, ++index, ++w, 0, file_names, cb)

			else 
				cb(null, file_names)
	)

if input_file?
	picture = input_file 
else 
	picture = './wortzel.jpg'

folder = __dirname + '/workspace/'
mkdir = spawn('mkdir', [folder])

gm(picture).size (err, size) =>

	width = size['width']
	height = size['height']

	possibilities = find_square_size_possibilities(width, height)
	squares = find_num_squares(possibilities, width, height)

	square = pick_one(squares, (err, square) =>
		console.log "in pick_one cb"
		console.log square

		square_pixels = square['square_pixels']

		width_offset = 0
		height_offset = 0
		index = 0

		make_squares(square, 1, 0, 0, [], (err, file_names) =>
			if err?
				console.log err
			else 
				if not output_file?
					output_file = (new Date()).getTime()

				file_names = shuffle(file_names)
				create_image(output_file, square, file_names, 0, [], (err, res) =>
					if err?
						console.log err
					else 
						folder = __dirname + '/workspace/'
						rm = spawn('rm', ['-rf', folder])
						# rm = spawn('ls', [folder, '|', 'xargs', 'rm', '-rf', folder], {cwd: process.env.PWD})
						console.log "Done!"
						console.log res
				)
		)
	)






