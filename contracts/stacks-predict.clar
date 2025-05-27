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