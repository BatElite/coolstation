// AI (i.e. game AI, not the AI player) controlled bots

/obj/machinery/bot
	icon = 'icons/obj/bots/aibots.dmi'
	layer = MOB_LAYER
	event_handler_flags = USE_FLUID_ENTER | USE_CANPASS
	flags = FPRINT | FLUID_SUBMERGE | TGUI_INTERACTIVE
	object_flags = CAN_REPROGRAM_ACCESS
	machine_registry_idx = MACHINES_BOTS
	var/obj/item/card/id/botcard // ID card that the bot "holds".
	var/access_lookup = "Assistant" // For the get_access() proc. Defaults to staff assistant.
	var/locked = null
	var/on = 1
	var/health = 25
	var/exploding = 0 //So we don't die like five times at once.
	var/muted = 0 // shut up omg shut up.
	var/no_camera = 0
	var/setup_camera_network = "Robots"
	var/obj/machinery/camera/cam = null
	var/emagged = 0
	var/mob/emagger = null
	/// The bot's net ID
	var/botnet_id = null
	/// What's it talk like?
	var/list/speakverbs = list("beeps", "boops")
	var/text2speech = 0 // dectalk!
	/// Should the bot's speech pop up over them?
	var/speech2text = 1
	/// What color is the bot's speech?
	var/bot_speech_color
	/// What does our bot's popup speech look like?
	var/bot_speech_style
	/// What does our bot's chat text speech look like?
	var/bot_chat_style
	/// The noise that happens whenever the bot speaks
	var/bot_voice = 'sound/misc/talk/bottalk_1.ogg'
	/// The bot's speech bubble
	var/static/mutable_appearance/bot_speech_bubble = mutable_appearance('icons/mob/mob.dmi', "speech")
	var/use_speech_bubble = 1
	/// Is this bot *dynamic* enough to need a higher processing tier when being watched?
	/// Set to 0 for bots that don't typically directly interact with people, like ducks and floorbots
	var/dynamic_processing = 1
	/// Bots get their processing tier changed based on what they're doing
	/// If they're offscreen and not doing anything interesting, they get processed less rapidly
	/// If they're onscreen and not in the middle of something major, they get processed rapidly
	/// If they're right in the middle of something like arresting someone, they get processed *ehhh* quick
	/// Low process rate for bots that we can't see
	var/PT_idle = PROCESSING_SIXTEENTH
	/// High process rate for bots looking for something to do
	var/PT_search = PROCESSING_HALF
	/// Middle process rate for bots currently trying to murder someone
	var/PT_active = PROCESSING_QUARTER
	var/hash_cooldown = (2 SECONDS)
	var/next_hash_check = 0
	/// If we're in the middle of something and don't want our tier to go wonky
	var/doing_something = 0
	/// Range that the bot checks for clients
	var/hash_check_range = 6

	var/frustration = 0
	/// How slowly the bot moves by default -- higher is slower!
	var/bot_move_delay = 6
	var/list/path = null	// list of path turfs
	var/datum/robot_mover/bot_mover
	var/moving = 0 // Are we ON THE MOVE??
	var/stunned = 0 //It can be stunned by tasers. Delicate circuits.
	var/current_movepath = 0
	var/scanrate = 10 // How often do we check for stuff while we're ON THE MOVE. in deciseconds

	p_class = 2

	power_change()
		return

	CanPass(atom/movable/mover, turf/target)
		if (istype(mover, /obj/projectile))
			return 0
		return ..()

	New()
		..()
		RegisterSignal(src, COMSIG_ATOM_HITBY_PROJ, PROC_REF(hitbyproj))
		if(!no_camera)
			src.cam = new /obj/machinery/camera(src)
			src.cam.c_tag = src.name
			src.cam.network = setup_camera_network
		src.processing_tier = src.PT_idle
		src.SubscribeToProcess()
		if(!src.chat_text)
			src.chat_text = new
		src.vis_contents += src.chat_text
		SPAWN_DBG(0.5 SECONDS)
			src.botcard = new /obj/item/card/id(src)
			src.botcard.access = get_access(src.access_lookup)
			src.botnet_id = format_net_id("\ref[src]")

	disposing()
		botcard = null
		//qdel(chat_text) should be on atom now
		//chat_text = null
		qdel(bot_mover)
		bot_mover = null
		if(cam)
			cam.dispose()
			cam = null
		..()

	attackby(obj/item/W as obj, mob/user as mob)
		user.lastattacked = src
		attack_particle(user,src)
		hit_twitch(src)
		if (W.hitsound)
			playsound(src,W.hitsound,50,1)
		..()

	process(mult, var/force)
		if(src.dynamic_processing)
			if(src.doing_something && src.processing_tier != src.PT_active)
				src.processing_tier = src.PT_active
				src.SubscribeToProcess()
			else if(!src.doing_something && TIME >= (src.next_hash_check))
				src.next_hash_check = TIME + src.hash_cooldown
				if(src.CheckIfVisible())
					src.processing_tier = src.PT_search
					src.SubscribeToProcess()
				else
					src.processing_tier = src.PT_idle
					src.SubscribeToProcess()
			. = ..()

	proc/CheckIfVisible()
		var/turf/T = get_turf(src)
		if(isnull(T))
			return FALSE
		for (var/mob/M in GET_NEARBY(T, src.hash_check_range))
			if(M.client)
				return TRUE
		return FALSE

	// Generic default. Override for specific bots as needed.
	bullet_act(var/obj/projectile/P)
		if (!P || !istype(P))
			return
		hit_twitch(src)

		var/damage = 0
		damage = round(((P.power/4)*P.proj_data.ks_ratio), 1.0)

		if (P.proj_data.damage_type == D_KINETIC)
			src.health -= damage
		else if (P.proj_data.damage_type == D_PIERCING)
			src.health -= (damage*2)
		else if (P.proj_data.damage_type == D_ENERGY)
			src.health -= damage

		if (src.health <= 0)
			src.explode()
		return

	proc/explode()
		return

	proc/speak(var/message, var/sing, var/just_float, var/just_chat)
		if (!src.on || !message || src.muted)
			return
		var/image/chat_maptext/chatbot_text = null
		if (src.speech2text && src.chat_text && !just_chat)
			if(src.use_speech_bubble)
				UpdateOverlays(bot_speech_bubble, "bot_speech_bubble")
				SPAWN_DBG(1.5 SECONDS)
					UpdateOverlays(null, "bot_speech_bubble")
			if(!src.bot_speech_color)
				var/num = hex2num(copytext(md5("[src.name][TIME]"), 1, 7))
				src.bot_speech_color = hsv2rgb(num % 360, (num / 360) % 10 + 18, num / 360 / 10 % 15 + 85)
			var/singing_italics = sing ? " font-style: italic;" : ""
			var/maptext_color
			if (sing)
				maptext_color ="#D8BFD8"
			else
				maptext_color = src.bot_speech_color
			chatbot_text = make_chat_maptext(src, message, "color: [maptext_color];" + src.bot_speech_style + singing_italics)
			if(chatbot_text && src.chat_text && length(src.chat_text.lines))
				chatbot_text.measure(src)
				for(var/image/chat_maptext/I in src.chat_text.lines)
					if(I != chatbot_text)
						I.bump_up(chatbot_text.measured_height)

		src.audible_message("<span class='game say'><span class='name'>[src]</span> [pick(src.speakverbs)], \"<span style=\"[src.bot_chat_style]\">[message]\"</span>", just_maptext = just_float, assoc_maptext = chatbot_text)
		playsound(src, src.bot_voice, 40, 1)
		if (src.text2speech)
			SPAWN_DBG(0)
				var/audio = dectalk("\[:nk\][message]")
				if (audio && audio["audio"])
					for (var/mob/O in hearers(src, null))
						if (!O.client)
							continue
						if (O.client.ignore_sound_flags & (SOUND_VOX | SOUND_ALL))
							continue
						ehjax.send(O.client, "browseroutput", list("dectalk" = audio["audio"]))

