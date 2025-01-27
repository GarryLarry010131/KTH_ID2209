/**
* Name: BasicFIPA
* Based on the internal empty template. 
* Author: Guangyuan Li
* Tags: 
*/


model challenge_1

global {
	/* Number of agents */
	int numberOfBars <- 2;
	int numberOfCasinos <- 2;
	int numberOfGuests <- 20;
	int numberOfSingers <- 20;
	int numberOfBoozers <- 10;
	int numberOfThieves <- 5;
	int numberOfGuards <- 30;
	/* Locations */
	list<point> barsLocations <- [{25.0, 25.0}, {75.0, 75.0}]; 
	list<point> casinosLocations <- [{25.0, 75.0}, {75.0, 25.0}];
	
	/* Believes */
	string barAtLocation <- "barAtLocation";
	string casinoAtLocation <- "casinoAtLocation";
	string guestAtLocation <- "guestAtLocation";
	string singerAtLocation <- "singerAtLocation";
	string boozerAtLocation <- "drunkAtLocation";
	string thiefAtLocation <- "thiefAtLocation";
	
	/* Predicates */
	predicate barLocation <- new_predicate(barAtLocation);
	predicate casinoLocation <- new_predicate(casinoAtLocation);
	predicate guestLocation <- new_predicate(guestAtLocation);
	predicate singerLocation <- new_predicate(singerAtLocation);
	predicate boozerLocation <- new_predicate(boozerAtLocation);
	predicate thiefLocation <- new_predicate(thiefAtLocation);
	/* Desires */
	predicate guestDesire <- new_predicate("guestDesire");
	predicate singerDesire <- new_predicate("singerDesire");
	predicate boozerDesire <- new_predicate("boozerDesire");
	predicate thiefDesire <- new_predicate("thiefDesire");
	predicate guardDesire <- new_predicate("guardDesire");
	
	predicate wanderDesire <- new_predicate("wanderDesire");
	predicate goBarDesire <- new_predicate("goBarDesire");
	predicate goCasinoDesire <- new_predicate("goCasinoDesire");
	predicate goToBoozerDesire <- new_predicate("goToBoozerDesire");
	predicate goToGuestDesire <- new_predicate("goToGuestDesire");
	predicate goToGuardDesire <- new_predicate("goToGuardDesire");
	
	predicate listenSongsDesire <- new_predicate("listenSongsDesire");
	predicate drinkDesire <- new_predicate("drinkDesire");
	predicate fightDesire <- new_predicate("fightDesire");
	predicate stealBoozerDesire <- new_predicate("stealBoozerDesire");
	predicate stealGuestDesire <- new_predicate("stealGuestDesire");
	predicate catchBoozerDesire <- new_predicate("catchBoozerDesire");
	predicate catchThiefDesire <- new_predicate("catchThiefDesire");
	predicate offerDrinkDesire <- new_predicate("offerDrinkDesire");
	predicate restDesire <- new_predicate("restDesire");
	
	/* Map */
	map<string, float> wealthMapAgent;
	map<string, float> wealthMapSpecie;
	float totalWealth <- 0.0;
	
	/* Configurations */
	float priceDrinks <- 5.0;
	
	/* A list of locations */
	list<point> headingLocation <- [{12.5, 12.5}, {12.5, 87.5}, {87.5, 12.5}, {87.5, 87.5}, {50.0, 50.0},
					{37.5, 37.5}, {37.5, 62.5}, {62.5, 37.5}, {62.5, 62.5}, 
					{12.5, 62.5}, {62.5, 12.5}, {12.5, 37.5}, {37.5, 12.5}, 
					{62.5, 87.5}, {87.5, 62.5}, {37.5, 87.5}, {87.5, 37.5}];
	
	init{
		/* Initialize bars */
		create Bar number: numberOfBars;
		loop bar_counter from: 0 to: numberOfBars - 1{
			Bar[bar_counter].location <- barsLocations[bar_counter];
		}
		/* Initialize casinos */
		create Casino number: numberOfCasinos;
		loop casino_counter from: 0 to: numberOfCasinos - 1{
			Casino[casino_counter].location <- casinosLocations[casino_counter];
		}
		/* Initialize characters */
		create Guest number: numberOfGuests;
		create Singer number: numberOfSingers;
		create Boozer number: numberOfBoozers;
		create Thief number: numberOfThieves;
		create Guard number: numberOfGuards;
		
		loop counterLocation from: 0 to: length(headingLocation) - 1{
			Singer[counterLocation].headingPlace <- headingLocation[counterLocation];
		}
	}
	
	reflex{
		write '----------------------------------------------------------';
		float currentWealth <- 0.0;
		float guestWealth <- 0.0;
		float singerWealth <- 0.0;
		float boozerWealth <- 0.0;
		float thiefWealth <- 0.0;
		float guardWealth <- 0.0;
		loop guest over: Guest{
			wealthMapAgent[guest.name] <- guest.wealthRate;
			guestWealth <- guestWealth + guest.wealthRate;
			currentWealth <- currentWealth + guest.wealthRate;
		}
		loop singer over: Singer{
			wealthMapAgent[singer.name] <- singer.wealthRate;
			singerWealth <- singerWealth + singer.wealthRate;
			currentWealth <- currentWealth + singer.wealthRate;
		}
		loop boozer over: Boozer{
			wealthMapAgent[boozer.name] <- boozer.wealthRate;
			boozerWealth <- boozerWealth + boozer.wealthRate;
			currentWealth <- currentWealth + boozer.wealthRate;
		}
		loop thief over: Thief{
			wealthMapAgent[thief.name] <- thief.wealthRate;
			thiefWealth <- thiefWealth + thief.wealthRate;
			currentWealth <- currentWealth + thief.wealthRate;
		}
		loop guard over: Guard{
			wealthMapAgent[guard.name] <- guard.wealthRate;
			guardWealth <- guardWealth + guard.wealthRate;
			currentWealth <- currentWealth + guard.wealthRate;
		}
		wealthMapSpecie['Guest'] <- guestWealth;
		wealthMapSpecie['Singer'] <- singerWealth;
		wealthMapSpecie['Boozer'] <- boozerWealth;
		wealthMapSpecie['Thief'] <- thiefWealth;
		wealthMapSpecie['Guard'] <- guardWealth;
		totalWealth <- currentWealth;
	}
}

