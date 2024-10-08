class_name Genome

#{id:Object}
var node_genes:Dictionary;
#{innovation_number:Object}
var connection_genes:Dictionary;

var fitness:float = 0.0;
var explicit_shared_fitness:float = 0.0;
#this variable saves the currently highest innovation number
#it needs to be shared across all genomes because innovation numbers have to be unique
static var connection_innovation:int;
static var node_innovation:int;
#{input_id:[[output_id, innovation_number], [output_id1, innovation_number1]}
static var global_connections:Dictionary;

var neural_network:Array = []

func add_connection(in_node:int, out_node:int, weight:float, enabled:bool, innovation_number:int):
	connection_genes[innovation_number] = ConnectionGene.new(in_node, out_node, weight, enabled, innovation_number)

func add_node(id:int, type:Enums.NodeType):
	node_genes[id] = NodeGene.new(id, type)

func mutate_add_connection():
	#this is done to prevent the in node from being the same node as the out node
	var nodes = node_genes.values();
	var random_in_node_index:int = randi_range(0, nodes.size()-1);
	var in_node:NodeGene = nodes[random_in_node_index];
	nodes.remove_at(random_in_node_index);
	
	var out_node:NodeGene = nodes.pick_random();
	if creates_cycle(in_node, out_node) == true:
		return
	#make sure nodes are not in reverse order
	#very messy but it works
	if((in_node.type == Enums.NodeType.HIDDEN and out_node.type == Enums.NodeType.SENSOR) or 
	(in_node.type == Enums.NodeType.OUTPUT and out_node.type == Enums.NodeType.HIDDEN) or 
	(in_node.type == Enums.NodeType.OUTPUT and out_node.type == Enums.NodeType.SENSOR)):
		var temp:NodeGene = in_node
		in_node = out_node
		out_node = temp;
	#check if connection exists
	#this function could be updated to not return if the connection is found but iteratively check every possible connection until one is found or none are left
	for k in connection_genes:
		if(connection_genes[k].in_node  == in_node.id and connection_genes[k].out_node == out_node.id) or (connection_genes[k].in_node  == out_node.id and connection_genes[k].out_node == in_node.id):
			return
	
	var random_weight = randf_range(-1.0,1.0);
	
	if global_connections.has(in_node.id):
		var is_existing = false
		for i in global_connections[in_node.id]:
			if i[0] == out_node.id:
				connection_innovation = i[1]
				is_existing = true
		if !is_existing:
			connection_innovation+=1
			global_connections[in_node.id].append([out_node.id, connection_innovation])
	else:
		connection_innovation+=1
		global_connections[in_node.id] = [[out_node.id, connection_innovation]]
	connection_genes[connection_innovation] = (ConnectionGene.new(in_node.id, out_node.id, random_weight, true, connection_innovation))
	


func mutate_add_node():
	var new_node = NodeGene.new(node_innovation, Enums.NodeType.HIDDEN);
	node_genes[node_innovation] = new_node;
	node_innovation+=1
	
	var old_connection:ConnectionGene = connection_genes.values().pick_random();
	old_connection.enabled = false;
	var in_node:int = old_connection.in_node;
	var out_node:int = old_connection.out_node;
	
	var connection_to_new_node = ConnectionGene.new(in_node, new_node.id, 1.0, true, connection_innovation)
	connection_genes[connection_innovation] = connection_to_new_node
	connection_innovation+=1;
	
	var connection_out_new_node = ConnectionGene.new(new_node.id, out_node, old_connection.weight, true, connection_innovation)
	connection_genes[connection_innovation] = connection_out_new_node
	connection_innovation+=1

