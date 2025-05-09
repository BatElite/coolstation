/turf/wall
	name = "wall"
	desc = "Looks like a regular wall."
	icon = 'icons/turf/walls.dmi'
#ifndef IN_MAP_EDITOR // display disposal pipes etc. above walls in map editors
	plane = PLANE_WALL
#else
	plane = PLANE_FLOOR
#endif
	opacity = 1
	density = 1
	gas_impermeable = 1
	pathable = 1
	flags = ALWAYS_SOLID_FLUID
	text = "<font color=#aaa>#"

	var/health = 100
	var/list/proj_impacts = list()
	var/list/forensic_impacts = list()
	var/image/proj_image = null
	var/last_proj_update_time = null

	color // lighter toned walls for easier use of color var
		icon = 'icons/turf/walls_auto_color.dmi'

	New()
		..()
		var/obj/plan_marker/wall/P = locate() in src
		if (P)
			P.check()

		//for fluids
		if (src.active_liquid && src.active_liquid.group)
			src.active_liquid.group.displace(src.active_liquid)

	ReplaceWithFloor()
		. = ..()
		if (map_currently_underwater)
			var/turf/space/fluid/n = get_step(src,NORTH)
			var/turf/space/fluid/s = get_step(src,SOUTH)
			var/turf/space/fluid/e = get_step(src,EAST)
			var/turf/space/fluid/w = get_step(src,WEST)
			if(istype(n))
				n.tilenotify(src)
			if(istype(s))
				s.tilenotify(src)
			if(istype(e))
				e.tilenotify(src)
			if(istype(w))
				w.tilenotify(src)

	get_desc()
		if (islist(src.proj_impacts) && length(src.proj_impacts))
			var/shots_taken = 0
			for (var/i in src.proj_impacts)
				shots_taken ++
			. += "<br>[src] has [shots_taken] hole[s_es(shots_taken)] in it."

	onMaterialChanged()
		..()
		if(istype(src.material))
			health = material.hasProperty("density") ? round(material.getProperty("density") * 2.5) : health
			if(src.material.material_flags & MATERIAL_CRYSTAL)
				health /= 2
		return

	thermal_conductivity = WALL_HEAT_TRANSFER_COEFFICIENT
	heat_capacity = 312500 //a little over 5 cm thick , 312500 for 1 m by 2.5 m by 0.25 m steel wall
	explosion_resistance = 2

	proc/update_projectile_image(var/update_time)
		if (src.proj_impacts.len > 10)
			return
		if (src.last_proj_update_time && (src.last_proj_update_time + 1) < ticker.round_elapsed_ticks)
			return
		if (!src.proj_image)
			src.proj_image = image('icons/obj/projectiles.dmi', "blank")
		//src.overlays -= src.proj_image
		src.proj_image.overlays = null
		for (var/image/i in src.proj_impacts)
			src.proj_image.overlays += i
		src.UpdateOverlays(src.proj_image, "projectiles")
		//src.overlays += src.proj_image

/turf/wall/New()
	..()
	if(!ticker && istype(src.loc, /area/station/maintenance) && prob(7))
		make_cleanable( /obj/decal/cleanable/fungus,src)

// Made this a proc to avoid duplicate code (Convair880).
/turf/wall/proc/attach_light_fixture_parts(var/mob/user, var/obj/item/W, var/instantly)
	if (!user || !istype(W, /obj/item/light_parts/) || istype(W, /obj/item/light_parts/floor))	//hack, no floor lights on walls
		return

	// the wall is the target turf, the source is the turf where the user is standing
	var/obj/item/light_parts/parts = W
	var/turf/target = src
	var/turf/source = get_turf(user)

	// need to find the direction to orient the new light
	var/dir = 0

	// find the direction from the mob to the target wall
	for (var/d in cardinal)
		if (get_step(source,d) == target)
			dir = d
			break

	// if no direction was found, fail. need to be standing cardinal to the wall to put the fixture up
	if (!dir)
		return //..(parts, user)

	if(!instantly)
		playsound(src, "sound/items/Screwdriver.ogg", 50, 1)
		boutput(user, "You begin to attach the light fixture to [src]...")

		if (!do_after(user, 4 SECONDS))
			user.show_text("You were interrupted!", "red")
			return

	if (!parts || parts.disposed) //ZeWaka: Fix for null.fixture_type
		return

	// if they didn't move, put it up
	boutput(user, "You attach the light fixture to [src].")

	var/obj/machinery/light/newlight = new parts.fixture_type(source)
	newlight.set_dir(dir)
	newlight.icon_state = parts.installed_icon_state
	newlight.base_state = parts.installed_base_state
	newlight.fitting = parts.fitting
	newlight.status = 1 // LIGHT_EMPTY

	newlight.add_fingerprint(user)
	src.add_fingerprint(user)

	user.u_equip(parts)
	qdel(parts)
	return

