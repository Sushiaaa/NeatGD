class_name Species

var representative_genome:Genome;
var members:Array;
var shared_fitness:float;
var compatibility_threshold = 1.5;

func _init(representative:Genome):
	representative_genome = representative;
	members.append(representative)

func get_shared_fitness(genome:Genome) -> float:
	var sharing_sum:int = 0
	for i in members:
		if members.size() == 0:
			sharing_sum = 1
		if i != genome:
			sharing_sum+=sharing(genome, i)

	return genome.fitness/sharing_sum if sharing_sum > 0 else 0

func sharing(genome1:Genome, genome2:Genome):

	if genome1.get_compatibility_distance(genome2, 1.0, 1.0, 1.0) > compatibility_threshold:
		return 0
	return 1 
