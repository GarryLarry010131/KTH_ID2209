# Add Merch to Festival
- New types of agents: auctioneers
- Auctioneers should pop up at least once per simulation.
- They should communicate only by **[FIPA](https://gama-platform.org/wiki/UsingFIPAACL)** protocol!
    - Please do not use **ask** or any other way!
- They sell some items to auction winners.
- You need to implement "Dutch" auction.
    - Auctioneer starts the offer with much higher price than the expected market value.
    - If no one wants to buy for the set price, they reduce the price at selected interval.
    - The auctioneer decides how much he reduces the price in every round.
    - If the price is reduced below the auctioneer minimum threshold, the auction is cancelled.

# Goals
- More experience with agents in GAMA
- Introduction to message passing and FIPA protocol
- Experience working with agent negotiation
- Simulation and practicing in an auction

# Challenge 1: Mutiple Auctions in the Festival
- Allow having multiple auctions at the same time.
- Agents will only join the auction if they are interested in the genre (e.g., cloths, CDs, etc)

# Challenge 2: Different Auction Settings
- In addition to the dutch auction, implement two or more types of auctions that agents can participate in.
    - E.g., English auction, Sealed bid auction, Vickrey auction, etc.
- Compare the gained value of all 3 methods for both auctioneer and the buyers, and report your findings which is more favorable.