#define childrentypesof(x) (typesof(x) - x)
// consider declaring the base type abstract instead and using concrete_typesof instead of childrentypesof

#define ABSTRACT_TYPE(type) /datum/_is_abstract ## type
#define IS_ABSTRACT(type) text2path("/datum/_is_abstract[type]")
/*
usage:

ABSTRACT_TYPE(/datum/test)
/datum/test
/datum/test/child

then you can do:
for(var/type in typesof(/datum/test))
	if(IS_ABSTRACT(type))
		continue
	do_stuff_with_type(type)

Useful for parent types you don't want to be instantiated in places that use istype like this
Note that the ABSTRACT_TYPE annotation *WILL* mark all predecesors of the type abstract too!
That is a feature, not a bug.

Turn on ABSTRACT_VIOLATION_CRASH or ABSTRACT_VIOLATION_WARN to get the server to yell at you
when you instantiate an abstract type. CRASH will runtime, WARN will log it. Don't turn it on
*permanently* on the live server (though turning it on once in a while is probably fine to see
if there are any violations).
*/

#ifdef ABSTRACT_VIOLATION_CRASH
/datum/New()
	..()
	if(IS_ABSTRACT(src.type))
		CRASH("Attempt to instantiate abstract type '[src.type]'.")
#elif defined(ABSTRACT_VIOLATION_WARN)
/datum/New()
	..()
	if(IS_ABSTRACT(src.type))
		logTheThing("debug", src, null, "Attempt to instantiate abstract type '[src.type]'.")
#endif

var/global/list/cached_concrete_types

/**
	* typesof() but only for concrete (not abstract) types,
	* it caches the result so you don't need to worry about doing that manually
	* so subsequent calls on the same type will be very fast.
	*
	* just don't modify the result of the call directly
	* OKAY: `var/list/hats = concrete_typesof(/obj/item/clothing/head) - /obj/item/clothing/head/hosberet`
	*
	* ALSO OKAY:
	* ```dm
	* var/list/hats = concrete_typesof(/obj/item/clothing/head).Copy()
	* hats -= /obj/item/clothing/head/hosberet
	* ```
	*
	* NOT OKAY:
	* ```dm
	* var/list/hats = concrete_typesof(/obj/item/clothing/head)
	* hats -= /obj/item/clothing/head/hosberet
	* ```
	*/
proc/concrete_typesof(type, cache=TRUE)
	if(isnull(cached_concrete_types))
		cached_concrete_types = list()
	if(type in cached_concrete_types)
		return cached_concrete_types[type]
	. = list()
	for(var/subtype in typesof(type))
		if(!IS_ABSTRACT(subtype))
			. += subtype
	if(cache)
		cached_concrete_types[type] = .

//fucked up but if you use abstracts as categories this might be helpful (or not)
//is this dumb? probably. if it is tell me so i can not do it ok thansk

var/global/list/cached_abstract_types

proc/abstract_typesof(type, cache=TRUE)
	if(isnull(cached_abstract_types))
		cached_abstract_types = list()
	if(type in cached_abstract_types)
		return cached_abstract_types[type]
	. = list()
	for(var/subtype in typesof(type))
		if(IS_ABSTRACT(subtype))
			. += subtype
	if(cache)
		cached_abstract_types[type] = .

var/global/list/cached_filtered_types

/**
	* The same thing but now you can filter the types using a proc. Also cached.
	* The filter proc takes a type and should return 1 if we want to include it and 0 otherwise.
	* That proc should also be pure (always return the same thing for the same arguments) because of the caching.
	* If you want to use non-pure proc do the filtering manually yourself and don't use this.
	* Note that the first call to filtered_concrete_typesof with a given type and filter will be (possibly a lot)
	* *slower* than doing it manually. The benefit of this proc only shows itself for future calls which are
	* very fast due to caching.
	*
	* Example:
	* ```
	* proc/filter_is_syndicate(type)
	* 	var/obj/fake_instance = type
	* 	return initial(fake_instance.is_syndicate)
	*
	* var/syndie_thing_type = pick(filtered_concrete_typesof(/obj/item, /proc/filter_is_syndicate))
	* ```
	*/
proc/filtered_concrete_typesof(type, filter)
	if(isnull(cached_filtered_types))
		cached_filtered_types = list()
	if((type in cached_filtered_types) && (filter in cached_filtered_types[type]))
		return cached_filtered_types[type][filter]
	. = list()
	for(var/subtype in typesof(type))
		if(!IS_ABSTRACT(subtype) && call(filter)(subtype))
			. += subtype
	if(!(type in cached_filtered_types))
		cached_filtered_types[type] = list()
	cached_filtered_types[type][filter] = .

