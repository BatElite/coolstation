var/list/prefab_shuttles = list()
/datum/prefab_shuttle
	var/prefab_path = null
	var/landmark = null

	proc/inialize_prefabs()
		switch(map_settings.escape_centcom)
			if(/area/shuttle/escape/centcom/cogmap)
				for(var/prefab_type in concrete_typesof(/datum/prefab_shuttle/cog1))
					var/datum/prefab_shuttle/D = new prefab_type()
					prefab_shuttles.Add(D)
			if(/area/shuttle/escape/centcom/cogmap2)
				for(var/prefab_type in concrete_typesof(/datum/prefab_shuttle/cog2))
					var/datum/prefab_shuttle/D = new prefab_type()
					prefab_shuttles.Add(D)
			if(/area/shuttle/escape/centcom/sealab)
				for(var/prefab_type in concrete_typesof(/datum/prefab_shuttle/sealab))
					var/datum/prefab_shuttle/D = new prefab_type()
					prefab_shuttles.Add(D)
			if(/area/shuttle/escape/centcom/donut2)
				for(var/prefab_type in concrete_typesof(/datum/prefab_shuttle/donut2))
					var/datum/prefab_shuttle/D = new prefab_type()
					prefab_shuttles.Add(D)
			if(/area/shuttle/escape/centcom/donut3)
				for(var/prefab_type in concrete_typesof(/datum/prefab_shuttle/donut3))
					var/datum/prefab_shuttle/D = new prefab_type()
					prefab_shuttles.Add(D)
			if(/area/shuttle/escape/centcom/destiny)
				for(var/prefab_type in concrete_typesof(/datum/prefab_shuttle/destiny))
					var/datum/prefab_shuttle/D = new prefab_type()
					prefab_shuttles.Add(D)
			else
				return

/datum/prefab_shuttle/cog1
	prefab_path = "assets/maps/escape_shuttles/cog1/cog1_default.dmm"
	landmark = LANDMARK_SHUTTLE_COG1

	dojo
		prefab_path = "assets/maps/escape_shuttles/cog1/cog1-dojo.dmm"
	dream
		prefab_path = "assets/maps/escape_shuttles/cog1/cog1-dream.dmm"
	iomoon
		prefab_path = "assets/maps/escape_shuttles/cog1/cog1-iomoon.dmm"
	martian
		prefab_path = "assets/maps/escape_shuttles/cog1/cog1-martian.dmm"
	syndicate
		prefab_path = "assets/maps/escape_shuttles/cog1/cog1-syndicate.dmm"
	zen
		prefab_path = "assets/maps/escape_shuttles/cog1/cog1-zenshuttle.dmm"
	disaster
		prefab_path = "assets/maps/escape_shuttles/cog1/cog1-disaster.dmm"
	royal
		prefab_path = "assets/maps/escape_shuttles/cog1/cog1-royal.dmm"

/datum/prefab_shuttle/cog2
	prefab_path = "assets/maps/escape_shuttles/cog2/cog2_default.dmm"
	landmark = LANDMARK_SHUTTLE_COG2

	martian
		prefab_path = "assets/maps/escape_shuttles/cog2/cog2_martian.dmm"
	disaster
		prefab_path = "assets/maps/escape_shuttles/cog2/cog2-disaster.dmm"
	royal
		prefab_path = "assets/maps/escape_shuttles/cog2/cog2-royal.dmm"

/datum/prefab_shuttle/sealab
	prefab_path = "assets/maps/escape_shuttles/sealab/oshan_default.dmm"
	landmark = LANDMARK_SHUTTLE_SEALAB

	meat
		prefab_path = "assets/maps/escape_shuttles/sealab/oshan-meat.dmm"
	minisubs
		prefab_path = "assets/maps/escape_shuttles/sealab/oshan-minisubs.dmm"
	disaster
		prefab_path = "assets/maps/escape_shuttles/sealab/oshan-disaster.dmm"
	royal
		prefab_path = "assets/maps/escape_shuttles/sealab/oshan-royal.dmm"

/datum/prefab_shuttle/donut2
	prefab_path = "assets/maps/escape_shuttles/donut2/donut2_default.dmm"
	landmark = LANDMARK_SHUTTLE_DONUT2

	disaster
		prefab_path = "assets/maps/escape_shuttles/donut2/donut2_disaster.dmm"
	syndicate
		prefab_path =  "assets/maps/escape_shuttles/donut2/donut2_syndicate.dmm"
	royal
		prefab_path =  "assets/maps/escape_shuttles/donut2/donut2_royal.dmm"

/datum/prefab_shuttle/donut3
	prefab_path = "assets/maps/escape_shuttles/donut3/donut3_default.dmm"
	landmark = LANDMARK_SHUTTLE_DONUT3

	cave
		prefab_path = "assets/maps/escape_shuttles/donut3/donut3-cave.dmm"
	disaster
		prefab_path = "assets/maps/escape_shuttles/donut3/donut3-disaster.dmm"
	royal
		prefab_path = "assets/maps/escape_shuttles/donut3/donut3-royal.dmm"

/datum/prefab_shuttle/destiny
	prefab_path = "assets/maps/escape_shuttles/destiny/destiny_default.dmm"
	landmark = LANDMARK_SHUTTLE_DESTINY

	disaster
		prefab_path = "assets/maps/escape_shuttles/destiny/destiny_disaster.dmm"
	royal
		prefab_path = "assets/maps/escape_shuttles/destiny/destiny_royal.dmm"