/obj/machinery/bot/examine()
	. = ..()
	var/healthpct = src.health / initial(src.health)
	if (healthpct <= 0.8)
		if (healthpct >= 0.4)
			. += "<span class='alert'>[src]'s parts look loose.</span>"
		else
			. += "<span class='alert'><B>[src]'s parts look very loose!</B></span>"

/obj/machinery/bot/proc/hitbyproj(source, obj/projectile/P)
	if((P.proj_data.damage_type & (D_KINETIC | D_ENERGY | D_SLASHING)) && P.proj_data.ks_ratio > 0)
		P.initial_power -= 10
		if(P.initial_power <= 0)
			P.die()
	if(!src.density)

		return PROJ_OBJ_HIT_OTHER_OBJS | PROJ_ATOM_PASSTHROUGH

/obj/machinery/bot/proc/DoWhileMoving()
	return

/obj/machinery/bot/proc/DoAtDestination()
	return

/obj/machinery/bot/proc/KillPathAndGiveUp(var/give_up)
	src.frustration = 0
	src.path = null
	qdel(src.bot_mover)
	if(give_up)
		src.doing_something = 0

/obj/machinery/bot/proc/point(var/atom/target, var/announce_it = 0) // I stole this from the medibot (and chefbot) <3 u marq ur a beter codr then me
	var/turf/T = get_turf(target)
	if(!T) return
	if(announce_it)
		visible_message("<b>[src]</b> points at [target]!")
	var/obj/decal/point/P = new(T)
	P.pixel_x = target.pixel_x
	P.pixel_y = target.pixel_y
	P.color = src.bot_speech_color
	SPAWN_DBG(2 SECONDS)
		P.invisibility = 101
		qdel(P)