func crossover(other_parent:Genome) -> Genome:
	var new_genome:Genome = Genome.new();
	var is_fitness_equal = true if fitness == other_parent.fitness else false
	
	if is_fitness_equal:
		var other_parent_nodes:Dictionary = other_parent.node_genes;
		for i in node_genes:
			if other_parent.node_genes.has(i):
				new_genome.node_genes[i] = node_genes[i] if randi_range(0,1) == 0 else other_parent.node_genes[i];
				other_parent_nodes.erase(i);
			else:
				new_genome.node_genes[i] = node_genes[i];
		for i in other_parent_nodes:
			new_genome.node_genes[i] = other_parent_nodes[i];
		
		var other_parent_connections:Dictionary = other_parent.connection_genes;
		for i in connection_genes:
			if other_parent.connection_genes.has(i):
				new_genome.connection_genes[i] = connection_genes[i] if randi_range(0,1) == 0 else other_parent.connection_genes[i];
				other_parent_connections.erase(i);
			else:
				new_genome.connection_genes[i] = connection_genes[i];
		for i in other_parent_connections:
			new_genome.connection_genes[i] = other_parent_connections[i];
	else:
		for i in node_genes:
			if other_parent.node_genes.has(i):
				new_genome.node_genes[i] = node_genes[i] if randi_range(0,1) == 0 else other_parent.node_genes[i];
			else:
				new_genome.node_genes[i] = node_genes[i];
		
		for i in connection_genes:
			if other_parent.connection_genes.has(i):
				new_genome.connection_genes[i] = connection_genes[i] if randi_range(0,1) == 0 else other_parent.connection_genes[i];
			else:
				new_genome.connection_genes[i] = connection_genes[i];
	
	return new_genome;

func get_compatibility_distance(other_genome:Genome, coefficient1:float, coefficient2:float, coefficient3:float):
	#compatibility_distance = (coefficient1 * number of excess genes) / number of genes in the larger genome 
	#						+ (coefficient2 * number of disjoint genes) / number of genes in the larger genome 
	#						+ coefficient3 * average weight difference of matching genes including disabled ones
	#coefficients allow adjusting importance of the factors
	var compatibility_distance:float = 0;
	
	var excess_genes:int = 0;
	var disjoint_genes:int = 0;
	var average_weight_difference:float = 0.0;
	var this_genome_genome_amount:int = 0;
	var other_genome_genome_amount:int = 0;
	
	var node_innovation_list = node_genes.keys()
	node_innovation_list.sort()
	var highest_node_innovation:int = node_innovation_list[-1];
	
	var other_node_innovation_list = other_genome.node_genes.keys()
	other_node_innovation_list.sort()
	var highest_other_node_innovation:int = other_node_innovation_list[-1];
	
	if highest_node_innovation >= highest_other_node_innovation:
		var value:Array = get_excess_and_disjoint_node_gene_amount(self, other_genome, highest_other_node_innovation, this_genome_genome_amount, other_genome_genome_amount);
		disjoint_genes = value[0]
		excess_genes = value[1]
		this_genome_genome_amount = value[2]
		other_genome_genome_amount = value[3]
	else:
		var value:Array = get_excess_and_disjoint_node_gene_amount(other_genome, self, highest_node_innovation, other_genome_genome_amount, this_genome_genome_amount);
		disjoint_genes = value[0]
		excess_genes = value[1]
		other_genome_genome_amount = value[2]
		this_genome_genome_amount = value[3]
	
	
	var connection_innovation_list = connection_genes.keys()
	node_innovation_list.sort()
	var highest_connection_innovation:int = connection_innovation_list[-1];
	
	var other_connection_innovation_list = other_genome.connection_genes.keys()
	other_connection_innovation_list.sort()
	var highest_other_connection_innovation:int = other_connection_innovation_list[-1];
	
	if highest_connection_innovation >= highest_other_connection_innovation:
		var value:Array = get_excess_and_disjoint_connection_gene_amount_and_average_weight_difference(self, other_genome, highest_other_connection_innovation);
		disjoint_genes += value[0]
		excess_genes += value[1]
		average_weight_difference = value[2]
		this_genome_genome_amount+=value[3]
		other_genome_genome_amount+=value[4]
		
	else:
		var value:Array = get_excess_and_disjoint_connection_gene_amount_and_average_weight_difference(other_genome, self, highest_connection_innovation);
		disjoint_genes += value[0]
		excess_genes += value[1]
		average_weight_difference = value[2]
		other_genome_genome_amount+=value[3]
		this_genome_genome_amount+=value[4]
	
	if this_genome_genome_amount > other_genome_genome_amount:
		compatibility_distance = (coefficient1 * excess_genes)/this_genome_genome_amount + (coefficient2 * disjoint_genes)/this_genome_genome_amount + (coefficient3 * average_weight_difference)
	else:
		compatibility_distance = (coefficient1 * excess_genes)/other_genome_genome_amount + (coefficient2 * disjoint_genes)/other_genome_genome_amount + (coefficient3 * average_weight_difference)
	return compatibility_distance

