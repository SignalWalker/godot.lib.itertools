class_name Iterator extends RefCounted

func _init() -> void:
	assert(false, "tried to instantiate Iterator")

static func _iter(i: Variant) -> Object:
	if i is Array:
		return IterArray.new(i as Array)
	assert(i is Object && is_iterator(i as Object), "object provided to iterator transformer is not iterable")
	return i


static func is_iterator(i: Object) -> bool:
	return i != null && i.has_method(&"_iter_init") && i.has_method(&"_iter_next") && i.has_method(&"_iter_get")

static func map(iter: Variant, fn: Callable) -> IterMap:
	return IterMap.new(_iter(iter), fn)

static func filter(iter: Variant, pred: Callable) -> IterFilter:
	return IterFilter.new(_iter(iter), pred)

static func filter_map(iter: Variant, pred: Callable, fn: Callable) -> IterMap:
	return IterMap.new(IterFilter.new(_iter(iter), pred), fn)

func collect() -> Array:
	var res: Array = []
	for item: Variant in self:
		res.push_back(item)
	return res

class IterArray extends Iterator:
	var arr: Array
	var from: int = 0
	var i: int = 0
	func _init(a: Array, f: int = 0) -> void:
		assert(a != null)
		self.arr = a
		self.from = f
		self.i = self.from

	func has_next() -> bool:
		return self.i < arr.size()

	func _iter_init(state: Array) -> bool:
		self.i = self.from
		return self.has_next()

	func _iter_next(state: Array) -> bool:
		self.i += 1
		return self.has_next()

	func _iter_get(state: Variant) -> Variant:
		return self.arr[self.i]

class IterMap extends Iterator:
	var iter: Variant
	var fn: Callable
	func _init(i: Object, f: Callable) -> void:
		assert(Iterator.is_iterator(i))
		self.iter = i
		self.fn = f

	func _iter_init(state: Array) -> bool:
		return self.iter._iter_init(state)

	func _iter_next(state: Array) -> bool:
		return self.iter._iter_next(state)

	func _iter_get(state: Variant) -> Variant:
		return self.fn.call(self.iter._iter_get(state))

class IterFilter extends Iterator:
	var iter: Variant
	var pred: Callable
	func _init(i: Object, p: Callable) -> void:
		assert(Iterator.is_iterator(i))
		self.iter = i
		self.pred = p

	func _iter_init(state: Array) -> bool:
		return self.iter._iter_init(state)

	func _iter_next(state: Array) -> bool:
		# advance
		if !self.iter._iter_next(state):
			# no next item
			return false
		# skip elements that fail the predicate
		# TODO :: am i using state correctly here? who knows
		while !self.pred.call(self.iter._iter_get(state)):
			# skip to the next item
			if !self.iter._iter_next(state):
				# there is no next item
				return false
		return true

	func _iter_get(state: Variant) -> Variant:
		return self.iter._iter_get(state)
