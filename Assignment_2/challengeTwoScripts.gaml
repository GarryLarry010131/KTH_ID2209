/**
* Name: challengeTwoScripts
* Based on the internal empty template. 
* Author: Guangyuan Li
* Tags: 
*/


model challengeTwoScripts

/* Insert your model definition here */
global {
	int numberOfAuctioneers <- 3;
	int numberOfBidders <- 5;
	list<string> typeOfAuctions <- ['Dutch', 'English', 'Vickrey'];
	
	init {
		create Auctioneer number: numberOfAuctioneers;
		create Bidder number: numberOfBidders;
		
		loop counter from: 0 to: numberOfAuctioneers - 1{
			Auctioneer[counter].allowedBidders <- list(Bidder);
			Auctioneer[counter].auctionType <- typeOfAuctions[counter];
		}
	}
}

/* Dutch auction */
species Auctioneer skills: [fipa]{
	string auctionType <- nil;	
	bool initializedAuction <- false;
	bool selling <- true;
	/* What good the auctioneer holds a auction for. */
	string auctionGood <- 'cloths';
	int valueThreshold <- 2000;
	int currentPrice <- -1;
	int startPrice <- -1;
	int changingPrice <- -1;
	/* The winner after auction process */
	Bidder winner <- nil;
	message winnerMsg <- nil;
	list<Bidder> allowedBidders <- nil;

	int largestOffer <- -1;
	message possibleWinnerMsg <- nil;
	Bidder possibleWinner <- nil;
	list<int> offerList <- [];
	
	/* If there are no offers in the new cycle in the English Auction */
	Bidder secondWinner <- nil;
	int secondWinnerPrice <- -1;
	
	reflex distributedParams when: time = 0{
		if (auctionType = 'Dutch'){
			startPrice <- 4000;
			currentPrice <- 4000;
			changingPrice <- 250;
		} else if (auctionType = 'English'){
			startPrice <- 1000;
			currentPrice <- 1000;
			changingPrice <- -1;
		} else if (auctionType = 'Vickrey'){
			startPrice <- -1;
			currentPrice <- -1;
			changingPrice <- -1;
		}
	}
	
	/* Received bid, and judge if the winner comes */
	reflex receiveBid when: !empty(proposes) and selling and (length(allowedBidders) != 0){
		if (auctionType = 'Dutch'){
			loop proposeMsg over: proposes{
				/* If there already exsisted a winner */
				if (winner != nil){
					do reject_proposal message: proposeMsg contents: ["Sorry, you are late. The good is already sold!"];
				} else{
					if (auctionType = 'Dutch'){
						/* Dutch Auction */
						winner <- proposeMsg.sender;
						write '(Time ' + time + '): ' + name + ' announces the winner is: ' + winner.name + " And the deal is at: " + currentPrice;
						write '------------------------------------------';
						do accept_proposal message: proposeMsg contents: ['Congratulations! You are the winner!'];
						selling <- false;
					}
				}
				string dummy <- proposeMsg.contents;
			}	
		}
		
		if (auctionType = 'English'){
			/* English Auction */
			/* If only one bidder offers price */
			if (length(proposes) = 1){
				possibleWinner <- proposes[0].sender;
				possibleWinnerMsg <- proposes[0];
				currentPrice <- int(possibleWinnerMsg.contents[1]);
				/* If the offer can be accepted by the auctioneer */
				if (currentPrice >= valueThreshold){
					winner <- possibleWinner;
					winnerMsg <- possibleWinnerMsg;
					write '(Time ' + time + '): ' + name + ' announces the winner is: ' + winner.name + " And the deal is at: " + currentPrice;
					write '------------------------------------------';
					do accept_proposal message: winnerMsg contents: ['Congratulations! You are the winner!'];
					selling <- false;
				} else{
					write name + " Annouces: Current price below the threshold! Auction closed and goods will not be sold!";
					selling <- false;
				}
			} else{
				currentPrice <- int(proposes[0].contents[1]);
				secondWinner <- proposes[0].sender;
				secondWinnerPrice <- int(proposes[0].contents[1]);
			}
			if (length(proposes) != 0){
				loop proposeMsg over: proposes{
					string dummy <- proposeMsg.contents;
				}
			}
		}
		
		if (auctionType = 'Vickrey'){
			/* Vickrey Auction */
			loop proposeMsg over: proposes{
				offerList <+ int(proposeMsg.contents[1]);
				if (int(proposeMsg.contents[1]) > largestOffer){
					largestOffer <- int(proposeMsg.contents[1]);
					possibleWinnerMsg <- proposeMsg;
					possibleWinner <- proposeMsg.sender;
				}
			}
			/* If the offer can be accepted by the auctioneer */
			if (largestOffer >= valueThreshold){
				winner <- possibleWinner;
				winnerMsg <- possibleWinnerMsg;
				remove item: largestOffer from: offerList;
				write '(Time ' + time + '): ' + name + ' announces the winner is: ' + winner.name + " And the deal is at: " + max(offerList);
				write '------------------------------------------';
				do accept_proposal message: winnerMsg contents: ['Congratulations! You are the winner!'];
				selling <- false;
			} else{
				write name + " Annouces: Current price below the threshold! Auction closed and goods will not be sold!";
				selling <- false;
			}
			loop proposeMsg over: proposes{
				string dummy <- proposeMsg.contents;	
			}
		}
	}
	
	/* If at this time, all bidders refuses to offer price, then select the offer from last cycle */
	reflex recieveFiveRefuses when: length(refuses) = numberOfBidders and auctionType = 'English' and selling{
		/* If the offer can be accepted by the auctioneer */
		write 'There are ' + length(refuses) + ' refuse to offer the price this time!';
		if (currentPrice >= valueThreshold){
			write '(Time ' + time + '): ' + name + ' announces the second winner is: ' + secondWinner + " And the deal is at: " + secondWinnerPrice;
			selling <- false;
		} else{
			write name + " Annouces: All bidders refuses to offer higher price. And current price below the threshold! Auction closed and goods will not be sold!";
			selling <- false;
		}
		loop refuseMsg over: refuses{
				string dummy <- refuseMsg.contents;	
		}
	}
	
	/* The bidder refused the offer */
	reflex recieveOfferRefuses when: !empty(refuses) and selling{
		loop refuseMsg over: refuses{
			string dummy <- refuseMsg.contents;
		}
	}
	
	/* The auction process, every time, the auctioneer will decrease the price till a winner appears or below the threshold */
	reflex auctionProcess when: selling and (length(allowedBidders) != 0){
		if (winner = nil){
			if (auctionType = 'Dutch'){
				/* Dutch Auction */
				/* Initialize the auction */
				if (!initializedAuction and length(allowedBidders) != 0){
					write '(Time ' + time + '): ' + name + ': ' + auctionType + ' auction initialized! Time to start!';
					initializedAuction <- true;
					do start_conversation to: allowedBidders protocol: 'fipa-contract-net' performative: 'cfp' contents: ["It's " + auctionType + " auction. " + "Let's start the offer, and the start price is: ", currentPrice];
				} else if (length(allowedBidders) = 0){
					selling <- false;
				} else{
					/* If the current price above the threshold */
					if (currentPrice > valueThreshold){
						write '------------------------------------------';
						currentPrice <- currentPrice - changingPrice;
						do start_conversation to: allowedBidders protocol: 'fipa-contract-net' performative: 'cfp' contents: ["It's " + auctionType + " auction. " + "This time the offer is: ", currentPrice];
					/* The price cannot decrease any more */
					} else{
						write name + " Annouces: Current price below the threshold! Auction closed and goods will not be sold!";
						selling <- false;
					}
				}	
			} else if (auctionType = 'English'){
				/* English Auction */
				if (!initializedAuction and length(allowedBidders) != 0){
					write '(Time ' + time + '): ' + name + ': ' + auctionType + ' auction initialized! Time to start!';
					initializedAuction <- true;
					do start_conversation to: allowedBidders protocol: 'fipa-contract-net' performative: 'cfp' contents: ["It's " + auctionType + " auction. " + "Please start giving offers, the start price is: ", currentPrice];
				} else{
					do start_conversation to: allowedBidders protocol: 'fipa-contract-net' performative: 'cfp' contents: ["It's " + auctionType + " auction. " + "The currents price is: ", currentPrice];
				}
			} else if (auctionType = 'Vickrey'){
				/* Vickrey Auction */
				/* Initialize the auction */
				if (!initializedAuction and length(allowedBidders) != 0){
					write '(Time ' + time + '): ' + name + ': ' + auctionType + ' auction initialized! Time to start!';
					initializedAuction <- true;
					do start_conversation to: allowedBidders protocol: 'fipa-contract-net' performative: 'cfp' contents: ["It's " + auctionType + " auction. " + "Please offer me the price."];
				}
			}
		}
	}
}

