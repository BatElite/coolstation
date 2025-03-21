// Contains:
// - Help procs
// - Grab procs
// - Disarm procs
// - Harm procs
// - Helper procs:
// -- attackResult datum [This is where the magic happens.]
// -- Targeting checks
// -- Calculate damage
// -- Target damage modifiers
// -- After attack

///////////////////////////////////////////////// Help intent //////////////////////////////////////////////

/mob/proc/do_help(var/mob/living/M)
	if (!istype(M))
		return
	src.lastattacked = M
	if (src != M && M.getStatusDuration("burning")) //help others put out fires!!
		src.help_put_out_fire(M)
	else if (src == M && src.getStatusDuration("burning"))
		M.resist()
	else if ((M.health <= 0 || M.find_ailment_by_type(/datum/ailment/malady/flatline)) && src.health >= -75.0)
		if (src == M && src.is_bleeding())
			src.staunch_bleeding(M) // if they've got SOMETHING to do let's not just harass them for trying to do CPR on themselves
		else
			src.administer_CPR(M)
	else if (M.is_bleeding())
		src.staunch_bleeding(M)
	else if (src.health > 0)
		src.shake_awake(M)

/mob/proc/help_put_out_fire(var/mob/living/M)
	playsound(M.loc, 'sound/impact_sounds/Generic_Shove_1.ogg', 50, 1, 0 , 0.7)
	src.visible_message("<span class='notice'>[src] pats down [M] wildly, trying to put out the fire!</span>")

	if (ishuman(src))
		var/mob/living/carbon/human/H = src
		var/obj/item/clothing/gloves/G = H.gloves
		if (G && G.hasProperty("heatprot") && (G.getProperty("heatprot") >= 7))
			M.update_burning(-2.5)
			boutput(H, "<span class='notice'>Your [G] protect you from the flames!</span>")
		else
			M.update_burning(-1.2)
			H.TakeDamage(prob(50) ? "l_arm" : "r_arm", 0, rand(1,2))
			playsound(src, "sound/impact_sounds/burn_sizzle.ogg", 30, 1)
			boutput(src, "<span class='alert'>Your hands burn from patting the flames!</span>")
	else
		M.update_burning(-1.2)
		src.TakeDamage("All", 0, rand(1,2))
		playsound(src, "sound/impact_sounds/burn_sizzle.ogg", 30, 1)
		boutput(src, "<span class='alert'>Your hands burn from patting the flames!</span>")


/mob/proc/shake_awake(var/mob/living/target)
	if (!src || !target)
		return 0

	if (ishuman(target))
		var/mob/living/carbon/human/H = target
		if (H)
			H.add_fingerprint(src) // Just put 'em on the mob itself, like pulling does. Simplifies forensic analysis a bit (Convair880).

	target.sleeping = 0
	target.delStatus("resting")

	target.changeStatus("stunned", -5 SECONDS)
	target.changeStatus("paralysis", -5 SECONDS)
	target.changeStatus("weakened", -5 SECONDS)

	playsound(src.loc, 'sound/impact_sounds/Generic_Shove_1.ogg', 50, 1, -1)
	if (src == target)
		var/obj/stool/S = (locate(/obj/stool) in src.loc)
		if (S)
			S.buckle_in(src,src)
		if(src.hasStatus("shivering"))
			src.visible_message("<span class='alert'><B>[src] shakes themselves, trying to warm up!</B></span>")
			src.changeStatus("shivering", -1 SECONDS)
		else if(istype(src.wear_mask,/obj/item/clothing/mask/moustache))
			src.visible_message("<span class='alert'><B>[src] twirls [his_or_her(src)] moustache and laughs [pick_string("tweak_yo_self.txt", "moustache")]!</B></span>")
		else if(istype(src.wear_mask,/obj/item/clothing/mask/clown_hat))
			var/obj/item/clothing/mask/clown_hat/mask = src.wear_mask
			mask.honk_nose(src)
		else
			var/item = src.get_random_equipped_thing_name()
			if (item)
				var/v = pick("tidies","adjusts","brushes off", "flicks a piece of lint off", "tousles", "fixes", "readjusts","fusses with", "sweeps off")
				src.visible_message("<span class='notice'>[src] [v] [his_or_her(src)] [item]!</span>")
			else
				src.visible_message("<span class='notice'>[src] pats themselves on the back. Feel better, [src].</span>")

	else
		if (target.lying)
			src.visible_message("<span class='notice'>[src] shakes [target], trying to wake them up!</span>")
		else if(target.hasStatus("shivering"))
			src.visible_message("<span class='alert'><B>[src] shakes [target], trying to warm up!</B></span>")
			target.changeStatus("shivering", -2 SECONDS)
		else
			if (ishuman(target) && ishuman(src))
				var/mob/living/carbon/human/Z = src
				var/mob/living/carbon/human/X = target

				if (Z.zone_sel && Z.zone_sel.selecting == "head")
					var/obj/item/clothing/head/sunhat/hat = X.head
					if(istype(hat) && hat.uses)
						src.visible_message("<span class='alert'>[src] tries to pat [target] on the head, but gets shocked by [target]'s hat!</span>")
						elecflash(target)

						hat.uses = max(0, hat.uses - 1)
						if (hat.uses < 1)
							X.head.icon_state = splittext(hat.icon_state,"-")[1]
							X.head.item_state = splittext(hat.item_state,"-")[1]
							X.update_clothing()

						if (hat.uses <= 0)
							X.show_text("The sunhat is no longer electrically charged.", "red")
						else
							X.show_text("The stunhat has [hat.uses] charges left!", "red")


						src.do_disorient(140, weakened = 40, stunned = 20, disorient = 80)
						src.stuttering = max(target.stuttering,5)
					else
						src.visible_message("<span class='notice'>[src] gently pats [target] on the head.</span>")
					return

			if (ismobcritter(target))
				var/mob/living/critter/C = target
				C.on_pet(src)
			else
				src.visible_message("<span class='notice'>[src] shakes [target], trying to grab their attention!</span>")
	hit_twitch(target)


/mob/proc/administer_CPR(var/mob/living/carbon/human/target)
	boutput(src, "<span class='alert'>You have no idea how to perform CPR.</span>")
	return

/mob/living/administer_CPR(var/mob/living/target)
	if (!src || !target)
		return 0

	if (src == target) // :I
		boutput(src, "<span class='alert'>You desperately try to think of a way to do CPR on yourself, but it's just not logically possible!</span>")
		return

	if (ishuman(target))
		var/mob/living/carbon/human/H = target
		if (H.head && (H.head.c_flags & 4))
			boutput(src, "<span class='notice'>You need to take off their headgear before you can give CPR!</span>")
			return

		if (H.wear_mask && !(H.wear_mask.c_flags & 32))
			boutput(src, "<span class='notice'>You need to take off their facemask before you can give CPR!</span>")
			return

	if (target.cpr_time >= world.time)
		return

	if (isdead(target))
		src.visible_message("<span class='alert'><B>[src] tries to perform CPR, but it's too late for [target]!</B></span>")
		return

	src.lastattacked = target
	target.cpr_time = world.time + src.combat_click_delay

	src.visible_message("<span class='alert'><B>[src] is trying to perform CPR on [target]!</B></span>")
	if (do_mob(src, target, 40)) //todo : unfuck this into a progres bar or something that happens automatically over time
		if (target.health < 0 || target.find_ailment_by_type(/datum/ailment/malady/flatline))
			target.take_oxygen_deprivation(-15)
			target.losebreath = 0
			target.changeStatus("paralysis", -2 SECONDS)

			if(target.find_ailment_by_type(/datum/ailment/malady/flatline) && target.health > -50)
				if ((target.reagents?.has_reagent("epinephrine") || target.reagents?.has_reagent("atropine")) ? prob(5) : prob(2))
					target.cure_disease_by_path(/datum/ailment/malady/flatline)

			if (src)
				src.visible_message("<span class='alert'>[src] performs CPR on [target]!</span>")

