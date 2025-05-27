# 🧠 StacksPredict

**StacksPredict** is a fully decentralized, trustless prediction market protocol built on top of **Stacks** (Layer 2 for Bitcoin). It enables users to stake STX tokens on directional price movements with oracle-verified outcomes and automated payouts. The protocol leverages Bitcoin's security model while maintaining on-chain transparency and fair reward distribution.

---

## 📜 Summary

StacksPredict allows users to:

* Participate in open prediction markets on asset price movements.
* Stake STX tokens in "up" or "down" directions.
* Earn proportional rewards if they predict correctly.
* Rely on oracles for market resolution.
* Claim winnings automatically with built-in fee mechanisms.

---

## ⚙️ Features

* **Decentralized**: Trustless, permissionless prediction markets on Stacks.
* **Oracle-Resolved**: Outcomes verified via a designated oracle address.
* **Transparent Payouts**: Proportional rewards and transparent fee structure.
* **Bitcoin Security**: Settlement and integrity backed by the Bitcoin blockchain via Stacks.
* **Configurable Platform**: Adjustable stake minimums, fee rates, and oracle accounts.

---

## 🏛️ Smart Contract Overview

### ✅ Core Functions

| Function          | Description                                                     |
| ----------------- | --------------------------------------------------------------- |
| `create-market`   | Admin creates new prediction market with price and time bounds. |
| `make-prediction` | Users stake STX on price direction ("up" or "down").            |
| `resolve-market`  | Oracle submits the actual outcome price.                        |
| `claim-winnings`  | Winners claim proportional rewards based on total stake.        |

### 🛠 Administrative Functions

* `set-oracle-address`: Change the oracle address.
* `set-minimum-stake`: Adjust minimum STX required to participate.
* `set-fee-percentage`: Modify platform fee (max 100%).
* `withdraw-fees`: Owner withdraws accumulated protocol fees.

---

## 🧱 Architecture

```
┌────────────────────────┐
│     StacksPredict      │
│   Smart Contract (Clarity)   │
└────────────────────────┘
        ▲           ▲
        │           │
        │           └─────┬────────────────┐
        │                 │                │
        │       ┌──────────────┐    ┌────────────┐
        │       │   Oracle     │    │ Admin CLI  │
        │       │ (Off-chain)  │    │ (Stacks.js)│
        │       └──────────────┘    └────────────┘
        │                 ▲
        │                 │
┌───────┴───────┐     ┌───┴───────────┐
│ STX Wallets   │     │ UI / Frontend │
│ (Hiro Wallet) │     │  (React + SDK)│
└───────────────┘     └───────────────┘
```

* **StacksPredict Contract**: The Clarity smart contract manages markets, stakes, resolutions, and payouts.
* **Oracle**: A trusted entity posts end-of-market prices.
* **Admin CLI**: Used by the platform owner to configure parameters or create markets.
* **Users**: Participate using STX wallets like Hiro.
* **Frontend Interface**: (Optional) DApp UI allowing users to browse markets, stake, and claim rewards.

---

## 🪙 Token Economics

* **Token Used**: STX (Stacks token)
* **Minimum Stake**: Configurable (default 1 STX)
* **Fee**: Configurable platform fee on winnings (default 2%)
* **Fee Receiver**: Contract owner

---

## 📘 Example Flow

1. **Market Creation**: Admin creates a market with price/time parameters.
2. **User Prediction**: Users stake STX to predict "up" or "down."
3. **Resolution**: Oracle submits the final price after the market ends.
4. **Claim**: Winning users claim STX payouts minus platform fee.

---

## 🛡 Security Considerations

* **No Custodial Risks**: Funds are locked and managed via smart contract logic.
* **Oracle Trust Assumption**: Market resolution depends on a designated oracle. Multi-oracle or DAO-based resolution could be considered in future.
* **Immutable Predictions**: Once submitted, predictions and stakes cannot be altered.

---

## 📂 File Structure

```
/contracts
  └── stacks-predict.clar   # Main Clarity smart contract
/README.md                  # Project documentation
```

---

## 🔮 Future Improvements

* Multiple oracle support with weighted voting.
* Support for non-price-based event predictions.
* UI DApp with wallet integration.
* Prediction pools with custom odds and leverage.