/**
	* Gets the instance of a singleton type (or a non-singleton type if you decide to use it on one).
	*/
proc/get_singleton(type)
	if(!singletons)
		singletons = list()
	if(!(type in singletons))
		singletons[type] = new type
	return singletons[type]
var/global/list/singletons


/// Find predecessor of a type
proc/predecessor_path_in_list(type, list/types)
	while(type)
		if(type in types)
			return type
		type = type2parent(type)
	return null

/**
	* Returns the maximal subtype (i.e. the most subby) in a list of given types
	*/
proc/maximal_subtype(var/list/L)
	if (!(length(L)))
		.= null
	else
		.= L[1]
		for (var/t in L)
			if (ispath(t, .))
				.= t
			else if (!(ispath(., t)))
				return null // paths in L aren't linearly ordered

// by_type and by_cat stuff

// sometimes we want to have all objects of a certain type stored (bibles, staffs of cthulhu, ...)
// to do that add START_TRACKING to New (or unpooled) and STOP_TRACKING to disposing, then use by_type[/obj/item/storage/bible] to access the list of things

#ifdef SPACEMAN_DMM // just don't ask
#define START_TRACKING
#define STOP_TRACKING
#else
#define START_TRACKING if(!by_type[......]) { by_type[......] = list() }; by_type[.......][src] = 1 //we use an assoc list here because removing from one is a lot faster
#if DM_BUILD >= 1552
#define STOP_TRACKING by_type[......].Remove(src) //ok if ur seeing this and thinking "wtf is up with the ....... in THIS use case it gives us the type path at the particular scope this is called. and the amount of dots varies based on scope in the macro! fun
#else
#define STOP_TRACKING by_type[.....].Remove(src) //ok if ur seeing this and thinking "wtf is up with the ...... in THIS use case it gives us the type path at the particular scope this is called. and the amount of dots varies based on scope in the macro! fun
#endif
#endif

/// contains lists of objects indexed by their type based on START_TRACKING / STOP_TRACKING
var/list/list/by_type = list()

/// Performs a typecheckless for loop with var/iterator over by_type[_type]
#define for_by_tcl(_iterator, _type) for(var ##_type/##_iterator as anything in by_type[##_type])

// sometimes we want to have a list of objects of multiple types, without having to traverse multiple lists
// to do that add START_TRACKING_CAT("category") to New, unpooled, or whatever proc you want to start tracking the objects in (eg: tracking dead humans, put start tracking in death())
// and add STOP_TRACKING_CAT("category") to disposing, or whatever proc you want to stop tracking the objects in (eg: tracking live humans, put stop tracking in death())
// and to traverse the list, use by_cat["category"] to get the list of objects in that category
// also ideally youd use defines for by_cat categories!
#define START_TRACKING_CAT(x) OTHER_START_TRACKING_CAT(src, x)
#define STOP_TRACKING_CAT(x) OTHER_STOP_TRACKING_CAT(src, x)
#define OTHER_START_TRACKING_CAT(what, x) if(!by_cat[x]) { by_cat[x] = list() }; by_cat[x][what] = 1
#define OTHER_STOP_TRACKING_CAT(what, x) by_cat[x].Remove(what)

//Hi sorry for overloading your lovely by_cat stuff and adding stealthy wrapper macros, I just need to store one more thing for video broadcasts and it'd be perfect
//Value should be the dmi where your video sprites are stored. If you don't have that, set it to 1 please.
#define SUBSCRIBE_BROADCAST(x, value) OTHER_SUB_BROADCAST(src, x, value)
#define OTHER_SUB_BROADCAST(what, x, value) if(!by_cat[x]) { by_cat[x] = list() }; by_cat[x][what] = value
#define UNSUBSCRIBE_BROADCAST(x) STOP_TRACKING_CAT(x); UpdateOverlays(null, BROADCAST_VIDEO_KEY)
//Overlay key for the broadcast video thingy
#define BROADCAST_VIDEO_KEY "broadcast_video"

/// contains lists of objects indexed by a category string based on START_TRACKING_CAT / STOP_TRACKING_CAT
var/list/list/by_cat = list()

// tracked categories

