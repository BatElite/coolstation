/obj/machinery/computer/card
	name = "identification computer"
	icon_state = "id"
	circuit_type = /obj/item/circuitboard/card
	var/obj/item/card/id/scan = null
	var/obj/item/card/id/modify = null
	var/obj/item/eject = null //Overrides modify slot set_loc. sometimes we want to eject something that's not a card. like an implant!
	var/authenticated = 0.0
	var/mode = 0.0
	var/printing = null
	var/list/scan_access = null
	var/list/custom_names = list("Custom 1", "Custom 2", "Custom 3")
	var/custom_access_list = list(list(),list(),list())
	var/list/civilian_access_list = list(access_morgue, access_maint_tunnels, access_chapel_office, access_tech_storage, access_bar, access_janitor, access_crematorium, access_kitchen, access_hydro, access_ranch)
	var/list/engineering_access_list = list(access_external_airlocks, access_construction, access_engineering, access_engineering_storage, access_engineering_power, access_engineering_engine, access_engineering_mechanic, access_engineering_atmos, access_engineering_control)
	var/list/supply_access_list = list(access_hangar, access_cargo, access_supply_console, access_mining, access_mining_shuttle, access_mining_outpost, access_scrapping)
	var/list/research_access_list = list(access_medical, access_tox, access_tox_storage, access_medlab, access_medical_lockers, access_research, access_robotics, access_chemistry, access_pathology, access_dwaine_superuser)
	var/list/security_access_list = list(access_security, access_brig, access_forensics_lockers, access_maxsec, access_securitylockers, access_carrypermit, access_contrabandpermit)
	var/list/command_access_list = list(access_research_director, access_emergency_storage, access_change_ids, access_ai_upload, access_teleporter, access_eva, access_heads, access_captain, access_engineering_chief, access_medical_director, access_head_of_personnel, access_ghostdrone)
	//associating command office accesses with respective lockers
	var/list/command_locker_access_list
	var/list/allowed_access_list
	req_access = list(access_change_ids)
	desc = "A computer that allows an authorized user to change the identification of other ID cards."

	deconstruct_flags = DECON_MULTITOOL
	light_r =0.7
	light_g = 1
	light_b = 0.1

/obj/machinery/computer/card/New()
	..()
	src.allowed_access_list = civilian_access_list + engineering_access_list + supply_access_list + research_access_list + command_access_list + security_access_list - access_maxsec
	src.command_locker_access_list = list("[access_research_director]" = access_research_director_locker, "[access_engineering_chief]" = access_chief_engineer_locker, "[access_medical_director]" = access_medical_director_locker, "[access_head_of_personnel]" = access_head_of_personnel_locker, "[access_quartermaster]" = access_quartermaster_locker)

/obj/machinery/computer/card/console_upper
	icon = 'icons/obj/machines/computerpanel.dmi'
	icon_state = "id1"
/obj/machinery/computer/card/console_lower
	icon = 'icons/obj/machines/computerpanel.dmi'
	icon_state = "id2"

