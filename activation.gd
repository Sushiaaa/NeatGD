class_name Activation

func relu(input:float) -> float:
	return max(0.0, input)

func lelu(input:float) -> float:
	var leak = 0.005
	return input if input > 0 else input * leak

func sigmoid(input:float) -> float:
	input = max(-60.0, min(60.0, 5.0 * input))
	return 1.0 / (1.0 + exp(-input))
