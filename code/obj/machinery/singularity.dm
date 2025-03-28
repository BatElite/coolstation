/*
Contains:
-Singularity generator
-Singularity
-Field generator & containment field
-Emitter
-Collector array & controller
-Singularity bomb
*/
// I came here with good intentions, I swear, I didn't know what this code was like until I was already waist deep in it
#define SINGULARITY_TIME 11
#define SINGULARITY_MAX_DIMENSION 11//defines the maximum dimension possible by a player created singularity.
#define MIN_TO_CONTAIN 4
#define DEFAULT_AREA 25
#define EVENT_GROWTH 3//the rate at which the event proc radius is scaled relative to the radius of the singularity
#define EVENT_MINIMUM 5//the base value added to the event proc radius, serves as the radius of a 1x1
//Anchoring states for the emitters, field generators, and singulo jar
#define UNWRENCHED 0
#define WRENCHED 1
#define WELDED 2

// I'm sorry
//////////////////////////////////////////////////// Singularity generator /////////////////////

/obj/machinery/the_singularitygen/
	name = "gravitational singularity generator"
	desc = "An Odd Device which produces a Black Hole when set up."
	icon = 'icons/obj/singularity.dmi'
	icon_state = "TheSingGen"
	anchored = 0 // so it can be moved around out of crates
	density = 1
	mats = 250
	var/bhole = 0 // it is time. we can trust people to use the singularity For Good - cirr

/obj/machinery/the_singularitygen/New()
	START_TRACKING
	..()

/obj/machinery/the_singularitygen/disposing()
	STOP_TRACKING
	..()

/obj/machinery/the_singularitygen/process()
	var/goodgenerators = 0 //ensures that there are 4 generators in place with at least 2 links. note that false positives are very possible and will result in a loose singularity
	var/smallestdimension = 13//determines the radius of the produced singularity,starts higher than is possible

	for_by_tcl(gen, /obj/machinery/field_generator)//this loop checks for valid field generators
		if(get_dist(gen,loc)<(SINGULARITY_MAX_DIMENSION/2)+1)
			if(gen.active_dirs >= 2)
				goodgenerators++
				smallestdimension = min(smallestdimension, gen.shortestlink)

	if (goodgenerators>=4)

		// Did you know this thing still works? And wasn't logged (Convair880)?
		logTheThing("bombing", src.fingerprintslast, null, "A [src.name] was activated, spawning a singularity at [log_loc(src)]. Last touched by: [src.fingerprintslast ? "[src.fingerprintslast]" : "*null*"]")
		message_admins("A [src.name] was activated, spawning a singularity at [log_loc(src)]. Last touched by: [key_name(src.fingerprintslast)]")

		var/turf/T = src.loc
		playsound(T, 'sound/machines/satcrash.ogg', 100, 0, 3, 0.8)
		if (src.bhole)
			new /obj/bhole(T, 3000)
		else
			if(!(smallestdimension % 2))
				smallestdimension--
			new /obj/machinery/the_singularity(T, 100,,round(smallestdimension/2))
		qdel(src)

/obj/machinery/the_singularitygen/attackby(obj/item/W, mob/user)
	src.add_fingerprint(user)
	if (iswrenchingtool(W))
		if (!anchored)
			anchored = 1
			playsound(src.loc, "sound/items/Ratchet.ogg", 75, 1)
			boutput(user, "You secure the [src.name] to the floor.")
			src.anchored = 1
		else if (anchored)
			anchored = 0
			playsound(src.loc, "sound/items/Ratchet.ogg", 75, 1)
			boutput(user, "You unsecure the [src.name].")
			src.anchored = 0

		logTheThing("station", user, null, "[src.anchored ? "bolts" : "unbolts"] a [src.name] [src.anchored ? "to" : "from"] the floor at [log_loc(src)].") // Ditto (Convair880).
		return
	else
		return ..()

//////////////////////////////////////////////////// Singularity /////////////////////////////

/obj/machinery/the_singularity/
	name = "gravitational singularity"
	desc = "Perhaps the densest thing in existence, except for you."

	icon = 'icons/effects/160x160.dmi'
	icon_state = "Sing2"
	anchored = 1
	density = 1
	event_handler_flags = IMMUNE_SINGULARITY
	deconstruct_flags = DECON_WELDER | DECON_MULTITOOL


	pixel_x = -64
	pixel_y = -64

	var/maxboom = 0
	var/has_moved
	var/active = 0 //determines if the singularity is contained
	///Roughly how much Shit the singularity has eaten. Also correlates to size when loose now ,see resize()
	var/energy = 10
	var/lastT = 0
	var/Dtime = null
	var/Wtime = 0
	var/dieot = 0
	var/selfmove = 1
	var/grav_pull = 6
	var/radius = 0 //the variable used for all calculations involving size.this is the current size
	var/maxradius = INFINITY//the maximum size the singularity can grow to

	///If loose, try and move towards this turf. see also proc/pick_target()
	var/turf/current_target


#ifdef SINGULARITY_TIME
/*
hello I've lost my remaining sanity by dredging this code from the depths of hell where it was cast eons before I arrived in this place
for some reason I brought it back and tried to clean it up a bit and I regret everything but it's too late now I can't put it back please forgive me
- haine
*/
/obj/machinery/the_singularity/New(loc, var/E = 100, var/Ti = null,var/rad = 2)
	START_TRACKING
	src.energy = E
	maxradius = rad
	if(maxradius<2)
		radius = maxradius
	else
		radius = 2
	SafeScale((radius+1)/3.0,(radius+1)/3.0)
	grav_pull = (radius+1)*3
	event()
	if (Ti)
		src.Dtime = Ti
	..()

/obj/machinery/the_singularity/disposing()
	STOP_TRACKING
	. = ..()

/obj/machinery/the_singularity/process()
	eat()

	if (src.Dtime)//If its a temp singularity IE: an event
		if (Wtime != 0)
			if ((src.Wtime + src.Dtime) <= world.time)
				src.Wtime = 0
				qdel (src)
		else
			src.Wtime = world.time

	if (dieot) //slowly dies over time
		energy -= 15

	if (energy <= 0) //only relevant to singularities with dieot set atm, but moved it out in case we want for singularities to lose energy later.
		qdel (src)
		return

	if (prob(20))//Chance for it to run a special event
		event()

	if (active == 1)
		move()
		SPAWN_DBG(1.1 SECONDS) // slowing this baby down a little -drsingh
			move()
	else//this should probably be modified to use the enclosed test of the generator
		var/checkpointC = 0
		for (var/obj/machinery/containment_field/X in orange(maxradius+2,src))
			checkpointC ++
		if (checkpointC < max(MIN_TO_CONTAIN,(radius*8)))//as radius of a 5x5 should be 2, 16 tiles are needed to hold it in, this allows for 4 failures before the singularity is loose
			src.active = 1
			maxradius = INFINITY
			if (src.z == Z_LEVEL_STATION)
				global_objective_status["engineering_whoopsie"] = FAILED
			message_admins("[src] has become loose at [log_loc(src)]")
			message_ghosts("<b>[src]</b> has become loose at [log_loc(src, ghostjump=TRUE)].")



/obj/machinery/the_singularity/emp_act()
	return // No action required this should be the one doing the EMPing

/obj/machinery/the_singularity/proc/eat()
	for (var/X in range(grav_pull, src.get_center()))
		if (!X)
			continue
		if (X == src)
			continue

		var/atom/A = X

		if (A.event_handler_flags & IMMUNE_SINGULARITY)
			continue

		if (!active)
			if (A.event_handler_flags & IMMUNE_SINGULARITY_INACTIVE)
				continue

		if (!isarea(X))
			if (get_dist(src.get_center(), X) <= radius) // why was this a switch before ffs
				src.Bumped(A)
			else if (istype(X, /atom/movable))
				var/atom/movable/AM = X
				if (!AM.anchored)
					step_towards(AM, src)

/obj/machinery/the_singularity/proc/move()
	// if we're inside something (e.g posessed mob) dont move
	if (!isturf(src.loc))
		return

	if (selfmove)
		if (!current_target || get_dist(src.get_center(), current_target) <= radius) //we're close enough to current target
			current_target = pick_target()

		//might want to add some jitter to this later
		var/dir = vector_to_dir(current_target.x - src.x, current_target.y - src.y)//pick(cardinal)

		var/checkloc = get_step(src.get_center(), dir)
		for (var/dist = 0, dist < max(2,radius+1), dist ++)
			if (locate(/obj/machinery/containment_field) in checkloc)
				current_target = null //can't reach
				return
			checkloc = get_step(checkloc, dir)

		step(src, dir)