/mob/living/carbon/human/administer_CPR(var/mob/living/target)
	if (src.head && (src.head.c_flags & 4))
		boutput(src, "<span class='notice'>You need to take off your headgear before you can give CPR!</span>")
		return

	if (src.wear_mask && !(src.wear_mask.c_flags & 32))
		boutput(src, "<span class='notice'>You need to take off your facemask before you can give CPR!</span>")
		return
	..()

///////////////////////////////////////////// Grab intent //////////////////////////////////////////////////////////

/mob/living/proc/grab_self()
	if (!src)
		return 0
	return 1

/mob/living/grab_self()
	if(!..())
		return

	var/obj/stool/S = (locate(/obj/stool) in src.loc)
	if (S && !src.lying && !src.getStatusDuration("weakened") && !src.getStatusDuration("paralysis"))
		// TODO remove this shit when stool code is in a better place
		if(istype(S, /obj/stool/chair/stepladder))
			S:stand_on(src)
		else
			S.buckle_in(src,src,src.a_intent == INTENT_GRAB)
	else /*
		var/obj/item/grab/block/G = new /obj/item/grab/block(src, src, src)
		src.put_in_hand(G, src.hand)

		playsound(src.loc, 'sound/impact_sounds/Generic_Shove_1.ogg', 50, 1, -1)
		src.visible_message("<span class='alert'>[src] starts blocking!</span>")
		SEND_SIGNAL(src, COMSIG_UNARMED_BLOCK_BEGIN, G)
		src.setStatus("blocking", duration = INFINITE_STATUS)
		block_begin(src)
		src.next_click = world.time + (COMBAT_CLICK_DELAY)
		*/
		src.visible_message("<span class='alert'><B>[src] tweaks [his_or_her(src)] own nipples! That's [pick_string("tweak_yo_self.txt", "tweakadj")] [pick_string("tweak_yo_self.txt", "tweak")]!</B></span>")


/mob/living/proc/grab_block() //this is sorta an ugly but fuck it!!!!
	if (src.grabbed_by && src.grabbed_by.len > 0)
		return 0

	.= 1

	var/obj/item/I = src.equipped()
	if (!I)
		src.grab_self()
		/*
	else
		var/obj/item/grab/block/G = new /obj/item/grab/block(I, src, src)
		G.loc = I

		I.chokehold = G
		I.chokehold.post_item_setup()

		playsound(src.loc, 'sound/impact_sounds/Generic_Shove_1.ogg', 50, 1, -1)
		src.visible_message("<span class='alert'>[src] starts blocking with [I]!</span>")
		SEND_SIGNAL(I, COMSIG_ITEM_BLOCK_BEGIN, G)
		src.setStatus("blocking", duration = INFINITE_STATUS)
		block_begin(src)
		src.next_click = world.time + (COMBAT_CLICK_DELAY)
*/

/mob/living/proc/grab_other(var/mob/living/target, var/suppress_final_message = 0, var/obj/item/grab_item = null)
	if(!src || !target)
		return 0

	var/mob/living/carbon/human/H = src

	logTheThing("combat", src, target, "grabs [constructTarget(target,"combat")] at [log_loc(src)].")

	if (target)
		target.add_fingerprint(src) // Just put 'em on the mob itself, like pulling does. Simplifies forensic analysis a bit (Convair880).

	if (check_target_immunity(target) == 1)
		playsound(target.loc, 'sound/impact_sounds/Generic_Shove_1.ogg', 50, 1, -1)
		target.visible_message("<span class='alert'><B>[src] tries to grab [target], but can't get a good grip!</B></span>")
		return

	if (!target.canbegrabbed)
		if (target.grabresistmessage)
			target.visible_message("<span class='alert'><B>[src] tries to grab [target], [target.grabresistmessage]</B></span>")
		return

	if (istype(H))
		if(H.traitHolder && !H.traitHolder.hasTrait("glasscannon"))
			H.process_stamina(STAMINA_GRAB_COST)

		if (prob(20) && isrobot(target))
			var/mob/living/silicon/robot/T = target
			src.visible_message("<span class='alert'><B>[T] blocks [src]'s attempt to grab [him_or_her(T)]!</span>")
			playsound(target.loc, 'sound/impact_sounds/Generic_Swing_1.ogg', 25, 1, 1)
			return
		else
			var/obj/item/grab/block/B = target.check_block()
			if (target.do_dodge(src, null, show_msg = 0))
				src.visible_message("<span class='alert'><B>[target] dodges [src]'s attempt to grab [him_or_her(target)]!</span>")
				playsound(target.loc, 'sound/impact_sounds/Generic_Swing_1.ogg', 25, 1, 1)
				return
			else if(B && !target.lying)
				src.visible_message("<span class='alert'><B>[target] blocks [src]'s attempt to grab [him_or_her(target)]!</span>")
				playsound(target.loc, 'sound/impact_sounds/Generic_Swing_1.ogg', 25, 1, 1)
				qdel(B)
				target.remove_stamina(STAMINA_DEFAULT_BLOCK_COST)
				return

	if (istype(H))
		for (var/uid in H.pathogens)
			var/datum/pathogen/P = H.pathogens[uid]
			P.ongrab(target)

	if (!grab_item)
		var/obj/item/grab/G = new /obj/item/grab(src, src, target)
		src.put_in_hand(G, src.hand)
	else// special. return it too
		if (!grab_item.special_grab)
			return
		var/obj/item/grab/G = new grab_item.special_grab(grab_item, src, target)
		G.loc = grab_item
		.= G

	for (var/obj/item/grab/block/G in target.equipped_list(check_for_magtractor = 0)) //being grabbed breaks a block
		qdel(G)

	playsound(target.loc, 'sound/impact_sounds/Generic_Shove_1.ogg', 50, 1, -1)
	if (!suppress_final_message) // Melee-focused roles (resp. their limb datums) grab the target aggressively (Convair880).
		if (grab_item)
			target.visible_message("<span class='alert'>[src] grabs hold of [target] with [grab_item]!</span>")
		else
			target.visible_message("<span class='alert'>[src] grabs hold of [target]!</span>")


///////////////////////////////////////////////////// Disarm intent ////////////////////////////////////////////////

