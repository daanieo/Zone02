/**
* Name: householdsmodel
* File with definition of households species 
* Author: daan
* Tags: 
*/


model householdsmodel


import "facilities_model.gaml"
import "Zone02_simulation.gaml"


/* Insert your model definition here */

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