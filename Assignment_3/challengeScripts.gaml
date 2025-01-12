/**
* Name: challengeScripts
* Based on the internal empty template. 
* Author: Guangyuan Li
* Tags: 
*/

/*
 * The influence of the crowd mass will be 80%, where crowd mass ranges (0, 20). 
 * The utility of the guests will be normalized to (0, actPreferenceRate).
 * Crowd preference: Each guest has a coefficient which refers the preference of high crowd mass or not. The coefficient ranges (-1.0, 1.0)
 * 
 * When new acts are published, the guests will send their utility without crowd mass and crowd preference to the leader.
 * Then the leader will calculate the global utility by suming the utilities of every guests and calculate the crowd mass utility.
 * And the leader will go through all the guests, and assume that a guest is realigned to another stage at each single time. 
 * It is to find if this increases the global utility. If yes, then do it, until the all the guests have been processed.
 */


model challengeScripts

/* Insert your model definition here */
global{
	int numberOfStages <- 4;
	list<point> stagesLocations <- [{25, 25}, {25, 75}, {75, 25}, {75, 75}];
	list<rgb> stagesColors <- [rgb("red"), rgb("blue"), rgb("yellow"), rgb("green")];
	int numberOfGuests <- 20;
	int numberOfAttributes <- 4;
	int actPreferenceWeight <- 5;
	
	init{
		create Leader number: 1;
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
		do start_conversation to: list(Guest + Leader) protocol: 'fipa-contract-net' performative: 'inform' contents: ['New acts available! The details are: ', actDetails];
		write 'Time ' + time + ': ' + name + ' informed new acts\' details: ' + actDetails;
	}
	
	 aspect base
    {
        draw square(5) at: location color: color;
    }
}

species Leader skills: [fipa]{
	float globalUtility <- 0.0;
	float currentGlobalUtility <- 0.0;
	/* Stages' infos */
	map<Stage, list<float>> stageDetailsMap <- []; // It's static when conduct following codes
	map<Stage, int> numberOfGuestsAtStages <- [];
	/* Guests' infos */
	map<Guest, Stage> guestStageMap <- [];
	map<Guest, float> guestUtilityMap <- [];
	map<Guest, list<float>> guestPreferenceMap <- [];	// It's static when conduct following codes
	map<Guest, float> guestCrowdPreferenceMap <- [];	// It's static when conduct following codes
	
	reflex processInforms when: !empty(informs){
		bool fromStage <- false;
		bool fromGuest <- false;
		loop informMsg over: informs{
			if ('New acts available!' in informMsg.contents[0]){
				fromStage <- true;
				stageDetailsMap[informMsg.sender] <- informMsg.contents[1];
				/* Reset */
				loop stage over: Stage{
					numberOfGuestsAtStages[stage] <- 0;
				}
			}
			if ('This is a guest' in informMsg.contents[0]){
				fromGuest <- true;
				guestStageMap[informMsg.sender] <- informMsg.contents[1];
				guestUtilityMap[informMsg.sender] <- float(informMsg.contents[3]);
				guestPreferenceMap[informMsg.sender] <- informMsg.contents[5];
				guestCrowdPreferenceMap[informMsg.sender] <- float(informMsg.contents[7]);	
			}
		}
		
		if fromGuest{
			/* Change map */
			map<Guest, Stage> changeMap <- []; 	// The map claim which guest needs to change a stage, and his destination
			/* Count how many guests at each stage */
			loop stage over: guestStageMap.values{
				numberOfGuestsAtStages[stage] <- numberOfGuestsAtStages[stage] + 1;
			}
			write 'The number of guests at each stage: ' + numberOfGuestsAtStages;
			/* Calculate guest crowd utilities */
			map<Guest, float> guestCrowdUtilityMap <- [];
			loop guest over: guestStageMap.keys{
				Stage atStage <- guestStageMap[guest];
				guestCrowdUtilityMap[guest] <- numberOfGuestsAtStages[atStage] * guestCrowdPreferenceMap[guest];
			}
			globalUtility <- sum(guestUtilityMap.values) + sum(guestCrowdUtilityMap.values);
			write "Global utility is: " + globalUtility;
			write '--------------------------------------------------';
			
			/* Start assumptions */
			
			loop while: true{
				Guest currentBestToMoveGuest <- nil;
				Stage currentBestToMoveStage <- nil;
				float currentBestUtility <- 0.0;
				float currentBestGlobalUtility <- globalUtility;
				
				loop guest over: Guest{
					list<Stage> notAtStages <- list(Stage);
					Stage guestOriginalStage <- guestStageMap[guest];
					remove item: guestOriginalStage from: notAtStages;
					/* Assume the guest go to other stages */
					loop stage over: notAtStages{
						/* Use temporary map to store the changes */
						map<Stage, int> newNumberOfGuestsAtStages <- [];
						map<Guest, Stage> newGuestStageMap <- [];
						map<Guest, float> newGuestUtilityMap <- [];
						loop stageTemp1 over: numberOfGuestsAtStages.keys{
							newNumberOfGuestsAtStages[stageTemp1] <- numberOfGuestsAtStages[stageTemp1];
						}
						loop guestTemp1 over: guestStageMap.keys{
							newGuestStageMap[guestTemp1] <- guestStageMap[guestTemp1];
						}
						loop guestTemp2 over: guestUtilityMap.keys{
							newGuestUtilityMap[guestTemp2] <- guestUtilityMap[guestTemp2];
						}
						
						/* Assume the guest move to another stage */
						float newGuestUtility <- 0.0;
						/* Calculate the preference utility at the stage */
						loop counter from: 0 to: numberOfAttributes - 1{
							newGuestUtility <- newGuestUtility + guestPreferenceMap[guest][counter] * stageDetailsMap[stage][counter];
						}
						/* Update temporary maps */
						newNumberOfGuestsAtStages[guestOriginalStage] <- newNumberOfGuestsAtStages[guestOriginalStage] - 1;
						newNumberOfGuestsAtStages[stage] <- newNumberOfGuestsAtStages[stage] + 1;
						newGuestStageMap[guest] <- stage;
//						write "Guest: " + guest + ' Stage: ' + stage + ' guestStageMap: ' + guestStageMap;
						newGuestUtilityMap[guest] <- newGuestUtility;
						map<Guest, float> newGuestCrowdUtilityMap <- [];
						/* Calculate the crowd utility map */
						loop guestTemp over: newGuestStageMap.keys{
							newGuestCrowdUtilityMap[guestTemp] <- newNumberOfGuestsAtStages[newGuestStageMap[guestTemp]] * guestCrowdPreferenceMap[guestTemp];
						}
						/* Calculate the new global utility */
						float newGlobalUtility <- sum(newGuestUtilityMap.values) + sum(newGuestCrowdUtilityMap.values);
						if (newGlobalUtility > currentBestGlobalUtility){
							currentBestGlobalUtility <- newGlobalUtility;
							currentBestToMoveStage <- stage;
							currentBestToMoveGuest <- guest;
						}
					}
				}
				
				if (currentBestToMoveGuest = nil){
					write 'Global utility after changing: ' + globalUtility;
					write 'Guest stage map:' + guestStageMap;
					write 'The change map: ' + changeMap;
					write 'The number of guests at each stage: ' + numberOfGuestsAtStages;
					write '--------------------------------------------------';
					break;
				}
				
				/* Update global maps */
				numberOfGuestsAtStages[guestStageMap[currentBestToMoveGuest]] <- numberOfGuestsAtStages[guestStageMap[currentBestToMoveGuest]] - 1;
				numberOfGuestsAtStages[currentBestToMoveStage] <- numberOfGuestsAtStages[currentBestToMoveStage] + 1;
				guestStageMap[currentBestToMoveGuest] <- currentBestToMoveStage;
				guestUtilityMap[currentBestToMoveGuest] <- currentBestUtility;
				globalUtility <- currentBestGlobalUtility;
				changeMap[currentBestToMoveGuest] <- currentBestToMoveStage;
			}
			/* Inform the guests */
			do start_conversation to: list(Guest) protocol: 'fipa-contract-net' performative: 'inform' contents: ['This is the result:', guestStageMap];	
		}
	}
}