#define TR_CAT_ATMOS_MACHINES "atmos_machines"
#define TR_CAT_LIGHT_GENERATING_TURFS "light_generating_turfs"
#define TR_CAT_CRITTERS "critters"
#define TR_CAT_PETS "pets"
#define TR_CAT_PW_PETS "pod_wars_pets"
#define TR_CAT_PODS_AND_CRUISERS "pods_and_cruisers"
#define TR_CAT_NERVOUS_MOBS "nervous_mobs"
#define TR_CAT_SHITTYBILLS "shittybills"
#define TR_CAT_JOHNBILLS "johnbills"
#define TR_CAT_OTHERBILLS "otherbills"
#define TR_CAT_TELEPORT_JAMMERS "teleport_jammers"
#define TR_CAT_BURNING_MOBS "dudes_on_fire"
#define TR_CAT_BURNING_ITEMS "items_on_fire"
#define TR_CAT_OMNIPRESENT_MOBS "omnipresent_mobs"
#define TR_CAT_CHAPLAINS "chaplains"
#define TR_CAT_SOUL_TRACKING_ITEMS "soul_tracking_items"
#define TR_CAT_CLOWN_DISBELIEF_MOBS "clown_disbelief_mobs"
#define TR_CAT_SPIDER_FILTER_MOBS "spider_filter_mobs"
#define TR_CAT_RADIO_BROADCAST_RECEIVERS "radio_receivers" //demo channel
#define TR_CAT_FINITE_BROADCAST_RECEIVERS "finite_radio_receivers" //demo channel
#define TR_CAT_TEEVEE_BROADCAST_RECEIVERS "teevee_broadcast_receivers" //demo channel, but this one gets video blasted at it
// powernets? processing_items?
// mobs? ai-mobs?


/// type-level information type
/typeinfo
	parent_type = /datum

/typeinfo/datum

/typeinfo/atom
	parent_type = /typeinfo/datum

/typeinfo/turf
	parent_type = /typeinfo/atom

/typeinfo/area
	parent_type = /typeinfo/atom

/typeinfo/atom/movable

/typeinfo/obj
	parent_type = /typeinfo/atom/movable

/typeinfo/mob
	parent_type = /typeinfo/atom/movable

/**
 * Declares typeinfo for some type.
 *
 * Example:
 * ```
 * TYPEINFO(/atom)
 * 	var/monkeys_hate = FALSE
 *
 * TYPEINFO(/obj/item/clothing/glasses/blindfold)
 * 	monkeys_hate = TRUE
 * ```
 *
 * Treat this as if you were defining a type. You can add vars and procs, override vars and procs etc.
 * There might be minor issues if you define TYPEINFO of one type multiple times. Consider using `/typeinfo/THE_TYPE` for subsequent additions
 * to the object's typeinfo **if you know it has already been declared once using TYPEINFO**.
*/
#define TYPEINFO(TYPE) \
	TYPE/typeinfo_type = /typeinfo ## TYPE; \
	TYPE/get_typeinfo() { /* maybe unnecessary, possibly replace the proc with a macro */ \
		RETURN_TYPE(/typeinfo ## TYPE); \
		return get_singleton(src.typeinfo_type); \
	} \
	/typeinfo ## TYPE


/// var storing the subtype of /typeinfo relevant for this object
/datum/var/typeinfo_type = /typeinfo/datum

/**
 * Retrieves the typeinfo datum for this datum's type.
 *
 * Example:
 * ```
 * var/obj/item/item_in_hand = src.equipped()
 * var/typeinfo/atom/typeinfo = item_in_hand.get_typeinfo()
 * if(typeinfo.monkeys_hate)
 * 	src.throw(src.equipped(), somewhere)
 * ```
*/
/datum/proc/get_typeinfo()
	RETURN_TYPE(/typeinfo/datum)
	return get_singleton(src.typeinfo_type)

/**
 * Retrieves the typeinfo datum for a given type.
 *
 * Example:
 * ```
 * for(var/type in types)
 * 	var/typeinfo/atom/typeinfo = get_type_typeinfo(type)
 * 	if(!typeinfo.admin_spawnable)
 * 		continue
 * 	valid_types += type
 * ```
*/
proc/get_type_typeinfo(type)
	RETURN_TYPE(/typeinfo/datum) // change to /typeinfo if we ever implement /typeinfo for non-datums for some reason
	var/datum/type_dummy = type
	return get_singleton(initial(type_dummy.typeinfo_type))