/mob/proc/disarm(var/mob/living/target, var/extra_damage = 0, var/suppress_flags = 0, var/damtype = DAMAGE_BLUNT, var/is_special = 0)
	if (!src || !ismob(src) || !target || !ismob(target))
		return

	hit_twitch(target)

	if (!isnum(extra_damage))
		extra_damage = 0

	//if (target.melee_attack_test(src, null, null, 1) != 1)
	//	return

	var/obj/item/affecting = target.get_affecting(src)
	var/datum/attackResults/disarm/msgs = calculate_disarm_attack(target, affecting, 0, 0, extra_damage, is_special)
	msgs.damage_type = damtype
	msgs.flush(suppress_flags)
	return

#define DISARM_WITH_ITEM_TEXT (disarming_item ? " with [disarming_item]" : "")
// I needed a harm intent-like attack datum for some limbs (Convair880).
// is_shove flag removes the possibility of slapping the item out of someone's hand. instead there is a chance to shove them backwards. The 'shove to the ground' chance remains unchanged. (mbc)
// mbc also added disarming_item flag - for when a disarm is performed BY something. Doesn't do anything but change text currently.
/mob/proc/calculate_disarm_attack(var/mob/target, var/obj/item/affecting, var/base_damage_low = 0, var/base_damage_high = 0, var/extra_damage = 0, var/is_shove = 0, var/obj/item/disarming_item = 0)
	var/datum/attackResults/disarm/msgs = new(src)
	msgs.clear(target)
	msgs.valid = 1
	msgs.disarm = 1
	msgs.disarm_RNG_result = list()
	var/list/obj/item/items = target.equipped_list()
	var/def_zone = null
	if (zone_sel)
		def_zone = zone_sel.selecting
		msgs.affecting = def_zone
	else
		def_zone = "All"
		msgs.affecting = def_zone

	if(prob(target.get_deflection())) //chance to deflect disarm attempts entirely
		msgs.played_sound = 'sound/impact_sounds/Generic_Swing_1.ogg'
		msgs.base_attack_message = "<span class='alert'><B>[src] shoves at [target][DISARM_WITH_ITEM_TEXT]!</B></span>"
		fuckup_attack_particle(src)
		return msgs

	if (target.lying == 1) //roll lying bodies
		msgs.played_sound = 'sound/impact_sounds/Generic_Shove_1.ogg'
		msgs.base_attack_message = "<span class='alert'><B>[src] rolls [target] backwards[DISARM_WITH_ITEM_TEXT]!</B></span>"
		msgs.disarm_RNG_result |= "shoved"
		msgs.disarm_RNG_result |= "handle_item_arm"
		return msgs

	//var/damage = rand(base_damage_low, base_damage_high) * extra_damage
	var/mult = 1
	/*
	var/target_stamina = STAMINA_MAX //uses stamina? - bleh
	if (isliving(target))
		var/mob/living/L = target
		target_stamina = L.stamina

	if (damage > 0)
		def_zone = target.check_target_zone(def_zone)

		var/armor_mod = 0
		armor_mod = target.get_melee_protection(def_zone)
		damage -= armor_mod
		msgs.stamina_target -= max((STAMINA_DISARM_COST * 2.5) - armor_mod, 0)

		var/attack_resistance = target.check_attack_resistance()
		if (attack_resistance)
			damage = 0
			if (istext(attack_resistance))
				msgs.show_message_target(attack_resistance)
		msgs.damage = max(damage, 0)
	else if ( !(HAS_MOB_PROPERTY(target, PROP_CANTMOVE)) )
		var/armor_mod = 0
		armor_mod = target.get_melee_protection(def_zone)
		if(target_stamina >= 0)
			msgs.stamina_target -= max(STAMINA_DISARM_DMG - (armor_mod*0.5), 0) //armor vs barehanded disarm gives flat reduction
			msgs.force_stamina_target = 1
*/

	if (ishuman(src))
		var/mob/living/carbon/human/H = src
		if (H.sims)
			mult *= H.sims.getMoodActionMultiplier()

	//var/stampart = floor(((STAMINA_MAX - target_stamina) / 3) )
	var/stampart = floor(abs((src.health - target.health)/3)) // the more disparity between the oponents, the more likely *either* will land a shove-down!
	if (is_shove)
		msgs.base_attack_message = "<span class='alert'><B>[src] shoves [target][DISARM_WITH_ITEM_TEXT]!</B></span>"
		msgs.played_sound = 'sound/impact_sounds/Generic_Shove_1.ogg'
		if (prob((stampart + 70) * mult))
			msgs.base_attack_message = "<span class='alert'><B>[src] shoves [target] backwards[DISARM_WITH_ITEM_TEXT]!</B></span>"
			msgs.disarm_RNG_result |= "shoved"

	if (prob((stampart + 5) * mult))
		if (ishuman(src))
			var/mob/living/carbon/human/H = src
			for (var/uid in H.pathogens)
				var/datum/pathogen/P = H.pathogens[uid]
				var/ret = P.ondisarm(target, 1)
				if (!ret)
					msgs.base_attack_message = "<span class='alert'><B>[src] shoves [target][DISARM_WITH_ITEM_TEXT]!</B></span>"
					return msgs
		msgs.base_attack_message = "<span class='alert'><B>[src] shoves [target] to the ground[DISARM_WITH_ITEM_TEXT]!</B></span>"
		msgs.played_sound = 'sound/impact_sounds/Generic_Shove_1.ogg'
		msgs.disarm_RNG_result |= "shoved_down"
		msgs.disarm_RNG_result |= "drop_item"
		msgs.disarm_RNG_result |= "handle_item_arm"

		return msgs

	if (is_shove) return msgs
	var/disarm_success = prob(40 * lerp(clamp(100 - target.health, 0, 100)/100, 1, 0.5) * mult)
	if (disarm_success && target.check_block() && !(HAS_MOB_PROPERTY(target, PROP_CANTMOVE)))
		disarm_success = 0
		msgs.stamina_target -= STAMINA_DEFAULT_BLOCK_COST * 2
	var/list/obj/item/limbs = list()
	var/list/obj/item/loose = list()
	var/list/obj/item/fixed_in_place = list()
	if (ishuman(src))
		var/mob/living/carbon/human/H2 = src
		for (var/uid in H2.pathogens)
			var/datum/pathogen/P = H2.pathogens[uid]
			var/ret = P.ondisarm(target, 1)
			if (!ret)
				disarm_success = 0
				break
	if(length(items))
		var/multi = length(items) > 1
		for(var/obj/item/I in items)
			if(I.two_handed)
				multi = 1


			if (I.temp_flags & IS_LIMB_ITEM)
				limbs |= I.loc
				if(disarm_success)
					msgs.disarm_RNG_result |= "handle_item_arm"
			else if (I.cant_other_remove)
				fixed_in_place |= I
			else
				loose |= I
				if(disarm_success)
					msgs.disarm_RNG_result |= "drop_item"

