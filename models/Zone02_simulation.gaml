/**
* Name: Zone02_simulation
* Based on the internal empty template. 
* Author: daan
* Tags: 
*/


model Zone02_simulation


global {
//	System specifications
	file shape_file_buildings <- shape_file("/home/daan/GAMA/workspace/Zone02/files/rr_within_zone02.shp","EPSG:4326");
	
	file faccoordinates <- shape_file("/home/daan/Desktop/gdf.shp","EPSG:4326");
	

	geometry shape <-envelope(shape_file_buildings);//to_GAMA_CRS(envelope(shape_file_buildings));//,"EPSG:4326"); // automatic envelope = environment boundaries 
	float step <- 1 #hour;
	
//	Constants	
	int cycles_in_day <- 24; 
	
	int capacity_per_cycle <- 50; 			// Beneficiaries that can be served per cycle
	int avg_nb_building <- 2; // the average number of beneficiaries per building 
		
//	Constants for system functioning
	int rerouting <- 5;
	
//	Statistics
	float total_food_delivered <- 0.0;
	float total_food_demanded <- 0.0;
	int total_hungry_days <- 0; 
	
	init {
		
	
		
//		Create facility agents
		create facilities from: faccoordinates with: [facility_food_storage_size::read('Size')] { //number: nb_facilities {
						
			// Constants 
//			capacity_per_cycle <- 50; 			// Beneficiaries that can be served per cycle
//			avg_nb_building <- 2; // the average number of beneficiaries per building 
			
			// Assign empties to variables 
			nb_beneficiaries <- 0; 
			queue <- [];
			queue_open<-true;
			facility_food_storage <- facility_food_storage_size * avg_nb_building; // At initialisation, food storage has max capacity 
			
//			write self.name + " has storage size "+facility_food_storage_size;
		}
		
//		Create household agents
		create households from: shape_file_buildings{
			
			speed <- 4 #km/#hour;					// speed of beneficiaries 
	
			// Constants
			food_consumption <- 0.6; 				// kg rice / pers / day
			home_location <- location;				// home location = current location 
			my_facility <- determine_facility();	// home facility is current closest facility 
			nb_members <- rnd(1,5); 				// 1 to 5 persons in one household 
			nb_days_tolerated <- rnd(1,10);			// days of food tolerated for perceived need 
			
			
			// Initial values variables
			hungry_days <- 0;					// hungry days of beneficiary agent 
			food_storage <- rnd(0,50);			// initial food storage 
			facility_of_choice <- my_facility;	// initally facility of choice is my facility 
			
			// add the number of household members to the facility			
			ask my_facility {
				nb_beneficiaries <- nb_beneficiaries + myself.nb_members; 
			}
			
		} 
		

// Check of the kaart goed gelezen is door logische afstanden te printen		
//		write "distance between one household and facility is "+distance_to(households[0].location,facilities[0].location);
//		write "household location is "+households[0].location +" and in wfs84 is "+ to_GAMA_CRS(households[0].location);
//		write "facility location is "+facilities[0].location;
		

	}
}



