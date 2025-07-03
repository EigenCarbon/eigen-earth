#!/usr/bin/env zsh
set -euo pipefail

# -------------------------------
# 1) Restart Anvil
# -------------------------------
echo "🔧 Restarting Anvil…"
pkill -f anvil || true
anvil --silent &
ANVIL_PID=$!
sleep 2

# --disable-code-size-limit --gas-limit 100000000 

# -------------------------------
# 2) Defaults
# -------------------------------
RPC_URL="${RPC_URL:-http://127.0.0.1:8545}"
PK="${PK:-0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80}"

# Set role-based wallet addresses from accounts (hardcoded from Anvil)
LAND_VERIFIER_WALLET="${LAND_VERIFIER_WALLET:-0x70997970C51812dc3A010C7d01b50e0d17dc79C8}"      # Account 1
CARBON_VERIFIER_WALLET="${CARBON_VERIFIER_WALLET:-0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC}"  # Account 2
LAND_WALLET="${LAND_WALLET:-0x90F79bf6EB2c4f870365E785982E1f101E93b906}"                        # Account 3
CARBON_COIN_WALLET="${CARBON_COIN_WALLET:-0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65}"           # Account 4

LAND_VERIFICATION_FEE_WEI="${LAND_VERIFICATION_FEE_WEI:-10000000000000000}"
CARBON_VERIFICATION_FEE_WEI="${CARBON_VERIFICATION_FEE_WEI:-20000000000000000}"

COIN_NAME="${COIN_NAME:-EigenCarbonCoin}"
COIN_SYMBOL="${COIN_SYMBOL:-CC}"

# -------------------------------
# 3) Write .env file
# -------------------------------
echo "📄 Writing .env and anvil.env …"
{
  echo "RPC_URL=\"$RPC_URL\""
  echo "PRIVATE_KEY=\"$PK\""
  echo "LAND_VERIFIER_WALLET=\"$LAND_VERIFIER_WALLET\""
  echo "LAND_VERIFICATION_FEE_WEI=\"$LAND_VERIFICATION_FEE_WEI\""
  echo "CARBON_VERIFIER_WALLET=\"$CARBON_VERIFIER_WALLET\""
  echo "LAND_WALLET=\"$LAND_WALLET\""
  echo "CARBON_COIN_WALLET=\"$CARBON_COIN_WALLET\""
  echo "CARBON_VERIFICATION_FEE_WEI=\"$CARBON_VERIFICATION_FEE_WEI\""
  echo "COIN_NAME=\"$COIN_NAME\""
  echo "COIN_SYMBOL=\"$COIN_SYMBOL\""
} | tee .env > anvil.env

# -------------------------------
# 4) Run Forge Deploy Script
# -------------------------------
echo "🚀 Deploying via DeployFoundation.s.sol..."

DEPLOY_OUT=$(forge script script/DeployEigenEarthFoundationWithExamples.s.sol:DeployWithExamples \
    --rpc-url "$RPC_URL" \
    --private-key "$PK" \
    --broadcast \
    --non-interactive \
    --sig "run(address,uint256,address,uint256,address,address)" \
    "$LAND_VERIFIER_WALLET" \
    "$LAND_VERIFICATION_FEE_WEI" \
    "$CARBON_VERIFIER_WALLET" \
    "$CARBON_VERIFICATION_FEE_WEI" \
    "$LAND_WALLET" \
    "$CARBON_COIN_WALLET" \
    -vvvv 2>&1 | tee /dev/tty)

echo "✅ Deployment complete."

# -------------------------------
# 5) Extract and record contract addresses
# -------------------------------
echo "🏷 Extracting contract addresses…"
echo "$DEPLOY_OUT" | grep -E "new .*@0x" | tac | while read -r line; do
  name=$(echo "$line" | sed -E 's/.*new ([^@]+)@.*/\1/' | tr '[:upper:]' '[:lower:]' | tr - _)
  upper_name=$(echo "$name" | tr '[:lower:]' '[:upper:]')
  addr=$(echo "$line" | grep -oE '0x[a-fA-F0-9]{40}')
  # Update both .env and anvil.env
  sed -i '' "/^${upper_name}=/d" .env
  sed -i '' "/^${upper_name}=/d" anvil.env
  echo "${upper_name}=${addr}" >> .env
  echo "${upper_name}=${addr}" >> anvil.env
done

# -------------------------------
# 6) Write output to log
# -------------------------------
echo "$DEPLOY_OUT" > deploy_all_anvil.txt

# -------------------------------
# 7) Show summary
# -------------------------------
echo
echo
echo "=== .env ==="
grep -E "^[A-Z_]+=.*" .env
echo
echo "=== .env ==="
grep -E "^[A-Z_]+=.*" anvil.env
echo
echo "ℹ️  Anvil is running (PID $ANVIL_PID)"
