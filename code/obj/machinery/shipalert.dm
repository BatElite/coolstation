//
//	Ship alert button
//	Teeny tiny hammer (to break the glass cover)
//

//Using this definition and global system in antipation of further extension onto this ship alert feature
var/global/shipAlertState = SHIP_ALERT_GOOD
var/global/soundGeneralQuarters = sound('sound/machines/siren_generalquarters_quiet.ogg')

/obj/machinery/shipalert
	name = "Ship Alert Button"
	icon = 'icons/obj/machines/monitors.dmi'
	icon_state = "shipalert0"
	desc = ""
	anchored = 1.0
	mats = 5
	var/usageState = 0 // 0 = glass cover, hammer. 1 = glass cover, no hammer. 2 = cover smashed
	var/working = 0 //processing loops
	var/lastActivated = 0
	var/cooldownPeriod = 2000 //2 minutes, change according to player abuse
	var/datum/directed_broadcast/emergency/broadcast

	New()
		..()
		UnsubscribeProcess()

/obj/machinery/shipalert/attack_hand(mob/user as mob)
	if (user.stat || isghostdrone(user) || !isliving(user))
		return

	src.add_fingerprint(user)

	switch (usageState)
		if (0)
			//take the hammer
			if (issilicon(user)) return
			var/obj/item/tinyhammer/hammer = new /obj/item/tinyhammer()
			user.put_in_hand_or_drop(hammer)
			src.usageState = 1
			src.icon_state = "shipalert1"
			user.visible_message("[user] picks up \the [hammer]", "You pick up \the [hammer]")
		if (1)
			//no effect punch
			out(user, "<span class='alert'>The glass casing is too strong for your puny hands!</span>")
		if (2)
			//activate
			if (src.working) return
			playsound(src.loc, "sound/machines/click.ogg", 50, 1)
			src.toggleActivate(user)

/obj/machinery/shipalert/attackby(obj/item/W as obj, mob/user as mob)
	if (user.stat)
		return

	if (src.usageState == 1)
		if (istype(W, /obj/item/tinyhammer))
			//break glass
			var/area/T = get_turf(src)
			T.visible_message("<span class='alert'>[src]'s glass housing shatters!</span>")
			playsound(T, pick("sound/impact_sounds/Glass_Shatter_1.ogg","sound/impact_sounds/Glass_Shatter_2.ogg","sound/impact_sounds/Glass_Shatter_3.ogg"), 100, 1)
			var/obj/item/raw_material/shard/glass/G = new()
			G.set_loc(get_turf(user))
			src.usageState = 2
			src.icon_state = "shipalert2"
		else
			//no effect
			out(user, "<span class='alert'>\The [W] is far too weak to break the patented Nanotrasen<sup>TM</sup> Safety Glass housing</span>")

/obj/machinery/shipalert/proc/toggleActivate(mob/user as mob)
	if (!user)
		return

	if (src.working)
		out(user, "The alert coils are currently discharging, please be patient.")
		return

	src.working = 1

	if (shipAlertState == SHIP_ALERT_BAD)
		//centcom alert
		command_alert("The emergency is over. Return to your regular duties.", "Alert - All Clear")

		broadcast_controls.broadcast_stop(broadcast)
		qdel(broadcast)

		//toggle off
		shipAlertState = SHIP_ALERT_GOOD

		for_by_tcl(T, /turf/floor/specialroom/elevator_shaft)
			T.toggle_lights()

		//update all lights
		for (var/obj/machinery/light/L in stationLights)
			L.power_change()
			sleep(0.25)

		lastActivated = world.time

	else
		if (src.lastActivated + src.cooldownPeriod > world.time)
			out(user, "The alert coils are still priming themselves.")
			src.working = 0
			return

		//alert and siren
		command_alert("All personnel, this is not a test. There is a confirmed, hostile threat on-board and/or near the station. Report to your stations. Prepare for the worst.", "Alert - Condition Red")
		world << soundGeneralQuarters
		broadcast = new(station_name, "Condition Red - General Emergency")
		broadcast_controls.broadcast_start(broadcast, TRUE, -1, 1)
		//toggle on
		shipAlertState = SHIP_ALERT_BAD

		for_by_tcl(T, /turf/floor/specialroom/elevator_shaft)
			T.toggle_lights()

		//update all lights
		for (var/obj/machinery/light/L in stationLights)
			L.power_change()
			sleep(0.25)

		lastActivated = world.time

	//alertWord stuff would go in a dedicated proc for extension
	var/alertWord = "green"
	if (shipAlertState == SHIP_ALERT_BAD) alertWord = "red"

	logTheThing("station", user, null, "toggled the ship alert to \"[alertWord]\"")
	logTheThing("diary", user, null, "toggled the ship alert to \"[alertWord]\"", "station")
	src.working = 0

/obj/item/tinyhammer
	name = "teeny tiny hammer"
	icon = 'icons/obj/items/items.dmi'
	icon_state = "tinyhammer"
	item_state = "tinyhammer"
	inhand_image_icon = 'icons/mob/inhand/hand_tools.dmi'
	flags = FPRINT | TABLEPASS | CONDUCT
	force = 5.0
	throwforce = 5
	w_class = W_CLASS_TINY
	m_amt = 50
	desc = "Like a normal hammer, but teeny."
	stamina_damage = 33
	stamina_cost = 18
	stamina_crit_chance = 10