#define ONE_OR_SOME(_mylist, _what) (length(_mylist) > 1 ? "multiple [_what]" : "[_mylist[1]]")

		if(disarm_success)
			msgs.played_sound = 'sound/impact_sounds/Generic_Shove_1.ogg'
			if(length(limbs))
				msgs.base_attack_message = "<span class='alert'><B>[src] shoves [ONE_OR_SOME(limbs, "item limbs")][DISARM_WITH_ITEM_TEXT] and forces [target] to hit [himself_or_herself(target)]!</B></span>"
			else if(length(loose))
				msgs.base_attack_message = "<span class='alert'><B>[src] knocks [ONE_OR_SOME(loose, "items")] out of [target]'s hand[multi?"s":""][DISARM_WITH_ITEM_TEXT]!</B></span>"
		else
			msgs.played_sound = 'sound/impact_sounds/Generic_Swing_1.ogg'
			if(length(limbs))
				msgs.base_attack_message = "<span class='alert'><B>[src] shoves at [ONE_OR_SOME(limbs, "item limbs")][DISARM_WITH_ITEM_TEXT]!</B></span>"
			else if(length(loose))
				msgs.base_attack_message = "<span class='alert'><B>[src] tries to knock [ONE_OR_SOME(loose, "items")] out of [target]'s hand[multi?"s":""][DISARM_WITH_ITEM_TEXT]!</B></span>"

			else if(length(fixed_in_place))
				msgs.base_attack_message = "<span class='alert'><B>[src] vainly tries to knock [ONE_OR_SOME(fixed_in_place, "items")] out of [target]'s hand[multi?"s":""][DISARM_WITH_ITEM_TEXT]!</B></span>"
				msgs.show_self.Add("<span class='alert'>Something is binding [ONE_OR_SOME(fixed_in_place, "items")] to [target]. You won't be able to disarm [him_or_her(target)].</span>")
				msgs.show_target.Add("<span class='alert'>Something is binding [ONE_OR_SOME(fixed_in_place, "items")] to you. It cannot be knocked out of your hands.</span>")
	else
		msgs.base_attack_message = "<span class='alert'><B>[src] shoves [target][DISARM_WITH_ITEM_TEXT]!</B></span>"
		msgs.played_sound = 'sound/impact_sounds/Generic_Shove_1.ogg'
#undef ONE_OR_SOME

	return msgs

#undef DISARM_WITH_ITEM_TEXT

/mob/proc/check_block(ignoreStuns = 0) //am i blocking?
	RETURN_TYPE(/obj/item/grab/block)
	if (ignoreStuns || (isalive(src) && !getStatusDuration("paralysis")))
		var/obj/item/I = src.equipped()
		if (I)
			if (istype(I,/obj/item/grab/block))
				return I
			else if (I.c_flags & HAS_GRAB_EQUIP)
				for (var/obj/item/grab/block/G in I)
					return G
	return null

/mob/proc/do_dodge(var/mob/attacker, var/obj/item/W, var/show_msg = 1)
	return 0

/mob/living/do_dodge(var/mob/attacker, var/obj/item/W, var/show_msg = 1)
	if (stance == "dodge")
		if (show_msg)
			visible_message("<span class='alert'><B>[src] narrowly dodges [attacker]'s attack!</span>")
		playsound(loc, 'sound/impact_sounds/Generic_Swing_1.ogg', 50, 1, 1)

		add_stamina(STAMINA_FLIP_COST * 0.25) //Refunds some stamina if you successfully dodge.
		stamina_stun()
		fuckup_attack_particle(attacker)
		return 1
	else if (prob(src.get_passive_block()))
		if (show_msg)
			visible_message("<span class='alert'><B>[src] blocks [attacker]'s attack!</span>")
		playsound(loc, 'sound/impact_sounds/Generic_Swing_1.ogg', 50, 1, 1)
		fuckup_attack_particle(attacker)
		return 1
	return ..()

/mob/living/proc/get_passive_block(var/obj/item/W)
	var/ret = 0
	if(getStatusDuration("stonerit"))
		ret += 20

	for (var/obj/item/C as anything in src.get_equipped_items())
		ret += C.getProperty("block")

	return ret



/////////////////////////////////////////////////// Harm intent ////////////////////////////////////////////////////////

/mob/living/proc/stun_glove_attack(var/mob/living/target)

//Todo : this
///mob/living/critter/stun_glove_attack(var/mob/living/target)


/mob/living/carbon/human/stun_glove_attack(var/mob/living/target)
	if (!src || !target || !src.gloves)
		return 0

	if (src.gloves.uses > 0)
		src.lastattacked = target
		target.lastattacker = src
		target.lastattackertime = world.time
		logTheThing("combat", src, target, "touches [constructTarget(target,"combat")] with stun gloves at [log_loc(src)].")
		target.add_fingerprint(src) // Some as the other 'empty hand' melee attacks (Convair880).
		src.unlock_medal("High Five!", 1)

		elecflash(target)

		src.gloves.uses = max(0, src.gloves.uses - 1)
		if (src.gloves.uses < 1)
			src.gloves.icon_state = "yellow"
			src.gloves.item_state = "ygloves"
			src.update_clothing() // Was missing (Convair880).

		if (src.gloves.uses <= 0)
			src.show_text("The gloves are no longer electrically charged.", "red")
			src.gloves.overridespecial = 0
		else
			src.show_text("The gloves have [src.gloves.uses]/[src.gloves.max_uses] charges left!", "red")

		target.visible_message("<span class='alert'><B>[src] touches [target] with the stun gloves!</B></span>")
		if (check_target_immunity(target) == 1)
			target.visible_message("<span class='alert'><B>...but it has no effect whatsoever!</B></span>")
			return

#ifdef USE_STAMINA_DISORIENT
		target.do_disorient(140, weakened = 40, stunned = 20, disorient = 80)
#else
		target.changeStatus("weakened", 3 SECONDS)
		target.changeStatus("stunned", 2 SECONDS)
#endif


		target.stuttering = max(target.stuttering,5)

	else
		boutput(src, "<span class='alert'>The stun gloves don't have enough charge!</span>")
		return

/mob/living/proc/melee_attack(var/mob/living/target)
	var/datum/limb/L = equipped_limb()
	if (!L)
		return

	L.harm(target, src) // Calls melee_attack_normal if limb datum doesn't override anything.

/mob/proc/melee_attack_normal(var/mob/target, var/extra_damage = 0, var/suppress_flags = 0, var/damtype = DAMAGE_BLUNT)
	if(!src || !target)
		return 0

	if(!isnum(extra_damage))
		extra_damage = 0

	if (!target.melee_attack_test(src))
		return

	var/obj/item/affecting = target.get_affecting(src)
	var/datum/attackResults/msgs = calculate_melee_attack(target, affecting, 2, 9, extra_damage)
	msgs.damage_type = damtype
	attack_effects(target, affecting)
	msgs.flush(suppress_flags)