species facilities{
//	Visual parameters
	float size <- 100 #m;
	rgb color <- #blue;
	
//	Constants
	float facility_food_storage_size;
	int avg_nb_building;

	int capacity_per_cycle;
	int nb_beneficiaries;
	
//	States
	bool queue_open; 
	
//	Variables 
	list<households> queue;
	float facility_food_storage;
	
//	Function to visualise
	aspect map_visualisation {		
		draw square(size) color: color ;
	}
	
	
//	Actions
	bool check_storage(float demanded_food) {
		return demanded_food<=facility_food_storage;
	}
	
	facilities determine_facility { 							// Function determining closes faculty 	
		float min_dist <- #infinity; 							// infinitely large minimal distance
		facilities closest_fac <- nil; 							// no closest facility 
		loop fac over: facilities { 							// loop over all facilities in system 
			if distance_to(location,fac.location)<min_dist{ 	// if distance between facilities is smaller than before
				min_dist <- distance_to(location,fac.location); // update smallest distance
				closest_fac <- fac; 							// update facility 
				}
			}
		return closest_fac; 
		}
		
		
	action reroute_beneficiary( households HH ){ 	// Reroute to a certain location depending on the policy option
	
		if rerouting = 1 or rerouting = 2 { 		// Policy options directing beneficiaries to closest facility 
			error "nothing here yet";
		} else if rerouting = 3 or rerouting = 4 { 	// Policy options directing beneficiaries to closest OPEN facility 
			error "nothing here yet";
		} else if rerouting = 5 or rerouting = 6 { 	// Policy options directing beneficiaries home
			ask HH {
				incentive_to_home <- true;			// Ask households to go  back home 
			}
		}else { 									// Throw error in case of invalid int 
			error "invalid policy integer for rerouting, namely "+rerouting;
		}
	}
	
	action satisfy_demand (households HH ) {  								// Updates food storage in households and facility  
		ask HH {
			self.food_storage <- self.food_storage + self.food_demanded; 	// update food storage in household agent
			incentive_to_home <- true;										// send beneficiary home 
			
			// Statistics
			total_food_delivered <- total_food_delivered + self.food_demanded; 
		}
		
		facility_food_storage <- facility_food_storage - HH.food_demanded;	// update food storage in facility agent 
		
	}
	
	
	bool sufficient_food_expected { // arranges potential closing of the queue
	
		if rerouting = 1 or rerouting = 3 or rerouting = 5 { 		// policy options 1,3,5
			float expected_food_withdrawn <- 12.5*3*1; 				// avg days avg nb_members food cons
			return expected_food_withdrawn < facility_food_storage;	// if expected enough food
		} else if rerouting = 2 or rerouting = 4 or rerouting = 6 {	// policy options 2,4,6
			return true;											// no consequences
		} else {													// throw error with another int 
			error "invalid policy integer for rerouting, namely "+rerouting;
		}
	}	
	
	
	
	
//	Reflexes
	reflex check_queue {  
		
		if !sufficient_food_expected() { 		// check if queue should be open or not
			queue_open <- false;				// close the queue
		}else if length(queue)>0 {
			
			loop times: capacity_per_cycle { 	// serves capacity_per_cycle people per cycle
				
				if length(queue)=0{ 			// stops if the queue is empty
					break;
				} else{
					
					float food_demanded <- first(queue).food_demanded;
						
					if facility_food_storage >= food_demanded { 	// if storage has enough food
						do satisfy_demand(first(queue));			// satisfy demand
						remove first(queue) from: queue; 			// remove from queue 
					} else {										// if storage hasnt enough food
						queue_open <- false;						// close the queue
//						write "empty the queue";				
						loop while: length(queue)>0 {				// while still people in queue
							do reroute_beneficiary( first(queue) );	// reroute beneficiary
							remove first(queue) from: queue;		// remove from queue 
							}
						}
				}				
			}
			}
		}
		
	reflex refill { // Daily refill 
		if cycle mod cycles_in_day = 0{ 		// every day 
			facility_food_storage <-  facility_food_storage_size * avg_nb_building; 	// refill storage up to max capacity
			queue_open <- true;					// (re-)open queue
		}
	}	
		
			
	}