species Bar skills: [fipa]{
	reflex processInforms when: !empty(informs){
			loop informMsg over: informs{
				write name + ' has offered drinks to: ' + informMsg.sender;
				/* Delete msgs */
				string dummy <- informMsg.contents[0];
			}
		}
	
	aspect base{
		draw square(5) at: location color: rgb('brown');
	}
}

species Casino skills: [fipa]{
	reflex processInforms when: !empty(informs){
			loop informMsg over: informs{
				if 'guest' in informMsg.contents[0] or 'boozer' in informMsg.contents[0]{
					/* Guest and boozer will win money. */
					float rewards <- float(informMsg.contents[1]);
					write name + ' has lost money: ' + rewards + ' to ' + informMsg.sender;	
				} else if 'singer' in informMsg.contents[0] or 'guard' in informMsg.contents[0]{
					/* Singer and guard will loose money. */
					float rewards <- float(informMsg.contents[1]);
					write name + ' has won money: ' + rewards + ' from ' + informMsg.sender;
				}
			}
		}
	
	aspect base{
		draw square(5) at: location color: rgb('orange');
	}
}

species Guest skills: [moving, fipa] control: simple_bdi{
	float happyRate <- rnd(0.0, 80.0) min: 0.0 max: 100.0;
	float wealthRate <- rnd(60.0, 100.0) min: 0.0;
	float drunkRate <- 0.0 min: 0.0 max: 100.0;
	
	float viewDis <- 5.0;
	
	list<Boozer> hitByBoozerList <- [];
	list<Thief> stolenByThiefList <- [];
	
	init{
		do add_desire(wanderDesire);
	}
	
	/* Default status: wandering */
	plan doWander intention: wanderDesire{
		if drunkRate < 40.0{
			do wander speed: 1.0;
			drunkRate <- drunkRate - rnd(0.0, 1.0);
		} else{
			/* If drunk. */
			do wander speed: 0.3;
			drunkRate <- drunkRate - rnd(1.0, 2.5);
		}
	}
	                                                           
	/* -------------------------Listen Songs------------------------- */
	perceive target: Singer where (each.singing = true) in: viewDis{
		focus id: singerAtLocation var: location;
		ask myself{
			/* If having enough money, then listen songs. */
			if wealthRate >= 10.0{
				do add_desire(predicate: listenSongsDesire, strength: 3.0);
				do remove_intention(wanderDesire, false);	
			}
		}
	}
	
	plan listenSongs intention: listenSongsDesire {
		list<Singer> singerList <- get_beliefs_with_name(singerAtLocation) collect (Singer(get_predicate(mental_state (each)).values["location_value"]));
		Singer nearestSinger <- singerList with_min_of (each distance_to self);
		float tips <- rnd(4.0, 8.0);
		/* Listen to the music if having enough money, and in the horizon. */
		if wealthRate > tips and (nearestSinger distance_to location) <= viewDis{
			do start_conversation to: list(nearestSinger) protocol: 'fipa-contract-net' performative: 'inform' 
			contents: ['I am a guest: ' + name + ', I am enjoying your songs! I will give you tips: ', tips];
			wealthRate <- wealthRate - tips;
			/* Listen to songs will increase happy rates. */
			happyRate <- happyRate + rnd(0.0, 4.0);
		} else {
			/* Quit listening if money is insufficient. */
			do remove_intention(listenSongsDesire, true);
		}
	}
	/* -------------------------End------------------------- */
	
	/* -------------------------Insufficient Money------------------------- */
	reflex insufficientMoney when: wealthRate < 10.0{
		do add_desire(predicate: goCasinoDesire, strength: 5.0);
	}
	
	plan goCasinoWinMoney intention: goCasinoDesire{
		Casino nearestCasino <- list(Casino) with_min_of (each distance_to self);
		/* Different speed if drunk. */
		float goCasinoSpeed <- 0.0;
		float drunkRateDecay <- 0.0;
		if drunkRate < 40.0{
			goCasinoSpeed <- 1.0;
			drunkRateDecay <- rnd(0.0, 1.0);
		} else{
			goCasinoSpeed <- 0.3;
			drunkRateDecay <- rnd(1.0, 2.5);
		}
		/* Go to casino */
		do goto target: nearestCasino speed: goCasinoSpeed;
		drunkRate <- drunkRate - drunkRateDecay;
		/* Reach casino */
		if nearestCasino.location = location{
			float rewards <- rnd(60.0, 100.0);
			do start_conversation to: list(nearestCasino) protocol: 'fipa-contract-net' performative: 'inform' 
			contents: ['I am a guest: ' + name + ', I have won this amount of money: ', rewards];
			wealthRate <- wealthRate + rewards;
			do remove_intention(goCasinoDesire, true);
		}
	}
	/* -------------------------End------------------------- */
	/* -------------------------Happy and Have Money then Go Bar to Drink------------------------- */
	reflex statusHappyToDrink when: happyRate >= 80.0 and wealthRate >= 10.0 and drunkRate <60.0{
		do add_desire(predicate: drinkDesire, strength: 4.0);
	}
	
	plan haveDrinksAtBar intention: drinkDesire{
		Bar nearestBar <- list(Bar) with_min_of (each distance_to self);
		/* If at a bar, then have drinks. */
		if (nearestBar.location = location){
			if drunkRate >= 100.0{
				/* If drunk, stop drinking. */
				do remove_intention(drinkDesire, true);
				/* Reset happyRate */
				happyRate <- rnd(0.0, 40.0);
			} else{
				if wealthRate >= priceDrinks and happyRate >= 80.0{
					/* Have money and happy(in case of being stolen or hit. */
					do start_conversation to: list(nearestBar) protocol: 'fipa-contract-net' performative: 'inform' 
					contents: ['I am a guest: ' + name + ', I would like to have a drink.'];
					drunkRate <- drunkRate + rnd(4.0, 10.0);
					wealthRate <- wealthRate - priceDrinks;
				} else{
					do remove_intention(drinkDesire, true);
				}
			}
		} else{
			/* Else go to the nearest bar. */
			do add_subintention(get_current_intention(), goBarDesire, true);
			do current_intention_on_hold();
		}
	}
	
	plan goBar intention: goBarDesire{
		Bar nearestBar <- list(Bar) with_min_of (each distance_to self);
		/* Different speed if drunk. */
		float goBarSpeed <- 0.0;
		float drunkRateDecay <- 0.0;
		if drunkRate < 40.0{
			goBarSpeed <- 1.0;
			drunkRateDecay <- rnd(0.0, 1.0);
		} else{
			goBarSpeed <- 0.3;
			drunkRateDecay <- rnd(1.0, 2.5);
		}
		/* Go to bar */
		do goto target: nearestBar speed: goBarSpeed;
		drunkRate <- drunkRate - drunkRateDecay;
		/* Reach bar */
		if nearestBar.location = location{
			do remove_intention(goBarDesire, true);
		}
	}
	/* -------------------------End------------------------- */
	/* -------------------------Be Hit or Stolen------------------------- */
	reflex processInforms when: !empty(informs){
		loop informMsg over: informs{
			if 'boozer' in informMsg.contents[0]{
				/* Hit by a boozer. */
				write name + ' was kicked by ' + informMsg.sender;
				string dummy <- informMsg.contents[0];
				hitByBoozerList <+ informMsg.sender;
				/* Be hit, unhappy! */
				happyRate <- happyRate - rnd(5.0, 15.0);
			} else if 'thief' in informMsg.contents[0]{
				if bool(informMsg.contents[2]){
					float moneyLost <- float(informMsg.contents[1]);
					/* Successfully stolen. */
					write name + ' was successfully stolen by ' + informMsg.sender + '. And he did not realize that! ' 
					+ moneyLost + ' money was lost.';
					/* Be stolen! */
					happyRate <- happyRate - rnd(5.0, 8.0);
					wealthRate <- wealthRate - moneyLost;
				} else{
					/* Failed stolen. */
					write name + ' was failed stolen by ' + informMsg.sender;
					stolenByThiefList <+ informMsg.sender;
					/* I am happy that I have not been stolen. */
					happyRate <- happyRate + rnd(5.0, 8.0);
				}
				string dummy <- informMsg.contents[0];
			}
		}
	}
	/* -------------------------End------------------------- */
	/* -------------------------Call guards------------------------- */
	reflex callGuards when: !empty(hitByBoozerList) or !empty(stolenByThiefList){
		Guard nearestGuard <- list(Guard) with_min_of (each distance_to self);
		if !empty(hitByBoozerList){
			do start_conversation to: list(nearestGuard) protocol: 'fipa-contract-net' performative: 'inform' 
			contents: ['I am a guest: ' + name + ', I have hit by boozers: ', hitByBoozerList];	
			/* Reset the list after reporting. */
			hitByBoozerList <- [];
		} else if !empty(stolenByThiefList){
			do start_conversation to: list(nearestGuard) protocol: 'fipa-contract-net' performative: 'inform' 
			contents: ['I am a guest: ' + name + ', I was stolen by thieves: ', stolenByThiefList];	
			/* Reset the list after reporting. */
			stolenByThiefList <- [];
		}
	}
	/* -------------------------End------------------------- */
	
	aspect base{
		draw circle(1) at: location color: rgb('green');
	}
}

