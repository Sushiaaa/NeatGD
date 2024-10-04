class_name NodeGene

var id:int;

#0 = hidden
#1 = sensor
#2 = output

var type:int;

func _init(id:int, type:int):
	self.type = type;
	self.id = id;