///Find a new target turf to get to
/obj/machinery/the_singularity/proc/pick_target()
	/*This little algorithm goes as follows:
	  -get a random X and Y (should be hard to predict?)
	  -look at every combination of those X and Y offset from our center (for example: [-7, -12], [7, -12], [-7, 12], [7, 12] - all relative coords)
	  -count how many edible atoms are in a 5x5 on those turfs
	  -use those counts as weights when picking one of the four options, so going towards "denser" areas is favoured but not garuanteed.
	*/

	var/turf/center = get_center()
	if (!istype(center))
		return

	var/list/weights = list()
	//highest score we found (if all 4 targets are empty this would )
	var/max_score = 0

	var/rand_x = rand(0, (radius+1)*3) //since radius 1 singularities can exist, we have to add 1 for them get any decent range.
	var/rand_y = rand(0, (radius+1)*3)

	if ((rand_x + rand_y) < radius) //try and stop the singulo from picking turfs that are very close by, it was picking too many close targets for my liking.
		rand_x += rand(1,3) //the effect of this bit will lessen as a singularity gets bigger.
		rand_y += rand(1,3)

	for (var/turf/T in list(locate(center.x - rand_x, center.y - rand_y, center.z),\
							locate(center.x + rand_x, center.y - rand_y, center.z),\
							locate(center.x - rand_x, center.y + rand_y, center.z),\
							locate(center.x + rand_x, center.y + rand_y, center.z))) //should filter out options out of map bounds

		var/score = 0
		for (var/turf/T2 in block(locate(T.x - 2, T.y - 2, T.z), locate(T.x + 2, T.y + 2, T.z))) //5x5

			for (var/atom/maybe_food in T2.contents)
				if (!(maybe_food.event_handler_flags & IMMUNE_SINGULARITY) && !(maybe_food.flags & TECHNICAL_ATOM)) //any food on this turf?
					score++
					if(maybe_food.event_handler_flags & IS_LOAF)
						var/obj/item/reagent_containers/food/snacks/prison_loaf/loaf = maybe_food
						score += loaf.loaf_factor // let's make the hole crave loaves.
			if (!(T2.event_handler_flags & IMMUNE_SINGULARITY) && !(T2.flags & TECHNICAL_ATOM)) //turfs themselves are food too
				score++

		max_score = max(max_score, score)
		weights[T] = score

	if (!length(weights)) //by virtue of our maps being 300*300, this shouldn't happen
		message_admins("Singularity at [log_loc(src)] failed to find any eligible target turfs")
		return get_turf(src) //the code expects a turf
	if (!max_score) //all space, probably
		return pick(weights) //weighted_pick would always go with the first option if all weights are zero, which would bias towards bottom left
	else
		return weighted_pick(weights)

/obj/machinery/the_singularity/ex_act(severity, last_touched)
	if(!maxboom)
		SPAWN_DBG(0.1 SECONDS)
			if(severity >= 6 && (maxboom ? prob(maxboom*5) : prob(30))) //need a big bomb (TTV+ sized), but a big enough bomb will always clear it
				qdel(src)
			maxboom = 0
	maxboom = max(severity, maxboom)

/obj/machinery/the_singularity/Bumped(atom/A)
	var/gain = 0

	if (A.event_handler_flags & IMMUNE_SINGULARITY)
		return
	if (!active)
		if (A.event_handler_flags & IMMUNE_SINGULARITY_INACTIVE)
			return

	// Don't bump that which no longer exists
	if(A.disposed)
		return

	if (isliving(A) && !isintangible(A))//if its a mob
		var/mob/living/L = A
		L.set_loc(src.get_center())
		gain = 20
		if (ishuman(L))
			var/mob/living/carbon/human/H = A
			//Special halloween-time Unkillable gibspam protection!
			if (H.unkillable)
				H.unkillable = 0
			if (H.mind && H.mind.assigned_role)
				switch (H.mind.assigned_role)
					if ("Clown")
						// Hilarious.
						gain = 500
#ifdef DATALOGGER
						game_stats.Increment("clownabuse")
#endif
						resize()
					if ("Lawyer")
						// Satan.
						gain = 250
					if ("Tourist", "Geneticist")
						// Nerds that are oblivious to dangers
						gain = 200
					if ("Chief Engineer")
						// Hubris
						gain = 150
					if ("Engineer", "Mechanic")
						// More hubris
						gain = 100
					if ("Staff Assistant", "Captain")
						// Worthless
						gain = 20
					else
						gain = 50

		L.remove()

	else if (isobj(A))
		//if (istype(A, /obj/item/graviton_grenade))
			//src.warp = 100

		if (istype(A, /obj/decal/cleanable)) //MBC : this check sucks, but its far better than cleanables doing hard-delete at the whims of the singularity. replace ASAP when i figure out cleanablessssss
			qdel(A)
			gain = 2
		else
			var/obj/O = A
			O.set_loc(src.get_center())
			O.ex_act(OLD_EX_TOTAL)
			if (O)
				qdel(O)
			gain = 2

	else if (isturf(A))
		var/turf/T = A
		if (T.turf_flags & IS_TYPE_SIMULATED)
			if (istype(T, /turf/floor))
				T.ReplaceWithSpace()
				gain = 2
			else
				T.ReplaceWithFloor()

	src.energy += gain

/obj/machinery/the_singularity/proc/get_center()
	return src.loc


/obj/machinery/the_singularity/attackby(var/obj/item/I as obj, var/mob/user as mob)
	if (istype(I, /obj/item/clothing/mask/cigarette))
		var/obj/item/clothing/mask/cigarette/C = I
		if (!C.on)
			C.light(user, "<span class='alert'><b>[user]</b> lights [C] on [src]. Holy fucking shit!</span>")
		else
			return ..()
	else
		return ..()

/obj/machinery/the_singularity/proc/resize() //also does shrinking as soon as someone else figures out how to get the cocksucking scaling to work
	var/diameter = 2*radius + 1
	//at least 50d^2 energy to achieve diameter d, picked kinda arbitrarily so the growth is slow and also increasingly more demanding
	//(though with increased size a singulo will eat more shit fast as well so IDK it's probably still mildly accelerating)
	//for a 1x1 through 11x11 (uneven diameters only) this comes out to thresholds of 50/450/1250/2450/4050/6050 energy needed
	//ATM everything that isn't a mob gives 2 energy, so the singulo shouldn't be growing quickly once it's loose
	var/godver = 50*(diameter+2)*(diameter+2)
	//var/godver2 = 50*diameter*diameter

	if (src.energy >= godver) //too small
		if(radius<maxradius)
			radius++
			SafeScale((radius+0.5)/(radius-0.5),(radius+0.5)/(radius-0.5))
	/*else if (src.energy < godver2)//too big
		if (radius == 1)
			return
		SafeScale(radius/((radius+0.5)/(radius-0.5)),radius/((radius+0.5)/(radius-0.5)))
		radius--*/


// totally rewrote this proc from the ground-up because it was puke but I want to keep this comment down here vvv so we can bask in the glory of What Used To Be - haine
		/* uh why was lighting a cig causing the singularity to have an extra process()?
		   this is dumb as hell, commenting this. the cigarette will get processed very soon. -drsingh
		SPAWN_DBG(0) //start fires while it's lit
			src.process()
		*/

/////////////////////////////////////////////Controls which "event" is called
/obj/machinery/the_singularity/proc/event()
	var/numb = rand(1,3)
	resize()
	switch (numb)
		if (1)//Eats the turfs around it
			BHolerip()
		if (2)//tox damage all carbon mobs in area
			Toxmob()
		if (3)//Stun mobs who lack optic scanners
			Mezzer()


/obj/machinery/the_singularity/proc/Toxmob()
	for (var/mob/living/carbon/M in orange(radius*EVENT_GROWTH+EVENT_MINIMUM, src.get_center()))
		var/mult = (1 - (M.get_rad_protection() / 100))
		if (!mult)
			continue
		//too broad, you could prevent singularity rads entirely by wearing suspenders
		/*if (ishuman(M))
			var/mob/living/carbon/human/H = M
			if (H.wear_suit)
				continue*/
		M.take_toxin_damage(12*mult)
		M.changeStatus("radiation", mult * (4*(radius+1) SECONDS))
		M.show_text("You feel odd.", "red")

/obj/machinery/the_singularity/proc/Mezzer()
	for (var/mob/living/carbon/M in oviewers(radius*EVENT_GROWTH+EVENT_MINIMUM, src.get_center()))
		//What if this required you actually look sorta in the direction of the goshdarn singularity
		if (abs((180 + abs(dir_to_angle(M.dir) - get_angle(M, src)))%360 - 180) > 90) //I copied this from stackoverflow we're a proper codebase now :)
			continue
		if (ishuman(M))
			var/mob/living/carbon/human/H = M
			if (istype(H.glasses,/obj/item/clothing/glasses/meson))
				M.show_text("You look directly into [src.name], good thing you had your protective eyewear on!", "green")
				continue
		M.changeStatus("stunned", 7 SECONDS)
		M.visible_message("<span class='alert'><B>[M] stares blankly at [src]!</B></span>",\
		"<B>You look directly into [src]!<br><span class='alert'>You feel weak!</span></B>")