species Singer skills: [moving, fipa] control: simple_bdi{
	float tiredRate <- 0.0 min: 0.0 max: 100.0;
	float wealthRate <- rnd(0.0, 100.0) min: 0.0 max: 100.0;
	bool afraid <- false;
	
	bool singing <- true;
	bool haveBeenToCasino <- false;
	
	float viewDis <- 5.0;
	
	/* Place where the singer goes after going to the casino. */
	point headingPlace <- headingLocation[rnd(0, length(headingLocation) - 1)];
	
	init{
		do add_desire(wanderDesire);
	}
	
	/* Default status: wandering */
	reflex recoverFromTired when: tiredRate = 0.0 and haveBeenToCasino{
		singing <- true;
		haveBeenToCasino <- false;
	}
	
	plan doSing intention: wanderDesire{
		float singerSpeed <- 0.3;
		/* If not tired, then sing. */
		if singing{
			tiredRate <- tiredRate + rnd(0.0, 2.0);
			do wander speed: singerSpeed;
		} else if !singing and haveBeenToCasino{
			/* Having rest and get away from the casino. */
			singerSpeed <- 3.0;
			tiredRate <- tiredRate - rnd(0.0, 2.0);
			/* Go to the other location of the map to get awaay from the current casino */
			if !(location = headingPlace){
				do goto target: headingPlace speed: singerSpeed;
			} else{
				/* After reaching the location */
				do wander speed: singerSpeed;
			}
		} else{
			do wander speed: singerSpeed;
		}
	}             
	
	/* -------------------------Gain Tips------------------------- */
	reflex processInforms when: !empty(informs){
		loop informMsg over: informs{
			if 'guest' in informMsg.contents[0]{
				write name + ' have recieved ' + informMsg.contents[1] + ' tips from ' + informMsg.sender;
				float tips <- float(informMsg.contents[1]);
				wealthRate <- wealthRate + tips;
			} else if 'boozer' in informMsg.contents[0]{
				write name + ' has been heard by ' + informMsg.sender + ' for free.';
			}
		}
	}
	/* -------------------------End------------------------- */
	/* -------------------------Tired and Go to a casino Then Rest------------------------- */
	reflex getTiredAndGoCasino when: tiredRate = 100.0 and !haveBeenToCasino{
		singing <- false;
		do remove_intention(wanderDesire, false);
		do add_desire(predicate: goCasinoDesire, strength: 5.0);
	}
	
	/* If tired then go to the casino. */
	plan goCasinoToRest intention: goCasinoDesire{
		Casino nearestCasino <- list(Casino) with_min_of (each distance_to self);
		/* Go to casino */
		do goto target: nearestCasino speed: 1.0;
		/* Reach casino */
		if nearestCasino.location = location{
			float debt <- rnd(0.0, wealthRate);
			do start_conversation to: list(nearestCasino) protocol: 'fipa-contract-net' performative: 'inform' 
			contents: ['I am a singer: ' + name + ', I have lost this amount of money: ', debt];
			wealthRate <- wealthRate - debt;
			/* Mark the flag */
			haveBeenToCasino <- true;
			do remove_intention(goCasinoDesire, true);
		}
	}
	/* -------------------------End------------------------- */
	/* -------------------------Saw Fights or Stealings------------------------- */
	perceive target: Boozer where (each.foughtMark = true) in: viewDis{
		focus id: boozerAtLocation var: location;
		ask myself{
				/* Find nearest guard to report. */
				afraid <- true;
				do add_desire(predicate: goToGuardDesire, strength: 10.0);
				do remove_intention(wanderDesire, false);	
			}
		}
		
	perceive target: Thief where (each.stealingMark = true) in: viewDis{
		focus id: thiefAtLocation var: location;
		ask myself{
				afraid <- true;
				/* Find nearest guard to report. */
				do add_desire(predicate: goToGuardDesire, strength: 10.0);
				do remove_intention(wanderDesire, false);	
			}
		}
	
	plan goGuardsAndReportFoughts intention: goToGuardDesire{
		/* Find the nearest guard. */
		Guard nearestGuard <- list(Guard) with_min_of (each distance_to self);
		list<Boozer> boozerList <- get_beliefs_with_name(boozerAtLocation) collect (Boozer(get_predicate(mental_state (each)).values["location_value"]));
		list<Thief> thiefList <- get_beliefs_with_name(thiefAtLocation) collect (Thief(get_predicate(mental_state (each)).values["location_value"]));
		/* If at the guard's location. */
		if location = nearestGuard.location{
			if !empty(boozerList){
				do start_conversation to: list(nearestGuard) protocol: 'fipa-contract-net' performative: 'inform' 
				contents: ['I am a singer: ' + name + ', I have seen a fight of ', boozerList];
			} else if !empty(thiefList){
				do start_conversation to: list(nearestGuard) protocol: 'fipa-contract-net' performative: 'inform' 
				contents: ['I am a singer: ' + name + ', I have seen a stealing of ', thiefList];
			}
			afraid <- false;
			do remove_intention(goToGuardDesire, true);
		} else{
			/* If not at the guard's location, then go to find him. */
			do goto target: nearestGuard speed: 2.0;
		}
	}
	
	aspect base{
		draw circle(1) at: location color: rgb('pink');
	}
}