/mob/proc/calculate_melee_attack(var/mob/target, var/obj/item/affecting, var/base_damage_low = 2, var/base_damage_high = 9, var/extra_damage = 0, var/stamina_damage_mult = 1, var/can_crit = 1)
	var/datum/attackResults/msgs = new(src)
	msgs.clear(target)
	msgs.valid = 1

	var/crit_chance = STAMINA_CRIT_CHANCE
	SEND_SIGNAL(target, COMSIG_MOB_ATTACKED_PRE, src, null)

	if (ishuman(src))
		var/mob/living/carbon/human/H = src
		if (H.gloves)
			if (H.gloves.crit_override)
				crit_chance = H.gloves.bonus_crit_chance
			else
				crit_chance += H.gloves.bonus_crit_chance
			if (H.gloves.stamina_dmg_mult)
				stamina_damage_mult += H.gloves.stamina_dmg_mult
		var/healthpart = floor(abs((src.health - target.health)/5))
		var/stampart = (((H.stamina_regen + GET_MOB_PROPERTY(src, PROP_STAMINA_REGEN_BONUS))-STAMINA_REGEN)/STAMINA_REGEN) // making stam regen do something???
		crit_chance += stampart
		crit_chance += healthpart // rng stuns
		msgs.crit_chance += crit_chance

	var/def_zone = null
	if (istype(affecting, /obj/item/organ))
		var/obj/item/organ/O = affecting
		def_zone = O.organ_name
		msgs.affecting = affecting
	else if (istype(affecting, /obj/item/parts))
		var/obj/item/parts/P = affecting
		def_zone = P.slot
		msgs.affecting = affecting
	else if (zone_sel)
		def_zone = zone_sel.selecting
		msgs.affecting = def_zone
	else
		def_zone = "All"
		msgs.affecting = def_zone

	var/punchmult = get_base_damage_multiplier(def_zone)
	if(ishuman(src))
		var/mob/living/carbon/human/LM = src
		for (var/uid in LM.pathogens)
			var/datum/pathogen/P = LM.pathogens[uid]
			punchmult *= P.onpunch(target, def_zone)

	var/punchedmult = target.get_taken_base_damage_multiplier(src, def_zone)

	if (!punchedmult)
		if (narrator_mode)
			msgs.played_sound = 'sound/vox/hit.ogg'
		else
			msgs.played_sound = pick(sounds_punch)
		msgs.visible_message_self("<span class='alert'><B>[src] [src.punchMessage] [target], but it does absolutely nothing!</B></span>")
		return

	if (!punchmult)
		msgs.played_sound = 'sound/impact_sounds/Generic_Snap_1.ogg'
		msgs.visible_message_self("<span class='alert'><B>[src] hits [target] with a ridiculously feeble attack!</B></span>")
		return

	var/damage = rand(base_damage_low, base_damage_high) * punchedmult * punchmult + extra_damage + calculate_bonus_damage(msgs)

	if (!target.canmove && target.lying)
		msgs.played_sound = 'sound/impact_sounds/Generic_Hit_1.ogg'
		msgs.base_attack_message = "<span class='alert'><B>[src] [src.kickMessage] [target]!</B></span>"
		msgs.logs = list("[src.kickMessage] [constructTarget(target,"combat")]")
		if (ishuman(src))
			var/mob/living/carbon/human/H = src
			if (H.shoes)
				damage += H.shoes.kick_bonus
			else if (H.limbs.r_leg)
				damage += H.limbs.r_leg.limb_hit_bonus
			else if (H.limbs.l_leg)
				damage += H.limbs.l_leg.limb_hit_bonus
		#if STAMINA_LOW_COST_KICK == 1
		msgs.stamina_self += STAMINA_HTH_COST / 3
		#endif
	else

		msgs.played_sound = "punch"

		if (src != target && iswrestler(src) && prob(66))
			msgs.base_attack_message = "<span class='alert'><B>[src]</b> winds up and delivers a backfist to [target], sending them flying!</span>"
			damage += 4
			msgs.after_effects += /proc/wrestler_backfist

		def_zone = target.check_target_zone(def_zone)

		var/stam_power = STAMINA_HTH_DMG * stamina_damage_mult

		var/armor_mod = 0
		armor_mod = target.get_melee_protection(def_zone, DAMAGE_BLUNT)
		var/pre_armor_damage = damage
		damage -= armor_mod
		if(damage/pre_armor_damage <= 0.66)
			block_spark(target,armor=1)
			playsound(target, 'sound/impact_sounds/block_blunt.ogg', 50, 1, -1, pitch=1.5)
		if(damage <= 0)
			fuckup_attack_particle(src)

		//reduce stamina by the same proportion that base damage was reduced
		//min cap is stam_power/3 so we still cant ignore it entirely
		if ((damage + armor_mod) <= 0) //mbc lazy runtime fix
			stam_power = stam_power / 3 //do the least
		else
			stam_power = max(  stam_power / 3, stam_power * ( damage / (damage + armor_mod) )  )

		msgs.stamina_target -= max(stam_power, 0)

		if (can_crit && prob(crit_chance) && !target.check_block()?.can_block(DAMAGE_BLUNT, 0))
			msgs.stamina_crit = 1
			//Good lord what is attack code
			//this does not belong where it is but where the hell else am I putting it?
			if (ishuman(target) && def_zone == "head")
				var/mob/living/carbon/human/Ht = target
				var/obj/item/skull/target_skull = Ht.organHolder?.skull
				if (target_skull && target_skull.teeth)
					target_skull.teeth--
					new /obj/decal/cleanable/tooth(get_turf(target))

			msgs.played_sound = pick(sounds_punch)
			if(prob(5))
				msgs.visible_message_target("<span class='notice'>[pick("... And lands a","That was a")] <b>[crit_chance]% hit!</b> [prob(75) ? "(roleplay it!)" : ""] </span>")

		var/armor_blocked = 0

		if(pre_armor_damage > 0 && damage/pre_armor_damage <= 0.66)
			block_spark(target,armor=1)
			playsound(target, 'sound/impact_sounds/block_blunt.ogg', 50, 1, -1,pitch=1.5)
			if(damage <= 0)
				fuckup_attack_particle(src)
				armor_blocked = 1

		if(armor_blocked)
			msgs.base_attack_message = "<span class='alert'><B>[src] [src.punchMessage] [target], but [target]'s armor blocks it!</B></span>"
		else
			target.lastgasp()
			msgs.base_attack_message = "<span class='alert'><B>[src] [src.punchMessage] [target][msgs.stamina_crit ? " and lands a devastating hit!" : "!"]</B></span>"

		//if (!(src.traitHolder && src.traitHolder.hasTrait("glasscannon")))
		//	msgs.stamina_self -= STAMINA_HTH_COST

	//awfulworldkid: this is meant to be code to do brain damage on head hits
	if (def_zone == "head")
		if(damage >= 6)
			var/brain = 1 + ((damage - 6) / 10)
			target.take_brain_damage(brain)

	var/attack_resistance = target.check_attack_resistance()
	if (attack_resistance)
		damage = 0
		if (istext(attack_resistance))
			msgs.show_message_target(attack_resistance)
	msgs.damage = max(damage, 0)

	return msgs