/obj/machinery/the_singularity/proc/BHolerip()
	for (var/turf/T in orange(radius*EVENT_GROWTH+EVENT_MINIMUM, src.get_center()))
		if (prob(70))
			continue
		if (T && !(T.turf_flags & CAN_BE_SPACE_SAMPLE) && (get_dist(src.get_center(),T) == radius+1 || get_dist(src.get_center(),T) == radius+2)) // I'm very tired and this is the least dumb thing I can make of what was here for now.   This needs to get updated for the variable size singularity at some point
			if (T.turf_flags & IS_TYPE_SIMULATED)
				if (istype(T,/turf/floor) && !istype(T,/turf/floor/plating))
					var/turf/floor/F = T
					if (!F.broken)
						if (prob(80))
							F.break_tile_to_plating()
							if(!F.intact)
								new/obj/item/tile (F)
						else
							F.break_tile()
				else if (istype(T, /turf/wall))
					var/turf/wall/W = T
					if (istype(W, /turf/wall/r_wall) || istype(W, /turf/wall/auto/reinforced))
						new /obj/structure/girder/reinforced(W)
					else
						new /obj/structure/girder(W)
					var/obj/item/sheet/S = new /obj/item/sheet(W)
					if (W.material)
						S.setMaterial(W.material)
					else
						var/datum/material/M = getMaterial("steel")
						S.setMaterial(M)
					W.ReplaceWithFloor()
			else
				T.ReplaceWithFloor()
	return
#endif
//////////////////////////////////////// Field generator /////////////////////////////////////////

/obj/machinery/field_generator
	name = "field generator"
	desc = "Projects an energy field when active."
	icon = 'icons/obj/singularity.dmi'
	icon_state = "Field_Gen"
	anchored = 0
	density = 1
	req_access = list(access_engineering_engine)
	object_flags = CAN_REPROGRAM_ACCESS
	///Set to true have the generator power up automatically
	var/Varedit_start = 0
	///Set to true to have the generator operate forever
	var/Varpower = 0
	var/active = 0
	var/power = 20
	var/max_power = 250
	var/state = UNWRENCHED
	var/locked = 1
	//Remote control stuff
	var/net_id = null
	var/obj/machinery/power/data_terminal/link = null
	mats = 14
	var/active_dirs = 0
	var/shortestlink = 0

	proc/set_active(var/act)
		if (src.active != act)
			src.active = act
			if (src.active)
				event_handler_flags |= IMMUNE_SINGULARITY
			else
				event_handler_flags &= ~IMMUNE_SINGULARITY

/obj/machinery/field_generator/attack_hand(mob/user as mob)
	if(state == WELDED)
		if(!src.locked)
			if(src.active >= 1)
	//			src.active = 0
	//			icon_state = "Field_Gen"
				boutput(user, "You are unable to turn off the field generator, wait till it powers down.")
	//			src.cleanup()
			else
				set_active(1)
				icon_state = "Field_Gen +a"
				boutput(user, "You turn on the field generator.")
				logTheThing("station", user, null, "activated a [src.name] at [log_loc(src)].") // Hmm (Convair880).
		else
			boutput(user, "The controls are locked!")
	else
		boutput(user, "The field generator needs to be firmly secured to the floor first.")
	src.add_fingerprint(user)

/obj/machinery/field_generator/ex_act(severity)
	if (src.active)
		src.power = max(round(power - severity), 0)
	else ..()

/obj/machinery/field_generator/attack_ai(mob/user as mob)
	var/prev_locked = src.locked
	src.locked = FALSE
	Attackhand(user)
	src.locked = prev_locked

/obj/machinery/field_generator/New()
	START_TRACKING
	..()
	SPAWN_DBG(0.6 SECONDS)
		if(!src.link && (state == WELDED))
			src.get_link()

		src.net_id = format_net_id("\ref[src]")

/obj/machinery/field_generator/disposing()
	STOP_TRACKING
	. = ..()

/obj/machinery/field_generator/get_desc()
	switch(state)
		if (WRENCHED)
			. += "It has been bolted to the floor."
		if (WELDED)
			. += "It has been bolted and welded to the floor."

/obj/machinery/field_generator/process()

	if(src.Varedit_start == 1)
		if(src.active == 0)
			src.set_active(1)
			src.state = WELDED
			src.power = 250
			src.anchored = 1
			icon_state = "Field_Gen +a"
		Varedit_start = 0

	if(src.active == 1)
		if(!src.state == WELDED)
			src.set_active(0)
			return
		setup_field(NORTH)
		setup_field(SOUTH)
		setup_field(EAST)
		setup_field(WEST)
		src.set_active(2)
	src.power = clamp(src.power, 0, src.max_power)
	if(src.active >= 1)
		src.power -= 1
		//maptext = num2text(power)
		if(Varpower == 0)
			if(src.power <= 0)
				src.visible_message("<span class='alert'>The [src.name] shuts down due to lack of power!</span>")
				icon_state = "Field_Gen_w"
				src.set_active(0)
				src.cleanup(1)
				src.cleanup(2)
				src.cleanup(4)
				src.cleanup(8)
				for(var/dir in cardinal)
					src.UpdateOverlays(null, "field_start_[dir]")
					src.UpdateOverlays(null, "field_end_[dir]")

/obj/machinery/field_generator/proc/setup_field(var/NSEW = 0)
	if(!NSEW)//Make sure its ran right
		return
	var/turf/T = src.loc
	//var/turf/T2 = src.loc
	var/obj/machinery/field_generator/G = null
	var/steps = 0
	var/oNSEW = 0
	switch(NSEW)
		if(NORTH)
			oNSEW = SOUTH
		if(SOUTH)
			oNSEW = NORTH
		if(EAST)
			oNSEW = WEST
		if(WEST)
			oNSEW = EAST

	for(var/dist = 0, dist <= SINGULARITY_MAX_DIMENSION, dist += 1) // checks out to max dimension tiles away for another generator to link to
		T = get_step(T, NSEW)
		//T2 = T
		G = (locate(/obj/machinery/field_generator) in T)
		if(G)
			if(shortestlink==0)
				shortestlink = dist
			else if (shortestlink > dist)
				shortestlink = dist
			if(!G.active)
				return
			if(G.active_dirs & oNSEW)
				return // already active I guess
			break
		steps += 1

	if(isnull(G))
		return

	src.UpdateOverlays(image('icons/obj/singularity.dmi', "Contain_F_Start", dir=NSEW, layer=(NSEW == NORTH ? src.layer - 1 : FLOAT_LAYER)), "field_start_[NSEW]")
	G.UpdateOverlays(image('icons/obj/singularity.dmi', "Contain_F_End", dir=NSEW, layer=(NSEW == SOUTH ? src.layer - 1 : FLOAT_LAYER)), "field_end_[NSEW]")

	T = get_turf(src)

	for(var/dist = 0, dist < steps, dist += 1) // creates each field tile
		//var/field_dir = get_dir(T2,get_step(T2, NSEW))
		T = get_step(T, NSEW)
		//T2 = T
		var/obj/machinery/containment_field/CF = new /obj/machinery/containment_field(src, G) //(ref to this gen, ref to connected gen)
		CF.set_loc(T)
		CF.set_dir(NSEW)

	active_dirs |= NSEW
	G.active_dirs |= oNSEW

	G.process() // ok, a cool trick / ugly hack to make the direction of the fields nice and consistent in a circle

//Create a link with a data terminal on the same tile, if possible.
/obj/machinery/field_generator/proc/get_link()
	if(src.link)
		src.link.master = null
		src.link = null
	var/turf/T = get_turf(src)
	var/obj/machinery/power/data_terminal/test_link = locate() in T
	if(test_link && !DATA_TERMINAL_IS_VALID_MASTER(test_link, test_link.master))
		src.link = test_link
		src.link.master = src

	return

/obj/machinery/field_generator/bullet_act(var/obj/projectile/P)
	if(!P)
		return
	if(!P.proj_data)
		return
	if(P.proj_data.damage_type == D_ENERGY)
		src.power += P.power

