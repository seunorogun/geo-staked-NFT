;; title: geo-staked-NFT
;; version: 1.0.0
;; summary: NFTs tied to real-world GPS locations
;; description: This contract implements NFTs that are staked to specific GPS coordinates
;;              and can only be unlocked when the user verifies they are at that location.

;; token definitions
(define-non-fungible-token geo-nft uint)

;; constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-token-owner (err u101))
(define-constant err-already-unlocked (err u102))
(define-constant err-location-mismatch (err u103))
(define-constant err-nft-not-found (err u104))
(define-constant err-already-exists (err u105))
(define-constant err-invalid-coordinates (err u106))
(define-constant err-not-staked (err u107))

;; Precision factor for coordinates (6 decimal places)
(define-constant coordinate-precision u1000000)

;; Maximum allowed distance variance in meters (for location verification)
;; This is a simplified distance check - in practice you'd use more sophisticated verification
(define-constant max-distance-variance u100)

;; data vars
(define-data-var last-token-id uint u0)

;; data maps
;; Store NFT metadata including GPS coordinates
(define-map nft-locations
    uint  ;; token-id
    {
        latitude: int,      ;; Latitude * coordinate-precision (e.g., 40.748817 = 40748817)
        longitude: int,     ;; Longitude * coordinate-precision (e.g., -73.985428 = -73985428)
        name: (string-ascii 50),
        description: (string-utf8 256),
        is-unlocked: bool,
        staked-at: uint     ;; Block height when staked
    }
)

;; Track NFT ownership
(define-map nft-owners
    uint      ;; token-id
    principal ;; owner
)

;; Track user's unlocked NFTs
(define-map user-unlocked-nfts
    { user: principal, token-id: uint }
    bool
)

;; public functions

;; Mint a new geo-staked NFT at a specific location
;; @param latitude: Latitude coordinate multiplied by coordinate-precision
;; @param longitude: Longitude coordinate multiplied by coordinate-precision
;; @param name: Name of the location/NFT
;; @param description: Description of the NFT
(define-public (mint-geo-nft (latitude int) (longitude int) (name (string-ascii 50)) (description (string-utf8 256)))
    (let
        (
            (token-id (+ (var-get last-token-id) u1))
        )
        ;; Validate coordinates (basic range check)
        (asserts! (and
            (>= latitude (* -90 (to-int coordinate-precision)))
            (<= latitude (* 90 (to-int coordinate-precision)))
            (>= longitude (* -180 (to-int coordinate-precision)))
            (<= longitude (* 180 (to-int coordinate-precision)))
        ) err-invalid-coordinates)

        ;; Mint the NFT
        (try! (nft-mint? geo-nft token-id tx-sender))

        ;; Store location data
        (map-set nft-locations token-id {
            latitude: latitude,
            longitude: longitude,
            name: name,
            description: description,
            is-unlocked: false,
            staked-at: block-height
        })

        ;; Store owner
        (map-set nft-owners token-id tx-sender)

        ;; Update last token ID
        (var-set last-token-id token-id)

        (ok token-id)
    )
)

;; Unlock NFT by verifying location
;; In a real implementation, this would use an oracle or trusted verification service
;; For this demo, we allow the user to submit coordinates and verify they match
;; @param token-id: The NFT to unlock
;; @param user-latitude: User's current latitude * coordinate-precision
;; @param user-longitude: User's current longitude * coordinate-precision
(define-public (unlock-nft (token-id uint) (user-latitude int) (user-longitude int))
    (let
        (
            (nft-data (unwrap! (map-get? nft-locations token-id) err-nft-not-found))
            (nft-owner (unwrap! (map-get? nft-owners token-id) err-nft-not-found))
            (lat-diff (abs-diff (get latitude nft-data) user-latitude))
            (lon-diff (abs-diff (get longitude nft-data) user-longitude))
        )
        ;; Verify caller owns the NFT
        (asserts! (is-eq tx-sender nft-owner) err-not-token-owner)

        ;; Verify not already unlocked
        (asserts! (not (get is-unlocked nft-data)) err-already-unlocked)

        ;; Verify location matches (simplified distance check)
        ;; In reality, you'd use Haversine formula and oracle verification
        (asserts! (and
            (< lat-diff max-distance-variance)
            (< lon-diff max-distance-variance)
        ) err-location-mismatch)

        ;; Mark as unlocked
        (map-set nft-locations token-id (merge nft-data { is-unlocked: true }))

        ;; Track user's unlocked NFT
        (map-set user-unlocked-nfts { user: tx-sender, token-id: token-id } true)

        (ok true)
    )
)