species Bidder skills: [fipa]{
	/* Wealth */
	int wealth <- rnd(2000, 2000 + 5000);
	/* No cheaters in challenge 2, and assume all bidders are eligible */
	int expectedPrice <- rnd(2000 - 1000, 2000 + 1000) max: wealth; 
	/* English Auction Params */
	int increasingPrice <- 250;
	int priceHaveToOffer <- -1;
	
	/* Recieve the offers */
	reflex recieveOfferCfps when: !empty(cfps){
		loop cfpMsg over: cfps{
			if ('Dutch' in cfpMsg.contents[0]){
				/* Dutch Auction */
				int offerPrice <- int(cfpMsg.contents[1]);
				write '(Time ' + time + '): ' + name + ' received an offer from ' + agent(cfpMsg.sender).name + 
				' at the price: ' + offerPrice + ' And his expected price is: ' + expectedPrice;
				
				/* If the price is acceptable */
				if (offerPrice <= expectedPrice){
					do propose message: cfpMsg contents: ['I would like to accept the offer!'];
				} else{
					/* If the price is too high to accept */
					do refuse message: cfpMsg contents: ['The price is too high! I cannot accept!'];
				}
			} else if ('English' in cfpMsg.contents[0]){
				/* English Auction */
				priceHaveToOffer <- int(cfpMsg.contents[1]) + increasingPrice;
				if (priceHaveToOffer > expectedPrice){
					do refuse message: cfpMsg contents: ['The price is too high! I cannot accept!'];
				} else{
					write '(Time ' + time + '): ' + name + ' will offer: ' + priceHaveToOffer + ' to ' + agent(cfpMsg.sender).name;
					do propose message: cfpMsg contents: ['I would like to offer: ', priceHaveToOffer];	
				}
			} else if ('Vickrey' in cfpMsg.contents[0]){
				/* Vickrey Auction */
				write '(Time ' + time + '): ' + name + ' will offer: ' + expectedPrice + ' to ' + agent(cfpMsg.sender).name;
				do propose message: cfpMsg contents: ['I would like to offer: ', expectedPrice];
			}
			string dummy <- cfpMsg.contents;
		}
	}
	
	/* Cheated and banned */
	reflex recieveRejects when: !empty(reject_proposals){
		loop rejectMsg over: reject_proposals{
			write '(Time ' + time + '): ' + name + ' is rejected by ' + agent(rejectMsg.sender).name + ' with content: ' + rejectMsg.contents;
		}
	}
	
	reflex recieveFinalAccepts when: !empty(accept_proposals){
		loop acceptMsg over: accept_proposals{
			do inform message: acceptMsg contents: ["Thank you! I have got my staff!"];
			string dummy <- acceptMsg.contents;
		}
	}

//	
//	reflex checkInformsIsEmpty when: empty(informs) and (time > 1){
//		write '(Time ' + time + '): ' + name + ' Empty mailbox!';
//		write '------------------------------------------';
//	}
}

experiment assignment_2_2 type: gui {}