/turf/wall/proc/take_hit(var/obj/item/I)
	if(src.material)
		if(I.material)
			if((I.material.getProperty("hard") ? I.material.getProperty("hard") : (I.throwing ? I.throwforce : I.force)) >= (src.material.getProperty("hard") ? src.material.getProperty("hard") : 60))
				src.health -= round((I.throwing ? I.throwforce : I.force) / 10)
				src.visible_message("<span class='alert'>[usr ? usr : "Someone"] hits [src] with [I]!</span>", "<span class='alert'>You hit [src] with [I]!</span>")
			else
				src.visible_message("<span class='alert'>[usr ? usr : "Someone"] uselessly hits [src] with [I].</span>", "<span class='alert'>You hit [src] with [I] but it takes no damage.</span>")
		else
			if((I.throwing ? I.throwforce : I.force) >= 80)
				src.health -= round((I.throwing ? I.throwforce : I.force) / 10)
				src.visible_message("<span class='alert'>[usr ? usr : "Someone"] hits [src] with [I]!</span>", "<span class='alert'>You hit [src] with [I]!</span>")
			else
				src.visible_message("<span class='alert'>[usr ? usr : "Someone"] uselessly hits [src] with [I].</span>", "<span class='alert'>You hit [src] with [I] but it takes no damage.</span>")
	else
		if(I.material)
			if((I.material.getProperty("hard") ? I.material.getProperty("hard") : (I.throwing ? I.throwforce : I.force)) >= 60)
				src.health -= round((I.throwing ? I.throwforce : I.force) / 10)
				src.visible_message("<span class='alert'>[usr ? usr : "Someone"] hits [src] with [I]!</span>", "<span class='alert'>You hit [src] with [I]!</span>")
			else
				src.visible_message("<span class='alert'>[usr ? usr : "Someone"] uselessly hits [src] with [I].</span>", "<span class='alert'>You hit [src] with [I] but it takes no damage.</span>")
		else
			if((I.throwing ? I.throwforce : I.force) >= 80)
				src.health -= round((I.throwing ? I.throwforce : I.force) / 10)
				src.visible_message("<span class='alert'>[usr ? usr : "Someone"] hits [src] with [I]!</span>", "<span class='alert'>You hit [src] with [I]!</span>")
			else
				src.visible_message("<span class='alert'>[usr ? usr : "Someone"] uselessly hits [src] with [I].</span>", "<span class='alert'>You hit [src] with [I] but it takes no damage.</span>")

	if(health <= 0)
		src.visible_message("<span class='alert'>[usr ? usr : "Someone"] destroys [src]!</span>", "<span class='alert'>You destroy [src]!</span>")
		dismantle_wall(1)
	return

