;; Title: StacksPredict - Decentralized Prediction Markets on Bitcoin
;;
;; Summary: A trustless prediction market protocol enabling users to stake STX tokens
;;          on price movements with oracle-verified outcomes and automated payouts.
;;
;; Description: StacksPredict leverages Bitcoin's security through Stacks Layer 2 to create
;;              a fully decentralized prediction market ecosystem. Users can participate in
;;              price prediction markets by staking STX tokens on directional price movements.
;;              The protocol features oracle-based resolution, proportional reward distribution,
;;              and built-in fee mechanisms to ensure sustainable operations while maintaining
;;              complete transparency and Bitcoin-level security guarantees.

;; CONSTANTS & ERROR CODES

;; Administrative Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-OWNER-ONLY (err u100))

;; Error Code Definitions
(define-constant ERR-NOT-FOUND (err u101))
(define-constant ERR-INVALID-PREDICTION (err u102))
(define-constant ERR-MARKET-CLOSED (err u103))
(define-constant ERR-ALREADY-CLAIMED (err u104))
(define-constant ERR-INSUFFICIENT-BALANCE (err u105))
(define-constant ERR-INVALID-PARAMETER (err u106))

;; STATE VARIABLES

;; Platform Configuration
(define-data-var oracle-address principal 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM)
(define-data-var minimum-stake uint u1000000) ;; 1 STX minimum stake
(define-data-var fee-percentage uint u2) ;; 2% platform fee
(define-data-var market-counter uint u0) ;; Incremental market ID counter

;; DATA STRUCTURES

;; Market Data Structure
;; Stores all market-related information including prices, stakes, and timing
(define-map markets
  uint
  {
    start-price: uint, ;; Initial price when market opens
    end-price: uint, ;; Final price for settlement (0 if unresolved)
    total-up-stake: uint, ;; Total STX staked on price increase
    total-down-stake: uint, ;; Total STX staked on price decrease
    start-block: uint, ;; Block height when predictions open
    end-block: uint, ;; Block height when predictions close
    resolved: bool, ;; Whether market has been settled
  }
)

;; User Prediction Tracking
;; Maps each user's prediction per market with stake details
(define-map user-predictions
  {
    market-id: uint,
    user: principal,
  }
  {
    prediction: (string-ascii 4), ;; "up" or "down"
    stake: uint, ;; Amount of STX staked
    claimed: bool, ;; Whether winnings have been claimed
  }
)

;; CORE PUBLIC FUNCTIONS

;; Create New Prediction Market
;; Only contract owner can create markets with specified parameters
(define-public (create-market
    (start-price uint)
    (start-block uint)
    (end-block uint)
  )
  (let ((market-id (var-get market-counter)))
    ;; Validation checks
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-OWNER-ONLY)
    (asserts! (> end-block start-block) ERR-INVALID-PARAMETER)
    (asserts! (> start-price u0) ERR-INVALID-PARAMETER)
    ;; Create new market entry
    (map-set markets market-id {
      start-price: start-price,
      end-price: u0,
      total-up-stake: u0,
      total-down-stake: u0,
      start-block: start-block,
      end-block: end-block,
      resolved: false,
    })
    ;; Increment counter for next market
    (var-set market-counter (+ market-id u1))
    (ok market-id)
  )
)

