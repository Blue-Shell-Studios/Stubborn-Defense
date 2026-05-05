class_name WeightedRoll
extends Object

static func pick_index(weights: Array) -> int:
	if weights.is_empty():
		return 0

	var total_weight := 0.0
	for weight in weights:
		total_weight += maxf(float(weight), 0.0)

	if total_weight <= 0.0:
		return 0

	var roll := randf() * total_weight
	for index in range(weights.size()):
		roll -= maxf(float(weights[index]), 0.0)
		if roll <= 0.0:
			return index

	return 0

