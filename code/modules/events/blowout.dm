/datum/random_event/major/blowout
	name = "Radioactive Blowout"
	required_elapsed_round_time = 40 MINUTES
	var/space_color = "#ff4646"
#ifdef DESERT_MAP
	disabled = TRUE
#endif

	event_effect() //Mirror changes to blowout_gehenna where applicable. I made that separate cause the alternative was making this proc unreadable with #ifndefs
		..()
		var/timetoreachsec = rand(1,9)
		var/timetoreach = rand(30,60)
		var/actualtime = timetoreach * 10 + timetoreachsec

		for (var/mob/M in mobs)
			M.flash(3 SECONDS)
		var/sound/siren = sound('sound/misc/airraid_loop_short.ogg')
		siren.repeat = TRUE
		siren.channel = 5
		siren.volume = 50 // wire note: lets not deafen players with an air raid siren
		world << siren
		command_alert("Extreme levels of radiation detected approaching the [station_or_ship()]. All personnel have [timetoreach].[timetoreachsec] seconds to enter a maintenance tunnel or radiation safezone. Maintenance doors have temporarily had their access requirements removed. This is not a test.", "Anomaly Alert")

		var/datum/directed_broadcast/emergency/broadcast = new(station_name, "Radiation Storm", "[timetoreach] Seconds", "Seek shelter in maintenance corridors immediately. Interlocks have been released.")
		broadcast_controls.broadcast_start(broadcast, TRUE, -1, 1)

		SPAWN_DBG(0)
			for_by_tcl(A, /obj/machinery/door/airlock)
				LAGCHECK(LAG_LOW)
				if (A.z != Z_LEVEL_STATION)
					continue
				if (!(istype(A, /obj/machinery/door/airlock/maintenance) || istype(A, /obj/machinery/door/airlock/pyro/maintenance) || istype(A, /obj/machinery/door/airlock/gannets/maintenance) || istype(A, /obj/machinery/door/airlock/gannets/glass/maintenance)))
					continue
				if (access_maint_tunnels in A.req_access)
					A.req_access = null

			sleep(actualtime)

			for (var/area/A in world)
				LAGCHECK(LAG_LOW)
				if (A.z != Z_LEVEL_STATION)
					continue
				if (A.do_not_irradiate)
					continue
				else
					if (!A.irradiated)
						A.irradiated = TRUE
						A.icon_state = "blowout"
					for (var/turf/T in A.turfs)
						if (rand(0,1000) < 5 && istype(T,/turf/floor))
							Artifact_Spawn(T)

			siren.repeat = FALSE
			siren.channel = 5
			siren.volume = 50

			for (var/mob/N in mobs)
				N.flash(3 SECONDS)

	#ifndef UNDERWATER_MAP
			for (var/turf/space/S in block(locate(1, 1, Z_LEVEL_STATION), locate(world.maxx, world.maxy, Z_LEVEL_STATION)))
				LAGCHECK(LAG_LOW)
				S.color = src.space_color
	#endif

			world << siren

			sleep(0.4 SECONDS)

			blowout = TRUE

			var/sound/blowoutsound = sound('sound/misc/blowout.ogg')
			blowoutsound.repeat = 0
			blowoutsound.channel = 5
			blowoutsound.volume  = 20
			world << blowoutsound
			boutput(world, "<span class='alert'><B>WARNING</B>: Mass radiation has struck [station_name(1)]. Do not leave safety until all radiation alerts have been cleared.</span>")

			for (var/mob/M in mobs)
				SPAWN_DBG(0)
					shake_camera(M, 400, 16)

			sleep(rand(1.5 MINUTES,2 MINUTES)) // drsingh lowered these by popular request.
			command_alert("Radiation levels lowering [station_or_ship()]wide. ETA 60 seconds until all areas are safe.", "Anomaly Alert")

			sleep(rand(25 SECONDS,50 SECONDS)) // drsingh lowered these by popular request

			for (var/area/A in world)
				LAGCHECK(LAG_LOW)
				if (A.z != Z_LEVEL_STATION)
					continue
				if (!A.permarads)
					A.irradiated = FALSE
				A.icon_state = null
			blowout = FALSE

			broadcast_controls.broadcast_stop(broadcast)
			qdel(broadcast)

			command_alert("All radiation alerts onboard [station_name(1)] have been cleared. You may now leave the tunnels freely. Maintenance doors will regain their normal access requirements shortly.", "All Clear")

	#ifndef UNDERWATER_MAP
			for (var/turf/space/S in block(locate(1, 1, Z_LEVEL_STATION), locate(world.maxx, world.maxy, Z_LEVEL_STATION)))
				LAGCHECK(LAG_LOW)
				S.color = null
	#endif
			for (var/mob/N in mobs)
				N.flash(3 SECONDS)

			sleep(rand(25 SECONDS,50 SECONDS))

			for_by_tcl(A, /obj/machinery/door/airlock)
				if (A.z != Z_LEVEL_STATION)
					continue
				if (!(istype(A, /obj/machinery/door/airlock/maintenance) || istype(A, /obj/machinery/door/airlock/pyro/maintenance) || istype(A, /obj/machinery/door/airlock/gannets/maintenance) || istype(A, /obj/machinery/door/airlock/gannets/glass/maintenance)))
					continue
				if (access_maint_tunnels in initial(A.req_access))
					A.req_access = list(access_maint_tunnels)