/obj/machinery/computer/card/attack_hand(var/mob/user as mob)
	if(..())
		return

	src.add_dialog(user)
	var/dat
	if (!( ticker ))
		return
	if (src.mode) // accessing crew manifest
		var/crew = ""
		for(var/datum/data/record/t in data_core.general)
			crew += "[t.fields["name"]] - [t.fields["rank"]]<br>"
		dat = "<tt><b>Crew Manifest:</b><br>Please use security record computer to modify entries.<br>[crew]<a href='byond://?src=\ref[src];print=1'>Print</a><br><br><a href='byond://?src=\ref[src];mode=0'>Access ID modification console.</a><br></tt>"
	else
		var/header = "<b>Identification Card Modifier</b><br><i>Please insert the cards into the slots</i><br>"

		var/target_name
		var/target_owner
		var/target_rank

		if(src.modify)
			target_name = src.modify.name
		else
			target_name = "--------"
		if(src.modify && src.modify.registered)
			target_owner = src.modify.registered
		else
			target_owner = "--------"
		if(src.modify && src.modify.assignment)
			target_rank = src.modify.assignment
		else
			target_rank = "Unassigned"
		if (src.eject)
			target_name = src.eject.name

		header += "Target: <a href='byond://?src=\ref[src];modify=1'>[target_name]</a><br>"

		var/scan_name
		if(src.scan)
			scan_name = src.scan.name
		else
			scan_name = "--------"
		header += "Confirm Identity: <a href='byond://?src=\ref[src];scan=1'>[scan_name]</a><br>"
		header += "<hr>"

		var/body = list()
		//When both IDs are inserted
		if (src.authenticated && src.modify)
			body += "Registered: <a href='byond://?src=\ref[src];reg=1'>[target_owner]</a><br>"
			body += "Assignment: <a href='byond://?src=\ref[src];assign=Custom Assignment'>[replacetext(target_rank, " ", "&nbsp")]</a><br>"
			body += "PIN: <a href='byond://?src=\ref[src];pin=1'>****</a>"

			//Jobs organised into sections
			var/list/civilianjobs = list("Staff Assistant", "Bartender", "Chef", "Botanist", "Rancher", "Chaplain", "Janitor", "Clown")
			var/list/maintainencejobs = list("Engineer", "Mechanic", "Miner", "Quartermaster", "Cargo Technician","Scrapper") //QM move to head...
			var/list/researchjobs = list("Scientist", "Chemist", "Medical Doctor", "Geneticist", "Roboticist", "Pathologist", "Surgeon", "Nurse", "Receptionist")
			var/list/securityjobs = list("Security Officer", "Security Assistant", "Detective")
			var/list/commandjobs = list("Head of Personnel", "Chief Engineer", "Research Director", "Medical Director", "Captain")

			body += "<br><br><u>Jobs</u>"
			body += "<br>Civilian:"
			for(var/job in civilianjobs)
				body += " <a href='byond://?src=\ref[src];assign=[job];colour=blue'>[replacetext(job, " ", "&nbsp")]</a>" //make sure there isn't a line break in the middle of a job

			body += "<br>Supply and Maintainence:"
			for(var/job in maintainencejobs)
				body += " <a href='byond://?src=\ref[src];assign=[job];colour=yellow'>[replacetext(job, " ", "&nbsp")]</a>"

			body += "<br>Research and Medical:"
			for(var/job in researchjobs)
				body += " <a href='byond://?src=\ref[src];assign=[job];colour=purple'>[replacetext(job, " ", "&nbsp")]</a>"

			body += "<br>Security:"
			for(var/job in securityjobs)
				body += " <a href='byond://?src=\ref[src];assign=[job];colour=red'>[replacetext(job, " ", "&nbsp")]</a>"

			body += "<br>Command:"
			for(var/job in commandjobs)
				body += " <a href='byond://?src=\ref[src];assign=[job];colour=green'>[replacetext(job, " ", "&nbsp")]</a>"

			body += "<br>Custom:"
			for (var/i = 1, i <= custom_names.len, i++)
				body += " [src.custom_names[i]] <a href='byond://?src=\ref[src];save=[i]'>save</a> <a href='byond://?src=\ref[src];apply=[i]'>apply</a>"

			//Change access to individual areas
			body += "<br><br><u>Access</u>"

			//Organised into sections
			var/civilian_access = list("<br>Staff:")
			var/engineering_access = list("<br>Engineering:")
			var/supply_access = list("<br>Supply:")
			var/research_access = list("<br>Science and Medical:")
			var/security_access = list("<br>Security:")
			var/command_access = list("<br>Command:")

			for(var/A in access_name_lookup)
				if(access_name_lookup[A] in src.modify.access)
					//Click these to remove access
					if (access_name_lookup[A] in civilian_access_list)
						civilian_access += " <a href='byond://?src=\ref[src];access=[access_name_lookup[A]];allowed=0'><font color=\"red\">[replacetext(A, " ", "&nbsp")]</font></a>"
					if (access_name_lookup[A] in engineering_access_list)
						engineering_access += " <a href='byond://?src=\ref[src];access=[access_name_lookup[A]];allowed=0'><font color=\"red\">[replacetext(A, " ", "&nbsp")]</font></a>"
					if (access_name_lookup[A] in supply_access_list)
						supply_access += " <a href='byond://?src=\ref[src];access=[access_name_lookup[A]];allowed=0'><font color=\"red\">[replacetext(A, " ", "&nbsp")]</font></a>"
					if (access_name_lookup[A] in research_access_list)
						research_access += " <a href='byond://?src=\ref[src];access=[access_name_lookup[A]];allowed=0'><font color=\"red\">[replacetext(A, " ", "&nbsp")]</font></a>"
					if (access_name_lookup[A] in security_access_list)
						security_access += " <a href='byond://?src=\ref[src];access=[access_name_lookup[A]];allowed=0'><font color=\"red\">[replacetext(A, " ", "&nbsp")]</font></a>"
					if (access_name_lookup[A] in command_access_list)
						command_access += " <a href='byond://?src=\ref[src];access=[access_name_lookup[A]];allowed=0'><font color=\"red\">[replacetext(A, " ", "&nbsp")]</font></a>"
						if ("[access_name_lookup[A]]" in command_locker_access_list)
							var/access_num_locker = command_locker_access_list["[access_name_lookup[A]]"]
							if (access_num_locker in src.modify.access)
								command_access += "&nbsp<a href='byond://?src=\ref[src];access=[access_num_locker];allowed=0'><font color=\"red\"><i>(Locker)</i></font></a>"
							else
								command_access += "&nbsp<a href='byond://?src=\ref[src];access=[access_num_locker];allowed=1'><i>(Locker)</i></a>"

				else//Click these to add access
					if (access_name_lookup[A] in civilian_access_list)
						civilian_access += " <a href='byond://?src=\ref[src];access=[access_name_lookup[A]];allowed=1'>[replacetext(A, " ", "&nbsp")]</a>"
					if (access_name_lookup[A] in engineering_access_list)
						engineering_access += " <a href='byond://?src=\ref[src];access=[access_name_lookup[A]];allowed=1'>[replacetext(A, " ", "&nbsp")]</a>"
					if (access_name_lookup[A] in supply_access_list)
						supply_access += " <a href='byond://?src=\ref[src];access=[access_name_lookup[A]];allowed=1'>[replacetext(A, " ", "&nbsp")]</a>"
					if (access_name_lookup[A] in research_access_list)
						research_access += " <a href='byond://?src=\ref[src];access=[access_name_lookup[A]];allowed=1'>[replacetext(A, " ", "&nbsp")]</a>"
					if (access_name_lookup[A] in security_access_list)
						security_access += " <a href='byond://?src=\ref[src];access=[access_name_lookup[A]];allowed=1'>[replacetext(A, " ", "&nbsp")]</a>"
					if (access_name_lookup[A] in command_access_list)
						command_access += " <a href='byond://?src=\ref[src];access=[access_name_lookup[A]];allowed=1'>[replacetext(A, " ", "&nbsp")]</a>"
						if ("[access_name_lookup[A]]" in command_locker_access_list)
							var/access_num_locker = command_locker_access_list["[access_name_lookup[A]]"]
							if (access_num_locker in src.modify.access)
								command_access += "&nbsp<a href='byond://?src=\ref[src];access=[access_num_locker];allowed=0'><font color=\"red\"><i>(Locker)</i></font></a>"
							else
								command_access += "&nbsp<a href='byond://?src=\ref[src];access=[access_num_locker];allowed=1'><i>(Locker)</i></a>"

			body += "[jointext(civilian_access, "")]<br>[jointext(engineering_access, "")]<br>[jointext(supply_access, "")]<br>[jointext(research_access, "")]<br>[jointext(security_access, "")]<br>[jointext(command_access, "")]"

			body += "<br><br><u>Customise ID</u><br>"
			body += "<a href='byond://?src=\ref[src];colour=none'>Plain</a> "
			body += "<a href='byond://?src=\ref[src];colour=blue'>Civilian</a> "
			body += "<a href='byond://?src=\ref[src];colour=yellow'>Engineering</a> "
			body += "<a href='byond://?src=\ref[src];colour=purple'>Research</a> "
			body += "<a href='byond://?src=\ref[src];colour=red'>Security</a> "
			body += "<a href='byond://?src=\ref[src];colour=green'>Command</a>"

			user.unlock_medal("Identity Theft", 1)

		else
			body += "<a href='byond://?src=\ref[src];auth=1'>{Log in}</a>"
		body = jointext(body, "")
		dat = "<tt>[header][body]<hr><a href='byond://?src=\ref[src];mode=1'>Access Crew Manifest</a><br></tt>"
	user.Browse(dat, "window=id_com;size=725x500")
	onclose(user, "id_com")
	return

