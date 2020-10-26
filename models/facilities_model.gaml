/**
* Name: facilitiesmodel
* Definition of facilities species 
* Author: daan
* Tags: 
*/


model facilitiesmodel

import "households_model.gaml"
import "Zone02_simulation.gaml"

species facilities{
//	Visual parameters
	float size <- 100 #m;
	rgb color <- #blue;
	
//	Constants
	float facility_food_storage_size;
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
			
			loop times: served_parallel { 	// serves capacity_per_cycle people per cycle
				
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