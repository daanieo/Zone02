/**
* Name: Zone02_simulation
* Based on the internal empty template. 
* Author: daan
* Tags: 
*/


model Zone02_simulation

import "facilities_model.gaml"


global {
//	System specifications
	file shape_file_buildings <- shape_file("/home/daan/GAMA/workspace/Zone02/files/rr_within_zone02.shp","EPSG:4326");
	
	file faccoordinates <- shape_file("/home/daan/Desktop/gdf.shp","EPSG:4326");
	

	geometry shape <-envelope(shape_file_buildings);//to_GAMA_CRS(envelope(shape_file_buildings));//,"EPSG:4326"); // automatic envelope = environment boundaries 
	float step <- 1 #hour;
	
//	Constants	
	int cycles_in_day <- 24; 
	
	int capacity_per_cycle <- 50 parameter: "Est. facility capacity per cycle"; // Beneficiaries that can be served per cycle
	int avg_nb_building <- 2 parameter: "Est. avg beneficiaries per building"; 	// the average number of beneficiaries per building 
		
//	Constants for system functioning
	int rerouting <- 5;
	
//	Statistics
	float total_food_delivered <- 0.0;
	float total_food_demanded <- 0.0;
	int total_hungry_days <- 0; 
	list<int> hungry_days_list <- [];
	
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

	}
	
	reflex collect_stats {
		add total_hungry_days to: hungry_days_list;
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

experiment gui_experiment type:gui {
	
	parameter "Est. facility capacity per cycle" var: capacity_per_cycle;
	parameter "Est. avg beneficiaries per building" var: avg_nb_building;
	
	init {
		create simulation with:[capacity_per_cycle::10];
		create simulation with:[avg_nb_building::1];
	}
	output {
		display zone_display{
			species households aspect: map_visualisation;
			species facilities aspect:map_visualisation;
		}
	}
	
}


experiment batch_experiment type: batch repeat: 4 keep_seed: true until: ( cycle > 10*24 ) {


	int simcount <- 0;

	parameter "Est. facility capacity per cycle" var: capacity_per_cycle min: 10 max: 100 step: 10;
	parameter "Est. avg beneficiaries per building" var: avg_nb_building min: 0 max: 5 step: 1;
	
	
	action save_results {
				
		loop i over: simulations{
			
        	write int(self);
        	save [i.name, capacity_per_cycle,avg_nb_building, i.hungry_days_list] to: "result.txt" type: "csv" rewrite: false;
        	
	}
}
	
	reflex save_results_explo {		
		
		do save_results;
        
        
			
	}
}