// This is used by certain limb datums (werewolf, shambling abomination) (Convair880).
/proc/special_attack_silicon(var/mob/target, var/mob/living/user)
	if (!target || !issilicon(target) || !user || !isliving(user))
		return

	if (check_target_immunity(target) == 1)
		playsound(user.loc, "punch", 50, 1, 1)
		user.visible_message("<span class='alert'><B>[user]'s attack bounces off [target] uselessly!</B></span>")
		return

	user.lastattacked = target

	var/damage = 0
	var/send_flying = 0 // 1: a little bit | 2: across the room

	if (isrobot(target))
		var/mob/living/silicon/robot/BORG = target
		if (!BORG.part_head)
			user.visible_message("<span class='alert'><B>[user] smashes [BORG.name] to pieces!</B></span>")
			playsound(user.loc, 'sound/impact_sounds/Metal_Hit_Lowfi_1.ogg', 70, 1)
			BORG.gib()
		else
			if (BORG.part_head.ropart_get_damage_percentage() >= 85)
				user.visible_message("<span class='alert'><B>[user] grabs [BORG.name]'s head and wrenches it right off!</B></span>")
				playsound(user.loc, 'sound/impact_sounds/Metal_Hit_Lowfi_1.ogg', 70, 1)
				BORG.compborg_lose_limb(BORG.part_head)
			else
				user.visible_message("<span class='alert'><B>[user] pounds on [BORG.name]'s head furiously!</B></span>")
				playsound(user.loc, "sound/impact_sounds/Metal_Clang_3.ogg", 50, 1)
				if (BORG.part_head.ropart_take_damage(rand(20,40),0) == 1)
					BORG.compborg_lose_limb(BORG.part_head)
				if (!BORG.anchored && prob(30))
					user.visible_message("<span class='alert'><B>...and sends them flying!</B></span>")
					send_flying = 2

	else if (isAI(target))
		user.visible_message("<span class='alert'><B>[user] [pick("wails", "pounds", "slams")] on [target]'s terminal furiously!</B></span>")
		playsound(user.loc, "sound/impact_sounds/Metal_Clang_3.ogg", 50, 1)
		damage = 10

	else
		user.visible_message("<span class='alert'><B>[user] smashes [target] furiously!</B></span>")
		playsound(user.loc, "sound/impact_sounds/Metal_Clang_3.ogg", 50, 1)
		damage = 10
		if (!target.anchored && prob(30))
			user.visible_message("<span class='alert'><B>...and sends them flying!</B></span>")
			send_flying = 2

	if (send_flying == 2)
		wrestler_backfist(user, target)
	else if (send_flying == 1)
		wrestler_knockdown(user, target)

	if (damage > 0)
		random_brute_damage(target, damage)
		target.UpdateDamageIcon()

	logTheThing("combat", user, target, "punches [constructTarget(target,"combat")] at [log_loc(user)].")
	return

/////////////////////////////////////////////////////// attackResult datum ////////////////////////////////////////

/datum/attackResults
	var/mob/owner
	var/mob/target
	var/list/visible_self = list()
	var/list/visible_target = list()
	var/list/show_self = list()
	var/list/show_target = list()
	var/list/logs = null
	var/list/after_effects = list()

	// the message to play to the target
	var/base_attack_message = null

	// a sound to play when this attack is flushed
	var/played_sound = null

	var/stamina_self = 0
	var/stamina_target = 0
	var/stamina_crit = 0
	var/damage = 0
	var/damage_type = DAMAGE_BLUNT
	var/obj/item/affecting = null
	var/valid = 0
	var/disarm = 0 // Is this a disarm as opposed to harm attack?
	var/disarm_RNG_result = null // Blocked, shoved down etc.
	var/bleed_always = 0 //Will cause bleeding regardless of damage type.
	var/bleed_bonus = 0 //bonus to bleed damage specifically.
	var/crit_chance = 5 //we're gonna pass a second value that determines likelyhood of making them horizontal.

	//grouping of combat message
	var/msg_group = 0

	var/force_stamina_target = null

	New(var/mob/M)
		..()
		owner = M

	proc/clear(var/mob/M)
		target = M
		visible_self.Cut()
		visible_target.Cut()
		show_self.Cut()
		show_target.Cut()
		logs = null
		played_sound = null
		base_attack_message = null
		stamina_self = 0
		stamina_target = 0
		stamina_crit = 0
		damage = 0
		damage_type = DAMAGE_BLUNT
		affecting = null
		valid = 0
		disarm = 0
		disarm_RNG_result = null
		bleed_always = 0 //Will cause bleeding regardless of damage type.
		bleed_bonus = 0 //bonus to bleed damage specifically.

		after_effects.Cut()

	proc/show_message_self(var/message)
		show_self += message

	proc/show_message_target(var/message)
		show_target += message

	proc/visible_message_self(var/message)
		visible_self += message

	proc/visible_message_target(var/message)
		visible_target += message

	proc/logc(var/message)
		logs += message

	// I worked disarm into this because I needed a more detailed disarm proc and didn't want to reinvent the wheel or repeat a bunch of code (Convair880).
	proc/flush(var/suppress = 0)
		if (!target)
			clear(null)
			logTheThing("debug", owner, null, "<b>Marquesas/Melee Attack Refactor:</b> NO TARGET FLUSH! EMERGENCY!")
			return

		if (!affecting)
			clear(null)
			logTheThing("debug", owner, null, "<b>Marquesas/Melee Attack Refactor:</b> NO AFFECTING FLUSH! WARNING!")
			return

		if (!msg_group)
			msg_group = "[affecting]_attacks_[target]_with_[disarm ? "disarm" : "harm"]"

		if (!(suppress & SUPPRESS_SOUND) && played_sound)
			var/obj/item/grab/block/G = target.check_block()
			if (G && G.can_block(damage_type) && damage > 0)
				G.play_block_sound(damage_type)
				playsound(owner.loc, played_sound, 15, 1, -1, 1.4)
			else
				playsound(owner.loc, played_sound, 50, 1, -1)

		if (!(suppress & SUPPRESS_BASE_MESSAGE) && base_attack_message)
			owner.visible_message(base_attack_message)

		if (!(suppress & SUPPRESS_SHOWN_MESSAGES))
			for (var/message in show_self)
				owner.show_message(message, group = msg_group)

			for (var/message in visible_self)
				owner.visible_message(message, group = msg_group)

		if (!(suppress & SUPPRESS_SHOWN_MESSAGES))
			for (var/message in visible_target)
				target.visible_message(message, group = msg_group)

			for (var/message in show_target)
				target.show_message(message, group = msg_group)

		if (!(suppress & SUPPRESS_LOGS))
			if (!length(logs))
				if (istype(src, /datum/attackResults/disarm))
					logs = list("disarms [constructTarget(target,"combat")]")
				else
					logs = list("punches [constructTarget(target,"combat")]")

//Pod wars friendly fire check
#if defined(MAP_OVERRIDE_POD_WARS)
			var/friendly_fire = 0
			if (owner != target && get_pod_wars_team_num(owner) == get_pod_wars_team_num(target))
				friendly_fire = 1
				if (istype(ticker.mode, /datum/game_mode/pod_wars))
					var/datum/game_mode/pod_wars/mode = ticker.mode
					mode.stats_manager?.inc_friendly_fire(owner)
				// message_admins("[owner] just committed friendly fire against [target]!")

			for (var/message in logs)
				logTheThing("combat", owner, target, "[friendly_fire ? "<span class='alert'>Friendly Fire!</span>":""][message] at [log_loc(owner)].")
#else
			for (var/message in logs)
				logTheThing("combat", owner, target, "[message] at [log_loc(owner)].")
