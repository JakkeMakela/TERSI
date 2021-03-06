# Translation of MATLAB code by Jakke Makela by Florian Lengyel. Sept-Oct 2012
# The code is a joint project of Florian Lengyel and Jakke Makela. Makela
# wrote the original MATLAB code based on discussions with Lengyel, who 
# translated the simulation to R. Lengyel currently maintains the code.

# The simulation is motivated by Joseph Heath's  typology of mechanisms of 
# cooperative benefit (Heath, Joseph. The Benefits of Cooperation. 
# Philosophy & Public Affairs.  Vol. 34, number 4. Blackwell Publishing Inc. 
# 2006. pp 313-351).
#
# The code attempts to follow Google's R Style Guide
# URL: http://google-styleguide.googlecode.com/svn/trunk/google-r-style.html
# The first rule we attempt to follow is the 80 character maximum line length. 
#
# The Google Style Guide recommends using S3 classes instead of S4 classes 
# unless there is a justification. My justification for S4 classes is 
# that I know more about S4 classes than S3 classes. They are used to store
# simulation parmeters and completed simulations. S4 class objects
# are immutable and R does not currently provide intrinsic support for 
# purely functional data structures (Chris Okasaki. Purely Functional
# Data Structures. Cambridge University Press, Jun 13, 1999). S4 objects
# require replacement methods to update a new copy of the original object
# for each slot that is updated. But they are useful for storing simulations.
#
# Addition: Class names are all UPPERCASE.

source("Mechanism.R")  # load R.oo MECHANISM class and constants
library(methods) # use version S4 R classes


# The SIMULATION class only knows how to define and run simulations.
# Saving, loading and analyzing simulations is deferred to the
# TERSI subclass, below.

setClass("SIMULATION", representation = representation( 
  crop.target.start = "numeric",  # Mean raised crop at beginning
  # On average there will be famine * rainfall (verify TK)
  max.sust.ratio = "numeric",     # maximum sustainabiilty ratio
  # Ratio to basic target where sustainability limit sets in
  max.harvest.ratio = "numeric",
  # Ratio to basic target that can be harvested in the absence of
  # economies of scale (without the cooperation of others).
  # Limit is 4, since rainfall*wisdom can equal 4 at end of simulation 
  # TK explain all parameter choices.
  #
  # The following parameters are set for all class instances.
  # They are inaccessible to the initialize method.
  runs = "numeric",  # number of simulation runs
  years.per.run = "numeric",   
  annual.wisdom.gain = "numeric",  # wisdom increase per year
  max.rain.ratio = "numeric",      # Maximum annual rainfall 
  max.coop.ratio = "numeric",      # TK
  trade.ratio = "numeric",         # Maximum that can be traded
  crop.seed.start = "numeric",     # Minimum seed crop for next year
  wisdom.start = "numeric",        # global wisdom parameter
  profit.start = "numeric",        # initial profit value (0)
  agents = "numeric",      # number of agents in society
  societies = "numeric"))          # number of societies


setMethod("initialize","SIMULATION", 
	  function(.Object, 
		   crop.target.start = 10, 
       max.sust.ratio = 1.3, 
		   max.harvest.ratio = 1.5,
		   trade.ratio = 0.5,
		   runs = 100,
		   years.per.run = 100,
		   max.rain.ratio = 2,
		   crop.seed.start = 1,
		   wisdom.start = 1,
       profit.start = 0,
		   agents = 9) {
  .Object@crop.target.start <- crop.target.start;
  .Object@max.sust.ratio <- max.sust.ratio;
  .Object@max.harvest.ratio <- max.harvest.ratio;
  .Object@trade.ratio <- trade.ratio;
  .Object@runs <- runs; 
  .Object@years.per.run <- years.per.run; 

   # Maximum Wisdom increase per year. Hundred years in total
   # At end of simulation, will be exactly at sustainability level!
  .Object@annual.wisdom.gain <- (max.sust.ratio - 1) / .Object@years.per.run;

  .Object@max.rain.ratio <- max.rain.ratio;
  .Object@max.coop.ratio <- .Object@max.rain.ratio * max.sust.ratio;
   # All can be lifted if cooperation is in place. This is full amount at end.
  .Object@crop.seed.start <- crop.seed.start;  
   # Minimum needed as seed crop for next year
   # Wisdom Parameters. Do not change by default
  .Object@wisdom.start <- wisdom.start;   # ordinarily 1
  .Object@profit.start <- profit.start;  # ordinarily 0
  .Object@agents  <- agents;        # number of agents 9 to begin with
  .Object@societies <- kSocieties;  # Set number of societies (32)

   return(.Object)  # return the initialized object
})  




