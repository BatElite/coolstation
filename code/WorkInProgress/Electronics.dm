
/obj/item/electronics/
	name = "electronic thing"
	icon = 'icons/obj/electronics.dmi'
	inhand_image_icon = 'icons/mob/inhand/hand_tools.dmi'
	force = 5
	hit_type = DAMAGE_BLUNT
	throwforce = 5
	w_class = W_CLASS_TINY
	pressure_resistance = 10
	item_state = "electronic"
	flags = FPRINT | TABLEPASS | CONDUCT
	value = 25 //base commodity price

/obj/item/electronics/New()
	..()
	desc = "A [src.name] used in electronic projects."

/obj/item/electronics/proc/randompix()
	src.pixel_x = rand(8, 12)
	src.pixel_y = rand(8, 12)

////////////////////////////////////////////////////////////////
/obj/item/electronics/battery
	name = "battery"
	icon_state = "batt1"
	value = 30

/obj/item/electronics/battery/New()
	src.icon_state = pick("batt1", "batt2", "batt3")
	randompix()
	..()
////////////////////////////////////////////////////////////////up
/obj/item/electronics/board
	name = "board"
	icon_state = "board1"
	value = 50

/obj/item/electronics/board/New()
	src.icon_state = pick("board1", "board2", "board3")
	randompix()
	..()
////////////////////////////////////////////////////////////////
/obj/item/electronics/fuse
	name = "fuse"
	icon_state = "fuse1"
	value = 10

/obj/item/electronics/fuse/New()
	src.icon_state = pick("fuse1", "fuse2", "fuse3")
	randompix()
	..()
////////////////////////////////////////////////////////////////
/obj/item/electronics/switc
	name = "switch"
	icon_state = "switch1"
	value = 10

/obj/item/electronics/switc/New()
	src.icon_state = pick("switch1", "switch2", "switch3")
	randompix()
	..()
////////////////////////////////////////////////////////////////up
/obj/item/electronics/keypad
	name = "keypad"
	icon_state = "keypad1"
	value = 30
/obj/item/electronics/keypad/New()
	src.icon_state = pick("keypad1", "keypad2", "keypad3")
	randompix()
	..()
////////////////////////////////////////////////////////////////up
/obj/item/electronics/screen
	name = "screen"
	icon_state = "screen1"
	value = 40
/obj/item/electronics/screen/New()
	src.icon_state = pick("screen1", "screen2", "screen3")
	randompix()
	..()
////////////////////////////////////////////////////////////////
/obj/item/electronics/capacitor
	name = "capacitor"
	icon_state = "capacitor1"
	value = 10
/obj/item/electronics/capacitor/New()
	src.icon_state = pick("capacitor1", "capacitor2", "capacitor3")
	randompix()
	..()
////////////////////////////////////////////////////////////////up
/obj/item/electronics/buzzer
	name = "buzzer"
	icon_state = "buzzer"
	value = 10
/obj/item/electronics/buzzer/New()
	randompix()
	..()
////////////////////////////////////////////////////////////////
/obj/item/electronics/resistor
	name = "resistor"
	icon_state = "resistor1"
	value = 10
/obj/item/electronics/resistor/New()
	src.icon_state = pick("resistor1", "resistor2")
	randompix()
	..()
////////////////////////////////////////////////////////////////
/obj/item/electronics/bulb
	name = "bulb"
	icon_state = "bulb1"
	value = 15
/obj/item/electronics/bulb/New()
	src.icon_state = pick("bulb1", "bulb2")
	randompix()
	..()
////////////////////////////////////////////////////////////////
/obj/item/electronics/relay
	name = "relay"
	icon_state = "relay1"
	value = 20
/obj/item/electronics/bulb/New()
	src.icon_state = pick("relay1", "relay2")
	randompix()
	..()
////////////////////////////////////////////////////////////////no
/obj/item/electronics/frame
	name = "frame"
	icon_state = "frame"
	value = 60
	var/store_type = null
	var/secured = 0
	var/viewstat = 0
	var/dir_needed = 0
	//var/list/parts = new/list()
	var/list/needed_parts = new/list()
	var/obj/deconstructed_thing = null


	disposing()
		if(deconstructed_thing)
			deconstructed_thing.dispose()
			deconstructed_thing = null
		store_type = null
		..()

