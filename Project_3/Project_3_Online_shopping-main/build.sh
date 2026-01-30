#!/bin/bash

# Exit immediately if a command fails
set -e

# Get arguments from command line
IMAGE_NAME="$1"
IMAGE_TAG="$2"

# Default values if arguments are not provided
IMAGE_NAME=${IMAGE_NAME:-devops-build}
IMAGE_TAG=${IMAGE_TAG:-latest}

DOCKERFILE_PATH="Dockerfile"
BUILD_CONTEXT="."

echo "🚀 Building Docker image..."
echo "Image: ${IMAGE_NAME}:${IMAGE_TAG}"

docker build \
  -t "${IMAGE_NAME}:${IMAGE_TAG}" \
  -f "${DOCKERFILE_PATH}" \
  "${BUILD_CONTEXT}"

echo "✅ Docker image built successfully!"

