/**
* Name: taskTwoScripts
* Based on the internal empty template. 
* Author: Guangyuan Li
* Tags: 
*/


model taskTwoScripts

/* Insert your model definition here */
global{
	int numberOfStages <- 4;
	list<point> stagesLocations <- [{25, 25}, {25, 75}, {75, 25}, {75, 75}];
	list<rgb> stagesColors <- [rgb("red"), rgb("blue"), rgb("yellow"), rgb("green")];
	int numberOfGuests <- 20;
	int numberOfAttributes <- 4;
	
	init{
		create Stage number: numberOfStages;
		loop counter from: 0 to: numberOfStages - 1{
			Stage[counter].location <- stagesLocations[counter];
			Stage[counter].color <- stagesColors[counter];
		}
		
		create Guest number: numberOfGuests{location <- {rnd(1.0, 99.0), rnd(1.0, 99.0)};}
	}
}

species Stage skills: [fipa]{
	rgb color <- nil;
	
	/* Act detailed attributes */
	list<float> actDetails <- [];
	/* Each stage has different last time */
	float lastTime <- 100.0;
	
	init{
		loop times: numberOfAttributes{
			actDetails <+ 0.0;
		}
	}
	
	/* Set or reset the attributes of acts and inform the guests */
	reflex setActDetails when: time mod lastTime = 0{
		/* Set act details */
		loop counter from:0 to: numberOfAttributes - 1{
			actDetails[counter] <- rnd(0.0, 1.0);
		}
		/* After setting the details, inform the guests */
		do start_conversation to: list(Guest) protocol: 'fipa-contract-net' performative: 'inform' contents: ['New acts available! The details are: ', actDetails];
		write 'Time ' + time + ': ' + name + ' informed new acts\' details: ' + actDetails;
	}
	
	 aspect base
    {
        draw square(5) at: location color: color;
    }
}

species Guest skills: [fipa, moving]{
	list<float> preference <- [];
	map<Stage, float> utilityMap <- [];
	/* The stage whose utility is the largest */
	Stage maxUtilityStage <- nil;
	
	init{
		/* Set preferences */
		loop times: numberOfAttributes{
			preference <+ rnd(0.0, 1.0);
		}
		
		write name + ' preference: ' + preference;
		/* Initialize the utility map */
		loop stage over: Stage{
			utilityMap[stage] <- 0.0;
		}
	}
	
	reflex responseInformAndGetStage when: !empty(informs){
		/* Recieve messages */
		loop informMsg over: informs{
			list<float> details <- informMsg.contents[1];
			float utility <- 0.0;
			/* Calculate utilities */
			loop counter from:0 to: length(preference) - 1{
				utility <- utility + details[counter] * preference[counter];
			}
			/* Update the map of utilities */
			utilityMap[informMsg.sender] <- utility;
		}
		/* Go to the maximum utility stage */
		float maxUtility <- max(utilityMap.values);
		int maxUtilityIdx <- utilityMap.values index_of maxUtility;
		maxUtilityStage <- utilityMap.keys[maxUtilityIdx];
		write name + ' prefers to go to: ' + maxUtilityStage + ' whose utility is: ' + maxUtility;
		write '--------------------------------------------------';
	}
	
	reflex gotoStage when: maxUtilityStage != nil{
			do goto target: maxUtilityStage.location speed: 5.0;	
		}
	
	aspect base
    {
        draw circle(1) at: location color: rgb('black');
    }
}

experiment assignment_3_2 type: gui{
	output{
		display map type: opengl{
			species Stage aspect: base;
			species Guest aspect: base;
		}
	}
}