species Boozer skills: [moving, fipa] control: simple_bdi{
	float happyRate <- rnd(0.0, 80.0) min: 0.0 max: 100.0;
	float wealthRate <- rnd(60.0, 100.0) min: 0.0;
	float drunkRate <- 0.0 min: 0.0 max: 100.0;
	
	float viewDis <- 5.0;
	/* Will be seen by singers, and will reset being caught. */
	bool foughtMark <- false;
	
	init{
		do add_desire(wanderDesire);
	}
	
	/* Default status: wandering */
	plan doWander intention: wanderDesire{
		if drunkRate < 40.0{
			do wander speed: 1.0;
		} else{
			/* If drunk. */
			do wander speed: 0.3;
		}
	}
	
	/* -------------------------Listen Songs------------------------- */
	perceive target: Singer where (each.singing = true) in: viewDis{
		focus id: singerAtLocation var: location;
		ask myself{
			do add_desire(predicate: listenSongsDesire, strength: 3.0);
			do remove_intention(wanderDesire, false);	
		}
	}
	
	/* The boozer enjoys the songs but will not give tips. */
	plan listenSongs intention: listenSongsDesire {
		list<Singer> singerList <- get_beliefs_with_name(singerAtLocation) collect (Singer(get_predicate(mental_state (each)).values["location_value"]));
		Singer nearestSinger <- singerList with_min_of (each distance_to self);
		/* Listen to the music if having enough money, and in the horizon. */
		if (nearestSinger distance_to location) <= viewDis{
			do start_conversation to: list(nearestSinger) protocol: 'fipa-contract-net' performative: 'inform' 
			contents: ['I am a boozer: ' + name + ', I am enjoying your songs! But I will not give you tips! '];
			happyRate <- happyRate + rnd(0.0, 4.0);
		} else {
			/* Quit listening if money is insufficient. */
			do remove_intention(listenSongsDesire, true);
		}
	}
	/* -------------------------End------------------------- */
	/* -------------------------Insufficient Money------------------------- */
	reflex insufficientMoney when: wealthRate < 10.0{
		do add_desire(predicate: goCasinoDesire, strength: 5.0);
	}
	
	plan goCasinoWinMoney intention: goCasinoDesire{
		Casino nearestCasino <- list(Casino) with_min_of (each distance_to self);
		/* Different speed if drunk. */
		float goCasinoSpeed <- 0.0;
		float drunkRateDecay <- 0.0;
		if drunkRate < 40.0{
			goCasinoSpeed <- 1.0;
			drunkRateDecay <- rnd(0.0, 1.0);
		} else{
			goCasinoSpeed <- 0.3;
			drunkRateDecay <- rnd(1.0, 2.5);
		}
		/* Go to casino */
		do goto target: nearestCasino speed: goCasinoSpeed;
		drunkRate <- drunkRate - drunkRateDecay;
		/* Reach casino */
		if nearestCasino.location = location{
			float rewards <- rnd(60.0, 100.0);
			do start_conversation to: list(nearestCasino) protocol: 'fipa-contract-net' performative: 'inform' 
			contents: ['I am a guest: ' + name + ', I have won this amount of money: ', rewards];
			wealthRate <- wealthRate + rewards;
			do remove_intention(goCasinoDesire, true);
		}
	}
	/* -------------------------End------------------------- */
	/* -------------------------Happy and Have Money then Go Bar to Drink------------------------- */
	reflex statusHappyToDrink when: happyRate >= 80.0 and wealthRate >= 10.0 and drunkRate <60.0{
		do add_desire(predicate: drinkDesire, strength: 4.0);
	}
	
	plan haveDrinksAtBar intention: drinkDesire{
		Bar nearestBar <- list(Bar) with_min_of (each distance_to self);
		/* If at a bar, then have drinks. */
		if (nearestBar.location = location){
			if drunkRate >= 100.0{
				/* If drunk, stop drinking. */
				do remove_intention(drinkDesire, true);
				/* Drunk and seek fights. */
				do add_desire(predicate: fightDesire, strength: 10.0);
				/* Reset happyRate */
				happyRate <- rnd(0.0, 20.0);
			} else{
				if wealthRate >= priceDrinks and happyRate >= 80.0{
					do start_conversation to: list(nearestBar) protocol: 'fipa-contract-net' performative: 'inform' 
					contents: ['I am a boozer: ' + name + ', I would like to have a drink.'];
					drunkRate <- drunkRate + rnd(4.0, 8.0);
					happyRate <- happyRate + rnd(4.0, 8.0);
					wealthRate <- wealthRate - priceDrinks;
				} else{
					do remove_intention(drinkDesire, true);
				}
			}
		} else{
			/* Else go to the nearest bar. */
			do add_subintention(get_current_intention(), goBarDesire, true);
			do current_intention_on_hold();
		}
	}
	
	plan goBar intention: goBarDesire{
		Bar nearestBar <- list(Bar) with_min_of (each distance_to self);
		/* Different speed if drunk. */
		float goBarSpeed <- 0.0;
		float drunkRateDecay <- 0.0;
		if drunkRate < 40.0{
			goBarSpeed <- 1.0;
			drunkRateDecay <- rnd(0.0, 1.0);
		} else{
			goBarSpeed <- 0.3;
			drunkRateDecay <- rnd(1.0, 2.5);
		}
		/* Go to bar */
		do goto target: nearestBar speed: goBarSpeed;
		drunkRate <- drunkRate - drunkRateDecay;
		/* Reach bar */
		if nearestBar.location = location{
			do remove_intention(goBarDesire, true);
		}
	}
	/* -------------------------End------------------------- */
	/* -------------------------Seek Fights------------------------- */
	plan seekFights intention: fightDesire{
		Guest nearestGuest <- list(Guest) with_min_of (each distance_to self);
		if location = nearestGuest.location{
			do start_conversation to: list(nearestGuest) protocol: 'fipa-contract-net' performative: 'inform' 
					contents: ['I am a boozer: ' + name + ', and I have kicked your ass!'];
			/* Fighting has made his mind clearer. */
			drunkRate <- drunkRate - rnd(20.0, 40.0);
			foughtMark <- true;
			do remove_intention(fightDesire, true);
		} else{
			do goto target: nearestGuest.location speed: 2.0;
		}
	}
	/* -------------------------End------------------------- */
	/* -------------------------Process Informs------------------------- */
	reflex processInforms when: !empty(informs){
		loop informMsg over: informs{
			if 'guard' in informMsg.contents[0] and 'arrest' in informMsg.contents[0]{
				/* Be caught */
				float finedMoney <- float(informMsg.contents[1]);
				write name + ' is caught by: ' + informMsg.sender + ' and is fined: ' + finedMoney;
				wealthRate <- wealthRate - finedMoney;
				happyRate <- happyRate - rnd(20.0, 40.0);
				/* Reset drunk status */
				drunkRate <- 0.0;
				foughtMark <- false;
			} else if 'drink' in informMsg.contents[0]{
				/* Be offered drinks */
				write name + ' is offered drinks by: ' + informMsg.sender;
				happyRate <- happyRate + rnd(5.0, 10.0);
				drunkRate <- drunkRate + rnd(4.0, 8.0);
			} else if 'thief' in informMsg.contents[0] and !('drinks' in informMsg.contents[0]){
				if bool(informMsg.contents[2]){
					/* Be successfully stolen by a thief */
					float moneyLost <- float(informMsg.contents[1]);
					/* Successfully stolen. */
					write name + ' was successfully stolen by ' + informMsg.sender + '. And he did not realize that! ' 
					+ moneyLost + ' money was lost.';
					/* Boozer will not call a guard. */
					happyRate <- happyRate - rnd(5.0, 8.0);
					wealthRate <- wealthRate - moneyLost;
				} else{
					/* Failed stolen. */
					write name + ' was failed stolen by ' + informMsg.sender;
					/* I am happy that I have not been stolen. */
					happyRate <- happyRate + rnd(5.0, 8.0);
				}
			}
			string dummy <- informMsg.contents[0];
		}
	}
	/* -------------------------End------------------------- */
	
	aspect base{
		draw circle(1) at: location color: rgb('lightblue');
	}
}

