class_name NumberFormatter
extends RefCounted

const SUFFIXES := ["", "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc"]

static func format(value: float) -> String:
	if is_nan(value): return "NaN"
	if is_inf(value): return "∞"
	var absolute := absf(value)
	if absolute < 1000.0:
		return "%.0f" % value if absolute >= 10.0 else "%.1f" % value
	var group := int(floor(log(absolute) / log(1000.0)))
	if group < SUFFIXES.size():
		return "%.2f%s" % [value / pow(1000.0, group), SUFFIXES[group]]
	return "%.2e" % value

