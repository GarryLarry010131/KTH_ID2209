/**
* Name: scripts
* Based on the internal empty template. 
* Author: Guangyuan Li
* Tags: 
*/


model scripts

/* Insert your model definition here */
global {
	/* Numbers of agents */
	int numberOfCenters <- 1;
	int numberOfGuests <- 20;
	int numberOfGuards <- 1;
	int numberOfGuestsWithoutBrain <- 10;
	int numberOfShops <- 4;
	/* The possibility to be a bad guest */
	float turnBadRate <- 0.005;
	/* Maximum number of bad guests */
	list<Guest> badGuestsList <- [];
	int maximumOfBadGuests <- 10;
	/* Maximum cycles */
	int cycles <- 0 update: cycles + 1;
	int maxCycles <- 100000;
	/* The speed of guests */
	float guestSpeed <- 4.0;
	float rushSpeed <- 8.0;
	/* The speed of guards */
	float guardSpeed <- 8.0;
	/* The distance reduced during the maximum cycles' iteration */
	float reducedDistance <- 0.0;
	/* Set to temp to check if food or drink is not offered */
	int temp1 <- 0;
	int temp2 <- 0;

	init{
		create Center number: numberOfCenters{location <- {50.0, 50.0};}
		create Guest number: numberOfGuests;
		create Guard number: numberOfGuards;
		create GuestWithoutBrain number: numberOfGuestsWithoutBrain;
		create Shop number: numberOfShops;
		
		/* Map of different types of shops */
		map<string, list<Shop>> shopMap <- [];
		
		/* Initialize guests */
		loop counter from: 0 to: numberOfGuests - 1{
			Guest guest <- Guest[counter];
			guest <- guest.setName(counter);
		}
		
		/* Initialize shops */
		loop counter from: 0 to: numberOfShops - 1{
			Shop shop <- Shop[counter];
			
			/* If nothing offered, then make the shop offer food or drinks */
			if (!shop.offerFood and !shop.offerDrink){
				bool chooseFood <- flip(0.5);
				if (chooseFood){
					shop.offerFood <- true;
				} else {
					shop.offerDrink <- true;
				}
			}
			
			/* Number of food shops */
			if (shop.offerFood){
				temp1 <- temp1 + 1;
			}
			/* Number of drink shops */
			if (shop.offerDrink){
				temp2 <- temp2 + 1;
			}
		}
		/* If all shops don't offer food */
		if (temp1 = 0){
			/* Randomly select a store to offer food */
			int shopId <- rnd(numberOfShops);
			Shop[shopId].offerFood <- true;
			Shop[shopId].offerDrink <- false;
		}
		/* If all shops don't offer drinks */
		if (temp2 = 0){
			/* Randomly select a store to offer drinks */
			int shopId <- rnd(numberOfShops);
			Shop[shopId].offerDrink <- true;
			Shop[shopId].offerFood <- false;
		}
		
		/* Set shops' names */
		loop counter from: 0 to: numberOfShops - 1{
			Shop shop <- Shop[counter];
			shop <- shop.setName(counter);
		}
		
		/* Add to map declaring goods of each shops */
		loop counter from: 0 to: numberOfShops - 1{
			Shop shop <- Shop[counter];
			if (shop.offerFood and shop.offerDrink){
				if (shopMap["both"] != nil){
					shopMap["both"] <+ shop;
				} else{
					shopMap["both"] <- [shop];
				}
			} else if (shop.offerFood){
				if (shopMap["food"] != nil){
					shopMap["food"] <+ shop;
				} else{
					shopMap["food"] <- [shop];
				}
			} else if (shop.offerDrink){
				if (shopMap["drink"] != nil){
					shopMap["drink"] <+ shop;
				} else{
					shopMap["drink"] <- [shop];
				}
			}
		}
		
		/* Give the information center the infos of shops */
		loop counter from: 0 to: numberOfCenters - 1{
			Center center <- Center[counter];
			center.shopMap <- shopMap;
		}
		
		loop counter from: 0 to: numberOfShops - 1{
			Shop shop <- Shop[counter];
			if (shop.offerFood and shop.offerDrink){
				if (Center[0].nearestBothShop != nil){
					float distanceShop <- sqrt((list(shop.location)[0] - list(self.location)[0])^2 + (list(shop.location)[1] - list(self.location)[1])^2);
					float distanceShopTemp <- sqrt((list(Center[0].nearestBothShop.location)[0] - list(self.location)[0])^2 + (list(Center[0].nearestBothShop.location)[1] - list(self.location)[1])^2);
					if (distanceShop < distanceShopTemp){
						Center[0].nearestBothShop <- shop;
					}
				} else{
					Center[0].nearestBothShop <- shop;
				}
			} else if (shop.offerFood){
				if (Center[0].nearestFoodShop != nil){
					float distanceShop <- sqrt((list(shop.location)[0] - list(self.location)[0])^2 + (list(shop.location)[1] - list(self.location)[1])^2);
					float distanceShopTemp <- sqrt((list(Center[0].nearestFoodShop.location)[0] - list(self.location)[0])^2 + (list(Center[0].nearestFoodShop.location)[1] - list(self.location)[1])^2);
					if (distanceShop < distanceShopTemp){
						Center[0].nearestFoodShop <- shop;
					}
				} else{
					Center[0].nearestFoodShop <- shop;
				} 
			} else if (shop.offerDrink){
				if (Center[0].nearestDrinkShop != nil){
					float distanceShop <- sqrt((list(shop.location)[0] - list(self.location)[0])^2 + (list(shop.location)[1] - list(self.location)[1])^2);
					float distanceShopTemp <- sqrt((list(Center[0].nearestDrinkShop.location)[0] - list(self.location)[0])^2 + (list(Center[0].nearestDrinkShop.location)[1] - list(self.location)[1])^2);
					if (distanceShop < distanceShopTemp){
						Center[0].nearestDrinkShop <- shop;
					}
				} else{
					Center[0].nearestDrinkShop <- shop;
				}
			}
		}
	}

	reflex getBadGuestsList{
		int numBadGuestTemp <- 0;
		loop counter from: 0 to: length(list(Guest)) - 1{
			Guest guest <- Guest[counter];
			if (guest.turnBad){
				if !(guest in badGuestsList){
					badGuestsList <+ guest;
				}
			}
		}
	}

	/* Calculate how long paths are saved by using brain*/
	reflex results when: cycles = maxCycles{
		int sumGuestCycles <- 0;
		float averageGuestCycles <- 0.0;
		int sumGuestWithoutBrainCycles <- 0;
		float averageGuestWithoutBrainCycles <- 0.0;
		/* Average cycles of guests using brain */
		loop counter from: 0 to: length(list(Guest)) - 1{
			Guest guest <- Guest[counter];
			/* Only calculate the cycles of the normal guests */
			sumGuestCycles <- sumGuestCycles + guest.cyclesWithBrain;
		}
		/* Get rid of bad guests */
		averageGuestCycles <- sumGuestCycles / length(list(Guest));
		
		loop counter from: 0 to: numberOfGuestsWithoutBrain - 1{
			GuestWithoutBrain guestWithoutBrain <- GuestWithoutBrain[counter];
			sumGuestWithoutBrainCycles <- sumGuestWithoutBrainCycles + guestWithoutBrain.cyclesWithoutBrain;
		}
		averageGuestWithoutBrainCycles <- sumGuestWithoutBrainCycles / numberOfGuestsWithoutBrain;
		
		/* Reduced distances = reduced cycles * speed */
		reducedDistance <- (averageGuestWithoutBrainCycles - averageGuestCycles) * rushSpeed;
		write "The distance reduced during " + maxCycles + " cycles is: " + reducedDistance;
	}
	
	reflex printResults when: cycles > maxCycles{
		write "The distance reduced during " + maxCycles + " cycles is: " + reducedDistance;
	}
}

