🗺️ Geo-Staked NFT Smart Contract

Summary: NFTs tied to real-world GPS locations and unlockable only through location verification.

📖 Overview

The Geo-Staked NFT contract introduces a unique concept of location-bound NFTs, where each token is linked to a specific geographic coordinate (latitude and longitude).
NFTs remain locked until the holder verifies their physical presence at the corresponding real-world location. Once verified, the NFT becomes transferable or can be re-staked to a new location.

This contract showcases the integration of real-world geolocation data into the Stacks blockchain, creating possibilities for location-based gaming, AR experiences, real-world scavenger hunts, tourism NFTs, and proof-of-presence collectibles.

🚀 Key Features

Minting: Create NFTs staked to specific GPS coordinates.

Unlocking: Owners can unlock NFTs by proving they are physically near the defined location.

Re-staking: NFTs can be re-staked to a new location, locking them again until reverified.

Transfer Control: Only unlocked NFTs can be transferred to others.

Burning: Owners can permanently burn their NFTs.

Ownership and Metadata Tracking: Complete tracking of owners, unlock state, and location data.

🧭 Core Concepts
Concept	Description
Geo-Staked NFT	A non-fungible token associated with real-world coordinates.
Coordinate Precision	Coordinates use a precision factor of 1,000,000 (6 decimal places).
Location Variance	Simplified distance check within 100 meters tolerance (configurable).
Unlock Mechanism	Users submit their current coordinates to verify proximity.
Oracle-Ready Design	Can be extended with an oracle for secure, trust-minimized GPS verification.
⚙️ Contract Functions
🧩 Public Functions
Function	Purpose
mint-geo-nft	Mints a new NFT with GPS coordinates, name, and description.
unlock-nft	Unlocks an NFT if the user’s submitted coordinates match the staked location.
transfer	Transfers ownership (only allowed for unlocked NFTs).
restake-nft	Re-stakes a previously unlocked NFT to new coordinates.
burn	Burns (destroys) an NFT owned by the caller.
🔍 Read-Only Functions
Function	Returns
get-nft-location	Metadata and location info for a token.
get-nft-owner	The principal address owning a token.
is-nft-unlocked	Boolean indicating whether a token is unlocked.
get-last-token-id	The latest minted token ID.
has-user-unlocked	Whether a specific user has unlocked a token.
get-token-uri	Returns the token’s name (as URI metadata placeholder).
🔒 Private Helper
Function	Description
abs-diff	Returns the absolute difference between two integer coordinates.

🧠 Design Notes

Simplicity First: The contract uses a straightforward distance comparison instead of the Haversine formula for simplicity.

Upgradeable for Real-World Use: Can be integrated with trusted GPS oracles (e.g., via Chainlink, Hiro, or custom APIs).

Security Checks: All mutating functions include owner validation and coordinate range checks.

Data Precision: Coordinates are multiplied by a precision factor for consistent fixed-point representation.

🧪 Example Workflow

Mint:

(contract-call? .geo-staked-nft mint-geo-nft 40748817 -73985428 "Statue of Liberty" "NFT tied to Liberty Island")


Try Unlocking (User physically nearby):

(contract-call? .geo-staked-nft unlock-nft u1 40748850 -73985400)


Transfer (after unlocking):

(contract-call? .geo-staked-nft transfer u1 tx-sender 'SP2C2...ABC)


Re-stake:

(contract-call? .geo-staked-nft restake-nft u1 51507500 -00012700)


Burn:

(contract-call? .geo-staked-nft burn u1)

🧩 Use Cases

Location-Based Collectibles: NFTs tied to landmarks, monuments, or event venues.

Geo-Gaming: Scavenger hunts and AR experiences requiring players to visit physical spots.

Proof of Visit / Attendance: NFTs that unlock when users attend real-world conferences or festivals.

Tourism Incentives: Cities issuing NFTs that unlock only at specific tourist attractions.

🧾 License

This smart contract is open-sourced under the MIT License. You’re free to fork, adapt, and build on top of it with attribution.