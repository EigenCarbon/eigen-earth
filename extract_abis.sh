#!/bin/bash
set -e

echo "📦 Building contracts..."
forge build

mkdir -p abis

contracts=(
  "EigenEarth.sol/EigenEarth"
  "EigenEarthFoundation.sol/EigenEarthFoundation"
  "EigenCarbonService.sol/EigenCarbonService"
  "EigenVintageCarbonCoin.sol/EigenVintageCarbonCoin"
  "EigenCarbonVerifier.sol/EigenCarbonVerifier"
  "EigenLandVerifier.sol/EigenLandVerifier"
)

for contract in "${contracts[@]}"; do
  src="out/${contract%%/*}/${contract##*/}.json"
  dst="abis/${contract##*/}.abi.json"
  if [ -f "$src" ]; then
    jq '.abi' "$src" > "$dst"
    echo "✅ ABI extracted: $dst"
  else
    echo "⚠️ Artifact not found: $src"
  fi
done

echo "🎉 ABI extraction complete."

