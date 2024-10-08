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
	var first_species = Species.new(population[0]);
	species.append(first_species)
	for genome in population.slice(1):
		var added_to_species:bool = false
		for specie in species:
			if specie.representative_genome.get_compatibility_distance(genome, coefficient1, coefficient2, coefficient3) <= compatibility_threshold:
				specie.members.append(genome)
				added_to_species = true
				break
		if !added_to_species:
			species.append(Species.new(genome))

func sort_by_species_fitness(a, b):
	return a.shared_fitness > b.shared_fitness

func new_generation():
	var species_offsprings:Array
	
	var total_shared_fitness:float
	for specie in range(species.size()):
		for genome in species[specie].members:
			var genome_shared_fitness:float
			genome_shared_fitness = species[specie].get_shared_fitness(genome)
			genome.explicit_shared_fitness = genome_shared_fitness
			total_shared_fitness+=genome_shared_fitness
			species[specie].shared_fitness+=genome_shared_fitness

	species.sort_custom(sort_by_species_fitness)
	
	if total_shared_fitness > 0:
		for i in range(species.size()):
			var current_total_population:float
			if i != species.size()-1:
				species_offsprings.append(round((species[i].shared_fitness/total_shared_fitness)*population.size()))
				current_total_population+= round((species[i].shared_fitness/total_shared_fitness)*population.size())
			else:
				species_offsprings.append(population.size()-current_total_population)
	var new_population:Array;
	for i in range(species.size()):
		print(species[i].members)
		for j in range(species_offsprings[i]):
			new_population.append(species[i].members.pick_random().crossover(species[i].members.pick_random()))
	population = new_population