/* Create Information Center Agent */
species Center{
	map<string, list<Shop>> shopMap <- [];
	/* Pick out the nearest shop of each type to the center */
	Shop nearestBothShop <- nil;
	Shop nearestFoodShop <- nil;
	Shop nearestDrinkShop <- nil;
	/* The list contains the bad guests that have visited the center */
	list<Guest> badGuestsVisited <- [];
	
	aspect base{
		rgb agentColor <- rgb("lightGreen");
		draw squircle(8.0, 8.0) at: location color: agentColor;
	}
	
	reflex reportBadGuests when: badGuestsVisited != []{
		write "Report bad guests to guard:" + badGuestsVisited;
		ask Guard{
			/* Add all the bad guests on the visited list to the guard */
			loop counter from: 0 to: length(myself.badGuestsVisited) - 1{
				Guest badGuest <- myself.badGuestsVisited[counter];
				if !(badGuest in killList){
					self.killList <+ badGuest;
				}
			}
			/* Reset the bad guests visited list after the report */
			myself.badGuestsVisited <- [];
		}
	}
}

/* Create Festival Guests Agent */
species Guest skills: [moving]{
	float hungryValue <- 100.0 min: 0.0 max: 100.0;
	float thirstyValue <- 100.0 min: 0.0 max: 100.0;
	bool isHungry <- false;
	bool isThirsty <- false;
	bool turnBad <- false;
	/* If bad guest has visited the center */
	bool badVisitedCenter <- false;
	string guestName <- "Undefined";
	/* The brain will remember the locations of stores having been to */
	map<string, list<Shop>> brain <- [];
	/* The distance brain will update and write down the distance of each shop, whose values indeices are same as shops in the brain */
	map<string, list<float>> shopDistance <- [];
	/* Within the distance of the recognize threshold, guests will remember the location of the shops */
	float recognizeThreshold <- 10.0;
	/* Count the number of cycles when seeking for the store */
	int cyclesWithBrain <- 0;
	
	/* Set a name of the guest */
	action setName(int num){
		guestName <- "Guest" + num;
	}
	
	/* Set colors of status */
	aspect base{
		rgb agentColor <- rgb("green");
		
		if (isHungry and isThirsty) {
			agentColor <- rgb("red");
		} else if (isHungry) {
			agentColor <- rgb("Purple");
		} else if (isThirsty) {
			agentColor <- rgb("darkOrange");
		}
		if (turnBad){
			agentColor <- rgb("black");
		}
		
		draw circle(1) color: agentColor;
	}
	
	/* Update status of hungry or thirsty */
	reflex hungryAndThirsty{
		/* Each step hungry and thirsty values changed till under a standard */
		float hungryWeight <- rnd(0.0, 1.0);
		float thirstyWeight <- rnd(0.0, 1.0);
		hungryValue <- hungryValue - hungryWeight;
		thirstyValue <- thirstyValue - thirstyWeight;
		/* Become hungry or thirsty, food or drinks required */
		if (hungryValue < 1.0){
			isHungry <- true;
		} 
		if (thirstyValue < 1.0){
			isThirsty <- true;
		}
//		/* Print status of guests */
//		if (isHungry and isThirsty) {
//				write guestName + " is hungry and thirsty.";
//			} else if (isHungry) {
//				write guestName + " is hungry." + "The hungry value is: " + hungryValue + " The thirsty value is: " + thirstyValue;
//			} else if (isThirsty) {
//				write guestName + " is thirsty." + "The hungry value is: " + hungryValue + " The thirsty value is: " + thirstyValue;
//			} else{
//				write guestName + " is good. The hungry value is: " + hungryValue + " The thirsty value is: " + thirstyValue;
//			}
	}
	
	/* Within the distance of the recognize threshold, guests will remember the location of the shops */
	reflex rememberNearShops when: !empty(Shop at_distance recognizeThreshold){
		list<Shop> recognizedShopList <- list(Shop at_distance recognizeThreshold);
		loop counter from: 0 to: length(recognizedShopList) - 1{
			Shop nearShop <- recognizedShopList[counter];
			/* Write near shops info into the brain */
			if (nearShop.offerFood and nearShop.offerDrink){
				if (brain["both"] != nil){
					if (!(nearShop in brain["both"])){
						brain["both"] <+ nearShop;
						}
				} else{
					brain["both"] <- [nearShop];
				}
			} else if (nearShop.offerFood){
				if (brain["food"] != nil){
					if (!(nearShop in brain["food"])){
						brain["food"] <+ nearShop;
						}
				} else{
					brain["food"] <- [nearShop];
				}
			} else if (nearShop.offerDrink){
				if (brain["drink"] != nil){
					if (!(nearShop in brain["drink"])){
						brain["drink"] <+ nearShop;
						}
				} else{
					brain["drink"] <- [nearShop];
				}
			}
		}
	}
	
	/* Calculate and write down the distance of the shops in the brain */
	reflex calculateDistances when: !empty(brain){
		list<float> bothDistanceList <- [];
		list<float> foodDistanceList <- [];
		list<float> drinkDistanceList <- [];
		if (brain["both"] != nil){
			loop count from: 0 to: length(brain["both"]) - 1{
				Shop shopInBrain <- brain["both"][count];
				list<float> guestLoc <- list(location);
				list<float> shopInBrainLoc <- list(shopInBrain.location);
				/* Calculate distances */
				float distance <- sqrt((guestLoc[0] - shopInBrainLoc[0])^2 + (guestLoc[1] - shopInBrainLoc[1])^2);
				bothDistanceList <+ distance;
				shopDistance["both"] <- bothDistanceList;
			}
		} 
		if (brain["food"] != nil){
			loop count from: 0 to: length(brain["food"]) - 1{
				Shop shopInBrain <- brain["food"][count];
				list<float> guestLoc <- list(location);
				list<float> shopInBrainLoc <- list(shopInBrain.location);
				float distance <- sqrt((guestLoc[0] - shopInBrainLoc[0])^2 + (guestLoc[1] - shopInBrainLoc[1])^2);
				foodDistanceList <+ distance;
				shopDistance["food"] <- foodDistanceList;
			}
		} 
		if (brain["drink"] != nil){
			loop count from: 0 to: length(brain["drink"]) - 1{
				Shop shopInBrain <- brain["drink"][count];
				list<float> guestLoc <- list(location);
				list<float> shopInBrainLoc <- list(shopInBrain.location);
				float distance <- sqrt((guestLoc[0] - shopInBrainLoc[0])^2 + (guestLoc[1] - shopInBrainLoc[1])^2);
				drinkDistanceList <+ distance;
				shopDistance["drink"] <- drinkDistanceList;
			}
		}
	}
	
	/* Move */
	reflex move{
		if (!turnBad){
			if (!isHungry and !isThirsty){
				/* Explore when not hungry or thirsty */
				do wander speed: guestSpeed;
				} else if (isHungry and isThirsty){
					/* When the guest is not good, start counting */
					cyclesWithBrain <- cyclesWithBrain + 1;
					/* If the guest knows where the shops selling both */
					if (brain["both"] != nil){
						/* Go to the nearest shop */
						int nearestBothShopIdx <- shopDistance["both"] index_of min(shopDistance["both"]);
						Shop nearestBothShop <- brain["both"][nearestBothShopIdx];
						do goto target: nearestBothShop.location speed: rushSpeed;
					} else if (brain["food"] != nil and hungryValue <= thirstyValue){
						/* More hungry and know the food shop  */
						int nearestFoodShopIdx <- shopDistance["food"] index_of min(shopDistance["food"]);
						Shop nearestFoodShop <- brain["food"][nearestFoodShopIdx];
						do goto target: nearestFoodShop.location speed: rushSpeed;
					} else if (brain["drink"] != nil and thirstyValue <= hungryValue){
						/* More thirsty and know the drinks shop */
						int nearestDrinkShopIdx <- shopDistance["drink"] index_of min(shopDistance["drink"]);
						Shop nearestDrinkShop <- brain["drink"][nearestDrinkShopIdx];
						do goto target: nearestDrinkShop.location speed: rushSpeed;
					} else{
						/* Nothing useful in brain, go to info center and ask */
						do goto target: Center[0].location speed: rushSpeed;
					}
				} else if (isHungry){
					cyclesWithBrain <- cyclesWithBrain + 1;
					/* If the guest knows where the shops selling food */
					if (brain["food"] != nil or brain["both"] != nil){
						if (brain["food"] != nil){
							int nearestFoodShopIdx <- shopDistance["food"] index_of min(shopDistance["food"]);
							Shop nearestFoodShop <- brain["food"][nearestFoodShopIdx];
							do goto target: nearestFoodShop.location speed: rushSpeed;
						} else{
							int nearestBothShopIdx <- shopDistance["both"] index_of min(shopDistance["both"]);
							Shop nearestBothShop <- brain["both"][nearestBothShopIdx];
							do goto target: nearestBothShop.location speed: rushSpeed;
						}
					} else{
						/* Nothing useful in brain, go to info center and ask */
						do goto target: Center[0].location speed: rushSpeed;
					}
				} else if (isThirsty){
					cyclesWithBrain <- cyclesWithBrain + 1;
					/* If the guest knows where the shops selling drinks */
					if (brain["drink"] != nil or brain["both"] != nil){
						if (brain["drink"] != nil){
							int nearestDrinkShopIdx <- shopDistance["drink"] index_of min(shopDistance["drink"]);
							Shop nearestDrinkShop <- brain["drink"][nearestDrinkShopIdx];
							do goto target: nearestDrinkShop.location speed: rushSpeed;
						} else{
							int nearestBothShopIdx <- shopDistance["both"] index_of min(shopDistance["both"]);
							Shop nearestBothShop <- brain["both"][nearestBothShopIdx];
							do goto target: nearestBothShop.location speed: rushSpeed;
						}
					} else{
						/* Nothing useful in brain, go to info center and ask */
						do goto target: Center[0].location speed: rushSpeed;
					}
				}
			} else{
				if (!badVisitedCenter){
					/* Bad guests will immediately heading to the information center seeking fights */
					do goto target: Center[0].location speed: rushSpeed;
					} else{
						/* After visited the center, bad guests hanging around for fights */
						do wander speed: guestSpeed;
					}
			}
	}
	
	/* If the guest at the shop, reset the value of either of the attributes */
	reflex resetAttributes when: (!empty(Shop at_distance 0.1) and (isHungry or isThirsty)){
		Shop inShop <- list(Shop at_distance 1.0)[0];
		if (inShop.offerFood and inShop.offerDrink){
			hungryValue <- 100.0;
			isHungry <- false;
			thirstyValue <- 100.0;
			isThirsty <- false;
			write guestName + " got food and drinks at " + inShop.shopName;
		} else if (inShop.offerFood){
			hungryValue <- 100.0;
			isHungry <- false;
			write guestName + " got food at " + inShop.shopName;
		} else if (inShop.offerDrink){
			thirstyValue <- 100.0;
			isThirsty <- false;
			write guestName + " got drinks at " + inShop.shopName;
		}
	}
	
	/* Ask the information center about infos */
	reflex askInfos when: !empty(Center at_distance 0.1){
		ask Center{
			if ((myself.isHungry or myself.isThirsty) and !myself.turnBad){
				myself.brain <- self.shopMap;
				write myself.guestName + " got infos at information center";
				write "The updated brain: " + myself.brain;
				write "The updated shopDistance: " + myself.shopDistance;
				}
			
			if (myself.turnBad and !myself.badVisitedCenter){
				/* Bad guests marked as visited */
				myself.badVisitedCenter <- true;
				self.badGuestsVisited <+ myself;
			}
		}
	}
	
	/* Some normal guests will turn bad according to turnBadRate */
	reflex becomingBad when: length(badGuestsList) < maximumOfBadGuests{
		if (!turnBad){
			turnBad <- flip(turnBadRate);
		}
	}
}

