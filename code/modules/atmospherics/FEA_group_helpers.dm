/turf/proc/find_group()
	//Basically, join any nearby valid groups
	//	If more than one, pick one with most members at my borders
	// If can not find any but there was an ungrouped at border with me, call for group assembly

	var/turf/floor/north = get_step(src,NORTH)
	var/turf/floor/south = get_step(src,SOUTH)
	var/turf/floor/east = get_step(src,EAST)
	var/turf/floor/west = get_step(src,WEST)

	//Clear those we do not have access to
	if(!gas_cross(north) || !istype(north))
		north = null
	if(!gas_cross(south) || !istype(south))
		south = null
	if(!gas_cross(east) || !istype(east))
		east = null
	if(!gas_cross(west) || !istype(west))
		west = null

	var/new_group_possible = 0

	var/north_votes = 0
	var/south_votes = 0
	var/east_votes = 0

	if(north)
		if(north.parent)
			north_votes = 1

			if(south && (south.parent == north.parent))
				north_votes++
				south = null

			if(east && (east.parent == north.parent))
				north_votes++
				east = null

			if(west && (west.parent == north.parent))
				north_votes++
				west = null
		else
			new_group_possible = 1

	if(south)
		if(south.parent)
			south_votes = 1

			if(east && (east.parent == south.parent))
				south_votes++
				east = null

			if(west && (west.parent == south.parent))
				south_votes++
				west = null
		else
			new_group_possible = 1

	if(east)
		if(east.parent)
			east_votes = 1

			if(west && (west.parent == east.parent))
				east_votes++
				west = null
		else
			new_group_possible = 1

//	boutput(world, "[north_votes], [south_votes], [east_votes]")

	if(west)
		if(west.parent)
			if(west.parent.group_processing)
				west.parent.suspend_group_processing()
			west.parent.members += src
			parent = west.parent

			air_master.tiles_to_update |= west.parent.members
			return 1

		else
			new_group_possible = 1

	if(north_votes && (north_votes >= south_votes) && (north_votes >= east_votes))
		if(north.parent.group_processing)
			north.parent.suspend_group_processing()
		north.parent.members += src
		parent = north.parent

		air_master.tiles_to_update |= north.parent.members
		return 1


	if(south_votes  && (south_votes >= east_votes))
		if(south.parent.group_processing)
			south.parent.suspend_group_processing()
		south.parent.members += src
		parent = south.parent

		air_master.tiles_to_update |= south.parent.members
		return 1

	if(east_votes)
		if(east.parent.group_processing)
			east.parent.suspend_group_processing()
		east.parent.members += src
		parent = east.parent

		air_master.tiles_to_update |= east.parent.members
		return 1

	if(new_group_possible)
		air_master.assemble_group_turf(src)
		return 1

	else
		air_master.active_singletons += src
		return 1