#endif

		if (stamina_self)
			if (stamina_self > 0)
				owner.add_stamina(stamina_self)
			else
				owner.process_stamina(-stamina_self)

		if (src.disarm == 1)
			target.add_fingerprint(owner)

			if (owner.traitHolder && !owner.traitHolder.hasTrait("glasscannon"))
				owner.process_stamina(STAMINA_DISARM_COST)

			if (length(src.disarm_RNG_result))
				if ("drop_item" in src.disarm_RNG_result)
					target.deliver_move_trigger("bump")
					for(var/obj/item/I in target.equipped_list())
						if(!(I.temp_flags & IS_LIMB_ITEM))
							target.drop_item_throw(I)

				if ("handle_item_arm" in src.disarm_RNG_result)
					for(var/obj/item/I in target.equipped_list())
						if(!(I.temp_flags & IS_LIMB_ITEM))
							continue

						var/old_zone_sel = 0
						if (target.zone_sel) //attack the zone of the attacker
							old_zone_sel = target.zone_sel.selecting
							if (owner.zone_sel)
								target.zone_sel.selecting = owner.zone_sel.selecting
						var/prev_intent = target.a_intent
						target.a_intent = INTENT_HARM

						target.Attackby(I, target)

						target.a_intent = prev_intent
						if (old_zone_sel)
							target.zone_sel.selecting = old_zone_sel

						if (prob(20))
							I.attack_self(target)


				if ("shoved_down" in src.disarm_RNG_result)
					target.deliver_move_trigger("pushdown")
					target.changeStatus("weakened", 2 SECONDS)
					target.force_laydown_standup()
				if ("shoved" in src.disarm_RNG_result)
					step_away(target, owner, 1)
					target.OnMove(owner)
			else
				target.deliver_move_trigger("bump")
		else
#ifdef DATALOGGER
			game_stats.Increment("violence")
			if(target.mind && target.mind.assigned_role == "Clown")
				game_stats.Increment("clownabuse")
#endif
			owner.lastattacked = target
			target.lastattacker = owner
			target.lastattackertime = world.time
			target.add_fingerprint(owner)

		if (damage > 0 || (src.disarm == 1 || force_stamina_target))

			if ((src.disarm == 1 || force_stamina_target) && damage <= 0)
				goto process_stamina

			if (damage > 0 && target != owner)
				target.changeStatus("staggered", 5 SECONDS)
				owner.changeStatus("staggered", 5 SECONDS)
			// important

			if (damage_type == DAMAGE_BLUNT && prob(25 + (damage * 2)) && damage >= 8)
				damage_type = DAMAGE_CRUSH

			if (istype(affecting))
				affecting.take_damage((damage_type != DAMAGE_BURN ? damage : 0), (damage_type == DAMAGE_BURN ? damage : 0), 0, damage_type)
				hit_twitch(target)
			else if (affecting)
				target.TakeDamage(affecting, (damage_type != DAMAGE_BURN ? damage : 0), (damage_type == DAMAGE_BURN ? damage : 0), 0, damage_type)
			else
				target.TakeDamage("chest", (damage_type != DAMAGE_BURN ? damage : 0), (damage_type == DAMAGE_BURN ? damage : 0), 0, damage_type)

			if ((damage_type & (DAMAGE_CUT | DAMAGE_STAB)) || bleed_always)
				take_bleeding_damage(target, owner, damage + bleed_bonus, damage_type)
				target.spread_blood_clothes(target)
				owner.spread_blood_hands(target)
				if (prob(15))
					owner.spread_blood_clothes(target)

			for (var/P in after_effects)
				call(P)(owner, target)

			process_stamina:

			if (stamina_target)
				if (stamina_target > 0)
					target.add_stamina(stamina_target)
				else
					var/prev_stam = target.get_stamina()
					target.remove_stamina(-stamina_target)
					target.stamina_stun()
					if(prev_stam > 0 && target.get_stamina() <= 0) //We were just knocked out.
						target.set_clothing_icon_dirty()
						target.lastgasp()

			if (stamina_crit)
				target.handle_stamina_crit(crit_chance)

			if (src.disarm != 1)
				owner.attack_finished(target)
				target.attackby_finished(owner)
			target.UpdateDamageIcon()


			if (ticker.mode && ticker.mode.type == /datum/game_mode/revolution)
				var/datum/game_mode/revolution/R = ticker.mode

				if (damage > 1)
					if ((owner.mind in R.revolutionaries) || (owner.mind in R.head_revolutionaries))	//attacker is rev, all heads who see the attack get mutiny buff
						for (var/datum/mind/M in R.get_living_heads())
							if (M.current)
								if (get_dist(owner,M.current) <= 7)
									if (owner in viewers(7,M.current))
										M.current.changeStatus("mutiny", 10 SECONDS)

				if(target.client && target.health < 0 && ishuman(target)) //Only do rev stuff if they have a client and are low health
					if ((owner.mind in R.revolutionaries) || (owner.mind in R.head_revolutionaries))
						if (R.add_revolutionary(target.mind))
							target.HealDamage("All", max(30 - target.health,0), 0)
							target.HealDamage("All", 0, max(30 - target.health,0))
					else
						if (R.remove_revolutionary(target.mind))
							target.HealDamage("All", max(30 - target.health,0), 0)
							target.HealDamage("All", 0, max(30 - target.health,0))
		clear(null)

/datum/attackResults/disarm
	logs = null //list("disarms [constructTarget(src,"diary")]") //handled above

////////////////////////////////////////////////////////// Targeting checks ////////////////////////////////////

/mob/proc/melee_attack_test(var/mob/attacker, var/obj/item/I, var/def_zone, var/disarm_check = 0)
	if (check_target_immunity(src) == 1)
		playsound(loc, "punch", 50, 1, 1)
		src.visible_message("<span class='alert'><B>[attacker]'s attack bounces off [src] uselessly!</B></span>")
		return 0

	return 1

/mob/living/melee_attack_test(var/mob/attacker, var/obj/item/I, var/def_zone, var/disarm_check = 0)
	if (!..())
		return 0

	if (src.do_dodge(attacker, I))
		return 0

	return 1

/mob/proc/get_affecting(mob/attacker, def_zone = null)
	if (def_zone)
		return def_zone
	var/t = pick("head", "chest")
	if(attacker.zone_sel)
		t = attacker.zone_sel.selecting
	return t

/mob/living/carbon/human/get_affecting(mob/attacker, def_zone = null)
	var/t = pick("head", "chest")
	if(def_zone)
		t = def_zone
	else if(attacker.zone_sel)
		t = attacker.zone_sel.selecting
	var/r_zone = ran_zone(t)

	return r_zone

/mob/proc/check_target_zone(var/def_zone)
	return def_zone

/mob/living/carbon/human/check_target_zone(var/def_zone)
	if (limbs && !limbs.l_arm && def_zone == "l_arm")
		return "chest"
	if (limbs && !limbs.r_arm && def_zone == "r_arm")
		return "chest"
	return def_zone

////////////////////////////////////////////////////// Calculate damage //////////////////////////////////////////

/mob/proc/get_base_damage_multiplier()
	return 1

/mob/living/carbon/human/get_base_damage_multiplier(var/def_zone)
	var/punchmult = 1

	if (sims)
		punchmult *= sims.getMoodActionMultiplier()

	return punchmult

/mob/proc/get_taken_base_damage_multiplier()
	return 1