/obj/machinery/bot/emp_act()
	src.emag_act()

	/// Takes a turf and spits out string of coordinates
/obj/machinery/bot/proc/turf2coordinates(var/atom/A)
	var/turf/T = get_turf(A)
	if(isturf(T))
		var/Tx = T.x
		var/Ty = T.y
		var/Tz = T.z
		return jointext(list(Tx, Ty, Tz), ",")
	else
		return "some invalid thing, probably"

/obj/machinery/bot/proc/get_pathable_turf(atom/the_target)
	var/turf/target_turf = get_turf(the_target)
	. = 0
	if(checkTurfPassable(target_turf))
		return target_turf
	else
		for(var/dir_look in alldirs)
			var/turf/T = get_step(target_turf, dir_look)
			if(checkTurfPassable(T))
				return T

/obj/machinery/bot/proc/navigate_to(atom/the_target, var/move_delay = 10, var/adjacent = 0, max_dist=600, turf/exclude = null)
	var/target_turf = get_pathable_turf(the_target)
	if(!target_turf)
		return 0

	src.KillPathAndGiveUp(0)
	src.bot_mover = new /datum/robot_mover(newmaster = src, _move_delay = move_delay, _target_turf = target_turf, _current_movepath = current_movepath, _adjacent = adjacent, _scanrate = scanrate, _max_dist = max_dist, _exclude = exclude)
	return 0

/obj/machinery/bot/proc/navigate_with_navbeacons(atom/the_target, var/move_delay = 10, var/adjacent = 0, max_dist=150, max_stop_dist = 150, turf/exclude = null)
	var/target_turf = get_pathable_turf(the_target)
	if(!target_turf)
		return 0

	src.KillPathAndGiveUp(0)

	var/obj/machinery/navbeacon/nearest_to_self
	var/selfdist = INFINITY
	for_by_tcl(navbeacon, /obj/machinery/navbeacon)
		var/nav_dist = GET_DIST(src, navbeacon)
		if(nav_dist < selfdist)
			nearest_to_self = navbeacon
			selfdist = nav_dist
			if(selfdist < 5)
				break

	var/obj/machinery/navbeacon/nearest_to_target
	var/targdist = INFINITY
	for_by_tcl(navbeacon, /obj/machinery/navbeacon)
		var/nav_dist = GET_DIST(target_turf, navbeacon)
		if(nav_dist < targdist)
			nearest_to_target = navbeacon
			targdist = nav_dist
			if(targdist < 5)
				break

	if(((targdist + selfdist) / 3) > (GET_DIST(src, target_turf)))
		src.bot_mover = new /datum/robot_mover(newmaster = src, _move_delay = move_delay, _target_turf = target_turf, _current_movepath = current_movepath, _adjacent = adjacent, _scanrate = scanrate, _max_dist = max_dist, _exclude = exclude)
		return 0
	var/list/obj/machinery/navbeacon/stops = NavBeaconAStar(nearest_to_self, nearest_to_target, /obj/machinery/navbeacon/proc/neighbors, /turf/proc/Distance, 20, max_stop_dist)
	if(length(stops))
		src.bot_mover = new /datum/robot_mover(newmaster = src, _move_delay = move_delay, _target_turf = target_turf, _current_movepath = current_movepath, _adjacent = adjacent, _scanrate = scanrate, _max_dist = max_dist, _stops = stops, _exclude = exclude)
	return 0