species Thief skills: [moving, fipa] control: simple_bdi{
	float happyRate <- rnd(0.0, 60.0) min: 0.0 max: 100.0;
	float wealthRate <- rnd(0.0, 60.0) min: 0.0;
	/* Successfully stealing rate equals to 100 - afraidRate. */
	int afraidRate <- 0 min: 0 max: 100;
	
	float viewDis <- 25.0;
	Boozer boozerTarget <- nil;
	Guest guestTarget <- nil;
	/* If stealing successfully, but seen by singers. */
	bool stealingMark <- false;
	
	int waitingBoozerCounter <- 0;
	
	init{
		do add_desire(wanderDesire);
	}
	
	/* -------------------------Wander------------------------- */
	/* Default status: wandering */
	plan doWander intention: wanderDesire{
		do wander speed: 0.5;
	}
	/* -------------------------End------------------------- */
	/* -------------------------Detect the Drunks and Steal------------------------- */
	/* More prefered to steal boozer, because they are more careless. */
	/* Find boozers */
	perceive target: Boozer where (each.drunkRate > 60.0) in: viewDis{
		focus id: boozerAtLocation var: location;
		ask myself{
			/* Activate to steal. */
			do add_desire(predicate: stealBoozerDesire, strength: 4.0);
			do remove_intention(wanderDesire, false);	
		}
	}
	/* Find guests */
	perceive target: Guest where (each.drunkRate > 60.0) in: viewDis{
		focus id: guestAtLocation var: location;
		ask myself{
			/* Activate to steal. */
			do add_desire(predicate: stealGuestDesire, strength: 3.0);
			do remove_intention(wanderDesire, false);	
		}
	}
	
	/* Steal boozers */
	plan stealBoozer intention: stealBoozerDesire{
		list<Boozer> boozerList <- get_beliefs_with_name(boozerAtLocation) collect (Boozer(get_predicate(mental_state (each)).values["location_value"]));
		boozerTarget <- boozerList with_min_of (each distance_to self);
		/* If have reached the location of boozer, then steal. */
		if location = boozerTarget.location{
			bool successStealing <- (rnd(0, 100) < (100 - afraidRate));
			/* If successfully stealing */
		 	if successStealing{
		 		float stolenMoney <- rnd(10.0, 20.0);
		 		wealthRate <- wealthRate + stolenMoney;
		 		do start_conversation to: list(boozerTarget) protocol: 'fipa-contract-net' performative: 'inform' 
				contents: ['I am a thief: ' + name + ', I have stolen your money: ', stolenMoney, successStealing];
				/* Become happier for successfully stealing. */
				happyRate <- happyRate + rnd(5.0, 10.0);
				do remove_intention(stealBoozerDesire, true);
		 	} else{
		 		/* If stealing failed */
		 		do start_conversation to: list(boozerTarget) protocol: 'fipa-contract-net' performative: 'inform' 
				contents: ['I am a thief: ' + name + ', I have failed to steal your money: ', 0.0, successStealing];
				stealingMark <- true;
				do remove_intention(stealBoozerDesire, true);
		 	}
		 	/* After stealing */
			boozerTarget <- nil;
			afraidRate <- afraidRate + rnd(5, 10);
		} else{
			/* Else go his location. */
			/* Else go to the nearest bar. */
			do add_subintention(get_current_intention(), goToBoozerDesire, true);
			do current_intention_on_hold();
		}
	}
	
	plan goToBoozer intention: goToBoozerDesire{
		do goto target: boozerTarget speed: 2.0;
		if location = boozerTarget.location{
			do remove_intention(goToBoozerDesire, true);
		}
	}
	
	/* Steal guests */
	plan stealGuest intention: stealGuestDesire{
		list<Guest> guestList <- get_beliefs_with_name(guestAtLocation) collect (Guest(get_predicate(mental_state (each)).values["location_value"]));
		guestTarget <- guestList with_min_of (each distance_to self);
		/* If have reached the location of guest, then steal. */
		if location = guestTarget.location{
			bool successStealing <- (rnd(0, 100) < (100 - afraidRate));
			/* If successfully stealing */
		 	if successStealing{
		 		float stolenMoney <- rnd(10.0, 20.0);
		 		wealthRate <- wealthRate + stolenMoney;
		 		do start_conversation to: list(guestTarget) protocol: 'fipa-contract-net' performative: 'inform' 
				contents: ['I am a thief: ' + name + ', I have stolen your money: ', stolenMoney, successStealing];
				/* Become happier for successfully stealing. */
				happyRate <- happyRate + rnd(5.0, 10.0);
				do remove_intention(stealGuestDesire, true);
		 	} else{
		 		/* If stealing failed */
		 		do start_conversation to: list(guestTarget) protocol: 'fipa-contract-net' performative: 'inform' 
				contents: ['I am a thief: ' + name + ', I have failed to steal your money: ', 0.0, successStealing];
				stealingMark <- true;
				do remove_intention(stealGuestDesire, true);
		 	}
		 	/* After stealing */
			guestTarget <- nil;
			afraidRate <- afraidRate + rnd(5, 10);
		} else{
			/* Else go his location. */
			/* Else go to the nearest bar. */
			do add_subintention(get_current_intention(), goToGuestDesire, true);
			do current_intention_on_hold();
		}
	}
	
	plan goToGuest intention: goToGuestDesire{
		do goto target: guestTarget speed: 2.0;
		if location = guestTarget.location{
			do remove_intention(goToGuestDesire, true);
		}
	}
	/* -------------------------End------------------------- */
	/* -------------------------Happy and Have Enough Money, Then Go To Bar and Buy Boozer Drinks------------------------- */
	reflex happyAndEnoughMoney when: happyRate>= 60.0 and wealthRate >= priceDrinks{
		do add_desire(predicate: offerDrinkDesire, strength: 5.0);
	}
	
	plan offerDrinksAtBar intention: offerDrinkDesire{
		Bar nearestBar <- list(Bar) with_min_of (each distance_to self);
		/* If at a bar, then have drinks. */
		if (nearestBar.location = location){
			/* If at a bar, then offer a drink to boozers. */
			
			/* Get boozers who are at bar */
			list<Boozer> boozersAtBar <- [];
			loop boozerCounter from: 0 to: numberOfBoozers - 1{
				if Boozer[boozerCounter].location = location{
					boozersAtBar <+ Boozer[boozerCounter];
				}
			}
			/* Offer a drink to a randomly selected lucky boozer, if there is at least one boozer at bar. */
			if !empty(boozersAtBar){
				Boozer luckyBoozer <- boozersAtBar[rnd(0, length(boozersAtBar) - 1)];
				do start_conversation to: list(luckyBoozer) protocol: 'fipa-contract-net' performative: 'inform' 
					contents: ['I am a guard: ' + name + ', and I would like to offer you a drink!'];
				/* Happy rate decreases after offering drinks. */
				happyRate <- happyRate - rnd(25.0, 50.0);
				wealthRate <- wealthRate - priceDrinks;
				waitingBoozerCounter <- 0;
				do remove_intention(offerDrinkDesire, true);	
			} else{
				/* If no boozers at bar, then wait for 10 cycles. */
				waitingBoozerCounter <- waitingBoozerCounter + 1;
				if waitingBoozerCounter = 10{
					happyRate <- 0.0;
					waitingBoozerCounter <- 0;
					do remove_intention(offerDrinkDesire, true);
				}
			}
		} else{
			/* Else go to the nearest bar. */
			do add_subintention(get_current_intention(), goBarDesire, true);
			do current_intention_on_hold();
		}
	}
	
	plan goBar intention: goBarDesire{
		Bar nearestBar <- list(Bar) with_min_of (each distance_to self);
		/* Different speed if drunk. */
		/* Go to bar */
		do goto target: nearestBar speed: 1.0;
		/* Reach bar */
		if nearestBar.location = location{
			do remove_intention(goBarDesire, true);
		}
	}
	/* -------------------------End------------------------- */
	/* -------------------------Process Informs------------------------- */
	reflex processInforms when: !empty(informs){
		loop informMsg over: informs{
			/* Be caught */
			float finedMoney <- float(informMsg.contents[1]);
			write name + ' is caught by: ' + informMsg.sender + ' and is fined: ' + finedMoney;
			wealthRate <- wealthRate - finedMoney;
			happyRate <- happyRate - rnd(20.0, 40.0);
			/* Reset drunk status */
			afraidRate <- afraidRate - rnd(20, 40);
			stealingMark <- false;
			string dummy <- informMsg.contents[0];
		}
	}
	/* -------------------------End------------------------- */
	
	aspect base{
		draw circle(1) at: location color: rgb('black');
	}
}