/turf/wall/proc/dismantle_wall(devastated=0, keep_material = 1)
	if (istype(src, /turf/wall/r_wall) || istype(src, /turf/wall/auto/reinforced))
		if (!devastated)
			playsound(src, "sound/items/Welder.ogg", 100, 1)
			var/atom/A = new /obj/structure/girder/reinforced(src)
			var/obj/item/sheet/B = new /obj/item/sheet( src )
			if (src.material)
				A.setMaterial(src.material)
				B.setMaterial(src.material)
				B.set_reinforcement(src.material)
			else
				var/datum/material/M = getMaterial("steel")
				A.setMaterial(M)
				B.setMaterial(M)
				B.set_reinforcement(M)
		else
			if (prob(50)) // pardon all these nested probabilities, just trying to vary the damage appearance a bit
				var/atom/A = new /obj/structure/girder/reinforced(src)
				if (src.material)
					A.setMaterial(src.material)
				else
					A.setMaterial(getMaterial("steel"))

				if (prob(50))
					var/atom/movable/B = new /obj/item/raw_material/scrap_metal()
					B.set_loc(src)
					if (src.material)
						B.setMaterial(src.material)
					else
						B.setMaterial(getMaterial("steel"))

			else if( prob(50))
				var/atom/A = new /obj/structure/girder(src)
				if (src.material)
					A.setMaterial(src.material)
				else
					A.setMaterial(getMaterial("steel"))
	if (istype(src, /turf/wall/s_wall))
		var/atom/movable/B = new /obj/item/raw_material/scrap_metal()
		B.set_loc(src)
		if (src.material)
			B.setMaterial(src.material)
		else
			B.setMaterial(getMaterial("steel"))
	else
		if (!devastated)
			playsound(src, "sound/items/Welder.ogg", 100, 1)
			var/atom/A = new /obj/structure/girder(src)
			var/atom/B = new /obj/item/sheet( src )
			var/atom/C = new /obj/item/sheet( src )
			if (src.material)
				A.setMaterial(src.material)
				B.setMaterial(src.material)
				C.setMaterial(src.material)
			else
				var/datum/material/M = getMaterial("steel")
				A.setMaterial(M)
				B.setMaterial(M)
				C.setMaterial(M)
		else
			if (prob(50))
				var/atom/A = new /obj/structure/girder/displaced(src)
				if (src.material)
					A.setMaterial(src.material)
				else
					A.setMaterial(getMaterial("steel"))

			else if (prob(50))
				var/atom/B = new /obj/structure/girder(src)

				if (src.material)
					B.setMaterial(src.material)
				else
					B.setMaterial(getMaterial("steel"))

				if (prob(50))
					var/atom/movable/C = new /obj/item/raw_material/scrap_metal()
					C.set_loc(src)
					if (src.material)
						C.setMaterial(src.material)
					else
						C.setMaterial(getMaterial("steel"))

	var/atom/D = ReplaceWithFloor()
	if (src.material && keep_material)
		D.setMaterial(src.material)
	else
		D.setMaterial(getMaterial("steel"))

/turf/wall/burn_down()
	src.ReplaceWithFloor()

/turf/wall/ex_act(severity)
	if (!isconstructionturf(src)) return
	switch(severity)
		if(OLD_EX_SEVERITY_1)
			src.ReplaceWithSpace()
			return
		if(OLD_EX_SEVERITY_2)
			if (prob(66))
				dismantle_wall(1)
		if(OLD_EX_SEVERITY_3)
			if (prob(40))
				dismantle_wall(1)
		else
	return

/turf/wall/blob_act(var/power)
	if(prob(power))
		dismantle_wall(1)

/turf/wall/attack_hand(mob/user as mob)
	if (user.is_hulk())
		if (prob(70))
			playsound(user.loc, "sound/impact_sounds/Generic_Hit_Heavy_1.ogg", 50, 1)
			if (src.material)
				src.material.triggerOnAttacked(src, user, user, src)
			for (var/mob/N in AIviewers(usr, null))
				if (N.client)
					shake_camera(N, 4, 8, 0.5)
		if (prob(40) && isconstructionturf(src))
			boutput(user, text("<span class='notice'>You smash through the [src.name].</span>"))
			logTheThing("combat", usr, null, "uses hulk to smash a wall at [log_loc(src)].")
			dismantle_wall(1)
			return
		else
			boutput(user, text("<span class='notice'>You punch the [src.name].</span>"))
			return

	if(src.material)
		var/fail = 0
		if(src.material.hasProperty("stability") && src.material.getProperty("stability") < 15) fail = 1
		if(src.material.quality < 0) if(prob(abs(src.material.quality))) fail = 1

		if(fail)
			user.visible_message("<span class='alert'>You punch the wall and it [getMatFailString(src.material.material_flags)]!</span>","<span class='alert'>[user] punches the wall and it [getMatFailString(src.material.material_flags)]!</span>")
			playsound(src, "sound/impact_sounds/Generic_Stab_1.ogg", 25, 1)
			dismantle_wall(1)
			return

	boutput(user, "<span class='notice'>You hit the [src.name] but nothing happens!</span>")
	playsound(src, "sound/impact_sounds/Generic_Stab_1.ogg", 25, 1)
	interact_particle(user,src,TRUE)
	return