/obj/item/electronics/frame/attackby(obj/item/W as obj, mob/user as mob)
	if(istype(W,/obj/item/electronics/))
		var/obj/item/electronics/E = W
		if(!(istype(E,/obj/item/electronics/disk)||istype(E,/obj/item/electronics/scanner)||istype(E,/obj/item/electronics/soldering)||istype(E,/obj/item/electronics/frame)))
			E.set_loc(src)
			user.u_equip(E)
			//parts.Add(E)
			boutput(user, "<span class='notice'>You add the [E.name] to the [src].</span>")
			needed_parts[E.type] -= 1
			return
		else if(istype(E,/obj/item/electronics/soldering))
			if(!secured)
				secured = 1
				viewstat = 1
				boutput(user, "<span class='notice'>You secure the [src].</span>")
			else if(secured == 1)
				secured = 0
				viewstat = 0
				boutput(user, "<span class='notice'>You unsecure the [src].</span>")
			else if(secured == 2)
				boutput(user, "<span class='alert'>You deploy the [src]!</span>")
				logTheThing("station", user, null, "deploys a [src.name] in [user.loc.loc] ([showCoords(src.x, src.y, src.z)])")
				if (!istype(user.loc,/turf) && (store_type in typesof(/obj/critter)))
					qdel(user.loc)

				actions.start(new/datum/action/bar/icon/build_electronics_frame(src), user)
				//deploy()
			return
		else if(istype(E,/obj/item/electronics/scanner) && !secured)
			if(!parts_check())
				boutput(user, "<span class='notice'>Missing components:</span>")
				for(var/part in needed_parts)
					var/obj/item/electronics/_part = part
					if(needed_parts[part] > 0)
						boutput(user, "<span class='notice'>[initial(_part.name)]: [needed_parts[part]]</span>")
			else
				boutput(user, "<span class='notice'>All components present</span>")
			return

	if (ispryingtool(W))
		if (!anchored)
			src.set_dir(turn(src.dir, 90))
			return
	else if (iswrenchingtool(W))
		boutput(user, "<span class='alert'>You deconstruct [src] into its base materials!</span>")
		src.drop_resources(W,user)
	..()

/obj/item/electronics/frame/MouseDrop_T(atom/movable/O as obj, mob/user as mob)
	if(!iscarbon(user) || user.stat || user.getStatusDuration("weakened") || user.getStatusDuration("paralysis"))
		return

	if(get_dist(user, src) > 1)
		return

	var/list/bad_types = list(/obj/item/electronics/disk, /obj/item/electronics/scanner, /obj/item/electronics/soldering, /obj/item/electronics/frame)
	if(!istype(O, /obj/item/electronics) || (O.type in bad_types))
		boutput(user, "<span class='alert'>That is not a valid component!</span>")
		return

	if (!src.secured)
		var/turf/source_turf = get_turf(O)
		if(!source_turf) return
		user.visible_message("<span class='notice'>[user] begins quickly adding components to [src]!</span>", "<span class='notice'>You begin to quickly add components to [src]!</span>")
		var/staystill = user.loc

		for(var/obj/item/electronics/I in source_turf)
			if(I.type in bad_types) continue
			I.set_loc(src)
			//parts.Add(I)
			sleep(0.3 SECONDS)
			if (user.loc != staystill) break

		boutput(user, "<span class='notice'>You finish adding components to [src]!</span>")
	else
		boutput(user, "<span class='alert'>The board is already secured!</span>")
	return

/obj/item/electronics/frame/attack_self(mob/user as mob)
	src.add_fingerprint(user)
	var/dat
	dat = "Parts:<BR>"

	switch(viewstat)

		if(0)
			for(var/obj/item/electronics/P in src.contents)
				dat += "[P.name]: <A href='byond://?src=\ref[src];op=\ref[P];tp=move'>Remove</A><BR>"

				src.add_dialog(user)
				user.Browse("<HEAD><TITLE>Frame</TITLE></HEAD><TT>[dat]</TT>", "window=fkit")
				onclose(user, "fkit")

		if(1)
			var/check = parts_check()
			if(!check)
				boutput(user, "<span class='alert'>Incomplete Object, unable to finish!</span>")
				return
			if(dir_needed)
				var/dirr = input("Select A Direction!", "UDLR", null, null) in list("Up","Down","Left","Right")
				switch(dirr)
					if("Up")
						src.set_dir(1)
					if("Down")
						src.set_dir(2)
					if("Left")
						src.set_dir(8)
					if("Right")
						src.set_dir(4)
			boutput(user, "Ready to deploy!")
			switch(alert("Ready to deploy?",,"Yes","No"))
				if("Yes")
					boutput(user, "<span class='alert'>Place box and solder to deploy!</span>")
					viewstat = 2
					secured = 2
					icon_state = "dbox"
				if("No")
					return
		else
			return

/obj/item/electronics/frame/Topic(href, href_list)
	if (usr.stat)
		return
	if ((usr.contents.Find(src) || usr.contents.Find(src.master) || in_interact_range(src, usr) && istype(src.loc, /turf)))
		src.add_dialog(usr)

		switch(href_list["tp"])
			if("move")
				if(href_list["op"])
					var/obj/Z = locate(href_list["op"]) in src.contents
					var/turf/T = src.loc
					if (ismob(T))
						T = T.loc
					Z.set_loc(T)
					//parts.Remove(Z)
					needed_parts[Z.type] += 1


		updateDialog()
	else
		usr.Browse(null, "window=fkit")
		src.remove_dialog(usr)
	return