func get_excess_and_disjoint_node_gene_amount(higher_innovation_genome:Genome, lower_innovation_genome:Genome, highest_lower_innovation:int, higher_genome_count:int, lower_genome_count:int):
	var disjoint_amount:int = 0;
	var excess_amount:int = 0;
	var lower_genome_amount = lower_genome_count
	var higher_genome_amount = higher_genome_count
	
	for i in lower_innovation_genome.node_genes:
		lower_genome_amount+=1
		if !higher_innovation_genome.node_genes.has(i):
			disjoint_amount+=1
	for i in higher_innovation_genome.node_genes:
		higher_genome_amount+=1
		if !lower_innovation_genome.node_genes.has(i):
			if highest_lower_innovation < i:
				excess_amount+=1
			else:
				disjoint_amount+=1
	return[disjoint_amount, excess_amount, lower_genome_amount, higher_genome_amount]
#sorry for this name
func get_excess_and_disjoint_connection_gene_amount_and_average_weight_difference(higher_innovation_genome:Genome, lower_innovation_genome:Genome, highest_lower_innovation:int):
	var disjoint_amount:int = 0;
	var excess_amount:int = 0;
	var total_weight_difference:float = 0;
	var total_shared_weights:float = 0;
	var lower_genome_amount = 0
	var higher_genome_amount = 0
	
	for i in lower_innovation_genome.connection_genes:
		lower_genome_amount+=1
		if !higher_innovation_genome.connection_genes.has(i):
			disjoint_amount+=1
		else:
			total_shared_weights+=1
			total_weight_difference+= abs(abs(higher_innovation_genome.connection_genes[i].weight)-abs(lower_innovation_genome.connection_genes[i].weight))
	for i in higher_innovation_genome.connection_genes:
		higher_genome_amount+=1
		if !lower_innovation_genome.connection_genes.has(i):
			if i > highest_lower_innovation:
				
				excess_amount+=1
			else:
				disjoint_amount+=1
	
	var average_weight_difference = total_weight_difference/total_shared_weights if total_shared_weights > 0 else 10
	return[disjoint_amount, excess_amount, average_weight_difference, lower_genome_amount, higher_genome_amount];

func creates_cycle(in_node:NodeGene, out_node:NodeGene):
	var visited:Dictionary = {out_node: 0};
	while true:
		var num_added = 0
		for connection in connection_genes:
			if visited.has(connection_genes[connection].in_node) and !visited.has(connection_genes[connection].out_node):
				if connection_genes[connection].out_node == in_node:
					return true
				visited[connection_genes[connection].out_node] = 0
				num_added+=1
		if num_added == 0:
			return false

func make_feed_forward_layers():
	var layers = []
	var s = {} 

	for i in node_genes:
		if node_genes[i].type == Enums.NodeType.SENSOR:
			s[i] = true

	while true:
		var candidates = {} 

		for i in connection_genes:
			var in_node = connection_genes[i].in_node
			var out_node = connection_genes[i].out_node
			if s.has(in_node) and not s.has(out_node):
				candidates[out_node] = true

		var valid_candidates = {}

		for candidate in candidates.keys():
			var all_inputs_processed = true
			for j in connection_genes:
				if connection_genes[j].out_node == candidate:
					if not s.has(connection_genes[j].in_node):
						all_inputs_processed = false
						break
			if all_inputs_processed:
				valid_candidates[candidate] = true

		if valid_candidates.size() == 0:
			break

		var new_layer = []
		for node in valid_candidates.keys():
			new_layer.append(node)
			s[node] = true 
		layers.append(new_layer)
	neural_network = layers

func feed_forward():
	print(neural_network)
