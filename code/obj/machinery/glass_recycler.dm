#define PLATE_COST 2

/obj/machinery/glass_recycler
	name = "glass recycler"//"Kitchenware Recycler"
	desc = "A machine that recycles glass shards into drinking glasses, beakers, or other glass things."
	icon = 'icons/obj/foodNdrink/kitchen.dmi'
	icon_state = "synthesizer"
	anchored = 1
	density = 0
	var/glass_amt = 0
	mats = 10
	flags = FPRINT | FLUID_SUBMERGE | TGUI_INTERACTIVE | TABLEPASS
	deconstruct_flags = DECON_SCREWDRIVER | DECON_WRENCH | DECON_WELDER | DECON_WIRECUTTERS
	object_flags = CAN_BE_LIFTED
	throw_speed = 2
	throw_range = 4
	throwforce = 10

	New()
		..()
		UnsubscribeProcess()

	throw_end(list/params, turf/thrown_from)
		. = ..()
		playsound(src.loc, 'sound/impact_sounds/Metal_Hit_Heavy_1.ogg', 50, 1)

	throw_impact(atom/hit_atom, datum/thrown_thing/thr)
		..()
		if(ismob(hit_atom))
			var/mob/living/L = hit_atom
			L.changeStatus("weakened", 1 SECOND)
			L.force_laydown_standup()

	throw_at(atom/target, range, speed, list/params, turf/thrown_from, throw_type = 1,
			allow_anchored = 0, bonus_throwforce = 0, end_throw_callback = null)
		..()
		if(ismob(usr))
			var/mob/living/L = usr
			L.changeStatus("weakened", 1.5 SECONDS)
			L.force_laydown_standup()

	attackby(obj/item/W as obj, mob/user as mob)
		if(istype(W.loc, /obj/item/storage))
			var/obj/item/storage/storage = W.loc
			storage.hud.remove_object(W)
		if(W.cant_drop)
			boutput(user, "<span class='alert'>You cannot put [W] into [src]!</span>")
			return

		var/success = FALSE //did we successfully recycle a thing?
		if(istype(W, /obj/item/reagent_containers/glass))
			if (istype(W, /obj/item/reagent_containers/glass/beaker))
				success = TRUE
				if (istype(W, /obj/item/reagent_containers/glass/beaker/large))
					glass_amt += 2
				else
					glass_amt += 1
			else
				var/obj/item/reagent_containers/glass/G = W
				if (G.can_recycle)
					success = TRUE
					glass_amt += 1
		else if (istype(W, /obj/item/reagent_containers/food/drinks/))
			var/obj/item/reagent_containers/food/drinks/D = W
			if (D.can_recycle)
				success = TRUE
				if (istype(W,/obj/item/reagent_containers/food/drinks/drinkingglass))
					var/obj/item/reagent_containers/food/drinks/drinkingglass/DG = W
					glass_amt += DG.shard_amt
				else
					if (istype(W,/obj/item/reagent_containers/food/drinks/bottle))
						var/obj/item/reagent_containers/food/drinks/bottle/B = W
						if (!B.broken) glass_amt += 1
					else
						glass_amt += W.amount
		else if (istype(W, /obj/item/material_piece) && W.material?.material_flags & MATERIAL_CRYSTAL && W.material?.alpha <= 180)
			success = TRUE
			glass_amt += W.amount * 10
		else if (istype(W, /obj/item/raw_material/shard))
			success = TRUE
			glass_amt += W.amount
		else if (istype(W, /obj/item/plate))
			success = TRUE
			glass_amt += PLATE_COST
		else if (istype(W, /obj/item/platestack))
			success = TRUE
			var/obj/item/platestack/PS = W
			var/plateCount = PS.platenum + 1
			glass_amt += plateCount * PLATE_COST
		else if (istype(W, /obj/item/storage/box))
			var/obj/item/storage/S = W
			for (var/obj/item/I in S.get_contents())
				if (!.(I, user))
					break

		if (success)
			user.visible_message("<span class='notice'>[user] inserts [W] into [src].</span>")
			user.u_equip(W)
			if (istype(W, /obj/item/raw_material/shard))
				qdel(W)
			else
				qdel(W)
			return 1
		else
			boutput(user, "<span class='alert'>You cannot put [W] into [src]!</span>")
			return 0

	attack_hand(mob/user as mob)
		var/dat = {"<b>Glass Left</b>: [glass_amt]<br>"}