/obj/item/electronics/frame/proc/deploy(mob/user)
	var/turf/T = get_turf(src)
	var/obj/O = null
	if (deconstructed_thing)
		O = deconstructed_thing
		O.set_loc(T)
		O.set_dir(src.dir)
		O.was_built_from_frame(user, 0)
		deconstructed_thing = null
	else
		O = new store_type(T)
		O.set_dir(src.dir)
		O.was_built_from_frame(user, 1)
	//O.mats = "Built"
	O.deconstruct_flags |= DECON_BUILT
	qdel(src)

	return

/obj/item/electronics/frame/proc/drop_resources(obj/item/W as obj, mob/user as mob)
	var/datum/manufacture/mechanics/R = null

	if (src.deconstructed_thing)
		for (var/datum/manufacture/mechanics/M in manuf_controls.custom_schematics)
			if (M.frame_path == deconstructed_thing.type)
				R = M
				break
	else
		for (var/datum/manufacture/mechanics/M in manuf_controls.custom_schematics)
			if (M.frame_path == src.store_type)
				R = M
				break

	if (istype(R))
		var/looper = round(R.item_amounts[1] / 10)
		while (looper > 0)
			var/obj/item/material_piece/mauxite/M = new()
			M.set_loc(get_turf(src))
			looper--
		looper = round(R.item_amounts[2] / 10)
		while (looper > 0)
			var/obj/item/material_piece/pharosium/P = new()
			P.set_loc(get_turf(src))
			looper--
		looper = round(R.item_amounts[3] / 10)
		while (looper > 0)
			var/obj/item/material_piece/molitz/M = new()
			M.set_loc(get_turf(src))
			looper--
	else
		boutput(user, "<span class='alert'>Could not reclaim resources.</span>")
	qdel(src)

/datum/action/bar/icon/build_electronics_frame
	duration = 10
	interrupt_flags = INTERRUPT_MOVE | INTERRUPT_ACT | INTERRUPT_STUNNED | INTERRUPT_ACTION
	id = "build_electronics_frame"
	icon_state = "working"
	var/obj/item/electronics/frame/F

	New(Frame)
		F = Frame
		..()

	onUpdate()
		..()
		if(get_dist(owner, F) > 1 || F == null || owner == null)
			interrupt(INTERRUPT_ALWAYS)
			return

	onStart()
		..()
		if(get_dist(owner, F) > 1 || F == null || owner == null)
			interrupt(INTERRUPT_ALWAYS)
			return

	onEnd()
		..()
		if(get_dist(owner, F) > 1 || F == null || owner == null)
			interrupt(INTERRUPT_ALWAYS)
			return
		if(owner && F)
			F.deploy(owner)


/obj/item/electronics/frame/proc/parts_check()
	for(var/part in needed_parts)
		if(needed_parts[part]>0)
			return 0
	return 1

////////////////////////////////////////////////////////////////?
/obj/item/electronics/soldering
	name = "soldering iron"
	icon = 'icons/obj/electronics.dmi'
	icon_state = "solderingiron"
	force = 10
	hit_type = DAMAGE_BURN
	throwforce = 5
	w_class = W_CLASS_SMALL
	pressure_resistance = 40
	value = 35

	afterattack(atom/target as mob|obj|turf|area, mob/user as mob)
		if (!isobj(target))
			return
		var/obj/O = target
		var/decon_len = O.decon_contexts ? O.decon_contexts.len : 0
		O.decon_contexts = null
		if (O.build_deconstruction_buttons() != decon_len)
			boutput(user, "<span class='alert'>You repair [target]'s deconstructed state.</span>")
			return
		..()

////////////////////////////////////////////////////////////////no
/obj/item/electronics/disk
	name = "data module"
	icon_state = "disk"
	var/list/parts = new/list()
	var/item_name = "Error"

////////////////////////////////////////////////////////////////up
/obj/item/electronics/scanner
	name = "device analyzer"
	icon_state = "deviceana"
	desc = "Used for diagnosing problems with station equipment and making backup scans. These scans can then be used with the ruckingenur kit to produce schematics for replacing equipment."
	force = 2
	hit_type = DAMAGE_BLUNT
	throwforce = 5
	w_class = W_CLASS_SMALL
	pressure_resistance = 50
	var/list/scanned = list()
	var/viewstat = 0
	value = 150

	syndicate
		is_syndicate = 1

