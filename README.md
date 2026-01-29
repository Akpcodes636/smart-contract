Here’s a **professional, GitHub-ready `README.md`** you can drop into your repo before pushing 🚀

You can copy this entire thing into a file called `README.md`.

---

# 🛡️ Freelance Escrow Smart Contract (Foundry)

A milestone-based escrow smart contract for freelance projects, written in Solidity and tested using **Foundry**.

This contract allows:

* Clients to stake project funds upfront
* Freelancers to receive payments per milestone
* Platforms to collect fees
* Mutual cancellation with refunds
* Full payout on completion

---

## 📦 Features

* ✅ Client-only staking
* ✅ Milestone payments
* ✅ One-time full payout
* ✅ Platform fee system (basis points)
* ✅ Mutual cancellation & refund
* ✅ Strong state machine
* ✅ Fully tested with Foundry
* ✅ Gas reporting support
* ✅ Ready for BNB / EVM chains

---

## 🗂️ Project Structure

```
.
├── contracts/
│   └── FreelanceEscrow.sol
├── test/
│   └── FreelanceEscrow.t.sol
├── foundry.toml
└── README.md
```

---

## ⚙️ Requirements

* [Foundry](https://book.getfoundry.sh/)
* Node.js (optional, for tooling)
* Git

---

## 🚀 Setup

Install Foundry:

```bash
curl -L https://foundry.paradigm.xyz | bash
foundryup
```

Clone repo and install deps:

```bash
git clone <your-repo-url>
cd freelance-escrow
forge install
```

---

## 🧪 Run Tests

Run full test suite:

```bash
forge test -vvv
```

With gas report:

```bash
forge test --gas-report
```

---

## 📜 Smart Contract Overview

### Contract: `FreelanceEscrow.sol`

### Roles

* **Client** → funds the escrow
* **Freelancer** → receives payments
* **Platform** → receives fee
* **Platform Wallet** → address collecting fees

---

### Project States

```solidity
enum ProjectState {
    Initiated,
    Active,
    Cancelled,
    Completed
}
```

---

### Core Flow

1️⃣ Deploy contract with project details
2️⃣ Client stakes full amount
3️⃣ Project becomes Active
4️⃣ Client pays by milestone OR all at once
5️⃣ Platform fee is deducted
6️⃣ Freelancer is paid
7️⃣ Final milestone → Completed

---

### Cancellation Flow

* Client or freelancer may request cancel
* If **both** request → funds refunded to client
* Either party can revoke before finalization

---

## 💰 Platform Fees

Fees are set in **basis points (BPS)**:

* `200` = 2%
* `1000` = 10% max

Fee formula:

```
fee = grossAmount * platformFeeBps / 10_000
```

---

## 🔒 Security Considerations

This repo currently includes:

* Access control tests
* State enforcement
* Payment correctness
* Refund logic

### ⚠️ Recommended Additions for Production

* Reentrancy attack simulations
* Invariant testing
* Fuzz tests
* Pausable mechanism
* Emergency withdraw logic
* Multi-sig platform wallet
* Formal audit

---

## 🌐 Deployment

To deploy to testnets:

```bash
forge create \
  --rpc-url <RPC_URL> \
  --private-key <PRIVATE_KEY> \
  contracts/FreelanceEscrow.sol:FreelanceEscrow \
  --constructor-args \
  <client> \
  <freelancer> \
  <price> \
  <milestones> \
  "Title" \
  "Description" \
  <platformWallet> \
  <feeBps>
```

---

## 🧠 Development Philosophy

This project focuses on:

* **Test-first mindset**
* **Clear state machines**
* **Minimal trust**
* **Explicit permissions**
* **Escrow safety**

---

## 📄 License

UNLICENSED (replace with MIT/Apache-2.0 if open-sourcing)

---

## ✨ Author

Built by **Ewherhe Akpesiri**
Software Engineer / Blockchain Developer