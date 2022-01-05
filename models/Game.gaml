/**
* Name: Game
* Based on the internal empty template. 
* Author: tocur
* Tags: 
*/


model MineSishop

global {
    int nb_agent<-3;
    int nb_thief<-2;
//     int nb_bank<-1;
    int env_length <- 300;
    
    float Agent_speed <- 1.1; 
    float thief_speed <- 1.0; 

    float Agent_perception_distance <- 50.0;  
    float thief_perception_distance <- 30.0;  
    
    Cell the_cell;
    
    string thief_at_location <- "thief_location";
    
    predicate patrol <- new_predicate("patrol");
    predicate thief_location <- new_predicate(thief_at_location);
    predicate chase <- new_predicate('chase');
    predicate choose_closest_thief <- new_predicate("choose_closeste_thief");
//    predicate has_to_patrol <- new_predicate('has_to_patrol');
    predicate share_thief <- new_predicate('share_thief');
    
      
    geometry shape <- square(env_length);
	geometry environment <- copy(shape); 
    init {
		create Cell number:1 {
			location <- any_location_in(environment);
			the_cell <- self;
		}
		create Agent number: nb_agent  {
			location <- any_location_in(environment);
		}
		create thief number: nb_thief  {
			location <- any_location_in(environment);
		}
//		create bank number: nb_bank {
//			location <- any_location_in(environment);
//		}
    }
    reflex display_social_links{
        loop tempAgent over: Agent{
                loop tempDestination over: tempAgent.social_link_base{
                    if (tempDestination !=nil){
                        bool exists<-false;
                        loop tempLink over: socialLinkRepresentation{
                            if((tempLink.origin=tempAgent) and (tempLink.destination=tempDestination.agent)){
                                exists<-true;
                            }
                        }
                        if(not exists){
                            create socialLinkRepresentation number: 1{
                                origin <- tempAgent;
                                destination <- tempDestination.agent;
                                if(get_liking(tempDestination)>0){
                                    my_color <- #green;
                                } else {
                                    my_color <- #red;
                                }
                            }
                        }
                    }
                }
            }
    }
}

species Cell {
	geometry shape <- square(50);
//	image_file my_icon <- image_file('../includes/inchisoare.png'); 
	aspect default {
		draw shape color:#blue;
	}
}
//species bank {
//    int quantity <- rnd(1,20);
//    aspect default {
//		draw shape color:#red; 
//    }
//}
species Agent skills: [moving] control:simple_bdi {
	float speed <- Agent_speed;
	float perception_distance <- Agent_perception_distance;
	thief target_thief <- nil ;
	int thiefs_catched <- 0;
	init {
		
		do add_desire(patrol, 1.0);
	}	
	
	plan patrolling intention: patrol{
		do wander(speed, 5.0);

	}
	
	rule belief:thief_location new_desire:chase strength: 5.0;
	
	perceive target: agents of_generic_species thief in:Agent_perception_distance {
		if(self.is_immune = false){
			thief the_theif <- self;
			ask myself{
				
				do remove_intention(patrol, false);
				do add_belief(new_predicate(thief_at_location, ['thief'::the_theif]));
				do add_desire(predicate: share_thief, strength: 5.0);
				  
			}
		}

	}
	 perceive target: Agent in: environment {
        socialize;
    }
	
	plan share_info intention: share_thief  instantaneous: true{
		list<Agent> all_agents <- list<Agent>(social_link_base  collect each.agent);
		list<thief> all_thiefs_i_know <- get_beliefs_with_name(thief_at_location) collect  (get_predicate(mental_state (each)).values["thief"]);
		if(empty(all_thiefs_i_know) = false){
			loop thief_agent over: all_thiefs_i_know{
				ask all_agents {
					do remove_intention(patrol, false);
					do add_belief(new_predicate(thief_at_location, ['thief'::thief_agent]));
				}
			}
		}
		
		 do remove_intention(share_thief, true); 
	}
	
	plan chasing intention: chase {
		

		if(target_thief = nil){
			do add_subintention(get_current_intention(), choose_closest_thief, true);
			do current_intention_on_hold();
		} else  {
				do goto target:target_thief;
				if(target_thief.location = location){					
					ask target_thief{
						immune_cycles <- 350;
						location <- the_cell.location;
							
	          
					}
					thiefs_catched <- thiefs_catched + 1;
					do remove_belief(new_predicate(thief_at_location, ["thief"::target_thief]));
					target_thief <- nil;
				
				}	
		}
	}
	
	plan choosing_closest_thief intention:choose_closest_thief instantaneous: true{
		list<thief> thiefs <- get_beliefs_with_name(thief_at_location) collect (get_predicate(mental_state (each)).values["thief"]);
		if(empty(thiefs)){
	        do remove_intention(chase, true);
	    
		} else {
			target_thief <- thiefs with_min_of(each distance_to self);
		}
		do remove_intention(choose_closest_thief, true);
	}	
	
	

   aspect default {
		draw circle(3) color: #blue ;
	} 
	
	aspect perception {
		draw circle(Agent_perception_distance) color:#black empty: true;
	}

}

species thief skills: [moving] control:simple_bdi {
	float speed <- thief_speed;
	float perception_distance <- Agent_perception_distance;
	bool is_immune <- false;
	int immune_cycles <- 0;

	reflex immune when: every(1#cycle){
		if(immune_cycles > 0){
			is_immune <- true;
			immune_cycles <- immune_cycles -1;
			
		} else {
			is_immune <- false;
			
		}
	}
	
	reflex  moving {
		do wander(speed, 5.0) ;
	}
		
   aspect default {
		draw circle(2) color: #red ;
	} 
	aspect perception {
		draw circle(thief_perception_distance) color:#black empty: true;
	}
}
	
species socialLinkRepresentation{
    Agent origin;
    agent destination;
    rgb my_color;
    
    aspect base{
        draw line([origin,destination],1.0) color: my_color;
    }
}


experiment mapa type: gui {
	parameter "Number of guardians" var: nb_agent min: 0 max: 50 category: "Agent";
	parameter "Base seed agent" var: Agent_speed min: 0.7 max: 1.5 category: "Agent";
	parameter "Field of View agents" var: Agent_perception_distance min: 30.0 max: 120.0 category: "Agent";
	
	parameter "Number of thief" var: nb_thief min: 0 max: 50 category: "Thief";
	parameter "Base Speed" var: thief_speed min: 0.7 max: 1.5 category: "Thief";
	parameter "Field of View" var: thief_perception_distance min: 30.0 max: 120.0 category: "Thief";
	
    output {
        display view synchronized: true {
			species Agent aspect:default ;
			species Agent aspect:perception;
			
			species thief aspect:default ; 
			species thief aspect:perception;  
			
			species Cell aspect:default transparency: 0.5; 
//			species bank aspect:default ;   
    	}
    	 display socialLinks type: opengl{
        species socialLinkRepresentation aspect: base;
    }
    	 display info {
			chart "Catched thiefs" type: series {
				datalist legend: Agent accumulate each.name value: Agent accumulate each.thiefs_catched;
			}
		}
		
    } 
    } 