/obj/machinery/field_generator/attackby(obj/item/W, mob/user)
	if (iswrenchingtool(W))
		if(active)
			boutput(user, "Turn off the field generator first.")
			return

		else if(state == UNWRENCHED)
			state = WRENCHED
			playsound(src.loc, "sound/items/Ratchet.ogg", 75, 1)
			boutput(user, "You secure the external reinforcing bolts to the floor.")
			src.anchored = 1
			return

		else if(state == WRENCHED)
			state = UNWRENCHED
			playsound(src.loc, "sound/items/Ratchet.ogg", 75, 1)
			boutput(user, "You undo the external reinforcing bolts.")
			src.anchored = 0
			return

	if(isweldingtool(W))
		if(state != UNWRENCHED)
			if(!W:try_weld(user, 1, noisy = 2))
				return
			SETUP_GENERIC_ACTIONBAR(user, src, 2 SECONDS, /obj/machinery/field_generator/proc/weld_action,\
			list(user), W.icon, W.icon_state, "[user] finishes using [his_or_her(user)] [W.name] on the field generator.", null)
		if(state == WRENCHED)
			boutput(user, "You start to weld the field generator to the floor.")
			return
		else if(state == WELDED)
			boutput(user, "You start to cut the field generator free from the floor.")
			return

	if (istype(W, /obj/item/device/pda2) && W:ID_card)
		W = W:ID_card
	if (istype(W, /obj/item/card/id))
		if (src.allowed(user))
			src.locked = !src.locked
			boutput(user, "Controls are now [src.locked ? "locked." : "unlocked."]")
		else
			boutput(user, "<span class='alert'>Access denied.</span>")

	else
		src.add_fingerprint(user)
		..()
		/*src.add_fingerprint(user)
		boutput(user, "<span class='alert'>You hit the [src.name] with your [W.name]!</span>")
		for(var/mob/M in AIviewers(src))
			if(M == user)	continue
			M.show_message("<span class='alert'>The [src.name] has been hit with the [W.name] by [user.name]!</span>")*/

/obj/machinery/field_generator/proc/weld_action(mob/user)
	if(state == WRENCHED)
		state = WELDED
		src.get_link() //Set up a link, now that we're secure!
		boutput(user, "You weld the field generator to the floor.")
		icon_state = "Field_Gen_w"
	else if(state == WELDED)
		state = WRENCHED
		if(src.link) //Clear active link.
			src.link.master = null
			src.link = null
		boutput(user, "You cut the field generator free from the floor.")
		icon_state = "Field_Gen"

/obj/machinery/field_generator/proc/cleanup(var/NSEW)
	var/obj/machinery/containment_field/F
	var/obj/machinery/field_generator/G
	var/turf/T = src.loc
	//var/turf/T2 = src.loc

	active_dirs &= ~NSEW

	src.UpdateOverlays(null, "field_start_[NSEW]")
	src.UpdateOverlays(null, "field_end_[turn(NSEW, 180)]")

	for(var/dist = 0, dist <= SINGULARITY_MAX_DIMENSION, dist += 1) // checks out to 8 tiles away for fields
		T = get_step(T, NSEW)
		//T2 = T
		F = (locate(/obj/machinery/containment_field) in T)
		if(F)
			qdel(F)
			F = null

		G = (locate(/obj/machinery/field_generator) in T)
		if(G)
			G.UpdateOverlays(null, "field_end_[NSEW]")
			G.UpdateOverlays(null, "field_start_[turn(NSEW, 180)]")
			G.active_dirs &= ~turn(NSEW, 180)
			break //gonna make this break every time cause I think it's possible this might screw with nerds who make a grid of singularities.
			//like I'm not even sure what this check was for
			/*if(!G.active)
				break*/

//Send a signal over our link, if possible.
/obj/machinery/field_generator/proc/post_status(var/target_id, var/key, var/value, var/key2, var/value2, var/key3, var/value3)
	if(!src.link || !target_id)
		return

	var/datum/signal/signal = get_free_signal()
	signal.source = src
	signal.transmission_method = TRANSMISSION_WIRE
	signal.data[key] = value
	if(key2)
		signal.data[key2] = value2
	if(key3)
		signal.data[key3] = value3

	signal.data["address_1"] = target_id
	signal.data["sender"] = src.net_id

	src.link.post_signal(src, signal)

//What do we do with an incoming command?
/obj/machinery/field_generator/receive_signal(datum/signal/signal)
	if(!src.link)
		return
	if(!signal || !src.net_id || signal.encryption)
		return

	/* People might abuse this but I find it funny
	if(signal.transmission_method != TRANSMISSION_WIRE) //No radio for us thanks
		return
	*/

	var/target = signal.data["sender"]

	//They don't need to target us specifically to ping us.
	//Otherwise, ff they aren't addressing us, ignore them
	if(signal.data["address_1"] != src.net_id)
		if((signal.data["address_1"] == "ping") && signal.data["sender"])
			SPAWN_DBG(0.5 SECONDS) //Send a reply for those curious jerks
				src.post_status(target, "command", "ping_reply", "device", "PNET_ENG_FIELD", "netid", src.net_id)

		return

	var/sigcommand = lowertext(signal.data["command"])
	if(!sigcommand || !signal.data["sender"])
		return

	//Oh okay, time to start up.
	if(sigcommand == "activate" && !src.active)
		src.set_active(1)
		icon_state = "Field_Gen +a"

	if(sigcommand == "deactivate" && src.active)
		src.set_active(0)
		icon_state = "Field_Gen"

	return

/obj/machinery/field_generator/disposing()
	src.cleanup(1)
	src.cleanup(2)
	src.cleanup(4)
	src.cleanup(8)
	if (link)
		link.master = null
		link = null
	..()

/////////////////////////////////////////////// Containment field //////////////////////////////////

/obj/machinery/containment_field
	name = "containment field"
	desc = "An energy field."
	icon = 'icons/obj/singularity.dmi'
	icon_state = "Contain_F"
	anchored = 1
	density = 0
	event_handler_flags = USE_FLUID_ENTER | IMMUNE_SINGULARITY | USE_CANPASS
	var/obj/machinery/field_generator/gen_primary
	var/obj/machinery/field_generator/gen_secondary
	var/datum/light/light

/obj/machinery/containment_field/New(var/obj/machinery/field_generator/A, var/obj/machinery/field_generator/B)
	src.gen_primary = A
	src.gen_secondary = B
	light = new /datum/light/point
	light.set_brightness(0.7)
	light.set_color(0, 0.1, 0.8)
	light.attach(src)
	light.enable()

	..()

/obj/machinery/containment_field/disposing()
	qdel(light)
	light = null
	..()

//we gotta override this anyway, might as well have a bit of fun with it
/obj/machinery/containment_field/ex_act(severity=0,last_touched=0, epicenter = null)
	//throw explosives at the containment field to speed up the singularity breaking out
	//I'm not 100% on whether this won't runtime if a generator isn't there, buuuut
	//(also the generators aren't explosion proof atm so)
	gen_primary?.power = max(0, round(gen_primary.power - severity))
	gen_secondary?.power = max(0, round(gen_secondary.power - severity))

/obj/machinery/containment_field/attack_hand(mob/user as mob)
	return

/obj/machinery/containment_field/process()
	if(isnull(gen_primary)||isnull(gen_secondary))
		qdel(src)
		return

	if(!(gen_primary.active)||!(gen_secondary.active))
		qdel(src)
		return

/obj/machinery/containment_field/proc/shock(mob/user as mob)
	if(isnull(gen_primary) || isnull(gen_secondary))
		qdel(src)
		return
	elecflash(user)

	var/spicy_power = max(gen_primary.power,gen_secondary.power)
	var/prot = 1
	var/shock_damage = 0
	//This not-switch is kinda nonsense but I can't be arsed right now.
	if(spicy_power > 200)
		shock_damage = min(rand(40,80),rand(40,100))*prot
	else if(spicy_power > 120)
		shock_damage = min(rand(30,60),rand(30,90))*prot
	else if(spicy_power > 80)
		shock_damage = min(rand(20,40),rand(20,40))*prot
	else if(spicy_power > 60)
		shock_damage = min(rand(20,30),rand(20,30))*prot
	else
		shock_damage = min(rand(10,20),rand(10,20))*prot

	// Added (Convair880).
	logTheThing("combat", user, null, "was shocked by a containment field at [log_loc(src)].")

	if (user?.bioHolder)
		if (user.bioHolder.HasEffect("resist_electric") == 2)
			//this healing seems busted strong
			var/healing = shock_damage / 3
			user.HealDamage("All", shock_damage, shock_damage)
			user.take_toxin_damage(0 - healing)
			boutput(user, "<span class='notice'>You absorb the electrical shock, healing your body!</span>")
			return
		else if (user.bioHolder.HasEffect("resist_electric") == 1)
			boutput(user, "<span class='notice'>You feel electricity course through you harmlessly!</span>")
			return

	user.TakeDamage(user.hand == 1 ? "l_arm" : "r_arm", 0, shock_damage)
	boutput(user, "<span class='alert'><B>You feel a powerful shock course through your body sending you flying!</B></span>")
	user.unlock_medal("HIGH VOLTAGE", 1)
	if (isliving(user))
		var/mob/living/L = user
		L.Virus_ShockCure(100)
		L.shock_cyberheart(100)
	if(user.getStatusDuration("stunned") < shock_damage * 10)	user.changeStatus("stunned", shock_damage SECONDS)
	if(user.getStatusDuration("weakened") < shock_damage * 10)	user.changeStatus("weakened", shock_damage SECONDS)

	if(user.get_burn_damage() >= 500) //This person has way too much BURN, they've probably been shocked a lot! Let's destroy them!
		user.visible_message("<span style=\"color:red;font-weight:bold;\">[user.name] was disintegrated by the [src.name]!</span>")
		user.elecgib()
		return
	else
		var/throwdir = get_dir(src, get_step_away(src, user)) //was get_step_away(user, src), but that seems backwards
		if (prob(20))
			user.set_loc(get_turf(src)) //why?
			if (prob(50))
				throwdir = turn(throwdir,90)
			else
				throwdir = turn(throwdir,-90)
		var/atom/target = get_edge_target_turf(user, throwdir)
		user.throw_at(target, 200, 4) //200 because that's the old map size?
		user.audible_message("<span class='alert'>[user.name] was shocked by the [src.name]!</span>", "<span class='alert'>You hear a heavy electrical crack</span>")
		/*for(var/mob/M in AIviewers(src))
			if(M == user)	continue
			M.show_message("<span class='alert'>[user.name] was shocked by the [src.name]!</span>", 3, "<span class='alert'>You hear a heavy electrical crack</span>", 2)*/

	src.gen_primary.power -= 3
	src.gen_secondary.power -= 3
	return

