#!/bin/bash

set -e

echo "🚀 Setting up Conda environment for Slither..."

# Name of the Conda environment
ENV_NAME="slither-env"

# Create Conda environment with Python 3.11 (or adjust if you want)
echo "✅ Creating conda environment: $ENV_NAME"
conda create -y -n "$ENV_NAME" python=3.11

# Activate the new environment
echo "✅ Activating $ENV_NAME"
# For non-interactive activation in a script
eval "$(conda shell.bash hook)"
conda activate "$ENV_NAME"

# Install slither
echo "✅ Installing Slither..."
pip install slither-analyzer

# Check that Slither is installed
echo "✅ Slither version:"
slither --version

echo "🎉 Slither is installed in Conda env '$ENV_NAME'."
echo "👉 To activate later, run: conda activate $ENV_NAME"


