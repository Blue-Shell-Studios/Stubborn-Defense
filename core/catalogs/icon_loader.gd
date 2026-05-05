class_name IconLoader
extends Object

# Small shared helper so Shop/LevelUp/etc don't each re-implement icon casting & loading.
# Also caches loaded textures by path.

static var _cache: Dictionary = {}

static func load_texture(path_value: Variant) -> Texture2D:
	if not (path_value is String):
		return null

	var path := path_value as String
	if path.is_empty():
		return null

	if _cache.has(path):
		return _cache[path] as Texture2D

	var tex := load(path) as Texture2D
	_cache[path] = tex
	return tex