;; Transfer NFT (can only transfer unlocked NFTs)
;; @param token-id: The NFT to transfer
;; @param sender: Current owner
;; @param recipient: New owner
(define-public (transfer (token-id uint) (sender principal) (recipient principal))
    (let
        (
            (nft-data (unwrap! (map-get? nft-locations token-id) err-nft-not-found))
        )
        ;; Verify sender owns the NFT
        (asserts! (is-eq tx-sender sender) err-not-token-owner)

        ;; Verify NFT is unlocked before transfer
        (asserts! (get is-unlocked nft-data) err-not-staked)

        ;; Transfer the NFT
        (try! (nft-transfer? geo-nft token-id sender recipient))

        ;; Update owner mapping
        (map-set nft-owners token-id recipient)

        (ok true)
    )
)

;; Stake an unlocked NFT back to require location verification again
;; This allows re-staking an NFT to a new location
;; @param token-id: The NFT to re-stake
;; @param new-latitude: New latitude * coordinate-precision
;; @param new-longitude: New longitude * coordinate-precision
(define-public (restake-nft (token-id uint) (new-latitude int) (new-longitude int))
    (let
        (
            (nft-data (unwrap! (map-get? nft-locations token-id) err-nft-not-found))
            (nft-owner (unwrap! (map-get? nft-owners token-id) err-nft-not-found))
        )
        ;; Verify caller owns the NFT
        (asserts! (is-eq tx-sender nft-owner) err-not-token-owner)

        ;; Validate new coordinates
        (asserts! (and
            (>= new-latitude (* -90 (to-int coordinate-precision)))
            (<= new-latitude (* 90 (to-int coordinate-precision)))
            (>= new-longitude (* -180 (to-int coordinate-precision)))
            (<= new-longitude (* 180 (to-int coordinate-precision)))
        ) err-invalid-coordinates)

        ;; Update location and lock the NFT again
        (map-set nft-locations token-id (merge nft-data {
            latitude: new-latitude,
            longitude: new-longitude,
            is-unlocked: false,
            staked-at: block-height
        }))

        (ok true)
    )
)

;; Burn NFT (only owner can burn)
(define-public (burn (token-id uint))
    (let
        (
            (nft-owner (unwrap! (map-get? nft-owners token-id) err-nft-not-found))
        )
        ;; Verify caller owns the NFT
        (asserts! (is-eq tx-sender nft-owner) err-not-token-owner)

        ;; Burn the NFT
        (try! (nft-burn? geo-nft token-id nft-owner))

        ;; Clean up maps
        (map-delete nft-locations token-id)
        (map-delete nft-owners token-id)

        (ok true)
    )
)

;; read only functions

;; Get NFT location data
(define-read-only (get-nft-location (token-id uint))
    (map-get? nft-locations token-id)
)

;; Get NFT owner
(define-read-only (get-nft-owner (token-id uint))
    (map-get? nft-owners token-id)
)

;; Check if NFT is unlocked
(define-read-only (is-nft-unlocked (token-id uint))
    (match (map-get? nft-locations token-id)
        nft-data (ok (get is-unlocked nft-data))
        err-nft-not-found
    )
)

;; Get last minted token ID
(define-read-only (get-last-token-id)
    (ok (var-get last-token-id))
)

;; Check if user has unlocked a specific NFT
(define-read-only (has-user-unlocked (user principal) (token-id uint))
    (default-to false (map-get? user-unlocked-nfts { user: user, token-id: token-id }))
)

;; Get token URI (returns basic metadata)
(define-read-only (get-token-uri (token-id uint))
    (match (map-get? nft-locations token-id)
        nft-data (ok (some (get name nft-data)))
        err-nft-not-found
    )
)

;; private functions

;; Helper function to calculate absolute difference
(define-private (abs-diff (a int) (b int))
    (if (>= a b)
        (to-uint (- a b))
        (to-uint (- b a))
    )
)