/obj/item/electronics/scanner/afterattack(var/obj/O, mob/user as mob)
	//Maintenance arrears
	//
	if (istype(O, /obj/machinery))
		var/obj/machinery/M = O
		var/hint = M.malfunction_hint()
		if (hint)
			animate_scanning(O, "#FF6633")
			user.visible_message("<b>[user]</b> has scanned the [O].")
			boutput(user, "<br><span class='alert'>Maintenance analysis: <b>[M] is not functioning properly.</span></b>")
			src.audible_message("<span class='notice'>NanoTrasen maintenance guide advises: <i>[hint]</i></span>")
			return

	if(istype(O,/obj/machinery/rkit) || istype(O, /obj/item/electronics/frame))
		return
	if(istype(O,/obj/))
		if(O.mats == 0 || isnull(O.mats) || O.disposed || (O.is_syndicate != 0 && src.is_syndicate == 0))
			// if this item doesn't have mats defined or was constructed or
			// attempting to scan a syndicate item and this is a normal scanner
			boutput(user, "<span class='alert'>The structure of this object is not compatible with the scanner.</span>")
			return

		user.visible_message("<B>[user.name]</B> scans [O].")

		var/final_type = O.mechanics_type_override ? O.mechanics_type_override : O.type

		for (var/X in src.scanned)
			if (final_type == X)
				boutput(user, "<span class='alert'>You have already scanned that object.</span>")
				return

		animate_scanning(O, "#FFFF00")
		src.scanned += final_type
		boutput(user, "<span class='notice'>Item scan successful.</span>")

////////////////////////////////////////////////////////////////no
/obj/machinery/rkit
	name = "ruckingenur kit"
	desc = "Used for reverse engineering certain items."
	icon = 'icons/obj/electronics.dmi'
	icon_state = "rkit"
	anchored = 1
	density = 1
	//var/datum/electronics/electronics_items/link = null
	req_access = list(access_captain, access_head_of_personnel, access_maxsec, access_engineering_chief, access_quartermaster)
	value = 30000

	var/processing = 0
	var/net_id = null
	var/frequency = FREQ_RUCK
	var/datum/radio_frequency/radio_connection
	var/no_print_spam = 1 // In relation to world.time.
	var/olde = 0
	var/datum/mechanic_controller/ruck_controls
	///net_id of the ruck that will send messages
	var/host_ruck
	///list of rucks we've seen send a SYNC or SYNCREPLY (or even DROP but that's weird)
	var/list/known_rucks = null
	var/boot_time = null
	var/data_initialized = FALSE
	var/datum/radio_frequency/pda = null

/obj/machinery/rkit/New()
	. = ..()
	known_rucks = new
	ruck_controls = new
	pda = radio_controller.return_frequency("[FREQ_PDA]")

	if(isnull(mechanic_controls)) mechanic_controls = ruck_controls //For objective tracking and admin
	if(radio_controller)
		radio_connection = radio_controller.add_object(src, "[frequency]")
	if(!src.net_id)
		src.net_id = generate_net_id(src)
		ruck_controls.rkit_addresses += src.net_id
		host_ruck = src.net_id

/obj/machinery/rkit/disposing()
	if (src.net_id == host_ruck) send_sync(1) //Everyone needs to find a new master
	SPAWN_DBG(0.8 SECONDS) //Wait for the sync to send
		radio_controller?.remove_object(src, "[frequency]")
		radio_connection = null
		if (src.net_id)
			ruck_controls.rkit_addresses -= src.net_id
		..()

/obj/machinery/rkit/power_change()
	. = ..()
	//This will run when we're created and find a host ruck
	if(status & (NOPOWER|BROKEN))
		if (src.net_id == host_ruck) send_sync(1)
		return

	if (powered())
		send_sync()
	else
		if (src.net_id == host_ruck) send_sync(1)

/obj/machinery/rkit/proc/send_sync(var/dispose) //Request SYNCREPLY from other rucks
	//If dispose is true we use "DROP" which won't be saved as the host
	SPAWN_DBG(rand(5, 10)) //Keep these out of sync a little, less spammy
		if(!boot_time) boot_time = world.time
		host_ruck = src.net_id //We're the host until someone else proves they are
		var/datum/signal/newsignal = get_free_signal()
		newsignal.source = src
		newsignal.transmission_method = TRANSMISSION_RADIO
		if(!dispose)
			newsignal.data["command"] = "SYNC"
		else
			newsignal.data["command"] = "DROP"
		newsignal.data["address_1"] = "TRANSRKIT"
		newsignal.data["sender"] = src.net_id
		radio_connection.post_signal(src, newsignal)

/obj/machinery/rkit/proc/upload_blueprint(var/datum/electronics/scanned_item/O, var/target, var/internal)
	SPAWN_DBG(0.5 SECONDS) //This proc sends responses so there must be a delay
		var/datum/computer/file/electronics_scan/scanFile = new
		scanFile.scannedName = O.name
		scanFile.scannedPath = O.item_type
		scanFile.scannedMats = O.mats
		var/datum/signal/newsignal = get_free_signal()
		newsignal.source = src
		newsignal.transmission_method = TRANSMISSION_RADIO
		if(!internal)
			newsignal.data["command"] = "NEW"
		else
			newsignal.data["command"] = "UPLOAD"
		newsignal.data["address_1"] = target
		newsignal.data["sender"] = src.net_id
		newsignal.data_file = scanFile
		radio_connection.post_signal(src, newsignal)