/mob/living/carbon/human/get_taken_base_damage_multiplier(var/mob/attacker, var/def_zone)
	var/punchedmult = 1

	for (var/uid in src.pathogens)
		var/datum/pathogen/P = src.pathogens[uid]
		punchedmult *= P.onpunched(attacker, def_zone)

	return punchedmult

/mob/proc/calculate_bonus_damage(var/datum/attackResults/msgs)
	return 0

/mob/living/calculate_bonus_damage(var/datum/attackResults/msgs)
	.= ..()

	if (src.traitHolder.hasTrait("bigbruiser"))
		msgs.stamina_self -= STAMINA_HTH_COST //Double the cost since this is stacked on top of default
		msgs.stamina_target -= STAMINA_HTH_DMG * 0.25


/mob/living/carbon/human/calculate_bonus_damage(var/datum/attackResults/msgs)
	. = ..()
	if (src.gloves)
		. += src.gloves.punch_damage_modifier

	if (src.reagents && (src.reagents.get_reagent_amount("ethanol") >= 100) && prob(40))
		. += rand(3,5)
		if (msgs)
			msgs.show_message_self("<span class='alert'>You drunkenly throw a brutal punch!</span>")

	if (src.is_hulk())
		. += max((abs(health+max_health)/max_health)*5, 5)


/////////////////////////////////////////////////////// Target damage modifiers //////////////////////////////////

/mob/proc/check_attack_resistance(var/obj/item/I)
	return null

/mob/living/silicon/robot/check_attack_resistance(var/obj/item/I)
	if (!I)
		return "<span class='alert'>Sensors indicate no damage from external impact.</span>"
	return null

/mob/living/check_attack_resistance(var/obj/item/I)
	if (reagents?.get_reagent_amount("ethanol") >= 100 && prob(40) && !I)
		return "<span class='alert'>You drunkenly shrug off the blow!</span>"
	return null

/mob/proc/get_melee_protection(zone, damage_type = 0)
	return 0

/mob/proc/get_ranged_protection()
	return 1

/mob/proc/get_deflection()
	.= 0

///////////////////
/mob/proc/get_head_pierce_prot()
	return 0

/mob/living/carbon/human/get_head_pierce_prot()
	if (client?.hellbanned)
		return 0
	if ((head && head.body_parts_covered & HEAD) || (wear_mask && wear_mask.body_parts_covered & HEAD))
		if (head && !wear_mask)
			return max(0, head.getProperty("pierceprot"))
		else if (!head && wear_mask)
			return max(0, wear_mask.getProperty("pierceprot"))
		else if (head && wear_mask)
			return max(0, max(head.getProperty("pierceprot"), wear_mask.getProperty("pierceprot")))
	return 0

/mob/proc/get_chest_pierce_prot()
	return 0

/mob/living/carbon/human/get_chest_pierce_prot()
	if (client?.hellbanned)
		return 0
	if ((wear_suit && wear_suit.body_parts_covered & TORSO) || (w_uniform && w_uniform.body_parts_covered & TORSO))
		if (wear_suit && !w_uniform)
			return max(0, wear_suit.getProperty("pierceprot"))
		else if (!wear_suit && w_uniform)
			return max(0, w_uniform.getProperty("pierceprot"))
		else if (wear_suit && w_uniform)
			return max(0, max(w_uniform.getProperty("pierceprot"), wear_suit.getProperty("pierceprot")))
	return 0

/////////////////////////////////////////////////////////// After attack ////////////////////////////////////////////

/mob/proc/attack_effects(var/target, var/obj/item/affecting)
	return

/mob/living/carbon/human/attack_effects(var/mob/target, var/obj/item/affecting)
	if (src.is_hulk())
		SPAWN_DBG(0)
			if (prob(20))
				target.changeStatus("stunned", 1 SECOND)
				step_away(target,src,15)
				sleep(0.3 SECONDS)
				step_away(target,src,15)
			else if (prob(20))				//what's this math, like 40% then with the if else? who cares

				var/turf/T = get_edge_target_turf(src, src.dir)
				if (isturf(T))
					src.visible_message("<span class='alert'><B>[src] savagely punches [target], sending them flying!</B></span>")
					target.throw_at(T, 10, 2)

	if (src.bioHolder.HasEffect("revenant"))
		var/datum/bioEffect/hidden/revenant/R = src.bioHolder.GetEffect("revenant")
		if (R.ghoulTouchActive)
			R.ghoulTouch(target, affecting)

//variant, using for werewolf pounce, to send mobs in a random direction and 50% chance to weaken them.
/proc/wrestler_knockdown(var/mob/H, var/mob/T, /var/variant)
	if (!H || !ismob(H) || !T || !ismob(T))
		return

	if (variant)
		if(prob(50))
			T.changeStatus("weakened", 2 SECONDS)
			T.force_laydown_standup()
		SPAWN_DBG(0)
			step_rand(T, 15)
	else
		T.changeStatus("weakened", 2 SECONDS)
		T.force_laydown_standup()
		SPAWN_DBG(0)
			step_away(T, H, 15)

	return

/proc/wrestler_backfist(var/mob/H, var/mob/T)
	if (!H || !ismob(H) || !T || !ismob(T))
		return

	T.changeStatus("weakened", 5 SECONDS)
	var/turf/throwpoint = get_edge_target_turf(H, get_dir(H, T))
	if (throwpoint && isturf(throwpoint))
		T.throw_at(throwpoint, 10, 2)

	return

/mob/proc/attack_finished(var/mob/target)
	return

/mob/living/carbon/human/attack_finished(var/mob/target)
	if (sims)
		sims.affectMotive("fun", 5)

/mob/proc/attackby_finished(var/mob/attacker)
	return

/mob/living/carbon/human/attackby_finished(var/mob/attacker)
	if (sims)
		if (istype(gloves, /obj/item/clothing/gloves/boxing))
			sims.affectMotive("fun", 2.5)

//return 1 on successful dodge or parry, 0 on fail
/mob/living/proc/parry_or_dodge(mob/M, obj/item/W)
	.= 0
	if (prob(60) && M && src.stance == "defensive" && iswerewolf(src) && src.stat)
		src.set_dir(get_dir(src, M))
		playsound(src.loc, "sound/weapons/punchmiss.ogg", 50, 1)
		//dodge more likely, we're more agile than macho
		if (prob(60))
			src.visible_message("<span class='alert'><B>[src] dodges the blow by [M]!</B></span>")
		else
			src.visible_message("<span class='alert'><B>[src] parries [M]'s attack, knocking them to the ground!</B></span>")
			if (prob(50))
				step_away(M, src, 15)
			else
				M.changeStatus("weakened", 4 SECONDS)
				M.force_laydown_standup()
		playsound(src.loc, "sound/weapons/thudswoosh.ogg", 65, 1)
		.= 1

/mob/living/proc/werewolf_tainted_saliva_transfer(var/mob/target)
	if (iswerewolf(src))
		var/datum/abilityHolder/werewolf/W = src.get_ability_holder(/datum/abilityHolder/werewolf)
		if (target && W?.tainted_saliva_reservoir.total_volume > 0)
			W.tainted_saliva_reservoir.trans_to(target,5, 2)