/obj/machinery/containment_field/CanPass(atom/movable/O as mob|obj, target as turf)
	if(iscarbon(O) && prob(80))
		shock(O)
	..()


/////////////////////////////////////////// Emitter ///////////////////////////////
/obj/machinery/emitter
	name = "Emitter"
	desc = "Shoots a high power laser when active."
	icon = 'icons/obj/singularity.dmi'
	icon_state = "Emitter"
	anchored = 0
	density = 1
	req_access = list(access_engineering_engine)
	object_flags = CAN_REPROGRAM_ACCESS
	var/active = 0
	var/power = 20
	var/fire_delay = 100
	var/last_shot = 0
	var/shot_number = 0
	var/state = UNWRENCHED
	var/locked = 1
	//Remote control stuff
	var/net_id = null
	var/obj/machinery/power/data_terminal/link = null
	var/datum/projectile/current_projectile = new/datum/projectile/laser/heavy
	mats = 10

/obj/machinery/emitter/New()
	..()
	SPAWN_DBG(0.6 SECONDS)
		if(!src.link && (state == WELDED))
			src.get_link()

		src.net_id = format_net_id("\ref[src]")

/obj/machinery/emitter/get_desc()
	switch(state)
		if (WRENCHED)
			. += "It has been bolted to the floor."
		if (WELDED)
			. += "It has been bolted and welded to the floor."

//Create a link with a data terminal on the same tile, if possible.
/obj/machinery/emitter/proc/get_link()
	if(src.link)
		src.link.master = null
		src.link = null
	var/turf/T = get_turf(src)
	var/obj/machinery/power/data_terminal/test_link = locate() in T
	if(test_link && !DATA_TERMINAL_IS_VALID_MASTER(test_link, test_link.master))
		src.link = test_link
		src.link.master = src

	return

/obj/machinery/emitter/attack_hand(mob/user as mob)
	if(state == WELDED)
		if(!src.locked)
			if(src.active==1)
				if(alert("Turn off the emitter?",,"Yes","No") == "Yes")
					src.active = 0
					icon_state = "Emitter_w"
					boutput(user, "You turn off the emitter.")
					logTheThing("station", user, null, "deactivated active emitter at [log_loc(src)].")
					message_admins("[key_name(user)] deactivated active emitter at [log_loc(src)].")
			else
				if(alert("Turn on the emitter?",,"Yes","No") == "Yes")
					src.active = 1
					icon_state = "Emitter +a"
					boutput(user, "You turn on the emitter.")
					logTheThing("station", user, null, "activated emitter at [log_loc(src)].")
					src.shot_number = 0
					src.fire_delay = 100
					message_admins("[key_name(user)] activated emitter at [log_loc(src)].")
		else
			boutput(user, "The controls are locked!")
	else
		boutput(user, "The emitter needs to be firmly secured to the floor first.")
	src.add_fingerprint(user)
	..()

/obj/machinery/emitter/attack_ai(mob/user as mob)
	var/prev_locked = src.locked
	src.locked = FALSE
	Attackhand(user)
	src.locked = prev_locked

/obj/machinery/emitter/process()
	if(status & (NOPOWER|BROKEN))
		return

	if(!src.state == WELDED)
		src.active = 0
		return

	//TODO? make this an ON_COOLDOWN
	if(((src.last_shot + src.fire_delay) <= world.time) && (src.active == 1))
		src.last_shot = world.time
		if(src.shot_number < 3)
			src.fire_delay = 2
			src.shot_number ++
		else
			src.fire_delay = rand(20,100)
			src.shot_number = 0

		if ((src.dir - 1) & src.dir) // Not cardinal (not power of 2)
			src.dir &= 12 // Cardinalize
		src.visible_message("<span class='alert'><b>[src]</b> fires a bolt of energy!</span>")
		shoot_projectile_DIR(src, current_projectile, dir)

		if(prob(35))
			elecflash(src)
	..()

/obj/machinery/emitter/attackby(obj/item/W, mob/user)
	if (ispryingtool(W))
		if(!anchored)
			src.set_dir(turn(src.dir, -90))
			return
		else
			boutput(user, "The emitter is too firmly secured to be rotated!")
			return
	else if (iswrenchingtool(W))
		if(active)
			boutput(user, "Turn off the emitter first.")
			return

		else if(state != WELDED)
			src.state = !src.state
			playsound(src.loc, "sound/items/Ratchet.ogg", 75, 1)
			boutput(user, state ? "You secure the external reinforcing bolts to the floor." : "You undo the external reinforcing bolts.")
			src.anchored = src.state
			return

	if(isweldingtool(W))
		if(state != UNWRENCHED)
			if(!W:try_weld(user, 1, noisy = 2))
				return
			SETUP_GENERIC_ACTIONBAR(user, src, 2 SECONDS, /obj/machinery/emitter/proc/weld_action,\
			list(user), W.icon, W.icon_state, "[user] finishes using [his_or_her(user)] [W.name] on the emitter.", null)
		if(state == WRENCHED)
			boutput(user, "You start to weld the emitter to the floor.")
			return
		else if(state == WELDED)
			boutput(user, "You start to cut the emitter free from the floor.")
			return

	if (istype(W, /obj/item/device/pda2) && W:ID_card)
		W = W:ID_card
	if (istype(W, /obj/item/card/id))
		if (src.allowed(user))
			src.locked = !src.locked
			boutput(user, "Controls are now [src.locked ? "locked." : "unlocked."]")
			if (!src.locked)
				logTheThing("station", user, null, "unlocked emitter at at [log_loc(src)].")
		else
			boutput(user, "<span class='alert'>Access denied.</span>")

	else
		src.add_fingerprint(user)
		..()
		/*src.add_fingerprint(user)
		boutput(user, "<span class='alert'>You hit the [src.name] with your [W.name]!</span>")
		for(var/mob/M in AIviewers(src))
			if(M == user)	continue
			M.show_message("<span class='alert'>The [src.name] has been hit with the [W.name] by [user.name]!</span>")*/

/obj/machinery/emitter/proc/weld_action(mob/user)
	if(state == WRENCHED)
		state = WELDED
		src.get_link()
		boutput(user, "You weld the emitter to the floor.")
		icon_state = "Emitter_w"
		logTheThing("station", user, null, "welds an emitter to the floor at [log_loc(src)].")
	else if(state == WELDED)
		state = WRENCHED
		if(src.link) //Time to clear our link.
			src.link.master = null
			src.link = null
		boutput(user, "You cut the emitter free from the floor.")
		icon_state = "Emitter"
		logTheThing("station", user, null, "unwelds an emitter from the floor at [log_loc(src)].")

//Send a signal over our link, if possible.
/obj/machinery/emitter/proc/post_status(var/target_id, var/key, var/value, var/key2, var/value2, var/key3, var/value3)
	if(!src.link || !target_id)
		return

	var/datum/signal/signal = get_free_signal()
	signal.source = src
	signal.transmission_method = TRANSMISSION_WIRE
	signal.data[key] = value
	if(key2)
		signal.data[key2] = value2
	if(key3)
		signal.data[key3] = value3

	signal.data["address_1"] = target_id
	signal.data["sender"] = src.net_id

	src.link.post_signal(src, signal)

