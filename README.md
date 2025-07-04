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
- 🪙 **ERC20 vintage carbon coins** for each carbon abatement vintage (e.g., 2025–2030) - these are freely tradeable to set the market price for carbon
- 🔥 A **carbon credit is granted** when the coin is **burned** and a certificate is issued - this is on chain irrefutable proof of a specific amount of carbon abatement for a specific time period against a specific piece of land - complete transparency, total authenticity, irrefutable verifiability

All contracts are deployed to Ethereum Mainnet and verified on Etherscan for transparency.

We can make an **extremely strong promise** that **1 coin = 1 kg of verified carbon abatement** for the specific vintage year. This guarantee is irrefutable, transparent, and ascertainable because it is enforced by the smart contract logic and fully visible on-chain.

---

## 🧠 Approach Taken

✅ **Modular Design:**The system is split into distinct components:

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

| Contract                           | Address                                        | Etherscan                                                                    |
| ---------------------------------- | ---------------------------------------------- | ---------------------------------------------------------------------------- |
| **EigenEarthFoundation**     | `0xFd58357744B7dA0839Fcb9A0a36F08a96206Dbf0` | [View](https://etherscan.io/address/0xFd58357744B7dA0839Fcb9A0a36F08a96206Dbf0) |
| **EigenEarth Proxy**         | `0x8793Da43c8A7cfb4Bc6118Dd5b769B90611457e4` | [View](https://etherscan.io/address/0x8793Da43c8A7cfb4Bc6118Dd5b769B90611457e4) |
| **EigenCarbonService Proxy** | `0x0Fd26cE062B84f84685ECf042F6a129a8EAa6dA0` | [View](https://etherscan.io/address/0x0Fd26cE062B84f84685ECf042F6a129a8EAa6dA0) |
| **EigenCarbonService Logic** | `0xfB1f840FD51F3f2f2c5Ce0B99f88948E24F9ef50` | [View](https://etherscan.io/address/0xfB1f840FD51F3f2f2c5Ce0B99f88948E24F9ef50) |
| **Land Verifier**            | `0x7DCe98d2F0b8401e71DEAa17b979341a953a65e9` | [View](https://etherscan.io/address/0x7DCe98d2F0b8401e71DEAa17b979341a953a65e9) |
| **Carbon Verifier**          | `0x21042A681EDAd08Edc510D10F01FdDe2b3bDBaeB` | [View](https://etherscan.io/address/0x21042A681EDAd08Edc510D10F01FdDe2b3bDBaeB) |
| **EigenEarth Logic**         | `0xA38633EdF5ce065EE01e24031CD951Add288DFe9` | [View](https://etherscan.io/address/0xA38633EdF5ce065EE01e24031CD951Add288DFe9) |
| **Vintage 2025 Coin**        | `0xf1730b5Be60EF13106573eD5d9bB030272aF7083` | [View](https://etherscan.io/address/0xf1730b5Be60EF13106573eD5d9bB030272aF7083) |
| **Vintage 2026 Coin**        | `0x7b6088748B7cd6c815FE4c8b05Dd0F8a3AD90B16` | [View](https://etherscan.io/address/0x7b6088748B7cd6c815FE4c8b05Dd0F8a3AD90B16) |
| **Vintage 2027 Coin**        | `0x05a520D75e0C27964f4BAd0fbc782FCAab9b51d6` | [View](https://etherscan.io/address/0x05a520D75e0C27964f4BAd0fbc782FCAab9b51d6) |
| **Vintage 2028 Coin**        | `0xE4C2D4fC73a168677c4A58D8208F7265965b9151` | [View](https://etherscan.io/address/0xE4C2D4fC73a168677c4A58D8208F7265965b9151) |
| **Vintage 2029 Coin**        | `0xF3BbAECb936e1Ae9D07f34200B7452039a6b4916` | [View](https://etherscan.io/address/0xF3BbAECb936e1Ae9D07f34200B7452039a6b4916) |
| **Vintage 2030 Coin**        | `0x80777A5AA2c2D6dBa569E593af217E24c0a49aC9` | [View](https://etherscan.io/address/0x80777A5AA2c2D6dBa569E593af217E24c0a49aC9) |

🌐 **Website:** [https://eigencarbon.xyz](https://eigencarbon.xyz)

## 🛠️ Technologies

- Solidity / Ethereum
- Foundry (Forge, Cast)
- OpenZeppelin Upgradeable Contracts
- Etherscan verification for full transparency

## 📜 License

MIT License — open source and community-driven.

---
