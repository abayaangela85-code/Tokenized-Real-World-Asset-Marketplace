(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-already-exists (err u102))
(define-constant err-unauthorized (err u103))
(define-constant err-insufficient-funds (err u104))
(define-constant err-not-for-sale (err u105))
(define-constant err-invalid-price (err u106))
(define-constant err-invalid-shares (err u107))
(define-constant err-asset-not-verified (err u108))

(define-map assets
  { asset-id: uint }
  {
    owner: principal,
    name: (string-ascii 50),
    description: (string-ascii 200),
    total-shares: uint,
    price-per-share: uint,
    verified: bool,
    created-at: uint
  }
)

(define-map asset-shares
  { asset-id: uint, holder: principal }
  { shares: uint }
)

(define-map listings
  { listing-id: uint }
  {
    asset-id: uint,
    seller: principal,
    shares-amount: uint,
    price-per-share: uint,
    active: bool,
    created-at: uint
  }
)

(define-map offers
  { offer-id: uint }
  {
    listing-id: uint,
    buyer: principal,
    shares-amount: uint,
    offered-price: uint,
    accepted: bool,
    created-at: uint
  }
)

(define-data-var asset-nonce uint u0)
(define-data-var listing-nonce uint u0)
(define-data-var offer-nonce uint u0)

(define-read-only (get-asset (asset-id uint))
  (map-get? assets { asset-id: asset-id })
)

(define-read-only (get-asset-shares (asset-id uint) (holder principal))
  (default-to { shares: u0 }
    (map-get? asset-shares { asset-id: asset-id, holder: holder })
  )
)

(define-read-only (get-listing (listing-id uint))
  (map-get? listings { listing-id: listing-id })
)

(define-read-only (get-offer (offer-id uint))
  (map-get? offers { offer-id: offer-id })
)

(define-read-only (get-asset-nonce)
  (ok (var-get asset-nonce))
)

(define-read-only (get-listing-nonce)
  (ok (var-get listing-nonce))
)

(define-read-only (get-offer-nonce)
  (ok (var-get offer-nonce))
)

(define-public (create-asset (name (string-ascii 50)) (description (string-ascii 200)) (total-shares uint) (price-per-share uint))
  (let
    (
      (new-asset-id (+ (var-get asset-nonce) u1))
    )
    (asserts! (> total-shares u0) err-invalid-shares)
    (asserts! (> price-per-share u0) err-invalid-price)
    (map-set assets
      { asset-id: new-asset-id }
      {
        owner: tx-sender,
        name: name,
        description: description,
        total-shares: total-shares,
        price-per-share: price-per-share,
        verified: false,
        created-at: stacks-block-height
      }
    )
    (map-set asset-shares
      { asset-id: new-asset-id, holder: tx-sender }
      { shares: total-shares }
    )
    (var-set asset-nonce new-asset-id)
    (ok new-asset-id)
  )
)

(define-public (verify-asset (asset-id uint))
  (let
    (
      (asset (unwrap! (map-get? assets { asset-id: asset-id }) err-not-found))
    )
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (map-set assets
      { asset-id: asset-id }
      (merge asset { verified: true })
    )
    (ok true)
  )
)

(define-public (transfer-shares (asset-id uint) (recipient principal) (shares-amount uint))
  (let
    (
      (sender-shares (get shares (get-asset-shares asset-id tx-sender)))
      (recipient-shares (get shares (get-asset-shares asset-id recipient)))
      (asset (unwrap! (map-get? assets { asset-id: asset-id }) err-not-found))
    )
    (asserts! (>= sender-shares shares-amount) err-insufficient-funds)
    (asserts! (> shares-amount u0) err-invalid-shares)
    (map-set asset-shares
      { asset-id: asset-id, holder: tx-sender }
      { shares: (- sender-shares shares-amount) }
    )
    (map-set asset-shares
      { asset-id: asset-id, holder: recipient }
      { shares: (+ recipient-shares shares-amount) }
    )
    (ok true)
  )
)

(define-public (create-listing (asset-id uint) (shares-amount uint) (price-per-share uint))
  (let
    (
      (new-listing-id (+ (var-get listing-nonce) u1))
      (seller-shares (get shares (get-asset-shares asset-id tx-sender)))
      (asset (unwrap! (map-get? assets { asset-id: asset-id }) err-not-found))
    )
    (asserts! (get verified asset) err-asset-not-verified)
    (asserts! (>= seller-shares shares-amount) err-insufficient-funds)
    (asserts! (> shares-amount u0) err-invalid-shares)
    (asserts! (> price-per-share u0) err-invalid-price)
    (map-set listings
      { listing-id: new-listing-id }
      {
        asset-id: asset-id,
        seller: tx-sender,
        shares-amount: shares-amount,
        price-per-share: price-per-share,
        active: true,
        created-at: stacks-block-height
      }
    )
    (var-set listing-nonce new-listing-id)
    (ok new-listing-id)
  )
)

