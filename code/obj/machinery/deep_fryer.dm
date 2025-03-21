//lazy init happens in the make-it-a-fried-thing proc
var/list/fryer_recipes

/obj/machinery/deep_fryer
	name = "Deep Fryer"
	desc = "An industrial deep fryer.  A big hit at state fairs!"
	icon = 'icons/obj/foodNdrink/kitchen.dmi'
	icon_state = "fryer0"
	anchored = 1
	density = 1
	flags = NOSPLASH | OPENCONTAINER
	machinery_flags = REQ_PHYSICAL_ACCESS
	mats = 20
	deconstruct_flags = DECON_SCREWDRIVER | DECON_WRENCH | DECON_CROWBAR | DECON_WELDER | DECON_WIRECUTTERS
	var/obj/item/fryitem = null
	var/cooktime = 0
	var/cooktime_prev = 0
	var/frytemp = 185 + T0C //365 F is a good frying temp, right?
	var/max_wclass = 3

	New()
		..()
		UnsubscribeProcess()
		src.create_reagents(150)

		reagents.add_reagent("grease", 25)
		reagents.set_reagent_temp(src.frytemp)

	attackby(obj/item/W as obj, mob/user as mob)
		var/fucked_up_now_kid = 0
		if (isghostdrone(user) || isAI(user))
			boutput(user, "<span class='alert'>The [src] refuses to interface with you, as you are not a properly trained chef!</span>")
			return
		if (W.cant_drop) //For borg held items
			boutput(user, "<span class='alert'>You can't put that in [src] when it's attached to you!</span>")
			return
		if (src.fryitem)
			boutput(user, "<span class='alert'>There is already something in the fryer!</span>")
			return
		if (istype(W, /obj/item/reagent_containers/food/snacks/shell/deepfry))
			boutput(user, "<span class='alert'>Your cooking skills are not up to the legendary Doublefry technique.</span>")
			return

		if (istype(W, /obj/item/reagent_containers/food/snacks/shell/frozen) || istype(W, /obj/item/raw_material/ice) || istype(W, /obj/item/material_piece/ice)) // oh no :DDDD
			boutput(user, "<span style='font-size:xx-large;color:red;font-family:cursive;'>OH FUGG OH SHID :DDDD!</span>")
			fucked_up_now_kid = 1


		else if (istype(W, /obj/item/reagent_containers/glass/) || istype(W, /obj/item/reagent_containers/food/drinks/))
			if (!W.reagents.total_volume)
				boutput(user, "<span class='alert'>There is nothing in [W] to pour!</span>")

			else
				logTheThing("combat", user, null, "pours chemicals [log_reagents(W)] into the [src] at [log_loc(src)].") // Logging for the deep fryer (Convair880).
				src.visible_message("<span class='notice'>[user] pours [W:amount_per_transfer_from_this] units of [W]'s contents into [src].</span>")
				playsound(src.loc, "sound/impact_sounds/Liquid_Slosh_1.ogg", 25, 1)
				W.reagents.trans_to(src, W:amount_per_transfer_from_this)
				if (!W.reagents.total_volume) boutput(user, "<span class='alert'><b>[W] is now empty.</b></span>")

			return

		else if (istype(W, /obj/item/grab))
			var/obj/item/grab/G = W
			if (!G.affecting) return
			user.lastattacked = src
			src.visible_message("<span class='alert'><b>[user] is trying to shove [G.affecting] into [src]!</b></span>")
			if(!do_mob(user, G.affecting) || !W)
				return

			if(ismonkey(G.affecting))
				logTheThing("combat", user, G.affecting, "shoves [constructTarget(G.affecting,"combat")] into the [src] at [log_loc(src)].") // For player monkeys (Convair880).
				src.visible_message("<span class='alert'><b>[user] shoves [G.affecting] into [src]!</b></span>")
				src.icon_state = "fryer1"
				src.cooktime = 0
				src.fryitem = G.affecting
				SubscribeToProcess()
				G.affecting.set_loc(src)
				G.affecting.death( 0 )
				qdel(W)
				return

			logTheThing("combat", user, G.affecting, "shoves [constructTarget(G.affecting,"combat")]'s face into the [src] at [log_loc(src)].")
			src.visible_message("<span class='alert'><b>[user] shoves [G.affecting]'s face into [src]!</b></span>")
			src.reagents.reaction(G.affecting, TOUCH)

			return

		if (W.w_class > src.max_wclass || istype(W, /obj/item/storage) || istype(W, /obj/item/storage/secure) || istype(W, /obj/item/plate))
			boutput(user, "<span class='alert'>There is no way that could fit!</span>")
			return

		if(istype(W, /obj/item/fishing_rod))
			return

		src.visible_message("<span class='notice'>[user] loads [W] into the [src].</span>")
		user.u_equip(W)
		W.set_loc(src)
		W.dropped()
		src.cooktime = 0
		src.fryitem = W
		src.icon_state = "fryer1"
		if(fucked_up_now_kid)
			#ifdef DATALOGGER
			game_stats.Increment("workplacesafety")
			#endif
			var/turf/T = get_turf(src)
			src.visible_message("<span class='alert'>[src] erupts into a disaster of hot oil!</span>")
			fireflash(T, 2)
			src.reagents.add_reagent("grease",25,null,T0C+350)
			T.fluid_react(src.reagents, src.reagents.total_volume/2,1)
			//src.reagents.remove_any(10) // just in case we dont have room for the surfactant, who cares.
			//src.reagents.add_reagent("water",5,null,T0C,1) // fuckin hell man water is hard
			//src.reagents.add_reagent("fluorosurfactant",5)
			//T.fluid_react(src.reagents, src.reagents.total_volume/2) // not necessary for foam?
			SPAWN_DBG(5 SECONDS)
				src.icon_state = "fryer0"
				qdel(fryitem)
				src.fryitem = null
				playsound(src.loc, "sound/machines/ding.ogg", 50, 1)
			return


		SubscribeToProcess()
		return

	SubscribeToProcess()
		//to prevent a fryer from instantly annihalating what you put in if it's not been used in a while
		last_process = TIME
		cooktime_prev = 0
		..()

	MouseDrop_T(obj/item/W as obj, mob/user as mob)
		if (istype(W) && in_interact_range(W, user) && in_interact_range(src, user))
			return src.Attackby(W, user)
		return ..()

	onVarChanged(variable, oldval, newval)
		if (variable == "fryitem")
			if (!oldval && newval)
				SubscribeToProcess()
			else if (oldval && !newval)
				UnsubscribeProcess()

	attack_hand(mob/user as mob)
		if (isghostdrone(user))
			boutput(user, "<span class='alert'>The [src] refuses to interface with you, as you are not a properly trained chef!</span>")
			return
		if (!src.fryitem)
			boutput(user, "<span class='alert'>There is nothing in the fryer.</span>")
			return

		if (src.cooktime < 5)
			boutput(user, "<span class='alert'>Frying things takes time! Be patient!</span>")
			return

		src.eject_food(user)
		return

	process()
		if (status & BROKEN)
			UnsubscribeProcess()
			return

		if (!src.reagents.has_reagent("grease"))
			src.reagents.add_reagent("grease", 25)

		//DaerenNote: so it turned out hellmixes + self-heating mixes constantly got dragged to the src.frytemp
		//so i fixed that, heated stuff won't get cooled by the fryer now b/c thats lame + i am not going to thermodynamics this shit to model equilibrium
		if (src.frytemp >= src.reagents.total_temperature)
			src.reagents.set_reagent_temp((src.reagents.total_temperature + src.frytemp)/2) // I'd love to have some thermostat logic here to make it heat up / cool down slowly but aaaaAAAAAAAAAAAAA (exposing it to the frytemp is too slow)

		if(!src.fryitem)
			UnsubscribeProcess()
			return
		else
			//Should roughly track seconds it's been on now, instead of # of cycles (much faster now!)
			src.cooktime += round((TIME - last_process)/(1 SECOND))

		if (!src.fryitem.reagents)
			src.fryitem.create_reagents(50)


		src.reagents.trans_to(src.fryitem, 2)

		if (src.cooktime <= 60)

			if (src.cooktime >= 30 && src.cooktime_prev < 30)
				playsound(src.loc, "sound/machines/ding.ogg", 50, 1)
				src.visible_message("<span class='notice'>[src] dings!</span>")
			else if (src.cooktime >= 60 && src.cooktime_prev < 60) //Welp!
				src.visible_message("<span class='alert'>[src] emits an acrid smell!</span>")
		else if(src.cooktime >= 120)

			if((src.cooktime % 5) == 0 && prob(10))
				src.visible_message("<span class='alert'>[src] sprays burning oil all around it!</span>")
				fireflash(src, 1)

		cooktime_prev = cooktime

	custom_suicide = 1
	suicide(var/mob/user as mob)
		if (!src.user_can_suicide(user))
			return 0
		if (src.fryitem)
			return 0
		user.visible_message("<span class='alert'><b>[user] climbs into the deep fryer! How is that even possible?!</b></span>")

		user.set_loc(src)
		src.cooktime = 0
		src.fryitem = user
		src.icon_state = "fryer1"
		user.TakeDamage("head", 0, 175)
		if(user.reagents && user.reagents.has_reagent("dabs"))
			var/amt = user.reagents.get_reagent_amount("dabs")
			user.reagents.del_reagent("dabs")
			user.reagents.add_reagent("deepfrieddabs",amt)
		SubscribeToProcess()
		SPAWN_DBG(50 SECONDS)
			if (user && !isdead(user))
				user.suiciding = 0
		return 1

	proc/fryify(atom/movable/thing, burnt=FALSE)
		var/obj/item/reagent_containers/food/snacks/shell/deepfry/fryholder = new(src)

		if(burnt)
			if (ismob(thing))
				var/mob/M = thing
				M.ghostize()
			else
				for (var/mob/M in thing)
					M.ghostize()
			qdel(thing)
			thing = new /obj/item/reagent_containers/food/snacks/yuckburn (src)
			if (!thing.reagents)
				thing.create_reagents(50)

			thing.reagents.add_reagent("grease", 50)
			fryholder.desc = "A heavily fried...something.  Who can tell anymore?"


		//lazy iniiiit
		if (!islist(fryer_recipes))
			fryer_recipes = list()
			for( var/type as anything in concrete_typesof(/datum/cookingrecipe/fryer))
				fryer_recipes += new type
		for(var/datum/cookingrecipe/fryer/recipe as anything in fryer_recipes) //Let's search for an actual recipe!
			if (!istype(thing,recipe.item1))
				continue
			if (recipe.required_reagents)
				//TODO
				logTheThing("debug", src, null, "we've for a fryer recipe with required reagents??? Help, coders???")

			//Recipe found!
			var/obj/item/reagent_containers/food/snacks/output = recipe.specialOutput(src)
			if (isnull(output))
				output = new recipe.output

			if (istype(output, /obj/item/reagent_containers/food/snacks))
				if (istype(thing, /obj/item/reagent_containers/food/snacks))
					output.food_effects += thing:food_effects

				output.food_effects |= "food_warm"
				output.food_effects -= "food_cold"

				/*
				recipe cookbonus implicitly ranges 1-20 which is what ovens can reach
				so if we take 2 seconds of frying per unit of cookbonus (now that cooktime doesn't count process loops anymore)
				that gives a range between 2 and 40 seconds, which is also a rough bisection of fryholders' lightly and regular fry times (note we can't eject below 5s)
				We'll deduct one point from the max of 5 quality for every 4 seconds you're off from ideal.
				Can't really go better than that atm as fryers tick at the normal 3.2s rate. That may need bumping up a level.

				(which also means frying well will be harder than oven cooking, since you gotta time it yourself)
				*/
				output.quality = 5 - (abs(2*recipe.cookbonus - src.cooktime)%4)

			//Doubt we'll ever have fried person recipies but just in case
			if (ismob(thing))
				var/mob/M = thing
				M.ghostize()
			else
				for (var/mob/M in thing)
					M.ghostize()
			qdel(thing)
			qdel(fryholder)
			return output

		//From here on out is generic fryholder code
		if (istype(thing, /obj/item/reagent_containers/food/snacks))
			fryholder.food_effects += thing:food_effects

		fryholder.food_effects |= "food_warm"
		fryholder.food_effects -= "food_cold"

		var/icon/composite = new(thing.icon, thing.icon_state)
		for(var/O in thing.underlays + thing.overlays)
			var/image/I = O
			composite.Blend(icon(I.icon, I.icon_state, I.dir, 1), ICON_OVERLAY)

		switch(src.cooktime)
			if (0 to 15)
				fryholder.name = "lightly-fried [thing.name]"
				fryholder.color = ( rgb(255, 156, 80) )


			if (16 to 49)
				fryholder.name = "fried [thing.name]"
				fryholder.color = ( rgb(201, 123, 45) )

			if (50 to 59)
				fryholder.name = "deep-fried [thing.name]"
				fryholder.color = ( rgb(131, 45, 5) )

			else
				fryholder.color = ( rgb(72, 35, 8) )
				fryholder.reagents.maximum_volume += 25
				fryholder.reagents.add_reagent("friedessence",25)

		fryholder.charcoaliness = src.cooktime
		fryholder.icon = composite
		fryholder.overlays = thing.overlays
		if (isitem(thing))
			var/obj/item/item = thing
			fryholder.amount = item.w_class
		else
			fryholder.amount = 5
		if(thing.reagents)
			fryholder.reagents.maximum_volume += thing.reagents.total_volume
			thing.reagents.trans_to(fryholder, thing.reagents.total_volume)
		fryholder.reagents.my_atom = fryholder

		thing.set_loc(fryholder)
		return fryholder

	proc/eject_food(var/mob/user)
		if (!src.fryitem)
			UnsubscribeProcess()
			return

		var/obj/item/reagent_containers/food/snacks/shell/deepfry/fryholder = src.fryify(src.fryitem, src.cooktime >= 60)
		fryholder.set_loc(get_turf(src))

		src.fryitem = null
		src.icon_state = "fryer0"
		for (var/obj/item/I in src) //Things can get dropped somehow sometimes ok
			I.set_loc(src.loc)

		//Let's use what came out instead of what came in thanks
		user.visible_message("<span class='notice'>[user] removes [fryholder] from [src]!</span>", "<span class='notice'>You remove [fryholder] from [src].</span>")
		UnsubscribeProcess()
		return

	verb/drain()
		set src in oview(1)
		set name = "Drain Oil"
		set desc = "Drain and replenish fryer oils."
		set category = "Local"

		if(src.reagents.reagent_list.len)
			if (isobserver(usr) || isintangible(usr)) // Ghosts probably shouldn't be able to take revenge on a traitor chef or whatever (Convair880).
				for(var/reagent_id in src.reagents.reagent_list)
					if(reagent_id != "grease") // The above comment makes sense if some traitor chef has filled the fryer with hard-fought deathchems. But if there's nothing in it to lose but standard default hot grease, fuck it: Let ghosts chairspin the deep fryer again.
						boutput(usr, "<span class='alert'>Some supernatural condition prevents you from tampering with the fryer from beyond the realm of the living! Nice try, though.</span>")
						return
			src.reagents.clear_reagents()
			src.reagents.add_reagent("grease", 25) //also maybe actually refresh the frying oil instead of just draining it and doing nothing
			src.reagents.set_reagent_temp(src.frytemp)
			src.visible_message("<span class='alert'>[usr] drains and refreshes the frying oil!</span>")

		return