setGeneric("Simulate", function(ob, ...) standardGeneric("Simulate"))

setMethod("Simulate", signature=signature(ob="SIMULATION"), definition=function(ob) {
# Run the simulation. 
#
# Args:
#   ob: SIMULATION object
#
# Returns:
# List of simulation summary parameters

  # Preallocate descriptive statistic matrices. Each is a runs x societies matrix
  
  current.profit <- matrix(0, ob@runs, ob@societies)  # profit in each run
  max.profit     <- matrix(0, ob@runs, ob@societies)  # max profit in each run
  min.profit     <- matrix(0, ob@runs, ob@societies)  # min profit/society in each run
  deaths         <- matrix(0, ob@runs, ob@societies)  # deaths per run
  dead.profit    <- matrix(0, ob@runs, ob@societies)  # profits of those who failed
  a.famines      <- matrix(0, ob@runs, ob@societies)  # number of a crop famines
  b.famines      <- matrix(0, ob@runs, ob@societies)  # ditto
  
  # we should have histograms also.
  
  for (run in 1:ob@runs) {
    print(paste("Run number", run, sep=":"))

    # set the initial society state for all societies in each run
    state <- MECHANISM(ob);   # pass simulation parameter object DRY
         
    # Define the environment for all societies. 
    # This is to change as little as necessary across societies
    # as the mechanisms of cooperative benefit change
    crop.sust.start <- ob@crop.target.start * ob@max.sust.ratio;
    crop.coop.start <- ob@crop.target.start * ob@max.coop.ratio;

    # Set growing parameters 
    crop.seed <- ob@crop.seed.start

    crop.target     <- ob@crop.target.start
    crop.sust       <- crop.sust.start
    global.wisdom   <- ob@wisdom.start


    # Simulate each world for a lifetime 
    for (year in 1:ob@years.per.run) {
      global.wisdom <- global.wisdom + ob@annual.wisdom.gain;

      # As wisdom grows, sustainable crops must also grow
      crop.target <- ob@crop.target.start * global.wisdom;
      crop.sust   <- crop.sust.start * global.wisdom;
      crop.coop   <- crop.coop.start * global.wisdom;
      crop.seed   <- ob@crop.seed.start * global.wisdom;  

      Rainfall(state);  # Rain on the societies
      
      for (soc in 1:ob@societies) {
        # Information transmission
        InfoTransmission(state, soc, ob@annual.wisdom.gain)
        
        
        GrowCrops(state, soc, crop.target)
        
      
        # Economies of scale
        crop.weight <- crop.target * ob@max.harvest.ratio;
        EconomiesOfScale(state, soc, ".a", crop.weight)  # Distribute excess a if EoS enabled
        EconomiesOfScale(state, soc, ".b", crop.weight)  # Distribute excess b if EoS enabled
        
        # Self binding. If some fields have unsustainable yield, we have a tragedy
        # of the commons and have to decrease the other fields.
        SelfBindingJM(state, soc, ".a", crop.sust) # Laissez-Faire 
        SelfBindingJM(state, soc, ".b", crop.sust) # ideological fantasy if no S
        
      
        # Risk pool mechanism. The insurance adjustor shows up only if present
        RiskPooling(state, soc, ".a", crop.seed)
        RiskPooling(state, soc, ".b", crop.seed)
        
        # Gain from trade. Markets exist only if this mechanism is present
        GainFromTrade(state, soc, crop.seed, ob@trade.ratio)
        
        # Compute profit after running mechanisms of cooperative benefit
        ComputeProfit(state, soc, crop.seed)
      
	# List bankrupted agents
	dead.agents <- Bankrupt(state, soc, crop.seed)  

        # Calculate famines 
        a.famines[[run, soc]] <- a.famines[[run, soc]] + Famines(state, soc, "a.seed.exists");
        b.famines[[run, soc]] <- b.famines[[run, soc]] + Famines(state, soc, "b.seed.exists");
	
	      num.dead    <- length(dead.agents)          # count them
        print(paste("run:", run, "year:", year, "soc:", soc, TersiLegend(soc), "deaths:", num.dead))
        if (num.dead > 0) { 
	        deaths[[run, soc]] <- deaths[[run, soc]] + num.dead
          for (corpse in dead.agents) {  
            dead.profit[[run, soc]] <- dead.profit[[run, soc]] 
	                                    + AgentProfit(state, soc, corpse)
	          EtResurrexit(state, soc, corpse, crop.target)
          }  # for           
        }  # if
       
        # Keep the descriptive statistics
        # TODO(we may want the histograpms of the farmer's profits at the end)
        current.profit[[run, soc]] <- sum(state$.profit[soc, ])
        max.profit[[run, soc]]     <- max(state$.profit[soc, ])
        min.profit[[run, soc]]     <- min(state$.profit[soc, ])
      } # for each society            
    } # for years.per.run
    rm(state)   # remove the old state
  }  # for runs
  return (list(current.profit = current.profit, 
               max.profit = max.profit,
               min.profit = min.profit,
               deaths = deaths, 
               dead.profit = dead.profit, 
               a.famines = a.famines, 
               b.famines = b.famines)) 
}) # (method {function})