//shitty little thing because we can't use a generic actionbar for wall murder atm
/datum/action/bar/wall_decon_crud
	id = "wall_welder_decon"
	interrupt_flags = INTERRUPT_MOVE | INTERRUPT_STUNNED
	duration = 10 SECONDS

	var/turf/wall/the_wall
	var/obj/item/the_tool
	var/interaction = WALL_REMOVERERODS

	New(var/obj/table/wall, var/obj/item/tool)
		..()
		if (wall)
			the_wall = wall
			//not a big fan of this actionbar implementation but this lets us mess with multiple walls at once again
			place_to_put_bar = wall
		if (usr)
			owner = usr
		if (tool)
			the_tool = tool
		if (ishuman(owner))
			var/mob/living/carbon/human/H = owner
			if (H.traitHolder.hasTrait("training_engineer"))
				duration = round(duration / 2)

	onUpdate()
		..()
		if (the_wall == null || the_tool == null || owner == null || get_dist(owner, the_wall) > 1)
			interrupt(INTERRUPT_ALWAYS)
			return
		var/mob/source = owner
		if (istype(source) && (the_tool != source.equipped()))
			interrupt(INTERRUPT_ALWAYS)
			return

	onEnd()
		..()
		the_wall.weld_action(the_tool, owner)
		owner.visible_message("<span class='notice'>[owner] finishes disassembling the outer wall plating.</span>")

/turf/wall/attackby(obj/item/W as obj, mob/user as mob, params)
	if(istype(W, /obj/item/spray_paint) || istype(W, /obj/item/gang_flyer))
		return

	if (istype(W, /obj/item/pen))
		var/obj/item/pen/P = W
		P.write_on_turf(src, user, params)
		return

	else if (istype(W, /obj/item/light_parts))
		src.attach_light_fixture_parts(user, W) // Made this a proc to avoid duplicate code (Convair880).
		return

	else if (isweldingtool(W) && isconstructionturf(src))
		var/turf/T = user.loc
		if (!( istype(T, /turf) ))
			return

		//cmon man let's not burn a fucken quarter of a welder's fuel *per wall*
		if(!W:try_weld(user, 2, burn_eyes = 1))
			return

		boutput(user, "<span class='notice'>Now disassembling the outer wall plating.</span>")
		actions.start(new /datum/action/bar/wall_decon_crud(src, W), user)
		/*SETUP_GENERIC_ACTIONBAR(user, src, 10 SECONDS, /turf/wall/proc/weld_action,\
			list(W, user), W.icon, W.icon_state, "[user] finishes disassembling the outer wall plating.", null)*/

	else if (istype(W, /obj/item/breaching_hammer/sledgehammer))
		src.weld_action(W, user)
		return

//Spooky halloween key
	else if(istype(W,/obj/item/device/key/haunted))
		//Okay, create a temporary false wall.
		if(W:last_use && ((W:last_use + 300) >= world.time))
			boutput(user, "<span class='alert'>The key won't fit in all the way!</span>")
			return
		user.visible_message("<span class='alert'>[user] inserts [W] into [src]!</span>","<span class='alert'>The key seems to phase into the wall.</span>")
		W:last_use = world.time
		blink(src)
		new /turf/wall/false_wall/temp(src)
		return

