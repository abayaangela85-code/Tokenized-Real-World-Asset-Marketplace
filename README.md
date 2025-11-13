# 🏛️ Tokenized Real-World Asset Marketplace

A decentralized marketplace smart contract built on Stacks blockchain that enables fractional ownership and trading of tokenized real-world assets.

## 🌟 Features

- **Asset Tokenization**: Create tokenized real-world assets with fractional shares
- **Verification System**: Contract owner can verify assets for authenticity
- **Share Trading**: Transfer ownership shares between parties
- **Marketplace Listings**: Create and manage listings for selling asset shares
- **Offer System**: Buyers can make offers on listings, sellers can accept
- **STX Payments**: All transactions settled in STX tokens

## 📋 Contract Overview

The smart contract provides a complete marketplace infrastructure for trading fractional ownership of real-world assets. Each asset can be divided into shares, verified by the contract owner, and traded on an open marketplace.

### Core Data Structures

- **Assets**: Tokenized real-world assets with metadata and share information
- **Asset Shares**: Tracks ownership distribution across holders
- **Listings**: Active marketplace listings for selling shares
- **Offers**: Buyer-initiated offers on existing listings

## 🚀 Getting Started

### Prerequisites

- [Clarinet](https://github.com/hirosystems/clarinet) installed
- Basic understanding of Clarity smart contracts

### Installation

```bash
clarinet new tokenized-marketplace
cd tokenized-marketplace
```

Copy the contract file into `contracts/Tokenized-Real-World-Asset-Marketplace.clar`

### Verify Contract

```bash
clarinet check
```

## 📖 Usage Guide

### Creating an Asset 🏗️

```clarity
(contract-call? .Tokenized-Real-World-Asset-Marketplace create-asset 
  "Luxury Apartment NYC" 
  "Premium downtown apartment, 2BR 2BA" 
  u1000 
  u100000)
```

Parameters:
- `name`: Asset name (max 50 characters)
- `description`: Asset description (max 200 characters)
- `total-shares`: Total number of shares
- `price-per-share`: Initial price per share in microSTX

### Verifying an Asset ✅

Only the contract owner can verify assets:

```clarity
(contract-call? .Tokenized-Real-World-Asset-Marketplace verify-asset u1)
```

### Transferring Shares 🔄

```clarity
(contract-call? .Tokenized-Real-World-Asset-Marketplace transfer-shares 
  u1 
  'ST2JHG361ZXG51QTKY2NQCVBPPRRE2KZB1HR05NNC 
  u50)
```

### Creating a Listing 💼

Assets must be verified before listing:

```clarity
(contract-call? .Tokenized-Real-World-Asset-Marketplace create-listing 
  u1 
  u100 
  u105000)
```

Parameters:
- `asset-id`: ID of the asset
- `shares-amount`: Number of shares to sell
- `price-per-share`: Asking price per share

### Purchasing Shares 💰

```clarity
(contract-call? .Tokenized-Real-World-Asset-Marketplace purchase-shares 
  u1 
  u50)
```

### Making an Offer 📝

```clarity
(contract-call? .Tokenized-Real-World-Asset-Marketplace create-offer 
  u1 
  u50 
  u5000000)
```

Parameters:
- `listing-id`: ID of the listing
- `shares-amount`: Number of shares offered for
- `offered-price`: Total price offered (not per share)

### Accepting an Offer ✔️

```clarity
(contract-call? .Tokenized-Real-World-Asset-Marketplace accept-offer u1)
```

### Canceling a Listing ❌

```clarity
(contract-call? .Tokenized-Real-World-Asset-Marketplace cancel-listing u1)
```

## 🔍 Read-Only Functions

### Query Asset Information

```clarity
(contract-call? .Tokenized-Real-World-Asset-Marketplace get-asset u1)
```

### Check Share Holdings

```clarity
(contract-call? .Tokenized-Real-World-Asset-Marketplace get-asset-shares 
  u1 
  'ST2JHG361ZXG51QTKY2NQCVBPPRRE2KZB1HR05NNC)
```

### View Listing Details

```clarity
(contract-call? .Tokenized-Real-World-Asset-Marketplace get-listing u1)
```

### View Offer Details

```clarity
(contract-call? .Tokenized-Real-World-Asset-Marketplace get-offer u1)
```

### Get Current Nonces

```clarity
(contract-call? .Tokenized-Real-World-Asset-Marketplace get-asset-nonce)
(contract-call? .Tokenized-Real-World-Asset-Marketplace get-listing-nonce)
(contract-call? .Tokenized-Real-World-Asset-Marketplace get-offer-nonce)
```

## ⚠️ Error Codes

| Code | Constant | Description |
|------|----------|-------------|
| u100 | err-owner-only | Action restricted to contract owner |
| u101 | err-not-found | Resource not found |
| u102 | err-already-exists | Resource already exists |
| u103 | err-unauthorized | Unauthorized action |
| u104 | err-insufficient-funds | Insufficient shares or balance |
| u105 | err-not-for-sale | Listing not active |
| u106 | err-invalid-price | Invalid price specified |
| u107 | err-invalid-shares | Invalid share amount |
| u108 | err-asset-not-verified | Asset not verified by owner |

## 🔐 Security Considerations

- Only verified assets can be listed on the marketplace
- Sellers must own sufficient shares to create listings
- Buyers must have sufficient STX balance for purchases
- All transfers are atomic and secure
- Share ownership is tracked immutably on-chain

## 🛠️ Development

### Run Tests

```bash
npm install
npm test
```

### Local Console

```bash
clarinet console
```

## 📝 License

MIT License

## 🤝 Contributing

Contributions welcome! Please open an issue or submit a pull request.

## 📞 Support

For questions or issues, please open a GitHub issue.

---

Built with ❤️ on Stacks blockchain