#ifndef NO_EASY_BEAKERS
		dat += {"<A href='byond://?src=\ref[src];type=beaker'>Beaker</A><br>
				<A href='byond://?src=\ref[src];type=largebeaker'>Large Beaker</A><br>"}
#endif
		dat += {"<A href='byond://?src=\ref[src];type=bottle'>Bottle</A><br>
				<A href='byond://?src=\ref[src];type=vial'>Vial</A><br>
				<A href='byond://?src=\ref[src];type=flute'>Champagne Flute</A><br>
				<A href='byond://?src=\ref[src];type=cocktail'>Cocktail Glass</A><br>
				<A href='byond://?src=\ref[src];type=drinkbottle'>Drink Bottle</A><br>
				<A href='byond://?src=\ref[src];type=tallbottle'>Tall Bottle</A><br>
				<A href='byond://?src=\ref[src];type=longbottle'>Long Bottle</A><br>
				<A href='byond://?src=\ref[src];type=rectangularbottle'>Rectangular Bottle</A><br>
				<A href='byond://?src=\ref[src];type=squarebottle'>Square Bottle</A><br>
				<A href='byond://?src=\ref[src];type=masculinebottle'>Wide Bottle</A><br>
				<A href='byond://?src=\ref[src];type=drinking'>Drinking Glass</A><br>
				<A href='byond://?src=\ref[src];type=oldf'>Old Fashioned Glass</A><br>
				<A href='byond://?src=\ref[src];type=pitcher'>Pitcher</A><br>
				<A href='byond://?src=\ref[src];type=round'>Round Glass</A><br>
				<A href='byond://?src=\ref[src];type=shot'>Shot Glass</A><br>
				<A href='byond://?src=\ref[src];type=wine'>Wine Glass</A><br>
				<A href='byond://?src=\ref[src];type=bowl'>Bowl</A><br>
				<A href='byond://?src=\ref[src];type=plate'>Plate</A><br>
				<HR><A href='byond://?src=\ref[src];refresh=1'>Refresh</A>
				<BR><BR><A href='byond://?action=mach_close&window=glass'>Close</A>"}
		//user.Browse(dat, "window=glass;size=220x240")
		user.Browse(dat, "window=glass;size=220x360;title=Recycler")
		onclose(user, "glass")
		return

	Topic(href, href_list) // should probably rewrite this since it's kinda shitty
		if(..())
			return
		if ((usr.contents.Find(src) || ((get_dist(src, usr) <= 1) && istype(src.loc, /turf))) || (isAI(usr)))
			src.add_dialog(usr)

			if (href_list["type"])
				create(lowertext(href_list["type"]))

			if (href_list["refresh"])
				src.updateUsrDialog()
			src.add_fingerprint(usr)
			src.updateUsrDialog()
		return
/* commenting out for now because this is really very unecessary for what can be accomplished in one line in that create() proc below
	proc/check_glass()
		if(src.glass_amt <= 0)
			return 0
		else
			return 1
*/
	proc/create(var/object)
		if(src.glass_amt < 1 || ((object == "pitcher" || object == "largebeaker" || object == "round" || object == "plate") && src.glass_amt < 2))
			src.visible_message("<span class='alert'>[src] doesn't have enough glass to make that!</span>")
			return

		var/obj/item/G

		switch(object)
			if("beaker")
				G = new /obj/item/reagent_containers/glass/beaker(get_turf(src))
				src.glass_amt -= 1
			if("largebeaker")
				G = new /obj/item/reagent_containers/glass/beaker/large(get_turf(src))
				src.glass_amt -= 2
			if("bottle")
				G = new /obj/item/reagent_containers/glass/bottle(get_turf(src))
				src.glass_amt -= 1
			if("vial")
				G = new /obj/item/reagent_containers/glass/vial(get_turf(src))
				src.glass_amt -= 1
			if("drinkbottle")
				G = new /obj/item/reagent_containers/food/drinks/bottle/soda(get_turf(src))
				src.glass_amt -= 1
			if("longbottle")
				G = new /obj/item/reagent_containers/food/drinks/bottle/empty/long(get_turf(src))
				src.glass_amt -= 1
			if("tallbottle")
				G = new /obj/item/reagent_containers/food/drinks/bottle/empty/tall(get_turf(src))
				src.glass_amt -= 1
			if("rectangularbottle")
				G = new /obj/item/reagent_containers/food/drinks/bottle/empty/rectangular(get_turf(src))
				src.glass_amt -= 1
			if("squarebottle")
				G = new /obj/item/reagent_containers/food/drinks/bottle/empty/square(get_turf(src))
				src.glass_amt -= 1
			if("masculinebottle")
				G = new /obj/item/reagent_containers/food/drinks/bottle/empty/masculine(get_turf(src))
				src.glass_amt -= 1
			if("plate")
				G = new /obj/item/plate(get_turf(src))
				src.glass_amt -= PLATE_COST
			if("bowl")
				G = new /obj/item/reagent_containers/food/drinks/bowl(get_turf(src))
				src.glass_amt -= 1
			if("drinking")
				G = new /obj/item/reagent_containers/food/drinks/drinkingglass(get_turf(src))
				src.glass_amt -= 1
			if("shot")
				G = new /obj/item/reagent_containers/food/drinks/drinkingglass/shot(get_turf(src))
				src.glass_amt -= 1
			if("oldf")
				new /obj/item/reagent_containers/food/drinks/drinkingglass/oldf(get_turf(src))
				src.glass_amt -= 1
			if("round")
				new /obj/item/reagent_containers/food/drinks/drinkingglass/round(get_turf(src))
				src.glass_amt -= 2
			if("wine")
				G = new /obj/item/reagent_containers/food/drinks/drinkingglass/wine(get_turf(src))
				src.glass_amt -= 1
			if("cocktail")
				G = new /obj/item/reagent_containers/food/drinks/drinkingglass/cocktail(get_turf(src))
				src.glass_amt -= 1
			if("flute")
				G = new /obj/item/reagent_containers/food/drinks/drinkingglass/flute(get_turf(src))
				src.glass_amt -= 1
			if("pitcher")
				G = new /obj/item/reagent_containers/food/drinks/drinkingglass/pitcher(get_turf(src))
				src.glass_amt -= 2
			else
				return

		if(G)
			src.visible_message("<span class='notice'>[src] manufactures \a [G]!</span>")
			return

/obj/machinery/glass_recycler/chemistry //Chemistry doesn't really need all of the drinking glass options and such so I'm limiting it down a notch.
	name = "chemistry glass recycler"
	icon_state = "synthesizer-purp"

	attack_hand(mob/user as mob)
		var/dat = {"<b>Glass Left</b>: [glass_amt]<br>"}
#ifndef NO_EASY_BEAKERS
		dat += {"<A href='byond://?src=\ref[src];type=beaker'>Beaker</A><br>
				<A href='byond://?src=\ref[src];type=largebeaker'>Large Beaker</A><br>"}
#endif
		dat +=	{"<A href='byond://?src=\ref[src];type=bottle'>Bottle</A><br>
				<A href='byond://?src=\ref[src];type=vial'>Vial</A><br>
				<A href='byond://?src=\ref[src];type=flask'>Flask</A>
				<HR><A href='byond://?src=\ref[src];refresh=1'>Refresh</A>
				<BR><BR><A href='byond://?action=mach_close&window=glass'>Close</A>"}
		//user << browse(dat, "window=glass;size=220x240")
		user.Browse(dat, "window=glass;size=220x360;title=Recycler")
		onclose(user, "glass")
		return

	create(var/object)
		if(src.glass_amt < 1 || ((object == "pitcher" || object == "largebeaker") && src.glass_amt < 2))
			src.visible_message("<span class='alert'>[src] doesn't have enough glass to make that!</span>")
			return

		var/obj/item/G

		switch(object)
			if("beaker")
				G = new /obj/item/reagent_containers/glass/beaker(get_turf(src))
				src.glass_amt -= 1
			if("largebeaker")
				G = new /obj/item/reagent_containers/glass/beaker/large(get_turf(src))
				src.glass_amt -= 2
			if("bottle")
				G = new /obj/item/reagent_containers/glass/bottle(get_turf(src))
				src.glass_amt -= 1
			if("vial")
				G = new /obj/item/reagent_containers/glass/vial(get_turf(src))
				src.glass_amt -= 1
			if("flask")
				G = new /obj/item/reagent_containers/glass/flask(get_turf(src))
				src.glass_amt -= 1
			else
				return

		if(G)
			src.visible_message("<span class='notice'>[src] manufactures \a [G]!</span>")
			return

#undef PLATE_COST
