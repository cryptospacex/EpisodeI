# Episode I

A long time ago in a galaxy far far away….
A young Jedi named Elon set aboard his millennium falcon to discover the mystical galaxy called
Tatooine. Several legends have been written and said about the mystical Tatooine. Some say it
can only be visited in the dreams, while some claim that it is so dark that nobody can ever see or
find it. Guided by the Force, one day young Elon discovered a strange source of light and he
followed it. The light got brighter and brighter and suddenly he saw a strange new planet. Elon
spent several years on the planet and documented everything he could about the strange planet.

Here’s what he wrote:
"I have found a new galaxy but this is not like any other galaxy we’ve ever seen. Perhaps its
Tatooine that I have found! It seems to be a very small galaxy with only 1000 stars. The planets in
Tatooine do not rotate around the sun!!! In fact this galaxy does not seem to obey any law of
nature as we know it. The stars here emit stardust which is the only natural resource in the entire
galaxy. Stardust can be used for anything from building new spaceships to upgrading your
battlestation. If anybody finds this note, on the back side I have drawn a map. There are only 4000
such maps and each map will guide you to one of the planets in Tatooine.”

# Planets
Every player must have at least one planet to be able to play the game. Planets are where your
battlestation and defence base is located. Each planet has its own set of features which
determines its value and rarity. In Tatooine everything from size to distance from nearby stars
matter because they affect how much stardust the planet can collect from the star. Every planet
has a unique set of defences which determine how well it performs against an attack.
characteristics :
id
owner id
position : associated star, distance theta
size
planet level
battle station : level
defence [] ; dependent on planet size
battle station id
stardust quantity
current allegiance

# Stars
Stars continuously emit stardust and are the only source of stardust in the galaxy. Owning a star is
extremely rewarding. To receive stardust from a nearby sun, planets have to pay for the duration
for which they want to receive stardust. Star owners get to decide the price they want to set for
the stardust. The prices will have lower and upper bounds to ensure stable game economics.
While users pay for time, the amount of stardust received depends upon the planet’s size and its
distance from the star. So choose wisely!
id
position
owner id
stardust generation rate
stardust price rate : set by owner (in range)

# Battle
Stardust is very rare and there is just not enough for everybody. While only the stars can produce
stardust, every planet also has its store of stardust and others can attack and steal it. A
successful attack results in the opponent losing some of his stardust to you. But winning a battle
isn’t as easy as it sounds. You have to defeat the planet defence and also battle against the ships
of the opponent planet.

# Planet Defence
Each planet features a set of unique defence elements like the shield, land droid, plasma cannon,
hellfire, laser shock. Players can choose different defensive strategies by changing their defence
elements. The shield is one of the coolest defence elements. Any battleship whose level is lower
than the planetary shield level, is completely destroyed during an attack. Upgrading any defence
element requires that you have already upgraded your planet to the next level. As you upgrade
your planets, more defence strategies get unlocked.

# The Shield
The shield is a very important defence element. Each shield has a level and protects the planet
against battleships with the same or lower level. Hence while attacking a planet with a level 1 
shield, you can only use battleships with a level 2 or higher. Upgrading a shield requires that you
have upgraded all other defence elements to the next level.

# Battlestation
Each planet has its own battlestation which holds the battleships for the planet. Battleships can
be added and removed from the station. Only the ships held in a planet’s battlestation are used
during an attack or defending against an attack. Upgrade your battlestation to hold more ships.

# Battleships
Stardust can be used to unlock a new battleship. Several battleships can be found all of which
have an element of chance. Be extremely lucky and you might receive a Guardian Star Destroyer.
Battleships can be upgraded using stardust but you can never change their rarity. Each battleship
has an assault power and a shield. Battleships stored in a planet’s battlestation are used while
attacking another planet and also help in defending against attacks.
id
owner
planet id
attack
shield
type
defence
level
rarity - bronze/silver/gold/guardian

# Explorer Rockets
Other than the 4000 planets found on the Jedi maps, Tatooine has several other unexplored
planets. Explorer rockets can be fired from planets to find new planets. Each rocket has a small
chance of finding another planet. Once you’ve found a planet, you can start upgrading its
defences and attack or simply sell it on the marketplace.
>% chance of finding a planet
>stardust_requirement

# Tournaments and Alliances
Every two weeks the top 32 players battle head to head in a knockout tournament to win the
ultimate prize. These players can form alliances with other players(but not amongst themselves) to
strengthen their army. Players can either offer their allegiance to one of the top 20 or put their
allegiance on sale in the marketplace. The game will also hold special events and tournaments
featuring all the players.

# SpaceX Tokens
The SpaceX tokens are sold during the pre sale and are hard capped at 4000. They are a means
to reward the early adopters of the game. The tokens acts as a lifetime membership to all game
episode releases by CryptoSpaceX. Owners of SpaceX tokens shall receive the new game assets
at the launch of each episode. 30% of all revenue generated by stars would be distributed among
all token HODLers.
id
owner id

# The Death Star
If you have watched star wars you already know what the death star is. It can be found at game
launch by token holders and has a very small generation chance. No other death star can ever be
made and can only be bought from those who already have one. Being the most powerful
spaceship of the Star Wars universe, the death star launches a plethora of destruction on any
planet. Good luck surviving against it!
battleship

# Marketplace
The marketplace will feature planets, spaceships, and allegiances for the upcoming war
tournament. While spaceships can be bought and sold individually, a planet’s defence cannot be
traded individually and are bought or sold with the planet itself.
			

# Blockchain’s first strategy game
A planet is all you need to get started with the game.
Episode I poster contest
Defences
• Shield—destroys all lower level battleships
• Shockwave—damages shield of all ships by 25%
• Plasma cannon—takes out a random ship
• Missile barrage—
• Flak cannon—
• Napalm—
• AT-AT land droid- protects stardust store