//What do we do with an incoming command?
/obj/machinery/emitter/receive_signal(datum/signal/signal)
	if(!src.link)
		return
	if(!signal || !src.net_id || signal.encryption)
		return


	if(signal.transmission_method != TRANSMISSION_WIRE) //No radio for us thanks
		return

	var/target = signal.data["sender"]

	//They don't need to target us specifically to ping us.
	//Otherwise, ff they aren't addressing us, ignore them
	if(signal.data["address_1"] != src.net_id)
		if((signal.data["address_1"] == "ping") && signal.data["sender"])
			SPAWN_DBG(0.5 SECONDS) //Send a reply for those curious jerks
				src.post_status(target, "command", "ping_reply", "device", "PNET_ENG_EMITR", "netid", src.net_id)

		return

	var/sigcommand = lowertext(signal.data["command"])
	if(!sigcommand || !signal.data["sender"])
		return

	//Oh okay, time to start up.
	if(sigcommand == "activate" && !src.active)
		src.active = 1
		icon_state = "Emitter +a"
		src.shot_number = 0
		src.fire_delay = 100
	//oh welp shutdown time.
	else if(sigcommand == "deactivate" && src.active)
		src.active = 0
		icon_state = "Emitter"

	return

/////////////////////////////////// Collector array /////////////////////////////////

/obj/item/electronics/frame/collector_array
	name = "radiation collector array frame"
	store_type = /obj/machinery/power/collector_array
	viewstat = 2
	secured = 2
	icon_state = "dbox"

/obj/machinery/power/collector_array
	name = "radiation collector array"
	desc = "A device which uses Hawking Radiation and plasma to produce power."
	icon = 'icons/obj/singularity.dmi'
	icon_state = "ca"
	anchored = 1
	density = 1
	directwired = 1
	var/magic = 0
	var/active = 0
	var/obj/item/tank/plasma/P = null
	var/obj/machinery/power/collector_control/CU = null

/obj/machinery/power/collector_array/New()
	..()
	SPAWN_DBG(0.5 SECONDS)
		updateicon()


/obj/machinery/power/collector_array/proc/updateicon()
	if(magic == 1)
		UpdateOverlays(image('icons/obj/singularity.dmi', "ptank"), "ptank")
	if(P)
		UpdateOverlays(image('icons/obj/singularity.dmi', "ptank"), "ptank")
	else
		UpdateOverlays(null, "ptank")

/obj/machinery/power/collector_array/power_change()
	..()
	if(magic == 1)
		src.active = 1
		icon_state = "ca_active"
	updateicon()

/obj/machinery/power/collector_array/process()
	if(!magic)
		if(P)
			if(P.air_contents.toxins <= 0)
				src.active = 0
				icon_state = "ca_deactive"
				updateicon()
		else if(src.active == 1)
			src.active = 0
			icon_state = "ca_deactive"
			updateicon()
		..()

/obj/machinery/power/collector_array/attack_hand(mob/user as mob)
	src.active = !src.active
	boutput(user, "You turn [active ? "on" : "off"] the collector array.")
	src.icon_state = active ? "ca_active" : "ca_deactive"
	CU?.updatecons()

/obj/machinery/power/collector_array/attackby(obj/item/W, mob/user)
	if (iswrenchingtool(W))
		if(src.active)
			boutput("<span class='alert'>The [src.name] must be turned off first!</span>")
		else
			if (!src.anchored)
				playsound(src.loc, "sound/items/Ratchet.ogg", 75, 1)
				boutput(user, "You secure the [src.name] to the floor.")
				src.anchored = 1
			else
				playsound(src.loc, "sound/items/Ratchet.ogg", 75, 1)
				boutput(user, "You unsecure the [src.name].")
				src.anchored = 0
			logTheThing("station", user, null, "[src.anchored ? "bolts" : "unbolts"] a [src.name] [src.anchored ? "to" : "from"] the floor at [log_loc(src)].") // Ditto (Convair880).
	else if(istype(W, /obj/item/tank/plasma))
		if(src.P)
			boutput(user, "<span class='alert'>There appears to already be a plasma tank loaded!</span>")
			return
		src.P = W
		W.set_loc(src)
		user.u_equip(W)
		CU?.updatecons()
		updateicon()
	else if (ispryingtool(W))
		if(!P)
			return
		var/obj/item/tank/plasma/Z = src.P
		Z.set_loc(get_turf(src))
		Z.layer = initial(Z.layer)
		src.P = null
		CU?.updatecons()
		updateicon()
	else
		src.add_fingerprint(user)
		..()
		/*src.add_fingerprint(user)
		boutput(user, "<span class='alert'>You hit the [src.name] with your [W.name]!</span>")
		for(var/mob/M in AIviewers(src))
			if(M == user)	continue
			M.show_message("<span class='alert'>The [src.name] has been hit with the [W.name] by [user.name]!</span>")*/

////////////////////////// Collector array controller ////////////////////////////

/obj/item/electronics/frame/collector_control
	name = "radiation collector control frame"
	store_type = /obj/machinery/power/collector_control
	viewstat = 2
	secured = 2
	icon_state = "dbox"

/obj/machinery/power/collector_control
	name = "radiation collector control"
	desc = "A device which uses Hawking Radiation and Plasma to produce power."
	icon = 'icons/obj/singularity.dmi'
	icon_state = "cu"
	anchored = 1
	density = 1
	directwired = 1
	///Supposed to make power just whenever, but I think it's broken cause S1 never gets assigned (and nothing uses magic collectors so I don't care)
	var/magic = 0
	var/active = 0
	///For atmos analyser readout
	var/lastpower = 0
	//plasma tanks from the collectors
	var/obj/item/tank/plasma/PN = null
	var/obj/item/tank/plasma/PS = null
	var/obj/item/tank/plasma/PE = null
	var/obj/item/tank/plasma/PW = null
	//collectors
	var/obj/machinery/power/collector_array/CAN = null
	var/obj/machinery/power/collector_array/CAS = null
	var/obj/machinery/power/collector_array/CAE = null
	var/obj/machinery/power/collector_array/CAW = null
	var/obj/machinery/the_singularity/S1 = null

/obj/machinery/power/collector_control/New()
	..()
	START_TRACKING
	SPAWN_DBG(1 SECOND)
		updatecons()

/obj/machinery/power/collector_control/disposing()
	. = ..()
	//There's technically nothing to stop collectors from stealing one another's arrays
	//In fact, I think collectors might be able to share arrays without issue
	if (CAN?.CU == src)
		CAN.CU = null
	CAN = null
	if (CAS?.CU == src)
		CAS.CU = null
	CAS = null
	if (CAE?.CU == src)
		CAE.CU = null
	CAE = null
	if (CAW?.CU == src)
		CAW.CU = null
	CAW = null
	PN = null
	PS = null
	PE = null
	PW = null

	STOP_TRACKING

/obj/machinery/power/collector_control/proc/updatecons()
	if(magic != 1)
		CAN = locate(/obj/machinery/power/collector_array) in get_step(src,NORTH)
		CAS = locate(/obj/machinery/power/collector_array) in get_step(src,SOUTH)
		CAE = locate(/obj/machinery/power/collector_array) in get_step(src,EAST)
		CAW = locate(/obj/machinery/power/collector_array) in get_step(src,WEST)
		for_by_tcl(singu, /obj/machinery/the_singularity)//this loop checks for valid singularities
			if(get_dist(singu,loc)<SINGULARITY_MAX_DIMENSION+2)
				S1 = singu

		//grab the plasma cans from
		if(!isnull(CAN))
			CAN.CU = src
			if(CAN.P)
				PN = CAN.P
		else
			PN = null
		if(!isnull(CAS))
			CAS.CU = src
			if(CAS.P)
				PS = CAS.P
		else
			PS = null
		if(!isnull(CAW))
			CAW.CU = src
			if(CAW.P)
				PW = CAW.P
		else
			PW = null
		if(!isnull(CAE))
			CAE.CU = src
			//DrMelon attempted fix for null.P at singularity.dm /// seemed to have been a tabulation error
			if(CAE.P)
				PE = CAE.P
		else
			PE = null

		if(S1?.disposed)
			S1 = null

	updateicon()

