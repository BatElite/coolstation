/obj/item/genetics_injector
	name = "genetics injector"
	desc = "A special injector designed to interact with one's genetic structure."
	icon = 'icons/obj/items/syringe.dmi'
	inhand_image_icon = 'icons/mob/inhand/hand_medical.dmi'
	item_state = "syringe_0"
	icon_state = "injector_1"
	force = 3
	throwforce = 3
	w_class = W_CLASS_SMALL
	var/inject_verb_self = "injects" //fucking needing 2 vars
	var/inject_verb_other = "inject"
	var/uses = 1

	attack(mob/M as mob, mob/user as mob)
		if(!M || !user)
			return

		if(src.uses < 1)
			boutput(user, "<span class='alert'>The injector is expended and has no more uses.</span>")
			return

		if(M == user)
			user.visible_message("<span class='alert'><b>[user.name] [inject_verb_self] [himself_or_herself(user)] with [src]!</b></span>")
			src.injected(user,user)
		else
			logTheThing("combat", user, M, "tries to [inject_verb_other] [constructTarget(M,"combat")] with [src.name] at [log_loc(user)]")
			actions.start(new/datum/action/bar/icon/genetics_injector(M,src), user)

	proc/injected(var/mob/living/carbon/user,var/mob/living/carbon/target)
		if(!istype(user) || !istype(target))
			return 1
		if(!istype(target.bioHolder))
			return 1
		logTheThing("combat", user, target, "injects [constructTarget(target,"combat")] with [src.name] at [log_loc(user)]")
		return 0

	proc/update_appearance()
		if(src.uses < 1)
			flick("injector_2", src)
			src.icon_state = "injector_0"
			src.desc = "A [src] that has been used up. It should be recycled or disposed of."
			//src.name = "expended " + src.name
		else
			flick("injector_in", src)
			src.icon_state = "injector_1"
			src.desc = initial(src.desc)

	dna_scrambler
		name = "dna scrambler"
		desc = "An illegal retroviral genetic serum designed to randomize the user's identity."
		contraband = 2

		injected(var/mob/living/carbon/user,var/mob/living/carbon/target)
			if (..())
				return
			if (ishuman(target))
				boutput(target, "<span class='alert'>Your body changes! You feel completely different!</span>")
				randomize_look(target)
				src.uses--
				src.update_appearance()

	dna_injector
		name = "dna injector"
		//desc = "A syringe designed to safely insert or remove genetic structures to and from a living organism."
		desc = "A syringe designed to safely insert genetic structures into a living organism." //IDK if these ever removed genes but they sure don't atm
		icon_state = "injector_0"
		var/list/datum/bioEffect/BE = null
		uses = 0 //starts empty 4 agar genes now thanks

		attackby(obj/item/W, mob/user, params)
			if (istype(W, /obj/item/device/analyzer/genes))
				var/obj/item/device/analyzer/genes/nerdery = W
				nerdery.do_scan(src, user)
			else ..()

		injected(var/mob/living/carbon/user,var/mob/living/carbon/target)
			if (..())
				return

			for (var/effect as anything in BE)
				target.bioHolder.AddEffectInstance(effect,1)
			src.uses--
			src.update_appearance()

	dna_activator
		name = "dna activator"
		desc = "A syringe designed to safely stimulate a living organism's genes into activation."
		var/gene_to_activate = null
		var/expended_properly = 0
		icon_state = "activator_1"

		injected(var/mob/living/carbon/user,var/mob/living/carbon/target)
			if (..())
				return

			var/datum/bioEffect/BE
			for(var/X in target.bioHolder.effectPool)
				BE = target.bioHolder.effectPool[X]
				if (BE && BE.id == gene_to_activate)
					//	Activator activated gene AND
					//		Target mob is an actual player
					//		OR
					//		There's 3 or less people connected	(so you can test using monkeys on an empty server)
					if (target.bioHolder.ActivatePoolEffect(BE,overrideDNA = 1,grant_research = 0) && ((total_clients() <= 3) || (!isnpcmonkey(target) && target.client)))
						src.expended_properly = 1 //counts for materials & chromosomes
					break
			src.uses--
			src.update_appearance()

		update_appearance()
			if(src.uses < 1)
				if (expended_properly)
					src.icon_state = "activator_3"
					src.desc = "A [src] that has been filled with useful genetic information."
					src.name = "filled " + src.name
				else
					src.icon_state = "activator_2"
					src.desc = "A [src] that has been used up. It should be disposed of."
					src.name = "expended " + src.name