//grabsmash
	else if (istype(W, /obj/item/grab/))
		var/obj/item/grab/G = W
		if  (!grab_smash(G, user))
			return ..(W, user)
		else return

	else if (istype(W, /obj/item/rcd))
		return //STFU with your "uselessly hits wall" messages ffs

	else
		if(src.material)
			src.material.triggerOnHit(src, W, user, 1)
			var/fail = 0
			if(src.material.hasProperty("stability") && src.material.getProperty("stability") < 15) fail = 1
			if(src.material.quality < 0) if(prob(abs(src.material.quality))) fail = 1

			if(fail)
				user.visible_message("<span class='alert'>You hit the wall and it [getMatFailString(src.material.material_flags)]!</span>","<span class='alert'>[user] hits the wall and it [getMatFailString(src.material.material_flags)]!</span>")
				playsound(src, "sound/impact_sounds/Generic_Stab_1.ogg", 25, 1)
				del(src)
				return

		src.take_hit(W)
		//return attack_hand(user)

/turf/wall/proc/weld_action(obj/item/W, mob/user)
	logTheThing("station", user, null, "deconstructed a wall ([src.name]) using \a [W] at [get_area(user)] ([showCoords(user.x, user.y, user.z)])")
	dismantle_wall()

/turf/wall/r_wall
	name = "reinforced wall"
	desc = "Looks a lot tougher than a regular wall."
	icon = 'icons/turf/walls.dmi'
	icon_state = "r_wall"
	opacity = 1
	density = 1
	pathable = 0
	var/d_state = 0
	explosion_resistance = 7
	health = 300

	color
		icon = 'icons/turf/walls_auto_color.dmi'

	onMaterialChanged()
		..()
		if(istype(src.material))
			health = material.hasProperty("density") ? round(material.getProperty("density") * 4.5) : health
			if(src.material.material_flags & MATERIAL_CRYSTAL)
				health /= 2
		return

