/obj/machinery/door/poddoor
	name = "blast door"
	desc = "A heavy duty blast door that opens mechanically."
	icon = 'icons/obj/doors/blastdoor.dmi'
	icon_state = "closed"
	var/id = 1
	layer = BLASTDOOR_LAYER
	closingLayer = CLOSED_BLASTDOOR_LAYER
	sub_door = TRUE
	explosion_block = 3
	heat_proof = TRUE
	safe = FALSE
	max_integrity = 600
	armor = list("melee" = 50, "bullet" = 100, "laser" = 100, "energy" = 100, "bomb" = 50, "bio" = 100, "rad" = 100, "fire" = 100, "acid" = 70)
	resistance_flags = FIRE_PROOF
	damage_deflection = 70
	poddoor = TRUE
	assemblytype = /obj/structure/poddoor_assembly
	var/open_sound = 'sound/machines/blastdoor.ogg'
	var/close_sound = 'sound/machines/blastdoor.ogg'

/obj/machinery/door/poddoor/attackby(obj/item/W, mob/user, params)
	. = ..()
	if((resistance_flags & INDESTRUCTIBLE) && W.tool_behaviour == TOOL_SCREWDRIVER) // This makes it so ERT members cannot cheese by opening their blast doors.
		to_chat(user, "<span class='warning'>You can't find the panel!</span>")
		return

	if(W.tool_behaviour == TOOL_SCREWDRIVER)
		if(density)
			to_chat(user, "<span class='warning'>You need to open [src] to access the maintenance panel!</span>")
			return
		else if(default_deconstruction_screwdriver(user, icon_state, icon_state, W))
			to_chat(user, "<span class='notice'>You [panel_open ? "open" : "close"] the maintenance hatch of [src].</span>")
			return TRUE

	if(panel_open && !density)
		if(W.tool_behaviour == TOOL_MULTITOOL)
			var/change_id = input("Set [src]'s ID. It must be a number between 1 and 100.", "ID", id) as num|null
			if(change_id)
				id = clamp(round(change_id, 1), 1, 100)
				to_chat(user, "<span class='notice'>You change the ID to [id].</span>")

		if(W.tool_behaviour == TOOL_CROWBAR)
			to_chat(user, "<span class='notice'>You start to remove the airlock electronics.</span>")
			if(!(machine_stat & NOPOWER))
				do_sparks(5, TRUE, src)
				electrocute_mob(user, get_area(src), src, 1, TRUE) //fuck this fella
				close()
			else if(W.use_tool(src, user, 10 SECONDS, volume=50))
				deconstruct(TRUE)

/obj/machinery/door/poddoor/examine(mob/user)
	. = ..()
	. += "<span class='notice'>The maintenance panel is [panel_open ? "opened" : "closed"].</span>"
	if(panel_open)
		. += "<span class='notice'>The <b>airlock electronics</b> are exposed and could be <i>pried out</i>."

/obj/machinery/door/poddoor/deconstruct(disassembled = TRUE, mob/user)
	if(!(flags_1 & NODECONSTRUCT_1))
		var/obj/structure/poddoor_assembly/assembly = new assemblytype(loc)
		assembly.set_anchored(TRUE)
		assembly.state = AIRLOCK_ASSEMBLY_NEEDS_ELECTRONICS
		assembly.created_name = name
		assembly.update_name()
		assembly.update_icon()
		assembly.welded = TRUE
		new /obj/item/electronics/airlock(loc)
	qdel(src)

/obj/machinery/door/poddoor/connect_to_shuttle(obj/docking_port/mobile/port, obj/docking_port/stationary/dock)
	id = "[REF(port)][id]"

/obj/machinery/door/poddoor/preopen
	icon_state = "open"
	density = FALSE
	opacity = FALSE

/obj/machinery/door/poddoor/ert
	name = "hardened blast door"
	desc = "A heavy duty blast door that only opens for dire emergencies."
	resistance_flags = INDESTRUCTIBLE | LAVA_PROOF | FIRE_PROOF | UNACIDABLE | ACID_PROOF

//special poddoors that open when emergency shuttle docks at centcom
/obj/machinery/door/poddoor/shuttledock
	var/checkdir = 4	//door won't open if turf in this dir is `turftype`
	var/turftype = /turf/open/space

/obj/machinery/door/poddoor/shuttledock/proc/check()
	var/turf/T = get_step(src, checkdir)
	if(!istype(T, turftype))
		INVOKE_ASYNC(src, .proc/open)
	else
		INVOKE_ASYNC(src, .proc/close)

/obj/machinery/door/poddoor/incinerator_toxmix
	name = "combustion chamber vent"
	id = INCINERATOR_TOXMIX_VENT

/obj/machinery/door/poddoor/incinerator_atmos_main
	name = "turbine vent"
	id = INCINERATOR_ATMOS_MAINVENT

/obj/machinery/door/poddoor/incinerator_atmos_aux
	name = "combustion chamber vent"
	id = INCINERATOR_ATMOS_AUXVENT

/obj/machinery/door/poddoor/incinerator_syndicatelava_main
	name = "turbine vent"
	id = INCINERATOR_SYNDICATELAVA_MAINVENT

/obj/machinery/door/poddoor/incinerator_syndicatelava_aux
	name = "combustion chamber vent"
	id = INCINERATOR_SYNDICATELAVA_AUXVENT

/obj/machinery/door/poddoor/Bumped(atom/movable/AM)
	if(density)
		return 0
	else
		return ..()

//"BLAST" doors are obviously stronger than regular doors when it comes to BLASTS.
/obj/machinery/door/poddoor/ex_act(severity, target)
	if(severity == 3)
		return
	..()

/obj/machinery/door/poddoor/do_animate(animation)
	switch(animation)
		if("opening")
			flick("opening", src)
			playsound(src, open_sound, 30, FALSE)
		if("closing")
			flick("closing", src)
			playsound(src, close_sound, 30, FALSE)

/obj/machinery/door/poddoor/update_icon_state()
	if(density)
		icon_state = "closed"
	else
		icon_state = "open"

/obj/machinery/door/poddoor/try_to_activate_door(mob/user)
	return

/obj/machinery/door/poddoor/try_to_crowbar(obj/item/I, mob/user)
	if(machine_stat & NOPOWER)
		open(TRUE)

/obj/machinery/door/poddoor/attack_alien(mob/living/carbon/alien/humanoid/user)
	if(density & !(resistance_flags & INDESTRUCTIBLE))
		add_fingerprint(user)
		user.visible_message("<span class='warning'>[user] begins prying open [src].</span>",\
					"<span class='noticealien'>You begin digging your claws into [src] with all your might!</span>",\
					"<span class='warning'>You hear groaning metal...</span>")
		playsound(src, 'sound/machines/airlock_alien_prying.ogg', 100, TRUE)

		var/time_to_open = 5 SECONDS
		if(hasPower())
			time_to_open = 15 SECONDS

		if(do_after(user, time_to_open, TRUE, src))
			if(density && !open(TRUE)) //The airlock is still closed, but something prevented it opening. (Another player noticed and bolted/welded the airlock in time!)
				to_chat(user, "<span class='warning'>Despite your efforts, [src] managed to resist your attempts to open it!</span>")

	else
		return ..()

