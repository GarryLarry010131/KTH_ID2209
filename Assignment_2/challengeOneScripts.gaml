/**
* Name: challengeOneScripts
* Based on the internal empty template. 
* Author: Guangyuan Li
* Tags: 
*/


model challengeOneScripts

/* Insert your model definition here */
global {
	int numberOfAuctioneers <- 3;
	int numberOfBidders <- 15;
	/* Three types of goods for auction */
	list<string> goods <- ['cloths', 'CDs', 'cups'];
	list<int> goodsValue <- [2000, 8000, 3500];
	list<int> startPrice <- [5000, 12000, 7000];
	list<int> decreasingPrice <- [250, 1000, 500];
	
	init {
		create Auctioneer number: numberOfAuctioneers;
		create Bidder number: numberOfBidders;
		
		/* Allocate the goods for auction to different auctioneer */
		loop counter from: 0 to: numberOfAuctioneers - 1{
			Auctioneer[counter].auctionGood <- goods[counter];
			Auctioneer[counter].valueThreshold <- goodsValue[counter];
			Auctioneer[counter].startPrice <- startPrice[counter];
			Auctioneer[counter].decreasingPrice <- decreasingPrice[counter];
			Auctioneer[counter].currentPrice <- Auctioneer[counter].startPrice;
		}
	}
}

/* Dutch auction */
species Auctioneer skills: [fipa]{	
	bool startAuction <- false;
	bool initializedAuction <- false;
	bool selling <- true;
	/* What good the auctioneer holds a auction for. */
	string auctionGood <- nil;
	int valueThreshold <- -1;
	int startPrice <- -1;
	int decreasingPrice <- -1;
	int currentPrice <- -1;
	/* Bidders that are willing to attend the auction. */
	list<Bidder> biddersList <- [];
	/* The winner after auction process */
	Bidder winner <- nil;
	
	/* Received bid */
	reflex receiveBid when: !empty(proposes) and startAuction and selling{
		loop proposeMsg over: proposes{
			/* If there already exsisted a winner */
			if (winner = nil){
				/* Check if the bidder has enough money */
				if (int(proposeMsg.contents[1]) >= currentPrice){
					winner <- proposeMsg.sender;
					write '(Time ' + time + '): ' + name + ' announces the winner is: ' + winner.name + " And the deal is at: " + currentPrice;
					write '------------------------------------------';
					do accept_proposal message: proposeMsg contents: ['Congratulations! You are the winner!'];
					selling <- false;
				} else{
					/* If the bidder does not have enough money, he will be forbidden to attend the auction */
					do reject_proposal message: proposeMsg contents: ['You are cheating! You will not be allowed to attend!'];
					remove item: proposeMsg.sender from: biddersList;
				}
			} else{
				do reject_proposal message: proposeMsg contents: ["Sorry, you are late. The good is already sold!"];
			}
			string dummy <- proposeMsg.contents;
		}
	}
	
	/* The bidder refused the offer */
	reflex recieveOfferRefuses when: !empty(refuses) and startAuction and selling{
		loop refuseMsg over: refuses{
			string dummy <- refuseMsg.contents;
		}
	}
	
	/* The auction process, every time, the auctioneer will decrease the price till a winner appears or below the threshold */
	reflex auctionProcess when: startAuction and selling{
		if (winner = nil){
			/* Initialize the auction */
			if !initializedAuction{
				initializedAuction <- true;
				do start_conversation to: biddersList protocol: 'fipa-contract-net' performative: 'cfp' contents: ["Let's start the offer, and the start price is: ", currentPrice];
			} else{
				/* If the current price above the threshold */
				if (currentPrice > valueThreshold){
					write '------------------------------------------';
					currentPrice <- currentPrice - decreasingPrice;
					do start_conversation to: biddersList protocol: 'fipa-contract-net' performative: 'cfp' contents: ["This time the offer is: ", currentPrice];
				/* The price cannot decrease any more */
				} else{
					write name + " Annouces: Current price below the threshold! Auction closed and goods will not be sold!";
					startAuction <- false;
					selling <- false;
				}
			}
		}
	}
	
	/* Annouce the good ready to auction */
	reflex initialProposal when: (time = 0){
		write name + ': Start inital announcement...';
		do start_conversation to: list(Bidder) protocol: 'fipa-contract-net' performative: 'cfp' 
		contents: ['This is ' + name + '. To all Biders: this auction is about ' + auctionGood  + '. Send me your proposol.'];
		write '------------------------------------------';
	}
	
	/* Be refused */
	reflex receivceRefuseAttendanceMsgs when: !empty(refuses) and !startAuction and selling{
		loop refuseMsg over: refuses{
			// write '(Time ' + time + '): ' + name + ' is refused by: ' + agent(refuseMsg.sender).name + '.';
			string dummy <- refuseMsg.contents[0];
		}
	}
	
	reflex receiveAttendanceProposals when: !empty(proposes) and !startAuction and selling{
		/* If someone is interested in the good, then starting permitted */
		loop proposeMsg over: proposes{
			write '(Time ' + time + '): ' + name + ' received a propose message from ' + agent(proposeMsg.sender).name + ' with content: ' + proposeMsg.contents;
			int biddersBudget <- int(proposeMsg.contents[1]);
			if (biddersBudget < valueThreshold){
				do reject_proposal message: proposeMsg contents: ['Sorry, your budget is not enough to attend the auction!'];
			} else{
				startAuction <- true;
				biddersList <+ proposeMsg.sender;
				do accept_proposal message: proposeMsg contents: ['Thanks, you are eligible to attend the auction! Please wait for the start!'];
			}
		}
		write "Following bidder will attend the auction: " + biddersList;
		write '------------------------------------------';
	}
}