;; Make Price Prediction
;; Users stake STX tokens on price direction within active market timeframe
(define-public (make-prediction
    (market-id uint)
    (prediction (string-ascii 4))
    (stake uint)
  )
  (let (
      (market (unwrap! (map-get? markets market-id) ERR-NOT-FOUND))
      (current-block stacks-block-height)
    )
    ;; Market timing validation
    (asserts!
      (and
        (>= current-block (get start-block market))
        (< current-block (get end-block market))
      )
      ERR-MARKET-CLOSED
    )
    ;; Prediction format validation
    (asserts! (or (is-eq prediction "up") (is-eq prediction "down"))
      ERR-INVALID-PREDICTION
    )
    ;; Stake amount validation
    (asserts! (>= stake (var-get minimum-stake)) ERR-INVALID-PREDICTION)
    (asserts! (<= stake (stx-get-balance tx-sender)) ERR-INSUFFICIENT-BALANCE)
    ;; Transfer stake to contract
    (try! (stx-transfer? stake tx-sender (as-contract tx-sender)))
    ;; Record user prediction
    (map-set user-predictions {
      market-id: market-id,
      user: tx-sender,
    } {
      prediction: prediction,
      stake: stake,
      claimed: false,
    })
    ;; Update market totals based on prediction direction
    (map-set markets market-id
      (merge market {
        total-up-stake: (if (is-eq prediction "up")
          (+ (get total-up-stake market) stake)
          (get total-up-stake market)
        ),
        total-down-stake: (if (is-eq prediction "down")
          (+ (get total-down-stake market) stake)
          (get total-down-stake market)
        ),
      })
    )
    (ok true)
  )
)

;; Resolve Market with Final Price
;; Oracle provides final price to determine winning predictions
(define-public (resolve-market
    (market-id uint)
    (end-price uint)
  )
  (let ((market (unwrap! (map-get? markets market-id) ERR-NOT-FOUND)))
    ;; Authorization and timing checks
    (asserts! (is-eq tx-sender (var-get oracle-address)) ERR-OWNER-ONLY)
    (asserts! (>= stacks-block-height (get end-block market)) ERR-MARKET-CLOSED)
    (asserts! (not (get resolved market)) ERR-MARKET-CLOSED)
    (asserts! (> end-price u0) ERR-INVALID-PARAMETER)
    ;; Mark market as resolved with final price
    (map-set markets market-id
      (merge market {
        end-price: end-price,
        resolved: true,
      })
    )
    (ok true)
  )
)

;; Claim Prediction Winnings
;; Winners can claim proportional rewards minus platform fees
(define-public (claim-winnings (market-id uint))
  (let (
      (market (unwrap! (map-get? markets market-id) ERR-NOT-FOUND))
      (prediction (unwrap!
        (map-get? user-predictions {
          market-id: market-id,
          user: tx-sender,
        })
        ERR-NOT-FOUND
      ))
    )
    ;; Validation checks
    (asserts! (get resolved market) ERR-MARKET-CLOSED)
    (asserts! (not (get claimed prediction)) ERR-ALREADY-CLAIMED)
    (let (
        ;; Determine winning prediction direction
        (winning-prediction (if (> (get end-price market) (get start-price market))
          "up"
          "down"
        ))
        (total-stake (+ (get total-up-stake market) (get total-down-stake market)))
        (winning-stake (if (is-eq winning-prediction "up")
          (get total-up-stake market)
          (get total-down-stake market)
        ))
      )
      ;; Verify user made winning prediction
      (asserts! (is-eq (get prediction prediction) winning-prediction)
        ERR-INVALID-PREDICTION
      )
      (let (
          ;; Calculate proportional winnings
          (winnings (/ (* (get stake prediction) total-stake) winning-stake))
          (fee (/ (* winnings (var-get fee-percentage)) u100))
          (payout (- winnings fee))
        )
        ;; Transfer payout to user and fee to owner
        (try! (as-contract (stx-transfer? payout (as-contract tx-sender) tx-sender)))
        (try! (as-contract (stx-transfer? fee (as-contract tx-sender) CONTRACT-OWNER)))
        ;; Mark prediction as claimed
        (map-set user-predictions {
          market-id: market-id,
          user: tx-sender,
        }
          (merge prediction { claimed: true })
        )
        (ok payout)
      )
    )
  )
)

;; READ-ONLY FUNCTIONS

;; Get Market Information
(define-read-only (get-market (market-id uint))
  (map-get? markets market-id)
)