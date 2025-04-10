extends Node2D
class_name EnergyChargingComponent

var energy_max: float = 100
var energy_cur: float = 50 #value for energy currently available
var energy_after_charging: float = 50 #value for energy that will be expended once charging is complete

const charging_rate: float = 30
const energy_regen_rate: float = 10

var b_charging : bool = false

#Main Tick
func _process(delta: float) -> void:
	ResolveEnergy(delta)

#Call this function to start to store energy (charging up to be released)
func StartCharging() -> void:
	b_charging = true
	
#Call this function to end storage of energy (release charged energy)
	#Returns some power value proportional to the energy charged
func EndCharging() -> float:
	b_charging = false
	#consume charged energy
	var energy_consumed: float = energy_cur - energy_after_charging
	energy_cur = energy_after_charging
	
	return energy_consumed
	

#Does a pass through and calculates energy_cur and energy_after_charging 
func ResolveEnergy(delta: float) -> void:
	#Regenerate during this time frame
	energy_cur += energy_regen_rate * delta
	#energy_after_charging += energy_regen_rate * delta
	if (energy_cur >= energy_max): #don't go above max energy 
		energy_cur = energy_max
	#if (energy_after_charging >= energy_max):
		#energy_after_charging = energy_max
	
	
	if (b_charging):
		energy_after_charging -= charging_rate * delta
		if (energy_after_charging <= 0): #don't go under 0 energy 
			energy_after_charging = 0
	else:
		energy_after_charging = energy_cur
		
		
	pass
