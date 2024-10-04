class_name Population

var species:Array;
var population:Array;
@export var compatibility_threshold:float = 1.5;

func initiate_population(size:int, input_amount:int, output_amount:int):
	for i in range(size):
		var new_genome = Genome.new();
		for j in range(input_amount):
			new_genome.add_node(j, Enums.NodeType.SENSOR)
			for k in range(output_amount):
				new_genome.add_connection(j, k, 1.0, true, j*output_amount+k)
		for j in range(output_amount):
			new_genome.add_node(input_amount+j, Enums.NodeType.OUTPUT)
		population.append(new_genome)

	population[0].node_innovation = input_amount+output_amount
	population[0].connection_innovation = input_amount*output_amount

func speciate(coefficient1:float, coefficient2:float, coefficient3:float):
	species = [[population[0]]]
	for genome in population.slice(1):
		var added_to_species:bool = false
		for specie in species:
			if specie[0].get_compatibility_distance(genome, coefficient1, coefficient2, coefficient3) <= compatibility_threshold:
				specie.append(genome)
				added_to_species = true
				break
		if !added_to_species:
			species.append([genome])

func get_shared_fitness(genome:Genome, species:Array) -> float:
	var sharing_sum:int = 0
	for i in species:
		if species.size() == 0:
			sharing_sum = 1
		if i != genome:
			sharing_sum+=sharing(genome, i)
	return genome.fitness/sharing_sum

func sharing(genome1:Genome, genome2:Genome):
	if genome1.get_compatibility_distance(genome2, 1.0, 1.0, 1.0) > compatibility_threshold:
		return 0
	return 1 
