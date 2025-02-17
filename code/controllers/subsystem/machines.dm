SUBSYSTEM_DEF(machines)
	name = "Machines"
	init_order = INIT_ORDER_MACHINES
	flags = SS_KEEP_TIMING
	runlevels = RUNLEVEL_LOBBY|RUNLEVEL_SETUP|RUNLEVEL_GAME|RUNLEVEL_POSTGAME

	var/list/currentrun = list()
	var/list/processing = list()
	var/list/powernets = list()
	var/list/zlevel_cables = list() //up or down cables

/datum/controller/subsystem/machines/Initialize()
	makepowernets()
	fire()
	return SS_INIT_SUCCESS

/datum/controller/subsystem/machines/proc/makepowernets()
	for(var/datum/powernet/PN in powernets)
		qdel(PN)
	powernets.Cut()

	for(var/obj/structure/cable/PC AS in GLOB.cable_list)
		if(!PC.powernet)
			var/datum/powernet/NewPN = new()
			NewPN.add_cable(PC)
			propagate_network(PC,PC.powernet)

/datum/controller/subsystem/machines/stat_entry()
	..("PN:[length(powernets)]|PM:[length(processing)]")

/datum/controller/subsystem/machines/fire(resumed = FALSE)
	if (!resumed)
		for(var/datum/powernet/Powernet in powernets)
			Powernet.reset() //reset the power state.
		src.currentrun = processing.Copy()

	//cache for sanic speed (lists are references anyways)
	var/list/currentrun = src.currentrun

	var/seconds = wait * 0.1
	while(length(currentrun))
		var/obj/machinery/thing = currentrun[length(currentrun)]
		currentrun.len--
		if(!QDELETED(thing) && thing.process(seconds) != PROCESS_KILL)
			if(thing.use_power)
				thing.auto_use_power() //add back the power state
		else
			processing -= thing
			if(!QDELETED(thing))
				thing.datum_flags &= ~DF_ISPROCESSING
		if(MC_TICK_CHECK)
			return

/datum/controller/subsystem/machines/proc/setup_template_powernets(list/cables)
	for(var/A in cables)
		var/obj/structure/cable/PC = A
		if(!PC.powernet)
			var/datum/powernet/NewPN = new()
			NewPN.add_cable(PC)
			propagate_network(PC,PC.powernet)


/datum/controller/subsystem/machines/Recover()
	if(istype(SSmachines.processing))
		processing = SSmachines.processing

	if(istype(SSmachines.powernets))
		powernets = SSmachines.powernets