species Guard skills: [moving, fipa] control: simple_bdi{
	float happyRate <- rnd(0.0, 50.0) min: 0.0 max: 100.0;
	float wealthRate <- 0.0 min: 0.0;
	float tiredRate <- 0.0 min: 0.0 max: 100.0;
	
	list<Boozer> boozerCrimes <- [];
	list<Thief> thiefCrimes <- [];
	
	int waitingBoozerCounter <- 0;
	
	init{
		do add_desire(wanderDesire);
	}
	
	plan doPatrol intention: wanderDesire{
		float patrolSpeed <- 0.3;
		/* If not tired, then sing. */
		tiredRate <- tiredRate + rnd(0.0, 2.0);
		do wander speed: patrolSpeed;
	}             
	
	/* -------------------------Process Reports------------------------- */
	reflex processInforms when: !empty(informs){
		loop informMsg over: informs{
			if 'boozers' in informMsg.contents[0] or 'fight' in informMsg.contents[0]{
				/* Fighting reports. */
				loop boozer over: list(informMsg.contents[1]){
					if !(boozer in boozerCrimes){
						boozerCrimes <+ boozer;
						write name + ' has recieved a report of violent event of ' + boozer + ' from ' + informMsg.sender;
					}
				}
			} else if 'thieves' in informMsg.contents[0] or 'stealing' in informMsg.contents[0]{
				/* Stealing reports. */
				loop thief over: list(informMsg.contents[1]){
					if !(thief in thiefCrimes){
						thiefCrimes <+ thief;
						write name + ' has recieved a report of stealing event of ' + thief + ' from ' + informMsg.sender;
					}
				}
			}
		}
		loop informMsg over: informs{
			string dummy <- informMsg.contents[0];
		}
	}
	
	/* Have reports of events. */
	reflex activeDuties when: !empty(boozerCrimes) or !empty(thiefCrimes){
		do remove_intention(wanderDesire, false);
		if !empty(boozerCrimes){
			do add_desire(predicate: catchBoozerDesire, strength: 3.0);
		} else{
			do add_desire(predicate: catchThiefDesire, strength: 3.0);
		}
	}
	
	/* Catch boozers */
	plan catchBoozer intention: catchBoozerDesire{
		/* Go to figure out the first boozer. */
		Boozer theFirstBoozer <- boozerCrimes[0];
		if theFirstBoozer.foughtMark{
			/* If the event has not been solved. */
			/* Not at the location, go and find him */
			do goto target: theFirstBoozer speed: 4.0;
			/* Feel tired while engaging. */
			tiredRate <- tiredRate + rnd(0.0, 2.0);
			/* If at location */
			if location = theFirstBoozer.location{
				/* Fine him */
				float finedMoney <- rnd(15.0, 30.0);
				wealthRate <- wealthRate + finedMoney;
				do start_conversation to: list(theFirstBoozer) protocol: 'fipa-contract-net' performative: 'inform' 
					contents: ['I am a guard: ' + name + ', and you are under arrest! You are fined: ', finedMoney];
				remove from: boozerCrimes index: 0;
				/* Catching bad and feeling happy! */
				happyRate <- happyRate + rnd(20.0, 40.0);
				do remove_intention(catchBoozerDesire, true);
			}
		} else{
			/* If the boozer has been punished. */
			remove from: boozerCrimes index: 0;
			do remove_intention(catchBoozerDesire, true);
		}
	}
	
	/* Catch thieves */
	plan catchThief intention: catchThiefDesire{
		/* Go to figure out the first boozer. */
		Thief theFirstThief <- thiefCrimes[0];
		if theFirstThief.stealingMark{
			/* If the event has not been solved. */
			/* Not at the location, go and find him */
			do goto target: theFirstThief speed: 2.5;
			/* Feel tired while engaging. */
			tiredRate <- tiredRate + rnd(0.0, 2.0);
			/* If at location */
			if location = theFirstThief.location{
				/* Fine him */
				float finedMoney <- rnd(15.0, 30.0);
				wealthRate <- wealthRate + finedMoney;
				do start_conversation to: list(theFirstThief) protocol: 'fipa-contract-net' performative: 'inform' 
					contents: ['I am a guard: ' + name + ', and you are under arrest! You are fined: ', finedMoney];
				/* After catching the boozer */
				remove from: thiefCrimes index: 0;
				/* Catching bad and feeling happy! */
				happyRate <- happyRate + rnd(10.0, 20.0);
				do remove_intention(catchThiefDesire, true);
			}
		} else{
			/* If the boozer has been punished. */
			remove from: thiefCrimes index: 0;
			do remove_intention(catchThiefDesire, true);
		}
	}
	
	/* -------------------------End------------------------- */
	/* -------------------------Happy and Go Bar to Offer Boozer Drinks------------------------- */
	reflex statusHappyToOfferDrink when: happyRate >= 60.0 and wealthRate >= priceDrinks {
		do add_desire(predicate: offerDrinkDesire, strength: 4.0);
	}
	
	plan offerDrinksAtBar intention: offerDrinkDesire{
		Bar nearestBar <- list(Bar) with_min_of (each distance_to self);
		/* If at a bar, then have drinks. */
		if (nearestBar.location = location){
			/* If at a bar, then offer a drink to boozers. */
			
			/* Get boozers who are at bar */
			list<Boozer> boozersAtBar <- [];
			loop boozerCounter from: 0 to: numberOfBoozers - 1{
				if Boozer[boozerCounter].location = location{
					boozersAtBar <+ Boozer[boozerCounter];
				}
			}
			/* Offer a drink to a randomly selected lucky boozer, if there is at least one boozer at bar. */
			if !empty(boozersAtBar){
				Boozer luckyBoozer <- boozersAtBar[rnd(0, length(boozersAtBar) - 1)];
				do start_conversation to: list(luckyBoozer) protocol: 'fipa-contract-net' performative: 'inform' 
					contents: ['I am a guard: ' + name + ', and I would like to offer you a drink!'];
				happyRate <- happyRate - rnd(25.0, 50.0);
				wealthRate <- wealthRate - priceDrinks;
				waitingBoozerCounter <- 0;
				do remove_intention(offerDrinkDesire, true);	
			} else{
				/* If no boozers at bar, then wait for 10 cycles. */
				waitingBoozerCounter <- waitingBoozerCounter + 1;
				if waitingBoozerCounter = 10{
					happyRate <- 0.0;
					waitingBoozerCounter <- 0;
					do remove_intention(offerDrinkDesire, true);
				}
			}
		} else{
			/* Else go to the nearest bar. */
			do add_subintention(get_current_intention(), goBarDesire, true);
			do current_intention_on_hold();
		}
	}
	
	plan goBar intention: goBarDesire{
		Bar nearestBar <- list(Bar) with_min_of (each distance_to self);
		/* Different speed if drunk. */
		/* Go to bar */
		do goto target: nearestBar speed: 1.0;
		/* Reach bar */
		if nearestBar.location = location{
			do remove_intention(goBarDesire, true);
		}
	}
	/* -------------------------End------------------------- */
	/* -------------------------Go to a Casino------------------------- */
	reflex goCasino when: wealthRate >= 80.0{
		do remove_intention(wanderDesire, false);
		do add_desire(predicate: goCasinoDesire, strength: 5.0);
	}
	
	/* If tired then go to the casino. */
	plan goCasinoToPlay intention: goCasinoDesire{
		Casino nearestCasino <- list(Casino) with_min_of (each distance_to self);
		/* Go to casino */
		do goto target: nearestCasino speed: 2.0;
		/* Reach casino */
		if nearestCasino.location = location{
			float debt <- rnd(0.0, wealthRate);
			do start_conversation to: list(nearestCasino) protocol: 'fipa-contract-net' performative: 'inform' 
			contents: ['I am a guard: ' + name + ', I have lost this amount of money: ', debt];
			wealthRate <- wealthRate - debt;
			do remove_intention(goCasinoDesire, true);
		}
	}
	/* -------------------------End------------------------- */
	/* -------------------------Tired and Stay Still------------------------- */
	reflex getRest when: tiredRate = 100.0{
		do add_desire(predicate: restDesire, strength: 10.0);
	}
	
	/* Stay still and rest. */
	plan rest intention: restDesire{
		if tiredRate != 0.0{
			/* Not finish resting. */
			do wander speed: 0.0;
			tiredRate <- tiredRate - rnd(2.0, 4.0);
		} else{
			do remove_intention(restDesire, true);
		}
	}
	/* -------------------------End------------------------- */
	
	aspect base{
		draw circle(1) at: location color: rgb('blue');
	}
}


experiment final_project_challenge_1 type:gui{
	output{
		display myDisplay{
			species Bar aspect: base;
			species Casino aspect: base;
			species Guest aspect: base;
			species Singer aspect: base;
			species Boozer aspect: base;
			species Thief aspect: base;
			species Guard aspect: base;
		}
		display chart_0{
			chart "Wealth - Agents" type: series style: bar x_label: "Agents"{
				data "Wealth of Each Agent" value: wealthMapAgent.values;
			}
		}
		display chart_1{
			chart "TotalWealth - Time" type: series style: spline x_label: "Time"{
				data "Total Wealth" value: totalWealth;
			}
		}
		display chart_2{
			chart "Wealth - Species" type: pie x_label: "Species"{
				data "Guest" value: wealthMapSpecie['Guest'];
				data "Singer" value: wealthMapSpecie['Singer'];
				data "Boozer" value: wealthMapSpecie['Boozer'];
				data "Thief" value: wealthMapSpecie['Thief'];
				data "Guard" value: wealthMapSpecie['Guard'];
			}
		}
	}
}