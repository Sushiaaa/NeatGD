class_name ConnectionGene

var in_node:int;
var out_node:int;
var weight:float;
var enabled:bool;
var innovation_number:int;

func _init(in_node, out_node, weight, enabled, innovation_number):
	self.in_node = in_node;
	self.out_node = out_node;
	self.weight = weight;
	self.enabled = enabled;
	self.innovation_number = innovation_number;