species households skills:[moving] {
	
//	Visual parameters
	rgb color <- #green;
	rgb hungry_color <- #red;
	
//	Constants
	int batch_id;
	float food_consumption;
	point home_location;
	facilities my_facility; 
	int nb_members; 
	
//	States
	bool incentive_to_facility;
	bool incentive_to_home;
		
//	Variables 
	facilities facility_of_choice;
	float food_demanded;
	float food_storage;
	int hungry_days;
	int nb_days_tolerated; // without specific behaviour it actually is a constant 
	
//	Function to visualise
	aspect map_visualisation {
		if food_storage < nb_members * food_consumption {
			draw shape color: hungry_color;
		} else{
			draw shape color: color; 
		}
	}
	
// Actions
	action consume_food { 													// Function consuming food/being hungry
			
		if food_storage < nb_members * food_consumption {					// if foood storage is smaller than amount needed
			food_storage <- 0.0; 											// set food_storage to 0
			hungry_days <- hungry_days + 1;									// it is a hungry day 
			// Statistics
			total_hungry_days <- total_hungry_days + 1; 						
		} else {															// if food storage is sufficient
			food_storage <- food_storage - nb_members * food_consumption; 	// update food storage minus consumption 
			}
		}
	
	float determine_demand { 								// Returns the demand based on randomness  
		return rnd(10,15) * food_consumption * nb_members; 	// rnd(days) * daily food cons * nb of hh members 
		}
	
	facilities determine_facility { 							// Function determining closes faculty 	
		float min_dist <- #infinity; 							// infinitely large minimal distance
		facilities closest_fac <- nil; 							// no closest facility 
		loop fac over: facilities { 							// loop over all facilities in system 
			if distance_to(location,fac.location)<min_dist{ 	// if distance between facilities is smaller than before
				min_dist <- distance_to(location,fac.location); // update smallest distance
				closest_fac <- fac; 							// update facility 
				}
			}
		return closest_fac; 
		}
	
	action enter_queue{								// Function arranging entering queue 
		if facility_of_choice.queue_open = true{	// if the facility's queue is open 
			ask facility_of_choice {				// ask facility to 
				add myself to: queue;				// add this household agent to queue 
			}			
		} else {									// if the queue is closed 
			ask facility_of_choice {				// ask the facility 
				do reroute_beneficiary(myself);		// to reroute this household agent 
			}
		}		
	}

	action go_facility{								// Function sending to facility
		do goto(facility_of_choice) speed: speed;	// go to facility with speed
	}
	
	action go_home {								// Function sending to home
		do goto(home_location) speed: speed;		// go to home with speed
		}

//	Reflexes

	reflex live {

		if cycle mod cycles_in_day = 0 { 				// if cycle equals a day 
			do consume_food;							// call consume food function
			
		}else if incentive_to_home = true { 			// if agent has to move home 
			if location = home_location{				// and location is home 
				incentive_to_home <- false;				// remove incentive 	
				facility_of_choice <- my_facility;		// reset facility of choice to the default, closest facility
			}else{ 										// if location is not home
				do go_home;								// move home 
			}
		}else if incentive_to_facility = true { 		// if agent has to move to facility			
			if location = facility_of_choice.location{	// and location is facility
				incentive_to_facility <- false;			// remove incentive 
				do enter_queue;							// try to enter queue
			}else {										// if location is not facility 
				do go_facility;							// move to facility 
				}		
		}else if  (	food_storage < nb_days_tolerated * food_consumption * nb_members 	// if food storage is smaller than perceived need
					and incentive_to_facility = false 									// and no incentive to facility 
					and location != facility_of_choice.location 						// and not at facility 
					) {
			food_demanded <- determine_demand(); 										// determine demand 	
			incentive_to_facility <- true;												// incentive to facility 
			// Statistics
			total_food_demanded <- total_food_demanded + food_demanded;
			}
	}
}



experiment simple_simulation type: gui {
//	parameter "Shapefile for the buildings:" var: shape_file_buildings category: "GIS" ;

		
	output {
		display zone_display{
			species households aspect: map_visualisation ;
			species facilities aspect:map_visualisation;
		}
		
		    display data_viz {

       	chart "Average hungry days " type: series y_range:[0,4000] x_range: [cycle-25,cycle+25] size: {1,0.5} position: {0, 0}{
        data facilities[0].name value: ((total_hungry_days*24)/(cycle+1));
    }


       	chart "Facilities food storage" type: histogram y_label: "kg rice" y_range:[0,4000*avg_nb_building] x_range: [cycle-25,cycle+25] size: {0.5,0.5} position: {0, 0.5}{
        data facilities[0].name value: facilities[0].facility_food_storage;
        data facilities[1].name value: facilities[1].facility_food_storage;
        data facilities[2].name value: facilities[2].facility_food_storage;
        data facilities[3].name value: facilities[3].facility_food_storage;
    }
    
       	chart "Facilities queue lengths" type: series y_label: "# people" y_range:[0,400] x_range: [cycle-25,cycle+25]size: {0.5,0.5} position: {0.5, 0.5} {
        data facilities[0].name value: length(facilities[0].queue);
        data facilities[1].name value: length(facilities[1].queue);
        data facilities[2].name value: length(facilities[2].queue);
        data facilities[3].name value: length(facilities[3].queue);
    }
	  
	  
	}
	

	
	monitor "Total food delivery gap" value: total_food_demanded-total_food_delivered;
	monitor "Total hungry days" value: total_hungry_days;
	monitor "Food storage in facility" value: facilities[0].facility_food_storage;


	
	}
}


experiment Exploration type: batch repeat: 2 keep_seed: true until: ( cycle > 5*24 ) {
	

	parameter "Prey max transfert:" var: capacity_per_cycle min: 10 max: 100 step: 2;
	parameter "Prey energy reproduce:" var: avg_nb_building min: 0 max: 5 step: 1;
	
	
	
	reflex save_results_explo {
		ask simulations {
			save [int(self),capacity_per_cycle,avg_nb_building,total_hungry_days] 
		   		to: "results.csv" type: "csv" rewrite: (int(self) = 0) ? true : false header: true;
		}		
	}
}








