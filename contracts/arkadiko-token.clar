
;; title: arkadiko-token
;; version: 1.0
;; summary: Governance token implementation for Arkadiko DAO
;; description: Implements the $ARE governance token for DAO voting and protocol decisions

;; traits
;;

;; token definitions
(define-fungible-token arkadiko-token)

;; constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_NOT_AUTHORIZED (err u100))
(define-constant ERR_INSUFFICIENT_BALANCE (err u101))
(define-constant TOTAL_SUPPLY u1000000000) ;; 1 billion tokens with 6 decimals

;; data vars
(define-data-var token-uri (optional (string-utf8 256)) none)
(define-data-var contract-owner principal CONTRACT_OWNER)

;; data maps
(define-map approved-contracts principal bool)

;; public functions
(define-public (transfer (amount uint) (from principal) (to principal) (memo (optional (buff 34))))
  (begin
    (asserts! (or (is-eq from tx-sender) (is-eq from contract-caller)) ERR_NOT_AUTHORIZED)
    (ft-transfer? arkadiko-token amount from to)
  )
)

(define-public (mint (amount uint) (recipient principal))
  (begin
    (asserts! (is-authorized-caller) ERR_NOT_AUTHORIZED)
    (ft-mint? arkadiko-token amount recipient)
  )
)

(define-public (burn (amount uint) (owner principal))
  (begin
    (asserts! (is-authorized-caller) ERR_NOT_AUTHORIZED)
    (ft-burn? arkadiko-token amount owner)
  )
)

(define-public (set-token-uri (uri (string-utf8 256)))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) ERR_NOT_AUTHORIZED)
    (var-set token-uri (some uri))
    (ok true)
  )
)

(define-public (authorize-contract (contract principal))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) ERR_NOT_AUTHORIZED)
    (map-set approved-contracts contract true)
    (ok true)
  )
)

;; read only functions
(define-read-only (get-name)
  (ok "Arkadiko Token")
)

(define-read-only (get-symbol)
  (ok "ARE")
)

(define-read-only (get-decimals)
  (ok u6)
)

(define-read-only (get-balance (who principal))
  (ok (ft-get-balance arkadiko-token who))
)

(define-read-only (get-total-supply)
  (ok (ft-get-supply arkadiko-token))
)

(define-read-only (get-token-uri)
  (ok (var-get token-uri))
)

(define-read-only (is-authorized-caller)
  (or 
    (is-eq tx-sender (var-get contract-owner))
    (default-to false (map-get? approved-contracts contract-caller))
  )
)

;; private functions
;;

;; Initialize contract
(begin
  (try! (ft-mint? arkadiko-token TOTAL_SUPPLY CONTRACT_OWNER))
)