/obj/machinery/rkit/proc/pda_message(var/target, var/message)
	SPAWN_DBG(0.5 SECONDS) //response proc
		var/datum/signal/newsignal = get_free_signal()
		newsignal.source = src
		newsignal.transmission_method = TRANSMISSION_RADIO
		newsignal.data["command"] = "text_message"
		newsignal.data["sender_name"] = "RKIT-MAILBOT"
		newsignal.data["message"] = message
		if (target) newsignal.data["address_1"] = target
		newsignal.data["group"] = list(MGO_MECHANIC, MGA_RKIT)
		newsignal.data["sender"] = src.net_id
		pda.post_signal(src, newsignal)

/obj/machinery/rkit/proc/transfer_database(target)
	//If we have a database of items, and we're the host, and we see a new ruck
	//Upload our database to it
	var/datum/computer/file/electronics_bundle/rkitFile = new
	rkitFile.ruckData = ruck_controls
	rkitFile.target = target
	rkitFile.known_rucks = src.known_rucks.Copy()
	SPAWN_DBG(0.5 SECONDS)
		var/datum/signal/newsignal = get_free_signal()
		newsignal.source = src
		newsignal.transmission_method = TRANSMISSION_RADIO
		newsignal.data["command"] = "UPLOAD"
		newsignal.data["address_1"] = target
		newsignal.data["sender"] = src.net_id
		newsignal.data_file = rkitFile
		radio_connection.post_signal(src, newsignal)
	known_rucks |= target

//Run this if there's a file and return
//This will either work, or you rejected a signal that had a file it didn't need
/obj/machinery/rkit/proc/process_upload(datum/signal/signal)
	var/target = signal.data["sender"]
	var/command = signal.data["command"]
	if(!target || (command != "add" && command != "UPLOAD") || (!istype(signal.data_file, /datum/computer/file/electronics_scan) && !istype(signal.data_file, /datum/computer/file/electronics_bundle)))
		return
	//If we get a database file, check that we just booted and that the file was made for us
	//And also that we haven't already digested a database
	var/datum/computer/file/electronics_bundle/rkitFile = signal.data_file
	if (istype(rkitFile) && !data_initialized && !isnull(boot_time) && rkitFile.target == src.net_id)
		var/datum/mechanic_controller/originalData = rkitFile.ruckData
		src.known_rucks = rkitFile.known_rucks
		known_rucks |= target
		data_initialized = TRUE
		SPAWN_DBG(0.5 SECONDS)
			var/datum/signal/newsignal = get_free_signal()
			newsignal.source = src
			newsignal.transmission_method = TRANSMISSION_RADIO
			newsignal.data["command"] = "SYNCREPLY"
			newsignal.data["address_1"] = "TRANSRKIT"
			newsignal.data["sender"] = src.net_id
			radio_connection.post_signal(src, newsignal)
		if(world.time - boot_time <= 3 SECONDS)
			for (var/datum/electronics/scanned_item/O in originalData.scanned_items)
				ruck_controls.scan_in(O.name, O.item_type, O.mats, O.locked) //Copy the database on digest so we never waste the effort
			updateDialog()
			return

		return

	else if(istype(rkitFile))
		return

	//And then process blueprint files
	//Scan them in if we haven't seen them before
	//UPLOAD is the internal command and doesn't generate PDA messages
	//add is sent by PDA scanners and does generate messages
	var/datum/computer/file/electronics_scan/scanFile = signal.data_file

	for(var/datum/electronics/scanned_item/O in ruck_controls.scanned_items)
		if(scanFile.scannedPath == O.item_type)
			if (command == "UPLOAD" || src.net_id != host_ruck) //Don't send a failure message if the it's an internal transfer("UPLOAD" command)
				//And don't send a message if we're not the host
				return //But we already had that blueprint, so we do leave

			pda_message(target, "Notice: Item already in database.")

			return
	var/strippedName = scanFile.scannedName
	ruck_controls.scan_in(strippedName, scanFile.scannedPath, scanFile.scannedMats)
	updateDialog()

	if(src.net_id != host_ruck || command != "add") //Only the host sends PDA messages, and we don't send them for internal transfer
		return

	pda_message(target, "Notice: Item entered into database.")