/turf/wall/r_wall/attackby(obj/item/W as obj, mob/user as mob, params)
	if(istype(W, /obj/item/spray_paint) || istype(W, /obj/item/gang_flyer))
		return

	if (istype(W, /obj/item/pen))
		var/obj/item/pen/P = W
		P.write_on_turf(src, user, params)
		return

	else if (istype(W, /obj/item/light_parts))
		src.attach_light_fixture_parts(user, W) // Made this a proc to avoid duplicate code (Convair880).
		return

	else if (isconstructionturf(src))

		if (isweldingtool(W))
			var/turf/T = user.loc
			if (!( istype(T, /turf) ))
				return

			if (src.d_state == 2)
				if(!W:try_weld(user,1,-1,1,1))
					return
				boutput(user, "<span class='notice'>Slicing metal cover.</span>")
				sleep(6 SECONDS)
				if ((user.loc == T && user.equipped() == W))
					src.d_state = 3
					boutput(user, "<span class='notice'>You removed the metal cover.</span>")
				else if((isrobot(user) && (user.loc == T)))
					src.d_state = 3
					boutput(user, "<span class='notice'>You removed the metal cover.</span>")

			else if (src.d_state == 5)
				if(!W:try_weld(user,1,-1,1,1))
					return
				boutput(user, "<span class='notice'>Removing support rods.</span>")
				sleep(10 SECONDS)
				if ((user.loc == T && user.equipped() == W))
					src.d_state = 6
					var/atom/A = new /obj/item/rods( src )
					if (src.material)
						A.setMaterial(src.material)
					else
						A.setMaterial(getMaterial("steel"))
					boutput(user, "<span class='notice'>You removed the support rods.</span>")
				else if((isrobot(user) && (user.loc == T)))
					src.d_state = 6
					var/atom/A = new /obj/item/rods( src )
					if (src.material)
						A.setMaterial(src.material)
					else
						A.setMaterial(getMaterial("steel"))
					boutput(user, "<span class='notice'>You removed the support rods.</span>")

		else if (iswrenchingtool(W))
			if (src.d_state == 4)
				var/turf/T = user.loc
				boutput(user, "<span class='notice'>Detaching support rods.</span>")
				playsound(src, "sound/items/Ratchet.ogg", 100, 1)
				sleep(4 SECONDS)
				if ((user.loc == T && user.equipped() == W))
					src.d_state = 5
					boutput(user, "<span class='notice'>You detach the support rods.</span>")
				else if((isrobot(user) && (user.loc == T)))
					src.d_state = 5
					boutput(user, "<span class='notice'>You detach the support rods.</span>")

		else if (issnippingtool(W))
			if (src.d_state == 0)
				playsound(src, "sound/items/Wirecutter.ogg", 100, 1)
				src.d_state = 1
				var/atom/A = new /obj/item/rods( src )
				if (src.material)
					A.setMaterial(src.material)
				else
					A.setMaterial(getMaterial("steel"))

		else if (isscrewingtool(W))
			if (src.d_state == 1)
				var/turf/T = user.loc
				playsound(src, "sound/items/Screwdriver.ogg", 100, 1)
				boutput(user, "<span class='notice'>Removing support lines.</span>")
				sleep(4 SECONDS)
				if ((user.loc == T && user.equipped() == W))
					src.d_state = 2
					boutput(user, "<span class='notice'>You removed the support lines.</span>")
				else if((isrobot(user) && (user.loc == T)))
					src.d_state = 2
					boutput(user, "<span class='notice'>You removed the support lines.</span>")

		else if (ispryingtool(W))
			if (src.d_state == 3)
				var/turf/T = user.loc
				boutput(user, "<span class='notice'>Prying cover off.</span>")
				playsound(src, "sound/items/Crowbar.ogg", 100, 1)
				sleep(10 SECONDS)
				if ((user.loc == T && user.equipped() == W))
					src.d_state = 4
					boutput(user, "<span class='notice'>You removed the cover.</span>")
				else if((isrobot(user) && (user.loc == T)))
					src.d_state = 4
					boutput(user, "<span class='notice'>You removed the cover.</span>")
			else if (src.d_state == 6)
				var/turf/T = user.loc
				boutput(user, "<span class='notice'>Prying outer sheath off.</span>")
				playsound(src, "sound/items/Crowbar.ogg", 100, 1)
				sleep(10 SECONDS)
				if ((user.loc == T && user.equipped() == W))
					boutput(user, "<span class='notice'>You removed the outer sheath.</span>")
					dismantle_wall()
					logTheThing("station", user, null, "dismantles a reinforced wall at [log_loc(user)].")
					return
				else if((isrobot(user) && (user.loc == T)))
					boutput(user, "<span class='notice'>You removed the outer sheath.</span>")
					dismantle_wall()
					logTheThing("station", user, null, "dismantles a reinforced wall at [log_loc(user)].")
					return

		//More spooky halloween key
		else if(istype(W,/obj/item/device/key/haunted))
			//Okay, create a temporary false wall.
			if(W:last_use && ((W:last_use + 300) >= world.time))
				boutput(user, "<span class='alert'>The key won't fit in all the way!</span>")
				return
			user.visible_message("<span class='alert'>[user] inserts [W] into [src]!</span>","<span class='alert'>The key seems to phase into the wall.</span>")
			W:last_use = world.time
			blink(src)
			var/turf/wall/false_wall/temp/fakewall = new /turf/wall/false_wall/temp(src)
			fakewall.was_rwall = 1
			return

		else if ((istype(W, /obj/item/sheet)) && (src.d_state))
			var/obj/item/sheet/S = W
			boutput(user, "<span class='notice'>Repairing wall.</span>")
			if (do_after(user, 10 SECONDS) && S.change_stack_amount(-1))
				src.d_state = 0
				src.icon_state = initial(src.icon_state)
				if(S.material)
					src.setMaterial(S.material)
				else
					src.setMaterial(getMaterial("steel"))
				boutput(user, "<span class='notice'>You repaired the wall.</span>")