/// movement control datum. Why yes, this is copied from secbot.dm. Which was copied from guardbot.dm
/// Now with navbeacon movement so its sorta not copied?? - Mylie
/datum/robot_mover
	var/obj/machinery/bot/master = null
	var/delay = 3
	var/atom/the_target
	var/list/obj/machinery/navbeacon/stops = list()
	var/travelled_to_stop = 0
	var/last_stop_net_id
	var/list/current_movepath
	var/adjacent = 0
	var/scanrate = 10
	var/max_dist = 150
	var/max_beacons = 20
	var/turf/exclude

	New(obj/machinery/bot/newmaster, _move_delay = 3, _target_turf, _current_movepath, _adjacent = 0, _scanrate = 10, _max_dist = 150, list/obj/machinery/navbeacon/_stops = null, turf/_exclude = null)
		..()
		if(istype(newmaster))
			src.master = newmaster
			src.delay = _move_delay
			src.the_target = get_turf(_target_turf)
			if(!isturf(src.the_target))
				if(istype(master))
					master.KillPathAndGiveUp(0)
					return
				else
					qdel(src)
			src.adjacent = _adjacent
			src.scanrate = _scanrate
			src.max_dist = _max_dist
			src.stops = _stops
			src.exclude = _exclude
			src.master_move()
		else
			qdel(src)
		return

	disposing()
		if(istype(master))
			if(master.bot_mover == src)
				master.bot_mover = null
			master.moving = FALSE
		src.master = null
		src.the_target = null
		src.stops = null
		src.exclude = null
		..()

	proc/master_move()
		if(QDELETED(src))
			return
		if(!istype(master))
			qdel(src)
			return
		if(!isturf(master.loc) || !istype(src.the_target))
			master.KillPathAndGiveUp(0)
			return

		if(length(stops))
			master.path = AStar(get_turf(master), src.master.get_pathable_turf(stops[1]), /turf/proc/CardinalTurfsWithAccess, /turf/proc/Distance, src.max_dist, master.botcard, src.exclude)
		else
			master.path = AStar(get_turf(master), src.the_target, /turf/proc/CardinalTurfsWithAccess, /turf/proc/Distance, src.max_dist, master.botcard, src.exclude)

		if(!length(master.path))
			qdel(src)
			return

		SPAWN_DBG(0)
			if (!istype(master) || (master && (!length(master.path) || !src.the_target)))
				qdel(src)
				return

			if(src.adjacent && (length(master?.path) > 1)) //Make sure to check it isn't null!!
				master.path.len-- //Only go UP to the target, not the same tile.

			master?.moving = 1

			while(length(src.stops) && !QDELETED(src))
				while(length(master?.path) && src.the_target && !QDELETED(src))
					if(!master) break
					if(!length(master.path)) break
					if(!master.on)
						master.frustration = 0
						break

					if(master.DoWhileMoving()) // We're here! Or something!
						master.moving = 0
						master.bot_mover = null
						master.process() // responsive, robust AI = calling process() a million zillion times
						master = null
						qdel(src)
						return

					src.travelled_to_stop++

					if(length(master?.path) && master.path[1])
						if(istype(get_turf(master), /turf/space)) // frick it, duckie toys get jetpacks
							var/obj/effects/ion_trails/I = new()
							I.set_loc(get_turf(master))
							I.set_dir(master.dir)
							flick("ion_fade", I)
							I.icon_state = "blank"
							I.pixel_x = master.pixel_x
							I.pixel_y = master.pixel_y
							SPAWN_DBG( 20 )
								if (I && !I.disposed) qdel(I)

						step(master, get_dir(master, master?.path[1]))
						if(isnull(master))
							break
						if(length(master?.path) && master.loc != master.path[1])
							master.frustration++
							sleep(delay)
							continue

						master.path -= master.path[1]
						sleep(delay)
					else
						break // i dunno, it runtimes
				if(last_stop_net_id)
					src.stops[1].neighbors[last_stop_net_id] = src.travelled_to_stop
				src.travelled_to_stop = 0
				var/obj/machinery/navbeacon/last_stop = src.stops[1]
				src.last_stop_net_id = last_stop.net_id
				src.stops -= src.stops[1]
				if(length(src.stops))
					master.path = AStar(get_turf(master), src.master.get_pathable_turf(src.stops[1]), /turf/proc/CardinalTurfsWithAccess, /turf/proc/Distance, src.max_dist, master.botcard, src.exclude)
				else
					master.path = AStar(get_turf(master), src.the_target, /turf/proc/CardinalTurfsWithAccess, /turf/proc/Distance, src.max_dist, master.botcard, src.exclude)
					break

			while(length(master?.path) && src.the_target && !QDELETED(src))
				if(!master) break
				if(!length(master.path)) break
				if(!master.on)
					master.frustration = 0
					break

				if(master.DoWhileMoving()) // We're here! Or something!
					master.moving = 0
					master.bot_mover = null
					master.process() // responsive, robust AI = calling process() a million zillion times
					master = null
					qdel(src)
					return

				src.travelled_to_stop++

				if(length(master?.path) && master.path[1])
					if(istype(get_turf(master), /turf/space)) // frick it, duckie toys get jetpacks
						var/obj/effects/ion_trails/I = new()
						I.set_loc(get_turf(master))
						I.set_dir(master.dir)
						flick("ion_fade", I)
						I.icon_state = "blank"
						I.pixel_x = master.pixel_x
						I.pixel_y = master.pixel_y
						SPAWN_DBG( 20 )
							if (I && !I.disposed) qdel(I)

					step(master, get_dir(master, master?.path[1]))
					if(isnull(master))
						break
					if(length(master?.path) && master.loc != master.path[1])
						master.frustration++
						sleep(delay)
						continue

					master.path -= master.path[1]
					sleep(delay)
				else
					break // i dunno, it runtimes

			if (istype(master))
				master.moving = 0
				master.bot_mover = null
				master.DoAtDestination()
				master.process() // responsive, robust AI = calling process() a million zillion times
				master = null
				qdel(src)

