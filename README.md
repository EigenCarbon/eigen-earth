# 🌍 EigenEarth — On-Chain Land & Carbon Credits Management

**EigenEarth** is a fully on-chain framework for managing land assets and carbon abatement credits using smart contracts.  
This project leverages Ethereum's decentralization and transparency to provide a robust, verifiable system for land registry, carbon services, and vintage carbon coin issuance.

---

## 🚀 What is EigenEarth?

EigenEarth is a suite of Solidity contracts that enables:
- 📌 **Registration of land assets** with detailed metadata (e.g. title, spatial data, H3 index)
- 🌱 **Issuance of carbon abatement credits** linked to land and vintage year
- 🔒 **Verifiable roles and permissions** for land and carbon verifiers
- ⚡ **Transparent on-chain fees** and commission flows
- 🪙 **ERC20 vintage carbon coins** for each carbon abatement vintage (e.g., 2025–2030) - these are freely tradeable to set the market price for carbon - a carbon credit is granted when the coin is burned and a certificate is issued - this is on chain irrefutable proof

All contracts are deployed to Ethereum Mainnet and verified on Etherscan for transparency.


We can make an **extremely strong promise** that **1 coin = 1 kg of verified carbon abatement** for the specific vintage year. This guarantee is irrefutable, transparent, and ascertainable because it is enforced by the smart contract logic and fully visible on-chain.

---

## 🧠 Approach Taken

✅ **Modular Design:**  
The system is split into distinct components:
- `EigenEarthFoundation`: Coordinates deployment and management of sub-contracts.
- `EigenEarth`: Core land asset registry (ERC721).
- `EigenCarbonService`: Manages carbon abatement issuance and linkage to land.
- `EigenVintageCarbonCoin`: ERC20 tokens for each vintage year.
- `EigenLandVerifier` / `EigenCarbonVerifier`: Enforce integrity through role-based verification.

✅ **Gas Efficiency:**  
- Deployment split into smaller contracts to stay under EIP-170 size limits.
- Use of proxies for upgradability while keeping logic contracts clean.

✅ **Transparency & Auditability:**  
- All contract code is open source.
- All deployments are verified on Etherscan.
- Fees, beneficiaries, and commission parameters are visible on-chain.

✅ **Extensibility:**  
- New vintage carbon coins can be deployed without impacting existing infrastructure.
- Compatible with DAO governance and other community-controlled systems.

---

## 🌎 Why this is a good idea

🌟 **Immutable proof of carbon abatement**  
Every vintage carbon coin is backed by specific land and verified abatement, with provenance on-chain.

🌟 **Solves greenwashing**  
Since carbon coins represent actual abatement linked to registered land and vintages, it eliminates double counting and unverifiable claims.

🌟 **Market ready & DeFi friendly**  
Vintage carbon coins are ERC20s — they can be traded, used in DeFi protocols, and integrated into carbon offset marketplaces.

🌟 **Global transparency**  
No hidden ledgers. No manual reconciliation. Everything from land registration to carbon issuance is visible on Ethereum.

---

## 🎯 Problems solved

- ❌ **Opacity of traditional carbon markets** → EigenEarth provides on-chain transparency.
- ❌ **Double counting and fraud** → Each credit is tied to unique, verifiable land and vintage data.
- ❌ **Fragmented systems** → A unified, composable smart contract suite that integrates land, carbon services, and coin issuance.
- ❌ **Difficulty in integrating carbon credits into crypto/DeFi ecosystems** → Native ERC20 vintage carbon coins solve this.

---

## 🔗 Deployed Contracts

| Contract | Address | Etherscan |
|-----------|---------|------------|
| **EigenEarthFoundation** | `0x7019311300213C4287F584e7D0e46A1c27Db6920` | [View](https://etherscan.io/address/0x7019311300213c4287f584e7d0e46a1c27db6920) |
| **EigenEarth Proxy** | `0xb34D8cf0018eD1493bfA90B7c74bB628c90D2416` | [View](https://etherscan.io/address/0xb34d8cf0018ed1493bfa90b7c74bb628c90d2416) |
| **EigenCarbonService Proxy** | `0x99Dd795cd05f2eE0086bBb844997380037ae0d22` | [View](https://etherscan.io/address/0x99dd795cd05f2ee0086bbb844997380037ae0d22) |
| **Land Verifier** | `0xCCe4623D59a2ea3c1Efa9De39B801312E7F83795` | [View](https://etherscan.io/address/0xcce4623d59a2ea3c1efa9de39b801312e7f83795) |
| **Carbon Verifier** | `0x6BA9Fd8f5c7563e516DD5d022fd3Eb123AD50946` | [View](https://etherscan.io/address/0x6ba9fd8f5c7563e516dd5d022fd3eb123ad50946) |
| **Vintage 2025 Coin** | `0xB3000539D752f5CF80606ae3B65DdE9Da55BDff8` | [View](https://etherscan.io/address/0xb3000539d752f5cf80606ae3b65dde9da55bdff8) |
| **Vintage 2026 Coin** | `0xA128E4fC62dA2FEc4ebf1Ecb5ebc78AB65286aB2` | [View](https://etherscan.io/address/0xa128e4fc62da2feC4ebf1ecb5ebc78ab65286ab2) |
| **Vintage 2027 Coin** | `0x28a1984A0182CA439F35CC545A19DCB8B96d918d` | [View](https://etherscan.io/address/0x28a1984a0182ca439f35cc545a19dcb8b96d918d) |
| **Vintage 2028 Coin** | `0xa41cb4cef27f5131Dcd0bcEC132bCa0977D07c60` | [View](https://etherscan.io/address/0xa41cb4cef27f5131dcd0bcec132bca0977d07c60) |
| **Vintage 2029 Coin** | `0xc5312796483F9Ee506D01AB71CDBDd32e3C3B057` | [View](https://etherscan.io/address/0xc5312796483f9ee506d01ab71cdbdd32e3c3b057) |
| **Vintage 2030 Coin** | `0x4275f3cad3c9134a90f381ce03EF17f5D28586a0` | [View](https://etherscan.io/address/0x4275f3cad3c9134a90f381ce03ef17f5d28586a0) |

🌐 **Website:** [https://eigencarbon.xyz](https://eigencarbon.xyz)

## 🛠️ Technologies

- Solidity / Ethereum
- Foundry (Forge, Cast)
- OpenZeppelin Upgradeable Contracts
- Etherscan verification for full transparency

## 📜 License

MIT License — open source and community-driven.

---