/obj/machinery/computer/card/Topic(href, href_list)
	if(..())
		return
	src.add_dialog(usr)
	if (href_list["modify"])
		if (src.modify)
			src.modify.update_name()
			if (src.eject)
				usr.put_in_hand_or_eject(src.eject)
				src.eject.pixel_y = 6
				src.eject = null
			else
				usr.put_in_hand_or_eject(src.modify)
				src.modify.pixel_y = 6
			src.modify = null
		else
			var/obj/item/I = usr.equipped()
			if (!istype(I,/obj/item/card/id))
				I = get_card_from(I)
			if (istype(I, /obj/item/card/id))
				usr.drop_item()
				if (src.eject)
					src.eject.set_loc(src)
				else
					I.set_loc(src)
				src.modify = I
			else if (istype(I, /obj/item/magtractor))
				var/obj/item/magtractor/mag = I
				if (istype(mag.holding, /obj/item/card/id))
					I = mag.holding
					mag.dropItem(0)
					if (src.eject)
						src.eject.set_loc(src)
					else
						I.set_loc(src)
					src.modify = I
			if (I && !src.modify)
				boutput(usr, "<span class='notice'>[I] won't fit in the modify slot.</span>")
		src.authenticated = 0
		src.scan_access = null
	if (href_list["scan"])
		if (src.scan)
			usr.put_in_hand_or_eject(src.scan)
			src.scan.pixel_y = -6
			src.scan = null
		else
			var/obj/item/I = usr.equipped()
			if (istype(I, /obj/item/card/id))
				usr.drop_item()
				I.set_loc(src)
				src.scan = I
			else if (istype(I, /obj/item/magtractor))
				var/obj/item/magtractor/mag = I
				if (istype(mag.holding, /obj/item/card/id))
					I = mag.holding
					mag.dropItem(0)
					I.set_loc(src)
					src.modify = I
			else
				boutput(usr, "<span class='notice'>[I] won't fit in the authentication slot.</span>")
		src.authenticated = 0
		src.scan_access = null
	if (href_list["auth"])
		if ((!( src.authenticated ) && (src.scan || ((issilicon(usr) || isAI(usr)) && !isghostdrone(usr))) && (src.modify || src.mode)))
			if (src.check_access(src.scan))
				src.authenticated = 1
				src.scan_access = src.scan.access
		else if ((!( src.authenticated ) && (issilicon(usr) || isAI(usr))) && (!src.modify))
			boutput(usr, "You can't modify an ID without an ID inserted to modify. Once one is in the modify slot on the computer, you can log in.")
	if(href_list["access"] && href_list["allowed"])
		if(src.authenticated)
			var/access_type = text2num(href_list["access"])
			var/access_allowed = text2num(href_list["allowed"])
			if(access_type in (get_all_accesses() + list(access_research_director_locker, access_chief_engineer_locker, access_medical_director_locker, access_head_of_personnel_locker, access_quartermaster_locker)))
				src.modify.access -= access_type
				if(access_allowed == 1)
					src.modify.access += access_type

	if (href_list["assign"])
		if (src.authenticated && src.modify)
			var/t1 = href_list["assign"]

			if(t1 == "Head of Security")
				return

			if (t1 == "Custom Assignment")
				t1 = input(usr, "Enter a custom job assignment.", "Assignment")
				t1 = strip_html(t1, 100, 1)
				playsound(src.loc, "keyboard", 50, 1, -15)
			else
				src.modify.access = get_access(t1)

			//Wire: This possibly happens after the input() above, so we re-do the initial checks
			if (src.authenticated && src.modify)
				src.modify.assignment = t1


	if (href_list["reg"])
		if (src.authenticated)
			var/t2 = src.modify

			var/t1 = input(usr, "What name?", "ID computer", null)
			t1 = strip_html(t1, 100, 1)

			if ((src.authenticated && src.modify == t2 && (in_interact_range(src, usr) || (issilicon(usr) || isAI(usr))) && istype(src.loc, /turf)))
				logTheThing("station", usr, null, "changes the registered name on the ID card from [src.modify.registered] to [t1]")
				src.modify.registered = t1

			playsound(src.loc, "keyboard", 50, 1, -15)

	if (href_list["pin"])
		if (src.authenticated)
			var/currentcard = src.modify

			var/newpin = input(usr, "Enter a new PIN.", "ID computer", 0) as null|num

			if ((src.authenticated && src.modify == currentcard && (in_interact_range(src, usr) || (istype(usr, /mob/living/silicon))) && istype(src.loc, /turf)))
				if(newpin < 1000)
					src.modify.pin = 1000
				else if(newpin > 9999)
					src.modify.pin = 9999
				else
					src.modify.pin = round(newpin)
				playsound(src.loc, "keyboard", 50, 1, -15)

	if (href_list["mode"])
		src.mode = text2num(href_list["mode"])
	if (href_list["print"])
		if (!( src.printing ))
			src.printing = 1
			sleep(5 SECONDS)
			var/obj/item/paper/P = new()
			P.set_loc(src.loc)

			var/t1 = "<B>Crew Manifest:</B><BR>"
			for(var/datum/data/record/t in data_core.general)
				t1 += "<B>[t.fields["name"]]</B> - [t.fields["rank"]]<BR>"
			P.info = t1
			P.name = "paper- 'Crew Manifest'"
			src.printing = null
	if (href_list["mode"])
		src.authenticated = 0
		src.scan_access = null
		src.mode = text2num(href_list["mode"])
	if (href_list["colour"])
		if(src.modify.keep_icon == FALSE) // ids that are FALSE will update their icon if the job changes
			var/newcolour = href_list["colour"]
			if (newcolour == "none")
				src.modify.icon_state = "id"
			if (newcolour == "blue")
				src.modify.icon_state = "id_civ"
			if (newcolour == "yellow")
				src.modify.icon_state = "id_eng"
			if (newcolour == "purple")
				src.modify.icon_state = "id_res"
			if (newcolour == "red")
				src.modify.icon_state = "id_sec"
			if (newcolour == "green")
				src.modify.icon_state = "id_com"
	if (href_list["save"])
		var/slot = text2num(href_list["save"])
		if (!src.modify.assignment)
			src.custom_names[slot] = "Custom [slot]"
		else
			src.custom_names[slot] = src.modify.assignment
		src.custom_access_list[slot] = src.modify.access.Copy()
		src.custom_access_list[slot] &= allowed_access_list //prevent saving non-allowed accesses
	if (href_list["apply"])
		var/slot = text2num(href_list["apply"])
		src.modify.assignment = src.custom_names[slot]
		var/list/selected_access_list = src.custom_access_list[slot]
		src.modify.access = selected_access_list.Copy()
	if (src.modify)
		src.modify.name = "[src.modify.registered]'s [src.modify.generic_name] ([src.modify.assignment])"
	if (src.eject)
		if (istype(src.eject,/obj/item/implantcase/access))
			var/obj/item/implantcase/access/A = src.eject
			var/obj/item/implant/access/I = A.imp
			var/iassign = "None"
			if (istype(I) && I.access)
				iassign = I.access.assignment
			A.name = "glass case - 'Electronic Access' ([iassign])"
		else if (istype(src.eject, /obj/item/implant/access))
			var/obj/item/implant/access/A = src.eject
			A.name = "electronic access implant ([A.access ? A.access.assignment : "None"])"
	src.updateUsrDialog()
	return

