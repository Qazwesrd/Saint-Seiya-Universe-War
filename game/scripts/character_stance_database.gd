extends RefCounted
class_name CharacterStanceDatabase
## Distinct procedural pose offsets for the fallback player mannequin.
const ACTION_STATES := ["idle", "walk", "run", "attack", "hit", "death"]
const CLASS_PROFILES := {
 "pegasus":{"stance_id":"pegasus_boxing","style":"forward_boxing","torso_pitch":-0.075,"torso_roll":-0.025,"arm_rest":[-0.34,-0.62],"forearm_rest":[-0.28,-0.42],"leg_rest":[0.035,-0.025],"gait_scale":1.12,"idle_breath":1.0},
 "dragon":{"stance_id":"dragon_guard","style":"low_guard","torso_pitch":0.055,"torso_roll":0.0,"arm_rest":[-0.82,-0.72],"forearm_rest":[-0.72,-0.68],"leg_rest":[-0.09,0.08],"gait_scale":0.78,"idle_breath":0.72},
 "cygnus":{"stance_id":"cygnus_frost","style":"upright_frost","torso_pitch":-0.015,"torso_roll":0.0,"arm_rest":[-0.20,-0.26],"forearm_rest":[-0.12,-0.16],"leg_rest":[0.0,0.0],"gait_scale":0.86,"idle_breath":0.62},
 "andromeda":{"stance_id":"andromeda_grace","style":"flowing_chain","torso_pitch":0.025,"torso_roll":0.035,"arm_rest":[-0.18,-0.42],"forearm_rest":[-0.22,-0.35],"leg_rest":[0.015,-0.015],"gait_scale":0.92,"idle_breath":0.9},
 "phoenix":{"stance_id":"phoenix_ignition","style":"angled_attack","torso_pitch":-0.11,"torso_roll":0.065,"arm_rest":[-0.72,-0.24],"forearm_rest":[-0.52,-0.18],"leg_rest":[-0.055,0.045],"gait_scale":1.18,"idle_breath":1.18},
 "sea_dragon":{"stance_id":"sea_dragon_tide","style":"tidal_flow","torso_pitch":-0.025,"torso_roll":0.045,"arm_rest":[-0.36,-0.48],"forearm_rest":[-0.30,-0.36],"leg_rest":[0.025,-0.02],"gait_scale":0.94,"idle_breath":0.9},
 "poseidon":{"stance_id":"poseidon_emperor","style":"regal_tidal","torso_pitch":0.035,"torso_roll":0.0,"arm_rest":[-0.16,-0.24],"forearm_rest":[-0.10,-0.18],"leg_rest":[0.0,0.0],"gait_scale":0.72,"idle_breath":0.55},
 "tenmou":{"stance_id":"underworld_reaper","style":"cold_reaper","torso_pitch":0.09,"torso_roll":-0.02,"arm_rest":[-0.55,-0.68],"forearm_rest":[-0.48,-0.56],"leg_rest":[-0.04,0.035],"gait_scale":0.82,"idle_breath":0.5},
 "hades":{"stance_id":"hades_sovereign","style":"underworld_sovereign","torso_pitch":0.015,"torso_roll":0.0,"arm_rest":[-0.20,-0.18],"forearm_rest":[-0.12,-0.12],"leg_rest":[0.0,0.0],"gait_scale":0.68,"idle_breath":0.42},
 "hypnos":{"stance_id":"hypnos_dream","style":"dreaming_float","torso_pitch":-0.025,"torso_roll":-0.035,"arm_rest":[-0.10,-0.32],"forearm_rest":[-0.08,-0.24],"leg_rest":[0.02,-0.02],"gait_scale":0.65,"idle_breath":0.38},
 "thanatos":{"stance_id":"thanatos_reaper","style":"executioner","torso_pitch":0.10,"torso_roll":0.025,"arm_rest":[-0.66,-0.48],"forearm_rest":[-0.54,-0.42],"leg_rest":[-0.07,0.06],"gait_scale":0.9,"idle_breath":0.48},
 "tenkishi":{"stance_id":"heavenly_warrior","style":"winged_ready","torso_pitch":-0.045,"torso_roll":0.0,"arm_rest":[-0.42,-0.52],"forearm_rest":[-0.30,-0.38],"leg_rest":[-0.025,0.025],"gait_scale":1.0,"idle_breath":0.9},
 "athena":{"stance_id":"athena_divine","style":"protective_divine","torso_pitch":0.0,"torso_roll":0.0,"arm_rest":[-0.10,-0.10],"forearm_rest":[-0.08,-0.08],"leg_rest":[0.0,0.0],"gait_scale":0.72,"idle_breath":0.52},
 "apollo":{"stance_id":"apollo_solar","style":"solar_pride","torso_pitch":-0.025,"torso_roll":0.0,"arm_rest":[-0.18,-0.34],"forearm_rest":[-0.12,-0.25],"leg_rest":[0.0,0.0],"gait_scale":0.82,"idle_breath":0.66},
 "zeus":{"stance_id":"zeus_thunder","style":"thunder_authority","torso_pitch":0.045,"torso_roll":0.0,"arm_rest":[-0.46,-0.38],"forearm_rest":[-0.34,-0.30],"leg_rest":[-0.04,0.04],"gait_scale":0.78,"idle_breath":0.62},
 "artemis":{"stance_id":"artemis_moon","style":"moon_archer","torso_pitch":-0.035,"torso_roll":0.055,"arm_rest":[-0.24,-0.52],"forearm_rest":[-0.18,-0.40],"leg_rest":[0.025,-0.025],"gait_scale":0.9,"idle_breath":0.52},
 "odin":{"stance_id":"odin_rune","style":"northern_guard","torso_pitch":0.035,"torso_roll":-0.025,"arm_rest":[-0.56,-0.62],"forearm_rest":[-0.48,-0.52],"leg_rest":[-0.05,0.05],"gait_scale":0.76,"idle_breath":0.58},
 "lucifer":{"stance_id":"lucifer_fallen","style":"fallen_wing","torso_pitch":0.025,"torso_roll":-0.065,"arm_rest":[-0.18,-0.62],"forearm_rest":[-0.14,-0.48],"leg_rest":[0.035,-0.035],"gait_scale":0.94,"idle_breath":0.82},
 "chronos":{"stance_id":"chronos_time","style":"timekeeper","torso_pitch":0.0,"torso_roll":0.0,"arm_rest":[-0.32,-0.32],"forearm_rest":[-0.22,-0.22],"leg_rest":[0.0,0.0],"gait_scale":0.7,"idle_breath":0.4},
 "ares":{"stance_id":"ares_warlord","style":"heavy_warlord","torso_pitch":0.12,"torso_roll":-0.02,"arm_rest":[-0.82,-0.66],"forearm_rest":[-0.62,-0.54],"leg_rest":[-0.10,0.09],"gait_scale":0.84,"idle_breath":0.8}
}
const FACTION_PROFILES := {
 "sanctuary":{"stance_id":"sanctuary_ready","style":"balanced_guard","torso_pitch":-0.02,"torso_roll":0.0,"arm_rest":[-0.32,-0.38],"forearm_rest":[-0.24,-0.28],"leg_rest":[-0.02,0.02],"gait_scale":1.0,"idle_breath":0.8},
 "dark_saints":{"stance_id":"dark_saint_duelist","style":"aggressive_duelist","torso_pitch":-0.085,"torso_roll":0.035,"arm_rest":[-0.62,-0.28],"forearm_rest":[-0.48,-0.18],"leg_rest":[-0.05,0.04],"gait_scale":1.08,"idle_breath":1.0},
 "sea":{"stance_id":"sea_mariner","style":"tidal_flow","torso_pitch":-0.02,"torso_roll":0.035,"arm_rest":[-0.28,-0.42],"forearm_rest":[-0.22,-0.32],"leg_rest":[0.02,-0.02],"gait_scale":0.9,"idle_breath":0.8},
 "underworld":{"stance_id":"specter_guard","style":"cold_reaper","torso_pitch":0.075,"torso_roll":-0.015,"arm_rest":[-0.58,-0.64],"forearm_rest":[-0.46,-0.52],"leg_rest":[-0.035,0.03],"gait_scale":0.78,"idle_breath":0.48},
 "divine":{"stance_id":"divine_guard","style":"protective_divine","torso_pitch":0.0,"torso_roll":0.0,"arm_rest":[-0.12,-0.18],"forearm_rest":[-0.08,-0.14],"leg_rest":[0.0,0.0],"gait_scale":0.72,"idle_breath":0.52},
 "asgard":{"stance_id":"asgardian_guard","style":"northern_guard","torso_pitch":0.045,"torso_roll":0.0,"arm_rest":[-0.5,-0.58],"forearm_rest":[-0.42,-0.48],"leg_rest":[-0.04,0.04],"gait_scale":0.78,"idle_breath":0.58},
 "steel":{"stance_id":"steel_combat","style":"mechanical_ready","torso_pitch":-0.015,"torso_roll":0.0,"arm_rest":[-0.42,-0.42],"forearm_rest":[-0.32,-0.32],"leg_rest":[-0.02,0.02],"gait_scale":0.86,"idle_breath":0.25},
 "bluegrad":{"stance_id":"bluegrad_frost","style":"upright_frost","torso_pitch":0.0,"torso_roll":0.0,"arm_rest":[-0.18,-0.28],"forearm_rest":[-0.12,-0.18],"leg_rest":[0.0,0.0],"gait_scale":0.78,"idle_breath":0.42},
 "fallen":{"stance_id":"fallen_angel","style":"fallen_wing","torso_pitch":0.02,"torso_roll":-0.06,"arm_rest":[-0.2,-0.58],"forearm_rest":[-0.16,-0.44],"leg_rest":[0.03,-0.03],"gait_scale":0.9,"idle_breath":0.72},
 "titans":{"stance_id":"titan_colossus","style":"heavy_warlord","torso_pitch":0.09,"torso_roll":0.0,"arm_rest":[-0.72,-0.68],"forearm_rest":[-0.58,-0.54],"leg_rest":[-0.08,0.08],"gait_scale":0.72,"idle_breath":0.7},
 "giants":{"stance_id":"giant_brute","style":"heavy_warlord","torso_pitch":0.14,"torso_roll":0.0,"arm_rest":[-0.88,-0.78],"forearm_rest":[-0.68,-0.62],"leg_rest":[-0.12,0.12],"gait_scale":0.7,"idle_breath":0.86},
 "hongmeng":{"stance_id":"hongmeng_celestial","style":"celestial_stillness","torso_pitch":0.0,"torso_roll":0.0,"arm_rest":[-0.08,-0.08],"forearm_rest":[-0.06,-0.06],"leg_rest":[0.0,0.0],"gait_scale":0.55,"idle_breath":0.25}
}
const HONGJUN_PROFILE := {"stance_id":"hongjun_primordial","style":"primordial_celestial","torso_pitch":-0.01,"torso_roll":0.0,"arm_rest":[-0.12,-0.12],"forearm_rest":[-0.08,-0.08],"leg_rest":[0.0,0.0],"gait_scale":0.52,"idle_breath":0.18,"hover_idle":true}

