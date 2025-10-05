
;; title: arkadiko-vault
;; version: 1.0
;; summary: Collateral management system for Arkadiko DAO
;; description: Collateral management system for over-collateralizing STX tokens to mint stablecoins

;; traits
(define-trait oracle-trait
  (
    (get-price ((string-ascii 32)) (response uint uint))
  )
)

;; token definitions
(define-fungible-token diko-stablecoin)

;; constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_NOT_AUTHORIZED (err u300))
(define-constant ERR_INSUFFICIENT_COLLATERAL (err u301))
(define-constant ERR_VAULT_NOT_FOUND (err u302))
(define-constant ERR_LIQUIDATION_THRESHOLD (err u303))
(define-constant ERR_INVALID_AMOUNT (err u304))
(define-constant MIN_COLLATERAL_RATIO u150) ;; 150% minimum
(define-constant LIQUIDATION_RATIO u120) ;; 120% liquidation threshold
(define-constant STABILITY_FEE u5) ;; 0.5% annual fee (simplified)

;; data vars
(define-data-var contract-owner principal CONTRACT_OWNER)
(define-data-var total-debt uint u0)
(define-data-var vault-counter uint u0)
(define-data-var oracle-contract (optional principal) none)

;; data maps
(define-map vaults
  { vault-id: uint }
  { 
    owner: principal,
    collateral: uint,
    debt: uint,
    created-at: uint,
    last-update: uint
  }
)

(define-map user-vaults principal (list 50 uint))

;; public functions
(define-public (create-vault (collateral-amount uint))
  (let (
    (vault-id (+ (var-get vault-counter) u1))
    (stx-price (unwrap-panic (get-stx-price)))
    (max-debt (calculate-max-debt collateral-amount stx-price))
  )
    (asserts! (> collateral-amount u0) ERR_INVALID_AMOUNT)
    (asserts! (> max-debt u0) ERR_INSUFFICIENT_COLLATERAL)
    
    ;; Transfer STX collateral to contract
    (try! (stx-transfer? collateral-amount tx-sender (as-contract tx-sender)))
    
    ;; Create vault record
    (map-set vaults
      { vault-id: vault-id }
      {
        owner: tx-sender,
        collateral: collateral-amount,
        debt: u0,
        created-at: stacks-block-height,
        last-update: stacks-block-height
      }
    )
    
    ;; Update user's vault list
    (update-user-vaults tx-sender vault-id)
    
    ;; Increment counter
    (var-set vault-counter vault-id)
    
    (ok vault-id)
  )
)

(define-public (mint-diko (vault-id uint) (amount uint))
  (let (
    (vault (unwrap! (map-get? vaults { vault-id: vault-id }) ERR_VAULT_NOT_FOUND))
    (stx-price (unwrap-panic (get-stx-price)))
    (new-debt (+ (get debt vault) amount))
    (collateral-value (* (get collateral vault) stx-price))
    (collateral-ratio (/ (* collateral-value u100) new-debt))
  )
    (asserts! (is-eq (get owner vault) tx-sender) ERR_NOT_AUTHORIZED)
    (asserts! (> amount u0) ERR_INVALID_AMOUNT)
    (asserts! (>= collateral-ratio MIN_COLLATERAL_RATIO) ERR_INSUFFICIENT_COLLATERAL)
    
    ;; Update vault debt
    (map-set vaults
      { vault-id: vault-id }
      (merge vault { debt: new-debt, last-update: stacks-block-height })
    )
    
    ;; Mint DIKO stablecoin
    (try! (ft-mint? diko-stablecoin amount tx-sender))
    
    ;; Update total debt
    (var-set total-debt (+ (var-get total-debt) amount))
    
    (ok true)
  )
)

(define-public (repay-diko (vault-id uint) (amount uint))
  (let (
    (vault (unwrap! (map-get? vaults { vault-id: vault-id }) ERR_VAULT_NOT_FOUND))
    (current-debt (get debt vault))
    (repay-amount (if (> amount current-debt) current-debt amount))
    (new-debt (- current-debt repay-amount))
  )
    (asserts! (is-eq (get owner vault) tx-sender) ERR_NOT_AUTHORIZED)
    (asserts! (> amount u0) ERR_INVALID_AMOUNT)
    
    ;; Burn DIKO tokens
    (try! (ft-burn? diko-stablecoin repay-amount tx-sender))
    
    ;; Update vault
    (map-set vaults
      { vault-id: vault-id }
      (merge vault { debt: new-debt, last-update: stacks-block-height })
    )
    
    ;; Update total debt
    (var-set total-debt (- (var-get total-debt) repay-amount))
    
    (ok repay-amount)
  )
)

(define-public (add-collateral (vault-id uint) (amount uint))
  (let (
    (vault (unwrap! (map-get? vaults { vault-id: vault-id }) ERR_VAULT_NOT_FOUND))
  )
    (asserts! (is-eq (get owner vault) tx-sender) ERR_NOT_AUTHORIZED)
    (asserts! (> amount u0) ERR_INVALID_AMOUNT)
    
    ;; Transfer additional STX collateral
    (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
    
    ;; Update vault
    (map-set vaults
      { vault-id: vault-id }
      (merge vault {
        collateral: (+ (get collateral vault) amount),
        last-update: stacks-block-height
      })
    )
    
    (ok true)
  )
)

(define-public (set-oracle-contract (oracle principal))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) ERR_NOT_AUTHORIZED)
    (var-set oracle-contract (some oracle))
    (ok true)
  )
)

;; read only functions
(define-read-only (get-vault (vault-id uint))
  (map-get? vaults { vault-id: vault-id })
)

(define-read-only (get-user-vaults (user principal))
  (default-to (list) (map-get? user-vaults user))
)

(define-read-only (calculate-collateral-ratio (vault-id uint))
  (match (map-get? vaults { vault-id: vault-id })
    vault 
      (if (> (get debt vault) u0)
        (let (
          (stx-price u1000000) ;; Use default price for read-only calculation
          (collateral-value (* (get collateral vault) stx-price))
        )
          (some (/ (* collateral-value u100) (get debt vault)))
        )
        none
      )
    none
  )
)

(define-read-only (get-diko-name)
  (ok "DIKO Stablecoin")
)

(define-read-only (get-diko-symbol)
  (ok "DIKO")
)

(define-read-only (get-diko-decimals)
  (ok u6)
)

(define-read-only (get-diko-balance (who principal))
  (ok (ft-get-balance diko-stablecoin who))
)

(define-read-only (get-total-debt)
  (var-get total-debt)
)

;; private functions
(define-private (get-stx-price)
  (match (var-get oracle-contract)
    oracle-addr 
      (contract-call? .arkadiko-oracle get-price "STX")
    (ok u1000000) ;; Default $1.00 if no oracle
  )
)

(define-private (calculate-max-debt (collateral uint) (stx-price uint))
  (let (
    (collateral-value (* collateral stx-price))
  )
    (/ (* collateral-value u100) MIN_COLLATERAL_RATIO)
  )
)

(define-private (update-user-vaults (user principal) (vault-id uint))
  (let (
    (current-vaults (default-to (list) (map-get? user-vaults user)))
  )
    (map-set user-vaults user (unwrap-panic (as-max-len? (append current-vaults vault-id) u50)))
  )
)