/obj/machinery/rkit/receive_signal(datum/signal/signal)
	if(status & NOPOWER)
		return

	if(!signal || !signal.data["sender"] || isnull(boot_time))
		return

	var/target = signal.data["sender"]
	var/command = signal.data["command"]

	//LOCK can come in encrypted
	if(signal.data["address_1"] == "TRANSRKIT" && signal.data["acc_code"] == netpass_heads && !isnull(signal.data["DATA"]) && !isnull(signal.data["LOCK"]))
		var/targetitem = signal.data["DATA"]
		var/targetlock = signal.data["LOCK"]
		if (istext(targetlock))
			targetlock = text2num(targetlock)

		for(var/datum/electronics/scanned_item/O in ruck_controls.scanned_items)
			if (targetitem == O.name)
				O.locked = targetlock
				updateDialog()
		return

	if(signal.encryption)
		return


	if((signal.data["address_1"] == "ping") && target)
		SPAWN_DBG(0.5 SECONDS)	//Send a reply for those curious jerks
								//Any replies in receive signal need a delay
			var/datum/signal/newsignal = get_free_signal()
			newsignal.source = src
			newsignal.transmission_method = TRANSMISSION_RADIO
			newsignal.data["command"] = "ping_reply"
			newsignal.data["device"] = "NET_RKANALZYER"
			newsignal.data["netid"] = src.net_id
			newsignal.data["address_1"] = target
			newsignal.data["sender"] = src.net_id
			radio_connection.post_signal(src, newsignal)

		return

	//Signals that take TRANSRKIT or the net_id
	if (signal.data["address_1"] == "TRANSRKIT" || signal.data["address_1"] == src.net_id)
		if (!isnull(signal.data_file))
			process_upload(signal)
			return
	else
		//Didn't match either, we're done here
		return

	//Signals that take TRANSRKIT
	if(signal.data["address_1"] == "TRANSRKIT")

		if(command == "SYNCREPLY" && target)
			if (target > host_ruck) //pick the highest net_id
				host_ruck = target
				//Wait we're done here?
				return


		//Set the host ruck to the highest net_id we see, and if it's a DROP command, don't save that net_id
		if((command == "SYNC" || command == "DROP") && target)

			if(length(ruck_controls.scanned_items) && src.net_id == host_ruck && !(target in known_rucks))
				//If we have a database of items, and we're the host, and we see a new ruck
				//Upload our database to it
				transfer_database(target)
				return

			known_rucks |= target
			//Got a sync time to reset this to ourselves
			host_ruck = src.net_id //We're the master!
			if (target > host_ruck && command == "SYNC") //Unless they are
				host_ruck = target

			SPAWN_DBG(0.5 SECONDS)
				var/datum/signal/newsignal = get_free_signal()
				newsignal.source = src
				newsignal.transmission_method = TRANSMISSION_RADIO
				newsignal.data["command"] = "SYNCREPLY"
				newsignal.data["address_1"] = "TRANSRKIT"
				newsignal.data["sender"] = src.net_id
				radio_connection.post_signal(src, newsignal)

			return
	//And anything down here runs if addressed by only net_id

	//I have no idea why anyone would want blueprint files
	//But I love making packets cryptic
	//Oh okay we have a distributed network now, THAT'S what this is for
	if(command == "DOWNLOAD" && target && !isnull(signal.data["data"]))
		var/targetitem = signal.data["data"]
		for(var/datum/electronics/scanned_item/O in ruck_controls.scanned_items)
			if (targetitem == O.name)
				upload_blueprint(O, target)

/obj/machinery/rkit/attackby(obj/item/W as obj, mob/user as mob)
	if(status & (NOPOWER|BROKEN))
		return

	if(istype(W,/obj/item/electronics/scanner))
		var/obj/item/electronics/scanner/S = W
		var/add_count = 0
		var/match_check = 1
		for(var/X in S.scanned)
			match_check = 0
			for(var/datum/electronics/scanned_item/O in ruck_controls.scanned_items)
				if(X == O.item_type)
					S.scanned -= X
					match_check = 1
					break
			if (!match_check)
				var/obj/tempobj = new X (src)
				var/datum/electronics/scanned_item/O = ruck_controls.scan_in(tempobj.name,tempobj.type,tempobj.mats)
				if(O)
					upload_blueprint(O, "TRANSRKIT", 1)
					SPAWN_DBG(4 SECONDS)
						qdel(tempobj)
				S.scanned -= X
				add_count++
		if (add_count==  1)
			boutput(user, "<span class='notice'>[add_count] new items entered into kit.</span>")
			pda_message(null, "Notice: Item entered into database.")
		else if (add_count > 0)
			boutput(user, "<span class='notice'>[add_count] new items entered into kit.</span>")
			pda_message(null, "Notice: [add_count] new items entered into database.")
		else
			boutput(user, "<span class='alert'>No new items entered into kit.</span>")

	else
		..()

/obj/machinery/rkit/attack_hand(mob/user as mob)
	src.add_fingerprint(user)
	var/dat
	var/hide_allowed = src.allowed(usr)
	dat = "<b>Ruckingenur Kit</b><HR>"

	dat += "<b>Scanned Items:</b><br>"
	for(var/datum/electronics/scanned_item/S in ruck_controls.scanned_items)
		dat += "<u>[S.name]</u><small> "
		//dat += "<A href='byond://?src=\ref[src];op=\ref[S];tp=done'>Frame</A>"
		if (S.item_mats && src.olde)
			dat += " * <A href='byond://?src=\ref[src];op=\ref[S];tp=done'>Frame</A>"
		else if (S.blueprint)
			if(!S.locked || hide_allowed || src.olde)
				dat += " * <A href='byond://?src=\ref[src];op=\ref[S];tp=blueprint'>Blueprint</A>"
			else
				dat += " * Blueprint Disabled"
		if(hide_allowed)
			dat += " * <A href='byond://?src=\ref[src];op=\ref[S];tp=lock'>[S.locked ? "Locked" : "Unlocked"]</A>"
		dat += "</small><br>"
	dat += "<br>"

	dat += "<HR>"

	src.add_dialog(user)
	user.Browse("<HEAD><TITLE>Ruckingenur Kit Control Panel</TITLE></HEAD><TT>[dat]</TT>", "window=rkit")
	onclose(user, "rkit")