# The TERSI class is intended for the analysis of simulations. 
# By default, the initialization calls the  Simulate method of 
# the SIMULATION superclass to create a new simulation to analyze. 
# Adding the filename argument to the class initialize method
# new("TERSI", filename) precomputed simulations to be loaded.
# The SIMULATION class doesn't load, save or analyze any 
# simulations. It only knows how to define and create them.
# Saving, loading and analyzing simulations is delegated to
# the TERSI subclass.

setClass("TERSI", contains = "SIMULATION",
	 representation = representation(stats = "list",
					 filename = "character",
					 palette = "character"))

setMethod("initialize","TERSI", function(.Object, filename="", 
	  crop.target.start = 10, max.sust.ratio = 1.3, 
	  max.harvest.ratio = 1.5, trade.ratio = 0.5, runs = 100, 
	  years.per.run = 100, max.rain.ratio = 2, crop.seed.start = 1, 
	  wisdom.start = 1, agents = 9) {
  # SIMULATION superclass not yet initialized, so initialize it
  # Parameters MUST be passed to callNextMethod() for SIMULATION superclass
  # NOTE: the defaults for SIMULATION can be removed.
  .Object <- callNextMethod(.Object,crop.target.start = crop.target.start,
			    max.sust.ratio = max.sust.ratio,
			    max.harvest.ratio = max.harvest.ratio,
			    trade.ratio = trade.ratio,
                            runs = runs,
			    years.per.run = years.per.run,
			    max.rain.ratio = max.rain.ratio,
			    crop.seed.start = crop.seed.start,
			    wisdom.start = wisdom.start,
			    agents = agents);  # initialize superclass object. 

  # initialize palette for ggplot graphics
  .Object@palette <- c("#000000", "#E69F00", "#56B4E9", "#009E73", 
		       "#F0E442", "#0072B2", "#D55E00", "#CC79A7");

  if (filename == "") {
    print("Running simulation.")
    .Object@stats <- Simulate(.Object); # set the simulation statistics
  }
  else {
    print(paste("Reading pre-computed simulation statistics from:", filename));
    maybe.error <- tryCatch(.Object <- readRDS(filename), error=function(e) e);
    if (inherits(maybe.error, "error")) {
      print(paste("Error reading file: ", filename));
    }
    else { # set the filename      
      .Object@filename <- filename # filename set when serialized object is instantiated
      # the filename is not stored with the object when it is saved to disk
    }
  }
  return (.Object);  # return the initialized object
}) 


setGeneric("save", function(ob, ...) standardGeneric("save"))

setMethod("save", signature=signature(ob="TERSI"), definition=function(ob, filename) {
  maybe.error <- tryCatch(saveRDS(ob, filename), error=function(e) e)
  if (inherits(maybe.error,"error"))
    print(paste("Error saving file: ", filename));
})