(define-public (cancel-listing (listing-id uint))
  (let
    (
      (listing (unwrap! (map-get? listings { listing-id: listing-id }) err-not-found))
    )
    (asserts! (is-eq tx-sender (get seller listing)) err-unauthorized)
    (asserts! (get active listing) err-not-for-sale)
    (map-set listings
      { listing-id: listing-id }
      (merge listing { active: false })
    )
    (ok true)
  )
)

(define-public (purchase-shares (listing-id uint) (shares-amount uint))
  (let
    (
      (listing (unwrap! (map-get? listings { listing-id: listing-id }) err-not-found))
      (asset-id (get asset-id listing))
      (seller (get seller listing))
      (price-per-share (get price-per-share listing))
      (total-cost (* shares-amount price-per-share))
      (seller-shares (get shares (get-asset-shares asset-id seller)))
      (buyer-shares (get shares (get-asset-shares asset-id tx-sender)))
    )
    (asserts! (get active listing) err-not-for-sale)
    (asserts! (<= shares-amount (get shares-amount listing)) err-invalid-shares)
    (asserts! (> shares-amount u0) err-invalid-shares)
    (asserts! (>= seller-shares shares-amount) err-insufficient-funds)
    (try! (stx-transfer? total-cost tx-sender seller))
    (map-set asset-shares
      { asset-id: asset-id, holder: seller }
      { shares: (- seller-shares shares-amount) }
    )
    (map-set asset-shares
      { asset-id: asset-id, holder: tx-sender }
      { shares: (+ buyer-shares shares-amount) }
    )
    (if (is-eq shares-amount (get shares-amount listing))
      (map-set listings
        { listing-id: listing-id }
        (merge listing { active: false, shares-amount: u0 })
      )
      (map-set listings
        { listing-id: listing-id }
        (merge listing { shares-amount: (- (get shares-amount listing) shares-amount) })
      )
    )
    (ok true)
  )
)

(define-public (create-offer (listing-id uint) (shares-amount uint) (offered-price uint))
  (let
    (
      (new-offer-id (+ (var-get offer-nonce) u1))
      (listing (unwrap! (map-get? listings { listing-id: listing-id }) err-not-found))
    )
    (asserts! (get active listing) err-not-for-sale)
    (asserts! (> shares-amount u0) err-invalid-shares)
    (asserts! (> offered-price u0) err-invalid-price)
    (asserts! (<= shares-amount (get shares-amount listing)) err-invalid-shares)
    (map-set offers
      { offer-id: new-offer-id }
      {
        listing-id: listing-id,
        buyer: tx-sender,
        shares-amount: shares-amount,
        offered-price: offered-price,
        accepted: false,
        created-at: stacks-block-height
      }
    )
    (var-set offer-nonce new-offer-id)
    (ok new-offer-id)
  )
)

(define-public (accept-offer (offer-id uint))
  (let
    (
      (offer (unwrap! (map-get? offers { offer-id: offer-id }) err-not-found))
      (listing-id (get listing-id offer))
      (listing (unwrap! (map-get? listings { listing-id: listing-id }) err-not-found))
      (asset-id (get asset-id listing))
      (buyer (get buyer offer))
      (shares-amount (get shares-amount offer))
      (total-price (get offered-price offer))
      (seller-shares (get shares (get-asset-shares asset-id tx-sender)))
      (buyer-shares (get shares (get-asset-shares asset-id buyer)))
    )
    (asserts! (is-eq tx-sender (get seller listing)) err-unauthorized)
    (asserts! (get active listing) err-not-for-sale)
    (asserts! (not (get accepted offer)) err-already-exists)
    (asserts! (>= seller-shares shares-amount) err-insufficient-funds)
    (try! (stx-transfer? total-price buyer tx-sender))
    (map-set asset-shares
      { asset-id: asset-id, holder: tx-sender }
      { shares: (- seller-shares shares-amount) }
    )
    (map-set asset-shares
      { asset-id: asset-id, holder: buyer }
      { shares: (+ buyer-shares shares-amount) }
    )
    (map-set offers
      { offer-id: offer-id }
      (merge offer { accepted: true })
    )
    (if (is-eq shares-amount (get shares-amount listing))
      (map-set listings
        { listing-id: listing-id }
        (merge listing { active: false, shares-amount: u0 })
      )
      (map-set listings
        { listing-id: listing-id }
        (merge listing { shares-amount: (- (get shares-amount listing) shares-amount) })
      )
    )
    (ok true)
  )
)