species Guest skills: [fipa, moving]{
	list<float> preference <- [];
	float crowdPreference <- rnd(-1.0, 1.0);
	map<Stage, float> utilityMap <- [];
	/* The stage whose utility is the largest */
	Stage maxUtilityStage <- nil;
	Stage maxGlobalUtilityStage <- nil;
	
	init{
		/* Set preferences */
		loop times: numberOfAttributes{
			preference <+ rnd(0.0, 1.0);
		}
		
		/* Normalization */
		float sumPreference <- sum(preference);
		loop counter from: 0 to: numberOfAttributes - 1{
			/* act preference weight: crowd preference weith = aPW: 20 */
			preference[counter] <- preference[counter] / sumPreference * actPreferenceWeight;
		}
		
		write name + ' preference: ' + preference + ', crowd preference: ' + crowdPreference;
		/* Initialize the utility map */
		loop stage over: Stage{
			utilityMap[stage] <- 0.0;
		}
	}
	
	reflex responseInformAndGetStage when: !empty(informs){
		/* Recieve messages */
		bool responseAct <- false;
		bool responseLeader <- false;
		loop informMsg over: informs{
			/* If the informs are from stages */
			if ('New acts available!' in informMsg.contents[0])
			{
				responseAct <- true;
				list<float> details <- informMsg.contents[1];
				float utility <- 0.0;
				/* Calculate utilities */
				loop counter from:0 to: length(preference) - 1{
					utility <- utility + details[counter] * preference[counter];
				}
				/* Update the map of utilities */
				utilityMap[informMsg.sender] <- utility;	
			}
			/* If the informs are from the leader */
			if ('This is the result' in informMsg.contents[0]){
				responseLeader <- true;
				map<Guest, Stage> finalGuestStageMap <- informMsg.contents[1];
				maxGlobalUtilityStage <- finalGuestStageMap[self];
			}
		}
		/* Response the inform from stages */
		if responseAct{
			/* Go to the maximum utility stage */
			float maxUtility <- max(utilityMap.values);
			int maxUtilityIdx <- utilityMap.values index_of maxUtility;
			maxUtilityStage <- utilityMap.keys[maxUtilityIdx];
			write name + ' prefers to go to: ' + maxUtilityStage + ' whose utility is: ' + maxUtility;
			write '--------------------------------------------------';
			
			/* Inform the leader */
			do start_conversation to: list(Leader) protocol: 'fipa-contract-net' performative: 'inform' 
			contents: ['This is a guest ' + name + ', I would like to go to: ', maxUtilityStage, 
			' the utility is: ', maxUtility, ' my preference is: ',  preference, 
			' my crowd preference is: ', crowdPreference];	
		}
	}
	
	reflex gotoStage when: maxGlobalUtilityStage != nil{
			do goto target: maxGlobalUtilityStage.location speed: 5.0;	
		}
	
	aspect base
    {
        draw circle(1) at: location color: rgb('black');
    }
}

experiment assignment_3_3 type: gui{
	output{
		display map type: opengl{
			species Stage aspect: base;
			species Guest aspect: base;
		}
	}
}