/obj/machinery/rkit/Topic(href, href_list)
	if (usr.stat)
		return
	if ((in_interact_range(src, usr) && istype(src.loc, /turf)) || (issilicon(usr)))
		src.add_dialog(usr)

		switch(href_list["tp"])

			if("done")
				if(href_list["op"])
					var/datum/electronics/scanned_item/O = locate(href_list["op"])
					if(istype(O,/datum/electronics/scanned_item/))
						var/obj/item/electronics/frame/F = new/obj/item/electronics/frame(src.loc)
						F.name = "[O.name]-frame"
						F.store_type = O.item_type
						F.needed_parts = O.item_mats

			if("blueprint")
				if(href_list["op"])
					if (src.no_print_spam && world.time < src.no_print_spam + 25)
						usr.show_text("[src] isn't done with the previous print job.", "red")
					else
						var/datum/electronics/scanned_item/O = locate(href_list["op"]) in ruck_controls.scanned_items
						if (istype(O.blueprint, /datum/manufacture/mechanics/))
							usr.show_text("Print job started...", "blue")
							var/datum/manufacture/mechanics/M = O.blueprint
							playsound(src.loc, 'sound/machines/printer_thermal.ogg', 25, 1)
							src.no_print_spam = world.time
							SPAWN_DBG(2.5 SECONDS)
								if (src)
									new /obj/item/paper/manufacturer_blueprint(src.loc, M)

			if("lock")
				if(href_list["op"])

					var/datum/electronics/scanned_item/O = locate(href_list["op"]) in ruck_controls.scanned_items
					O.locked = !O.locked
					for (var/datum/electronics/scanned_item/OP in ruck_controls.scanned_items) //Lock items with the same name, that's how LOCK works
						if(O.name == OP.name)
							OP.locked = O.locked
					updateDialog()
					var/datum/signal/newsignal = get_free_signal()
					newsignal.source = src
					newsignal.transmission_method = TRANSMISSION_RADIO
					newsignal.data["address_1"] = "TRANSRKIT"
					newsignal.data["acc_code"] = netpass_heads
					newsignal.data["LOCK"] = O.locked
					newsignal.data["DATA"] = O.name
					newsignal.data["sender"] = src.net_id
					newsignal.encryption = "ERR_12845_NT_SECURE_PACKET:"
					radio_connection.post_signal(src, newsignal)

	else
		usr.Browse(null, "window=rkit")
		src.remove_dialog(usr)
	return

/obj/item/deconstructor
	name = "deconstruction device"
	desc = "A device meant to facilitate the deconstruction of scannable machines."
	icon = 'icons/obj/items/device.dmi'
	icon_state = "deconstruction-saw"
	inhand_image_icon = 'icons/mob/inhand/hand_tools.dmi'
	item_state = "deconstruction-saw"
	force = 10
	throwforce = 4
	hitsound = 'sound/machines/chainsaw_green.ogg'
	hit_type = DAMAGE_CUT
	tool_flags = TOOL_SAWING
	w_class = W_CLASS_NORMAL
	value = 150

	proc/finish_decon(atom/target,mob/user)
		if (!isobj(target))
			return
		var/obj/O = target
		logTheThing("station", user, null, "deconstructs [target] in [user.loc.loc] ([showCoords(user.x, user.y, user.z)])")
		playsound(user.loc, 'sound/items/Deconstruct.ogg', 50, 1)
		user.visible_message("<B>[user.name]</B> deconstructs [target].")

		var/obj/item/electronics/frame/F = new(get_turf(target))
		F.name = "[target.name] frame"
		if(O.deconstruct_flags & DECON_DESTRUCT)
			F.store_type = O.type
			qdel(O)
		else
			F.deconstructed_thing = target
			O.set_loc(F)
		F.viewstat = 2
		F.secured = 2
		F.icon_state = "dbox_big"
		F.w_class = W_CLASS_BULKY

		elecflash(src,power=2)

		O.was_deconstructed_to_frame(user)

	MouseDrop_T(atom/target, mob/user)
		if (!isobj(target))
			return
		src.afterattack(target,user)
		..()

	afterattack(atom/target as mob|obj|turf|area, mob/user as mob)
		if (!isobj(target))
			return
		var/obj/O = target

		var/decon_complexity = O.build_deconstruction_buttons()
		if (!decon_complexity)
			boutput(user, "<span class='alert'>[target] cannot be deconstructed.</span>")
			if (O.deconstruct_flags & DECON_ACCESS)
				boutput(user, "<span class='alert'>[target] is under an access lock and must have its access requirements removed first.</span>")
			return

		if ((!O.allowed(user) || O.is_syndicate) && !(O.deconstruct_flags & DECON_BUILT))
			boutput(user, "<span class='alert'>You cannot deconstruct [target] without sufficient access to operate it.</span>")
			return

		if(locate(/mob/living) in O)
			boutput(user, "<span class='alert'>You cannot deconstruct [target] while someone is inside it!</span>")
			return

		if (isrestrictedz(O.z) && !isitem(target))
			boutput(user, "<span class='alert'>You cannot bring yourself to deconstruct [target] in this area.</span>")
			return

		if (O.decon_contexts && O.decon_contexts.len <= 0) //ready!!!
			boutput(user, "Deconstructing [O], please remain still...")
			playsound(user.loc, 'sound/effects/pop.ogg', 50, 1)
			actions.start(new/datum/action/bar/icon/deconstruct_obj(target,src,(decon_complexity * 2.5 SECONDS)), user)
		else
			user.showContextActions(O.decon_contexts, O)
			boutput(user, "<span class='alert'>You need to use some tools on [target] before it can be deconstructed.</span>")
			return

