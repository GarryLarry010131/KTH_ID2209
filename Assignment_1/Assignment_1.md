# Create a Basic Festival with Stores
- Create 3 types of agent for the festival simulation.
- These types should be Guests, Stores and an Information Center.
- Make sure they look different (shape, color).
- Add them to a simulation and make them interact with each other according to description.
# Goals
- Introduction to the Gama platform
- Working with agents
- Learning the GAMA syntax
- Creating different types of agents
- Starting basic simulations
- Little bit of movement and behavior

# Challenge 1: Memory of Agents - Small Brain
- When an agent visits a shop, they will remember the position. However, sometimes they would like to discover new places as well. Implement a small memory in agents so they will remember places they have been to (make his actions randomized).
- Extra - Implement this logic and compare distance traveled.
- Hint: Track distance traveled of agents with and without the brain and report on if this reduces the total distance traveled.

# Challenge 2: Removing Bad Behavior Agents
- There are always bad apples at festivals. Some are noisy, some steal and some are just looking for a fight.
- Create a scenario where an agent should be removed (killed) from the festival.
    - Hint: Agents are removed using the **die** function.
- Create a new agent, **Security Guard**, that is able to do so.
- The only way of this happening, is that Information center reports is.
    - When the bad guest goes to the information center, it calls for the Security Guard and tells him who the bad behaving actor is.
- Once the Guard reaches the agent, he shoul kill him. (Brutal, but that's life!)