/datum/action/bar/icon/genetics_injector
	duration = 20
	interrupt_flags = INTERRUPT_MOVE | INTERRUPT_ACT | INTERRUPT_STUNNED | INTERRUPT_ACTION
	id = "genetics_injector"
	icon = 'icons/obj/items/syringe.dmi'
	icon_state = "injector_1"
	var/mob/living/carbon/target = null
	var/obj/item/genetics_injector/injector = null

	New(Target,Injector)
		target = Target
		injector = Injector
		..()

	onUpdate()
		..()
		if(get_dist(owner, target) > 1 || target == null || owner == null || injector == null)
			interrupt(INTERRUPT_ALWAYS)
			return
		var/mob/living/ownerMob = owner
		if(ownerMob.r_hand != injector && ownerMob.l_hand != injector)
			interrupt(INTERRUPT_ALWAYS)
			return

	onStart()
		..()
		if(get_dist(owner, target) > 1 || target == null || owner == null || injector == null)
			interrupt(INTERRUPT_ALWAYS)
			return
		var/mob/living/ownerMob = owner
		if(ownerMob.r_hand != injector && ownerMob.l_hand != injector)
			interrupt(INTERRUPT_ALWAYS)
			return
		owner.visible_message("<span class='alert'><b>[owner.name] begins to inject [target.name] with [injector]!</b></span>")

	onEnd()
		..()
		owner.visible_message("<span class='alert'><b>[owner.name] injects [target.name] with [injector].</b></span>")
		injector.injected(owner,target)

// Traitor item
/obj/item/speed_injector
	name = "screwdriver"
	desc = "A hollow tool used to turn slotted screws and other slotted objects."
	icon = 'icons/obj/items/tools/tools.dmi'
	inhand_image_icon = 'icons/mob/inhand/hand_tools.dmi'
	icon_state = "screwdriver"
	flags = FPRINT | TABLEPASS | CONDUCT
	w_class = W_CLASS_TINY
	hide_attack = 1
	var/obj/item/genetics_injector/dna_injector/payload = null

	attack_self(var/mob/user as mob)
		if (istype(payload))
			boutput(user, "You unload [payload].")
			payload.set_loc(get_turf(user))
			payload = null
		return

	attackby(obj/item/W as obj, mob/user as mob)
		if(istype(W, /obj/item/genetics_injector/dna_injector/))
			if (payload)
				boutput(user, "<span class='alert'>The injector is already loaded.</span>")
				return
			var/obj/item/genetics_injector/dna_injector/DI = W
			if (!istype(DI.BE) || DI.uses < 1)
				boutput(user, "<span class='alert'>The injector is rejecting [DI]. It mustn't be usable.</span>")
				return
			user.drop_item()
			DI.set_loc(src)
			src.payload = DI
			//DI.BE.msgGain = ""
			//DI.BE.msgLose = ""
			//DI.BE.add_delay = 100
			boutput(user, "You slot [DI] into the injector.")
		else
			..()
		return

	attack(mob/M, mob/user as mob)
		if (!iscarbon(M))
			return
		if (payload)
			boutput(user, "<span class='alert'>You stab [M], injecting them.</span>")
			logTheThing("combat", user, M, "stabs [constructTarget(M,"combat")] with the speed injector (<b>Payload:</b> [payload.name]).")
			payload.injected(user,M)
			qdel(payload)
			payload = null
		else
			boutput(user, "<span class='alert'>You stab [M], but nothing happens.</span>")
		return
