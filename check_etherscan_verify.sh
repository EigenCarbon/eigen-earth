#!/bin/zsh

# Your Etherscan API key (load from env if you like) - required for verification status check
source contracts.env

# Map of contract name -> GUID
typeset -A contract_guids

contract_guids=(
  "EigenEarthFoundation" "s5tikmgrtrzlkfx5jyxzjhnt22hjgn8xeftvpnppkjupmnpe4t"
  "EigenCarbonService"   "nzysytqhp5frhf3st7jvtbafbrqpiezdyk4cfxsqz9j5qca1gn"
  "EigenCarbonVerifier"  "ernwd8hlmqzaajcl92dquc4jebjfkzaqhptzyj373nc4spjsbn"
  "EigenLandVerifier"    "e1gnxahsgi5xkvjb86csgxa8ernz6eddfe98hrihpxy5jmzxfl"
  "EigenEarth"           "fitdlhq8z7nimc6thxnbtgnucjy6ptrqjkqwa3tshahbv7cvzr"
  "Vintage2025"          "6q8zqt1vwgrqqbybui5uwmdgziyaegrnbmem1tzsyp3ck6hfuv"
  "Vintage2026"          "wrdpxicrzymrgfquednbbbjcvgksxubh7ijrknfv99j1xzymmg"
  "Vintage2027"          "f9pwtfvgu3fqehfqbqswzqzc8jst2ka3jqsqdx2f3vgir4y3k8"
  "Vintage2028"          "mvvdxavgzssbgdaaz4jnpkq7tjdutgc7i89qing78xwfwzgjdp"
  "Vintage2029"          "wq7b5qacnzeufzud6prplfpds49gl5mphurjvzj2griuraqipd"
  "Vintage2030"          "jbimxuq48vnah2r3e634fagtmv3fpvld1dh3duhvbwxnzfivng"
)

echo "🔍 Checking verification status on Etherscan..."

for contract in ${(k)contract_guids}; do
  guid=${contract_guids[$contract]}
  echo "➡ Checking $contract (GUID: $guid)..."
  
  # API call to Etherscan to check status
  response=$(curl -s "https://api.etherscan.io/api?module=contract&action=checkverifystatus&guid=${guid}&apikey=${ETHERSCAN_API_KEY}")
  
  verify_status=$(echo $response | jq -r '.status')
  message=$(echo $response | jq -r '.message')
  result=$(echo $response | jq -r '.result')
  
  if [[ "$verify_status" == "1" ]]; then
    echo "✅ $contract verified successfully!"
  else
    echo "⚠️  $contract verification status: $message - $result"
  fi
done