species Bidder skills: [fipa]{
	/* Which good is the bidder interested in */
	int interestIdx <- rnd(0, numberOfAuctioneers - 1);
	string interest <- goods[interestIdx];
	/* Wealth */
	int wealth <- rnd(goodsValue[interestIdx] - 1000, goodsValue[interestIdx] + 3000);
	int expectedPrice <- rnd(goodsValue[interestIdx] - 1000, goodsValue[interestIdx] + 1000);
	
	/* Cfps for gathering bidders for auction */
	reflex recieveInformCfps when: !empty(cfps) and time < 2{
		loop cfpMsg over: cfps{
			string msg <- cfpMsg.contents[0];
			/* Accept the invitation from the auctioneer that offers things interested in */
			if (interest in msg){
				write '(Time ' + time + '): ' + name + ' received a propose message from ' + agent(cfpMsg.sender).name + ' with content: ' + cfpMsg.contents;
				do propose message: cfpMsg contents: ['I would like to attend the auction. My budget is: ', wealth];	
			} else{
				do refuse message: cfpMsg contents: ['I will not attend the auction.'];
			}	
		}
	}
	
	/* Recieve the messages about being rejected to attend the auction */
	reflex recieveRejectedToAttend when: !empty(reject_proposals) and time < 3{
		loop rejectMsg over: reject_proposals{
			write '(Time ' + time + '): ' + name + ' received a reject message from ' + agent(rejectMsg.sender).name + ' with content: ' + rejectMsg.contents;
		}
	}
	
	/* Recieve the messages about being approved to attend the auction */
	reflex recieveApprovedToAttend when: !empty(accept_proposals) and time < 3{
		loop acceptMsg over: accept_proposals{
			write '(Time ' + time + '): ' + name + ' received an accept message from ' + agent(acceptMsg.sender).name + ' with content: ' + acceptMsg.contents;
		}
	}
	
	/* Recieve the offers */
	reflex recieveOfferCfps when: !empty(cfps) and time >= 3{
		loop cfpMsg over: cfps{
			int offerPrice <- int(cfpMsg.contents[1]);
			write '(Time ' + time + '): ' + name + ' received an offer from ' + agent(cfpMsg.sender).name + 
			' at the price: ' + offerPrice + ' And his expected price is: ' + expectedPrice + ' With budget: ' + wealth;
			
			/* If the price is acceptable */
			if (offerPrice <= expectedPrice){
				do propose message: cfpMsg contents: ['I would like to accept the offer! I have money: ', wealth];
			} else{
				/* If the price is too high to accept */
				do refuse message: cfpMsg contents: ['The price is too high! I cannot accept!'];
			}
			
			string dummy <- cfpMsg.contents;
		}
	}
	
	/* Cheated and banned */
	reflex recieveCheatedRejects when: !empty(reject_proposals) and time >= 3{
		loop rejectMsg over: reject_proposals{
			write '(Time ' + time + '): ' + name + ' is rejected by ' + agent(rejectMsg.sender).name + ' with content: ' + rejectMsg.contents;
		}
	}
	
	/* Inform to end */
	reflex recieveFinalAccepts when: !empty(accept_proposals) and time >= 3{
		loop acceptMsg over: accept_proposals{
			do inform message: acceptMsg contents: ["Thank you! I have got my staff!"];
			string dummy <- acceptMsg.contents;
		}
	}
}

experiment assignment_2_1 type: gui {}