/obj/machinery/power/collector_control/proc/updateicon()

	if(magic != 1)

		if((status & (NOPOWER|BROKEN)) || src.active == 0)
			ClearAllOverlays(TRUE) //I think we want the cache?
			return
		UpdateOverlays(image('icons/obj/singularity.dmi', "cu on"), "power light")
		if((PN)&&(CAN.active))
			UpdateOverlays(image('icons/obj/singularity.dmi', "cu n on"), "north_array_light")
		else
			UpdateOverlays(null, "north_array_light")

		if((PE)&&(CAE.active))
			UpdateOverlays(image('icons/obj/singularity.dmi', "cu e on"), "east_array_light")
		else
			UpdateOverlays(null, "east_array_light")

		if((PS)&&(CAS.active))
			UpdateOverlays(image('icons/obj/singularity.dmi', "cu s on"), "south_array_light")
		else
			UpdateOverlays(null, "south_array_light")

		if((PW)&&(CAW.active))
			UpdateOverlays(image('icons/obj/singularity.dmi', "cu w on"), "west_array_light")
		else
			UpdateOverlays(null, "west_array_light")

		if((CAN && !PN)||(CAS && !PS)||(CAE && !PE)||(CAW && !PW)) //IDK what this was trying to do before but now it's a warning for tankless arrays
			UpdateOverlays(image('icons/obj/singularity.dmi', "cu n error"), "array_error_light")
		else
			UpdateOverlays(null, "array_error_light")

		if(S1)
			UpdateOverlays(image('icons/obj/singularity.dmi', "cu sing"), "singularity_light")
			if(!S1.active)
				UpdateOverlays(image('icons/obj/singularity.dmi', "cu conterr"), "singularity_containment_alarm")
			else
				UpdateOverlays(null, "singularity_containment_alarm")
		else
			UpdateOverlays(null, "singularity_light")
			UpdateOverlays(null, "singularity_containment_alarm")

	else
		//magic collectors just have everything good on I guess?
		UpdateOverlays(image('icons/obj/singularity.dmi', "cu on"), "power light")
		UpdateOverlays(image('icons/obj/singularity.dmi', "cu n on"), "north_array_light")
		UpdateOverlays(image('icons/obj/singularity.dmi', "cu e on"), "east_array_light")
		UpdateOverlays(image('icons/obj/singularity.dmi', "cu s on"), "south_array_light")
		UpdateOverlays(image('icons/obj/singularity.dmi', "cu w on"), "west_array_light")
		UpdateOverlays(image('icons/obj/singularity.dmi', "cu sing"), "singularity_light")

/obj/machinery/power/collector_control/power_change()
	..()
	updateicon()

/obj/machinery/power/collector_control/process(mult)
	if (!ON_COOLDOWN(src, "updatecons", 1 MINUTE))
		updatecons()
	if(magic != 1)
		//no magic? time for the magic of power generation!
		if(src.active == 1)
			var/power_a = 0 //the actual generated wattage. or jouleage?
			var/power_s = 0 //number directly from singularity, not WATTS
			var/power_p = 0 //number from collector plasma, not WATTS

			if(!isnull(S1)) //First, derive some kinda number from the singularity (I haven't tried to understand this formula)
				power_s += S1.energy*max((S1.radius**2),1)/4
			//For each possible collector, grab the current moles of plasma in the tank and then delete some plasma
			//If you don't top up the tank after grabbing it from the dispenser, it will take approximately 466 minutes (assuming no lag) at the current
			//3.2s machine loop for an array to run dry. Even with a 1Hz machine loop it takes over two hours. Realistically we will never run out of plasma.
			if(PN?.air_contents)
				if(CAN.active != 0)
					power_p += PN.air_contents.toxins
					PN.air_contents.toxins -= 0.001 * mult
			if(PS?.air_contents)
				if(CAS.active != 0)
					power_p += PS.air_contents.toxins
					PS.air_contents.toxins -= 0.001 * mult
			if(PE?.air_contents)
				if(CAE.active != 0)
					power_p += PE.air_contents.toxins
					PE.air_contents.toxins -= 0.001 * mult
			if(PW?.air_contents)
				if(CAW.active != 0)
					power_p += PW.air_contents.toxins
					PW.air_contents.toxins -= 0.001 * mult
			//multiply it all together I guess
			power_a = power_p*power_s*50
			src.lastpower = power_a
			add_avail(power_a)
			..()
	else
		var/power_a = 0
		var/power_s = 0
		var/power_p = 0
		if(!isnull(S1))
			power_s += S1.energy*((S1.radius*2+1)**2)/DEFAULT_AREA  //should give the area of the singularity and divide it by the area of a standard singularity(a 5x5)
		power_p += 50
		power_a = power_p*power_s*50
		src.lastpower = power_a
		add_avail(power_a)
		..()

/obj/machinery/power/collector_control/attack_hand(mob/user as mob)
	if (src.anchored)
		if(src.active==1)
			src.lastpower = 0
		src.active = !src.active
		boutput(user, "You turn [active ? "on" : "off"] the collector control.")
		updateicon()
	else
		boutput(user, "<span class='alert'>The [src.name] must be secured first!</span>")

/obj/machinery/power/collector_control/attackby(obj/item/W, mob/user)
	if (iswrenchingtool(W))
		if(src.active)
			boutput(user, "<span class='alert'>The [src.name] must be turned off first!</span>")
		else
			src.anchored = !src.anchored
			boutput(user, "You [src.anchored ? "" : "un"]secure the [src.name] to the floor.")
			playsound(src.loc, "sound/items/Ratchet.ogg", 75, 1)

			logTheThing("station", user, null, "[src.anchored ? "bolts" : "unbolts"] a [src.name] [src.anchored ? "to" : "from"] the floor at [log_loc(src)].") // Ditto (Convair880).

	else if(istype(W, /obj/item/device/analyzer/atmospheric))
		boutput(user, "<span class='notice'>The analyzer detects that [lastpower]W are being produced.</span>")

	else
		src.add_fingerprint(user)
		..()
		/*src.add_fingerprint(user)
		boutput(user, "<span class='alert'>You hit the [src.name] with your [W.name]!</span>")
		for(var/mob/M in AIviewers(src))
			if(M == user)	continue
			M.show_message("<span class='alert'>The [src.name] has been hit with the [W.name] by [user.name]!</span>")*/

///////////////////////////////////////// Singularity bomb /////////////////////////////

// Thing thing had zero logging despite being overhauled recently. I corrected that oversight (Convair880).
/obj/machinery/the_singularitybomb/
	name = "singularity bomb"
	desc = "A WMD that creates a singularity."
	icon = 'icons/obj/machines/power.dmi'
	icon_state = "portgen0"
	anchored = 0
	density = 1
	var/state = UNWRENCHED
	var/timing = 0.0
	var/time = 30
	var/last_tick = null
	var/mob/activator = null // For logging purposes.
	is_syndicate = 1
	mats = 14
	var/bhole = 1

/obj/machinery/the_singularitybomb/attackby(obj/item/W, mob/user)
	src.add_fingerprint(user)

	if (iswrenchingtool(W))

		if(state == UNWRENCHED)
			state = WRENCHED
			playsound(src.loc, "sound/items/Ratchet.ogg", 75, 1)
			boutput(user, "You secure the external reinforcing bolts to the floor.")
			src.anchored = 1
			return

		else if(state == WRENCHED)
			state = UNWRENCHED
			playsound(src.loc, "sound/items/Ratchet.ogg", 75, 1)
			boutput(user, "You undo the external reinforcing bolts.")
			src.anchored = 0
			return

	if(isweldingtool(W))
		if(timing)
			boutput(user, "Stop the countdown first.")
			return

		var/turf/T = user.loc


		if(state == WRENCHED)
			if(!W:try_weld(user, 1, noisy = 2))
				return
			boutput(user, "You start to weld the bomb to the floor.")
			sleep(5 SECONDS)

			logTheThing("station", user, null, "welds a [src.name] to the floor at [log_loc(src)].") // Like here (Convair880).

			if ((user.loc == T && user.equipped() == W))
				state = WELDED
				icon_state = "portgen1"
				boutput(user, "You weld the bomb to the floor.")
			else if((isrobot(user) && (user.loc == T)))
				state = WELDED
				icon_state = "portgen1"
				boutput(user, "You weld the bomb to the floor.")
			return

		if(state == WELDED)
			if(!W:try_weld(user, 1, noisy = 2))
				return
			boutput(user, "You start to cut the bomb free from the floor.")
			sleep(5 SECONDS)

			logTheThing("station", user, null, "cuts a [src.name] from the floor at [log_loc(src)].") // Hmm (Convair880).
			if (src.activator)
				src.activator = null

			if ((user.loc == T && user.equipped() == W))
				state = WRENCHED
				icon_state = "portgen0"
				boutput(user, "You cut the bomb free from the floor.")
			else if((isrobot(user) && (user.loc == T)))
				state = WRENCHED
				icon_state = "portgen0"
				boutput(user, "You cut the bomb free from the floor.")
			return

	else
		boutput(user, "<span class='alert'>You hit the [src.name] with your [W.name]!</span>")
		for(var/mob/M in AIviewers(src))
			if(M == user)	continue
			M.show_message("<span class='alert'>The [src.name] has been hit with the [W.name] by [user.name]!</span>")