/obj/machinery/computer/card/attackby(obj/item/I as obj, mob/user as mob)
	//grab the ID card from an access implant if this is one
	var/modify_only = 0
	if (!istype(I,/obj/item/card/id))
		I = get_card_from(I)
		modify_only = 1

	if (modify_only && src.eject && !src.scan && src.modify)
		boutput(user, "<span class='notice'>[src.eject] will not work in the authentication card slot.</span>")
		return
	else if (istype(I, /obj/item/card/id))
		if ((!src.scan && !modify_only) && src.check_access(I)) //QOL do a simultaneous front-loaded auth check: if it won't work for auth, then insert it as a target card if the slot's open. ezpz
			boutput(user, "<span class='notice'>You insert [I] into the authentication card slot.</span>")
			user.drop_item()
			I.set_loc(src)
			src.scan = I
		else if (!src.modify)
			boutput(user, "<span class='notice'>You insert [src.eject ? src.eject : I] into the target card slot.</span>")
			user.drop_item()
			if (src.eject)
				src.eject.set_loc(src)
			else
				I.set_loc(src)
			src.modify = I
		src.updateUsrDialog()
		return
	else
		..()
	return

/obj/machinery/computer/card/proc/get_card_from(obj/item/I as obj)
	if (istype(I, /obj/item/implantcase/access))
		src.eject = I
		var/obj/item/implantcase/access/A = I
		if (A.imp)
			return A.imp:access
	else if (istype(I, /obj/item/implant/access)) //accept access implant - get their ID
		src.eject = I
		return I:access
	return I
