extends PopupDialog


var content
var doubArr
var onQuestion = -1

func _ready():
	var file = File.new()
	file.open("res://questions.csv", File.READ)
	content = file.get_csv_line()
	file.close()
	
	print(content)
	
	var count = 0
	doubArr = create_2d_array(4, content.size()%5)
	print("FRESH DOUB ARR \n\n",doubArr, "\n\n")
	for i in content.size():
		if i % 5 == 0 && i != 0:
			print("\n\n\nTHIS IS THE DOUBLEARRAY BEFORE DOING ANYTHING CRAZY!!!!!!!!!!!!!!!!!!!",doubArr)
			doubArr
			count += 1
		doubArr[count].append(content[i])
	
	print("\n\nHERE COMES THE DOUBLE ARRAY: \n", doubArr)
	
	fisher_yates_modern_randomizer()
	
	print("\n\n\n THE GRAND REVEAL OF THE MIXED ARRAY: \n", doubArr, "\n\n\n")
	
	
	# Makes sure clicking outside of the popup doesn't close it
	set_exclusive(true)


# https://godotengine.org/qa/5122/how-do-i-create-a-2d-array, from vitalfadeev
func create_2d_array(l, h):
	var array = []

	for x in range(l):
		var col = []
		col.resize(h)
		array.append(col)

	return array









func get_all_children(node) -> Array:
	# This gets all the children of the QuestionPopup node,
	# So that way it's possible to access and change the text
	# of the nodes
	var nodes : Array = []

	for N in node.get_children():

		if N.get_child_count() > 0:

			nodes.append(N)

			nodes.append_array(get_all_children(N))

		else:

			nodes.append(N)

	return nodes


func fisher_yates_modern_randomizer():
	# Makes the float array in the a double array to keep
	# track of the questions an answer nicely
	
	
	var tempStor
	var randNum
	var random = RandomNumberGenerator.new()
	random.randomize()
	
	for i in doubArr.size():
		for j in doubArr[i].size() -1:
			print("THIS IS THE LENGTH OF SUB ARR",doubArr[i].size()-1)
			randNum =random.randi_range(j + 1, doubArr[i].size() - 1)
			print("RANDNUM: ", randNum)
			tempStor = doubArr[i][j + 1]
			doubArr[i][j+1] = doubArr[i][randNum]
			doubArr[i][randNum] = tempStor


func _on_QuestionPopup_about_to_show():
	get_tree().paused = true
	onQuestion += 1
	if (onQuestion == doubArr.size()):
		onQuestion = 0
	print("THIS IS WHAT QUESTION ITS ON",onQuestion)
	var promptChildren  = get_all_children($"PromptContainer")
	print(promptChildren)
	for i in 5:
		promptChildren[i].text = doubArr[onQuestion][i]
	#SOMETHING WENT WRONG ON 94!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
	
	pass # Replace with function body.



func _on_ChoiceA_button_down():
	if(content[onQuestion*5 + 1] == $PromptContainer/ChoiceA.text):
		get_tree().paused = false
		hide()
	pass # Replace with function body.


func _on_ChoiceB_button_down():
	if(content[onQuestion*5 + 1] == $PromptContainer/ChoiceB.text):
		get_tree().paused = false
		hide()


func _on_ChoiceC_button_down():
	if(content[onQuestion*5 + 1] == $PromptContainer/ChoiceC.text):
		get_tree().paused = false
		hide()

func _on_ChoiceD_button_down():
	if(content[onQuestion*5 + 1] == $PromptContainer/ChoiceD.text):
		get_tree().paused = false
		hide()
