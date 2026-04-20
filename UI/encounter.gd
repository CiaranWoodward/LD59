extends Node
class_name Encounter

enum SanityRequirement {
	ANY,
	SANE,
	INSANE,
}

@export var title: String = "What's that?"
@export_multiline var encounter_text: String = "There is a rustling"
@export_multiline var encounter_text_sane: String = ""
@export_multiline var encounter_text_insane: String = ""

@export_group("Choice A")
@export var choicea_text: String = ""
@export var choicea_card: PackedScene
@export var choicea_sanity: SanityRequirement = SanityRequirement.ANY
@export var choicea_stat: Global.Statistic = Global.Statistic.HEALTH
@export var choicea_stat_delta: int = 0
@export var choicea_card_required: String = ""
@export var choicea_lose_required_card: bool = true

@export_group("Choice B")
@export var choiceb_text: String = ""
@export var choiceb_card: PackedScene
@export var choiceb_sanity: SanityRequirement = SanityRequirement.ANY
@export var choiceb_stat: Global.Statistic = Global.Statistic.HEALTH
@export var choiceb_stat_delta: int = 0
@export var choiceb_card_required: String = ""
@export var choiceb_lose_required_card: bool = true

@export_group("Skip")
@export var skip_text: String = "Ignore"
@export var skip_sanity: SanityRequirement = SanityRequirement.ANY
@export var skip_stat: Global.Statistic = Global.Statistic.HEALTH
@export var skip_stat_delta: int = 0

@export_group("Restrictions")
@export var repeatable: bool = false
@export var requires_fire: bool = false
@export var requires_no_fire: bool = false
@export var requires_day: bool = false
@export var requires_night: bool = false
@export var sanity_requirement: SanityRequirement = SanityRequirement.ANY
@export var must_be_after_encounter: NodePath = ""
@export var must_be_scene_type: Global.SceneType = Global.SceneType.ANY

var played: bool = false

func can_encounter() -> bool:
	if played and not repeatable:
		return false
	if requires_fire and Global.statistics[Global.Statistic.FIRE_LIT] <= 0:
		return false
	if requires_no_fire and Global.statistics[Global.Statistic.FIRE_LIT] > 0:
		return false
	if requires_day and not Global.is_daytime():
		return false
	if requires_night and Global.is_daytime():
		return false
	match sanity_requirement:
		SanityRequirement.SANE:
			if Global.is_insane():
				return false
		SanityRequirement.INSANE:
			if not Global.is_insane():
				return false
	if must_be_after_encounter != NodePath(""):
		var prereq := get_node_or_null(must_be_after_encounter)
		if prereq is Encounter and not prereq.played:
			return false
	if must_be_scene_type != Global.SceneType.ANY:
		if Global.table and Global.table.scene_type != must_be_scene_type:
			return false
	return true
