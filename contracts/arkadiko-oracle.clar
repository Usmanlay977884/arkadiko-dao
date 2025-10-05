
;; title: arkadiko-oracle
;; version: 1.0
;; summary: Price oracle system for Arkadiko DAO
;; description: Price oracle system for determining collateralization ratios and asset values

;; traits
;;

;; token definitions
;;

;; constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_NOT_AUTHORIZED (err u200))
(define-constant ERR_INVALID_PRICE (err u201))
(define-constant ERR_PRICE_TOO_OLD (err u202))
(define-constant PRICE_VALIDITY_PERIOD u144) ;; ~24 hours in blocks

;; data vars
(define-data-var contract-owner principal CONTRACT_OWNER)

;; data maps
(define-map price-feeds 
  { asset: (string-ascii 32) }
  { price: uint, timestamp: uint, source: principal }
)

(define-map authorized-sources principal bool)

;; public functions
(define-public (set-price (asset (string-ascii 32)) (price uint))
  (begin
    (asserts! (is-authorized-source tx-sender) ERR_NOT_AUTHORIZED)
    (asserts! (> price u0) ERR_INVALID_PRICE)
    (map-set price-feeds 
      { asset: asset }
      { price: price, timestamp: stacks-block-height, source: tx-sender }
    )
    (ok true)
  )
)

(define-public (authorize-source (source principal))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) ERR_NOT_AUTHORIZED)
    (map-set authorized-sources source true)
    (ok true)
  )
)

(define-public (revoke-source (source principal))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) ERR_NOT_AUTHORIZED)
    (map-delete authorized-sources source)
    (ok true)
  )
)

(define-public (transfer-ownership (new-owner principal))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) ERR_NOT_AUTHORIZED)
    (var-set contract-owner new-owner)
    (ok true)
  )
)

;; read only functions
(define-read-only (get-price (asset (string-ascii 32)))
  (match (map-get? price-feeds { asset: asset })
    price-data 
      (if (is-price-valid (get timestamp price-data))
        (ok (get price price-data))
        ERR_PRICE_TOO_OLD
      )
    ERR_INVALID_PRICE
  )
)

(define-read-only (get-price-info (asset (string-ascii 32)))
  (map-get? price-feeds { asset: asset })
)

(define-read-only (is-authorized-source (source principal))
  (default-to false (map-get? authorized-sources source))
)

(define-read-only (get-owner)
  (var-get contract-owner)
)

;; private functions
(define-private (is-price-valid (timestamp uint))
  (< (- stacks-block-height timestamp) PRICE_VALIDITY_PERIOD)
)

;; Initialize with STX price feed
(begin
  (map-set authorized-sources CONTRACT_OWNER true)
  (try! (set-price "STX" u1000000)) ;; $1.00 in micro-dollars
)