static func get_profile(class_id: String, faction_id: String = "sanctuary", is_supreme_deity: bool = false) -> Dictionary:
 var result: Dictionary = FACTION_PROFILES.get(faction_id, FACTION_PROFILES["sanctuary"]).duplicate(true)
 if CLASS_PROFILES.has(class_id):
  result = CLASS_PROFILES[class_id].duplicate(true)
 if is_supreme_deity:
  result = HONGJUN_PROFILE.duplicate(true)
  result["character_title"] = "鸿钧老祖"
 result["class_id"] = class_id
 result["faction_id"] = faction_id
 return result

static func get_supported_action_states() -> Array[String]:
 var result: Array[String] = []
 for state_id in ACTION_STATES:
  result.append(state_id)
 return result

static func validate_catalog() -> Dictionary:
 var errors: Array[String] = []
 for class_id in CLASS_PROFILES:
  var profile: Dictionary = CLASS_PROFILES[class_id]
  for key in ["stance_id","style","torso_pitch","torso_roll","arm_rest","forearm_rest","leg_rest","gait_scale","idle_breath"]:
   if not profile.has(key):
    errors.append("%s missing %s" % [class_id,key])
  if str(profile.get("stance_id","")).is_empty():
   errors.append("%s has an empty stance id" % class_id)
 for faction_id in FACTION_PROFILES:
  if str(FACTION_PROFILES[faction_id].get("stance_id","")).is_empty():
   errors.append("%s has an empty faction stance id" % faction_id)
 return {"valid":errors.is_empty(),"errors":errors}