/obj/machinery/the_singularitybomb/Topic(href, href_list)
	..()
	if (usr.stat || usr.restrained() || usr.lying)
		return
	if ((in_interact_range(src, usr) && istype(src.loc, /turf)))
		src.add_dialog(usr)
		switch(href_list["action"]) //Yeah, this is weirdly set up. Planning to expand it later.
			if("trigger")
				switch(href_list["spec"])
					if("prime")
						if(!timing)
							src.timing = 1
							processing_items |= src
							src.icon_state = "portgen2"

							// And here (Convair880).
							logTheThing("bombing", usr, null, "activated [src.name] ([src.time] seconds) at [log_loc(src)].")
							message_admins("[key_name(usr)] activated [src.name] ([src.time] seconds) at [log_loc(src)].")
							if (ismob(usr))
								src.activator = usr

						else
							boutput(usr, "<span class='alert'>\The [src] is already primed!</span>")
					if("abort")
						if(timing)
							src.timing = 0
							src.icon_state = "portgen1"

							// And here (Convair880).
							logTheThing("bombing", usr, src.activator, "deactivated [src.name][src.activator ? " (primed by [constructTarget(src.activator,"bombing")]" : ""] at [log_loc(src)].")
							message_admins("[key_name(usr)] deactivated [src.name][src.activator ? " (primed by [key_name(src.activator)])" : ""] at [log_loc(src)].")

						else
							boutput(usr, "<span class='alert'>\The [src] is already deactivated!</span>")
			if("timer")
				if(!timing)
					var/tp = text2num(href_list["tp"])
					src.time += tp
					src.time = min(max(round(src.time), 30), 600)
				else
					boutput(usr, "<span class='alert'>You can't change the time while the timer is engaged!</span>")
		/*
		if (href_list["time"])
			src.timing = text2num(href_list["time"])
			if(timing) processing_items |= src
				src.icon_state = "portgen2"
			else
				src.icon_state = "portgen1"

		if (href_list["tp"])
			var/tp = text2num(href_list["tp"])
			src.time += tp
			src.time = min(max(round(src.time), 60), 600)

		if (href_list["close"])
			usr.Browse(null, "window=timer")
			usr.machine = null
			return
		*/
		if (ismob(src.loc))
			attack_hand(src.loc)
		else
			src.updateUsrDialog()

		src.add_fingerprint(usr)
	else
		usr.Browse(null, "window=timer")
		return
	return

/obj/machinery/the_singularitybomb/attack_ai(mob/user as mob)
	return

/obj/machinery/the_singularitybomb/attack_hand(mob/user as mob)
	..()
	if(src.state != 3)
		boutput(user, "The bomb needs to be firmly secured to the floor first.")
		return
	if (user.stat || user.restrained() || user.lying)
		return
	if ((get_dist(src, user) <= 1 && istype(src.loc, /turf)))
		src.add_dialog(user)
		/*
		var/dat = text("<TT><B>Timing Unit</B><br>[] []:[]<br><A href='byond://?src=\ref[];tp=-30'>-</A> <A href='byond://?src=\ref[];tp=-1'>-</A> <A href='byond://?src=\ref[];tp=1'>+</A> <A href='byond://?src=\ref[];tp=30'>+</A><br></TT>", (src.timing ? text("<A href='byond://?src=\ref[];time=0'>Timing</A>", src) : text("<A href='byond://?src=\ref[];time=1'>Not Timing</A>", src)), minute, second, src, src, src, src)
		dat += "<BR><BR><A href='byond://?src=\ref[src];close=1'>Close</A>"
		*/
		user.Browse(src.get_interface(), "window=timer")
		onclose(user, "timer")
	else
		user.Browse(null, "window=timer")
		src.remove_dialog(user)

	src.add_fingerprint(user)
	return

/obj/machinery/the_singularitybomb/proc/time()
	var/turf/T = get_turf(src.loc)
	for(var/mob/O in hearers(src.loc, null))
		O.show_message("[bicon(src)] *beep* *beep*", 3, "*beep* *beep*", 2)


	playsound(T, 'sound/effects/creaking_metal1.ogg', 100, 0, 5, 0.5)
	for (var/mob/M in range(7,T))
		boutput(M, "<span class='bold alert'>The contaiment field on \the [src] begins destabilizing!</span>")
		shake_camera(M, 5, 16)
	for (var/turf/TF in range(4,T))
		animate_shake(TF,5,1 * get_dist(TF,T),1 * get_dist(TF,T))
	particleMaster.SpawnSystem(new /datum/particleSystem/bhole_warning(T))

	SPAWN_DBG(3 SECONDS)
		for (var/mob/M in range(7,T))
			boutput(M, "<span class='bold alert'>The containment field on \the [src] fails completely!</span>")
			shake_camera(M, 5, 16)

		// And most importantly here (Convair880)!
		logTheThing("bombing", src.activator, null, "A [src.name] (primed by [src.activator ? "[src.activator]" : "*unknown*"]) detonates at [log_loc(src)].")
		message_admins("A [src.name] (primed by [src.activator ? "[key_name(src.activator)]" : "*unknown*"]) detonates at [log_loc(src)].")

		playsound(T, 'sound/machines/satcrash.ogg', 100, 0, 5, 0.5)
		if (bhole)
			var/obj/B = new /obj/bhole(get_turf(src.loc), rand(1600, 2400), rand(75, 100))
			B.name = "gravitational singularity"
			B.color = "#FF00FF"
		else
			new /obj/machinery/the_singularity(get_turf(src.loc), rand(1600, 2400))

	return

/obj/machinery/the_singularitybomb/process()
	if (src.timing)
		if (src.time > 0)
			if (!last_tick) last_tick = world.time
			var/passed_time = round(max(round(world.time - last_tick),10) / 10)
			src.time = max(0, src.time - passed_time)
			last_tick = world.time
		else
			time()
			src.time = 0
			src.timing = 0
			last_tick = 0

		if (ismob(src.loc))
			attack_hand(src.loc)
		else
			for(var/mob/M in viewers(1, src))
				if (M.using_dialog_of(src))
					src.Attackhand(M)

	return

/obj/machinery/the_singularitybomb/proc/get_time()
	if(src.time < 0)
		return "DO:OM"
	else
		var/seconds = src.time % 60
		var/minutes = (src.time - seconds) / 60
		var/flick_seperator = (seconds % 2 == 0)  || !src.timing
		minutes = minutes < 10 ? "0[minutes]" : "[minutes]"
		seconds = seconds < 10 ? "0[seconds]" : "[seconds]"

		return "[minutes][flick_seperator ? ":" : " "][seconds]"

/obj/machinery/the_singularitybomb/proc/get_interface()
	return {"<html>
				<head>
					<style>
						body {
							font-family:verdana,sans-serif;

						}
						a {
							text-decoration:none;
						}
						.top_level {
							display: inline;
							border: 2px solid #333;
							padding:10px;
						}
						.timing_div {
							overflow:auto;
							padding:10px;
						}
						.timer {
							display:table-cell;
							color:#0A0;
							font-weight:bold;
							text-align:src.get_center();
							vertical-align:middle;
							border:3px solid #222;
							background-color:#111;
							padding:3px;
						}
						.timer.active {
							color:#F00;
						}
						.button {
							display:table-cell;
							color:#0A0;
							font-weight:bold;
							text-align:src.get_center();
							vertical-align:middle;
							border:3px solid #222;
							background-color:#111;
							padding:3px;
						}
						.button.timer_b {
							width:50px;
						}
						/*
						.button:hover {
							background-color:#222;
							border:3px solid #333;
						}
						*/
						#abort {
							color:#000;
							background-color:#A00;
						}
						/*
						#abort:hover {
							background-color:#600;
						}
						*/
						#prime {
							color:#000;
							background-color:#0A0;
						}
						/*
						#prime:hover {
							background-color:#060;
						}
						*/

						.timer_table {
							text-align:src.get_center();
							vertical-align:middle;
							width:200px;
						}
					</style>

				</head>
				<body bgcolor=#555>
					<div class="timing_div top_level">
						<table class="timer_table">
							<tr>
								<td class="timer[src.timing ? " active" : ""]" colspan=4>[src.get_time()]</td>
							</tr>

							<tr>
								<td>
									<a href="byond://?src=\ref[src];action=timer;tp=-30">
										<div class="button timer_b">
											--
										</div>
									</a>
								</td>
								<td>
									<a href="byond://?src=\ref[src];action=timer;tp=-1">
										<div class="button timer_b">
											-
										</div>
									</a>
								</td>
								<td>
									<a href="byond://?src=\ref[src];action=timer;tp=1">
										<div class="button timer_b">
											+
										</div>
									</a>
								</td>
								<td>
									<a href="byond://?src=\ref[src];action=timer;tp=30">
										<div class="button timer_b">
											++
										</div>
									</a>
								</td>
							</tr>
							<tr>
								<td colspan=2>
									<a href="byond://?src=\ref[src];action=trigger;spec=abort">
										<div class="button" id="abort">
											Abort
										</div>
									</a>
								</td>
								<td colspan=2>
									<a href="byond://?src=\ref[src];action=trigger;spec=prime">
										<div class="button" id="prime">
											Prime
										</div>
									</a>
								</td>
							</tr>
						</table>
					</div>
				</body>
			</html>"}
