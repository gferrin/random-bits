readline = require 'readline'

rl = readline.createInterface({
	input: process.stdin,
	output: process.stdout
})
options = ["1. this", "2. that"]
question = "1. this\n2. that\n"
rl.question(question, (answer)  => 
  # // TODO: Log the answer in a database
  	
  	


	console.log("Thank you for your valuable feedback:", answer)

	rl.close();
)