/* Create Festival Guard Agent */
species Guard skills: [moving]{
	/* List of bad guests */
	list<Guest> killList <- [];
	
	aspect base{
		draw triangle(2.0) color: rgb("orange");
	}
	
	reflex move when: killList = []{
		do wander speed: guardSpeed;
	}
	
	/* Find and kill the bad guests */
	reflex killBad when: killList != []{
		Guest badGuest <- killList[0];
		do goto target: badGuest.location speed: guardSpeed;
		/* If bad guest closed, then kill */
		if (location distance_to badGuest.location < 0.5){
			ask badGuest{
				write "Bad guest " + badGuest.guestName + " got killed.";
				do die;
			}
			remove from: killList index: 0;
		}
	}
}

/* Create Festival Guests Agent */
species GuestWithoutBrain skills: [moving]{
	float hungryValue <- 100.0 min: 0.0 max: 100.0;
	float thirstyValue <- 100.0 min: 0.0 max: 100.0;
	bool isHungry <- false;
	bool isThirsty <- false;
	/* Goto targetPoint */
	point targetPoint <- nil;
	/* Count the number of cycles when seeking for the store */
	int cyclesWithoutBrain <- 0;
	
//	reflex{
//		write targetPoint;
//	}
	
	/* Set colors of status */
	aspect base{
		rgb agentColor <- rgb("green");
		
		if (isHungry and isThirsty) {
			agentColor <- rgb("red");
		} else if (isHungry) {
			agentColor <- rgb("Purple");
		} else if (isThirsty) {
			agentColor <- rgb("darkOrange");
		}
		
		draw circle(1) color: agentColor;
	}
	
	/* Update status of hungry or thirsty */
	reflex hungryAndThirsty{
		/* Each step hungry and thirsty values changed till under a standard */
		float hungryWeight <- rnd(0.0, 1.0);
		float thirstyWeight <- rnd(0.0, 1.0);
		hungryValue <- hungryValue - hungryWeight;
		thirstyValue <- thirstyValue - thirstyWeight;
		/* Become hungry or thirsty, food or drinks required */
		if (hungryValue < 1.0){
			isHungry <- true;
		} 
		if (thirstyValue < 1.0){
			isThirsty <- true;
		}
	}
	
	/* Move */
	reflex move{
		if (!isHungry and !isThirsty){
			/* Explore when not hungry or thirsty */
			do wander speed: guestSpeed;
			} else{
				if (targetPoint != nil){
					do goto target: targetPoint speed: rushSpeed;
				} else{
					do goto target: Center[0].location speed: rushSpeed;
				}
				cyclesWithoutBrain <- cyclesWithoutBrain + 1;
			}
	}
	
	/* If the guest at the shop, reset the value of either of the attributes */
	reflex resetAttributes when: (!empty(Shop at_distance 0.1) and (isHungry or isThirsty)){
		Shop inShop <- list(Shop at_distance 1.0)[0];
		if (inShop.offerFood and inShop.offerDrink){
			hungryValue <- 100.0;
			isHungry <- false;
			thirstyValue <- 100.0;
			isThirsty <- false;
		} else if (inShop.offerFood){
			hungryValue <- 100.0;
			isHungry <- false;
		} else if (inShop.offerDrink){
			thirstyValue <- 100.0;
			isThirsty <- false;
		}
		targetPoint <- nil;
	}
	
	/* Ask the information center about infos */
	reflex askInfos when: (!empty(Center at_distance 0.1) and (isHungry or isThirsty)){
		ask Center{
			if (myself.isHungry and myself.isThirsty){
				if (self.shopMap["both"] != nil){
					myself.targetPoint <- self.nearestBothShop.location;
				} else if (myself.hungryValue >= myself.thirstyValue){
					myself.targetPoint <- self.nearestFoodShop.location;
				} else{
					myself.targetPoint <- self.nearestDrinkShop.location;
				}
			} else if (myself.isHungry){
				if (self.shopMap["food"] != nil){
					myself.targetPoint <- self.nearestFoodShop.location;
				} else{
					myself.targetPoint <- self.nearestBothShop.location;
				}
			} else if (myself.isThirsty){
				if (self.shopMap["drink"] != nil){
					myself.targetPoint <- self.nearestDrinkShop.location;
				} else{
					myself.targetPoint <- self.nearestBothShop.location;
				}
			}
		}
	}
}

/* Create Shops Agent */
species Shop{
	bool offerFood <- flip(0.5);
	bool offerDrink <- flip(0.5);
	string shopName <- "Undefined";
	
	/* Set colors of different shops */
	aspect base{
		rgb agentColor <- rgb("black");
		
		if (offerFood and offerDrink){
			agentColor <- rgb("Green");
		} else if (offerFood){
			agentColor <- rgb("yellow");	
		} else if (offerDrink){
			agentColor <- rgb("blue");
		}
		
		draw square(4) color: agentColor;
	}
	
	/* Set a name of the shop */
	action setName(int num) {
		if (offerFood and offerDrink){
			shopName <- "BothShop" + num;
		} else if (offerFood){
			shopName <- "FoodShop" + num;
		} else if (offerDrink){
			shopName <- "DrinkShop" + num;
		}
	}
}



experiment assignment_1 type: gui {
	output {
		display myDisplay{
			species Center aspect: base;
			species Guest aspect: base;
			species Guard aspect: base;
			species GuestWithoutBrain aspect: base;
			species Shop aspect: base;
		}
	}
}