//grabsmash
	else if (istype(W, /obj/item/grab/))
		var/obj/item/grab/G = W
		if  (!grab_smash(G, user))
			return ..(W, user)
		else return

	else if (istype(W, /obj/item/rcd))
		return //STFU with your "uselessly hits wall" messages ffs

	if(istype(src, /turf/wall/r_wall) && src.d_state > 0)
		src.icon_state = "r_wall-[d_state]"

	if(src.material)
		src.material.triggerOnHit(src, W, user, 1)
		var/fail = 0
		if(src.material.hasProperty("stability") && src.material.getProperty("stability") < 15) fail = 1
		if(src.material.quality < 0) if(prob(abs(src.material.quality))) fail = 1

		if(fail)
			user.visible_message("<span class='alert'>You hit the wall and it [getMatFailString(src.material.material_flags)]!</span>","<span class='alert'>[user] hits the wall and it [getMatFailString(src.material.material_flags)]!</span>")
			playsound(src.loc, "sound/impact_sounds/Generic_Stab_1.ogg", 25, 1)
			del(src)
			return

	src.take_hit(W)
	//return attack_hand(user)


/turf/wall/meteorhit(obj/M as obj)
	dismantle_wall()
	return 0

/turf/wall/s_wall
	name = "scrap wall"
	desc = "Take a welder to it and the metal would slough right off the frame."
	icon = 'icons/turf/walls.dmi'
	icon_state = "s_wall"
	opacity = 1
	density = 1
	pathable = 0
	var/d_state = 0
	health = 50

	color
		icon = 'icons/turf/walls_auto_color.dmi'

	onMaterialChanged()
		..()
		if(istype(src.material))
			health = material.hasProperty("density") ? round(material.getProperty("density") * 1.5) : health
			if(src.material.material_flags & MATERIAL_CRYSTAL)
				health /= 2
		return
/turf/wall/s_wall/attackby(obj/item/W as obj, mob/user as mob, params)
	if(istype(W, /obj/item/spray_paint) || istype(W, /obj/item/gang_flyer))
		return

	if (istype(W, /obj/item/pen))
		var/obj/item/pen/P = W
		P.write_on_turf(src, user, params)
		return

	else if (istype(W, /obj/item/light_parts))
		src.attach_light_fixture_parts(user, W) // Made this a proc to avoid duplicate code (Convair880).
		return

	else if (isweldingtool(W) && isconstructionturf(src))
		var/turf/T = user.loc
		if (!( istype(T, /turf) ))
			return

		//cmon man let's not burn a fucken quarter of a welder's fuel *per wall*
		if(!W:try_weld(user, 2, burn_eyes = 1))
			return

		boutput(user, "<span class='notice'>Now disassembling the wall.</span>")
		actions.start(new /datum/action/bar/wall_decon_crud(src, W), user)
		/*SETUP_GENERIC_ACTIONBAR(user, src, 10 SECONDS, /turf/wall/proc/weld_action,\
			list(W, user), W.icon, W.icon_state, "[user] finishes disassembling the outer wall plating.", null)*/

//Spooky halloween key
	else if(istype(W,/obj/item/device/key/haunted))
		//Okay, create a temporary false wall.
		if(W:last_use && ((W:last_use + 300) >= world.time))
			boutput(user, "<span class='alert'>The key won't fit in all the way!</span>")
			return
		user.visible_message("<span class='alert'>[user] inserts [W] into [src]!</span>","<span class='alert'>The key seems to phase into the wall.</span>")
		W:last_use = world.time
		blink(src)
		new /turf/wall/false_wall/temp(src)
		return

//grabsmash
	else if (istype(W, /obj/item/grab/))
		var/obj/item/grab/G = W
		if  (!grab_smash(G, user))
			return ..(W, user)
		else return

	else if (istype(W, /obj/item/rcd))
		return //STFU with your "uselessly hits wall" messages ffs

	else
		if(src.material)
			src.material.triggerOnHit(src, W, user, 1)
			var/fail = 0
			if(src.material.hasProperty("stability") && src.material.getProperty("stability") < 15) fail = 1
			if(src.material.quality < 0) if(prob(abs(src.material.quality))) fail = 1

			if(fail)
				user.visible_message("<span class='alert'>You hit the wall and it [getMatFailString(src.material.material_flags)]!</span>","<span class='alert'>[user] hits the wall and it [getMatFailString(src.material.material_flags)]!</span>")
				playsound(src, "sound/impact_sounds/Generic_Stab_1.ogg", 25, 1)
				del(src)
				return

		src.take_hit(W)
		//return attack_hand(user)