/obj/var/list/decon_contexts = null

/obj/disposing()
	if (src.decon_contexts)
		for(var/datum/contextAction/C in src.decon_contexts)
			C.dispose()
	..()

/obj/proc/was_deconstructed_to_frame(mob/user)
	.= 0

/obj/proc/was_built_from_frame(mob/user, newly_built)
	.= 0

/obj/proc/build_deconstruction_buttons()
	.= 0

	if (deconstruct_flags & DECON_ACCESS)
		if (src.has_access_requirements())
			return

	if (deconstruct_flags)
		.= 1

		if (src.decon_contexts != null)	//dont need rebuild
			return

		src.decon_contexts = list() //empty list would mean we are ready for deconstruction. otherwise you need to clear contexts by tool usage

		if (deconstruct_flags & DECON_SCREWDRIVER)
			var/datum/contextAction/deconstruction/screw/newcon = new
			decon_contexts += newcon
		if (deconstruct_flags & DECON_WRENCH)
			var/datum/contextAction/deconstruction/wrench/newcon = new
			decon_contexts += newcon
		if (deconstruct_flags & DECON_CROWBAR)
			var/datum/contextAction/deconstruction/pry/newcon = new
			decon_contexts += newcon
		if (deconstruct_flags & DECON_WELDER)
			var/datum/contextAction/deconstruction/weld/newcon = new
			decon_contexts += newcon
		if (deconstruct_flags & DECON_WIRECUTTERS)
			var/datum/contextAction/deconstruction/cut/newcon = new
			decon_contexts += newcon
		if (deconstruct_flags & DECON_MULTITOOL)
			var/datum/contextAction/deconstruction/pulse/newcon = new
			decon_contexts += newcon

		.+= length(decon_contexts)


/datum/action/bar/icon/deconstruct_obj
	duration = 20
	interrupt_flags = INTERRUPT_MOVE | INTERRUPT_ACT | INTERRUPT_STUNNED | INTERRUPT_ACTION
	id = "deconstruct_obj"
	icon_state = "decon"
	var/obj/O
	var/obj/item/deconstructor/D
	New(Obj, Decon, ExtraTime)
		O = Obj
		D = Decon
		duration += ExtraTime
		..()

	onUpdate()
		..()
		if(get_dist(owner, O) > 1 || O == null || owner == null || D == null || locate(/mob/living) in O)
			interrupt(INTERRUPT_ALWAYS)
			return

	onStart()
		..()
		if(get_dist(owner, O) > 1 || O == null || owner == null || D == null || locate(/mob/living) in O)
			interrupt(INTERRUPT_ALWAYS)
			return

	onEnd()
		..()
		if(get_dist(owner, O) > 1 || O == null || owner == null || D == null || locate(/mob/living) in O)
			interrupt(INTERRUPT_ALWAYS)
			return
		if (ismob(owner))
			var/mob/M = owner
			if (!(D in M.equipped_list()))
				interrupt(INTERRUPT_ALWAYS)
				return
		D.finish_decon(O,owner)

	onInterrupt()
		if (O && owner)
			boutput(owner, "<span class='alert'>Deconstruction of [O] interrupted!</span>")
		..()

/obj/item/deconstructor/borg
	name = "deconstruction device"
	desc = "A device meant to facilitate the deconstruction of scannable machines. This one has been modified for safe use by borgs."
	icon = 'icons/obj/items/device.dmi'
	icon_state = "deconstruction"
	force = 0
	throwforce = 0
	hitsound = 'sound/impact_sounds/Generic_Hit_1.ogg'
	hit_type = DAMAGE_BLUNT
	tool_flags = 0
	w_class = W_CLASS_NORMAL
	value = -9999 //bug
