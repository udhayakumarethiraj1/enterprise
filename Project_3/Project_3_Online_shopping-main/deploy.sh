#!/bin/bash
set -e

# ===== ARGUMENTS FROM JENKINS =====
IMAGE_NAME="$1"
IMAGE_TAG="$2"
BRANCH_NAME="$3"   # Pass branch name from Jenkins

if [ -z "$IMAGE_NAME" ] || [ -z "$IMAGE_TAG" ] || [ -z "$BRANCH_NAME" ]; then
  echo "❌ IMAGE_NAME, IMAGE_TAG and BRANCH_NAME are required"
  exit 1
fi

# ===== CONFIGURE PORT & CONTAINER NAME =====
if [ "$BRANCH_NAME" == "dev" ]; then
  PORT_MAPPING="8080:80"
elif [ "$BRANCH_NAME" == "main" ]; then
  PORT_MAPPING="80:80"
else
  echo "❌ Unsupported branch: $BRANCH_NAME"
  exit 1
fi

CONTAINER_NAME="devops-build-${BRANCH_NAME}"

# Convert image name to a safe filename
SAFE_IMAGE_NAME=$(echo "$IMAGE_NAME" | tr '/' '_')
IMAGE_TAR="${SAFE_IMAGE_NAME}.tar"

# ===== REMOTE CONFIG =====
REMOTE_USER="ubuntu"
REMOTE_HOST="172.31.27.2"
REMOTE_DIR="/home/ubuntu/project_3/${BRANCH_NAME}"
COMPOSE_FILE="docker-compose.yml"

# ===== CHECK IMAGE =====
echo "🔍 Checking local Docker image..."
docker image inspect ${IMAGE_NAME}:${IMAGE_TAG} > /dev/null 2>&1 \
  || { echo "❌ Image not found locally"; exit 1; }

# ===== SAVE IMAGE =====
echo "📦 Saving Docker image..."
docker save ${IMAGE_NAME}:${IMAGE_TAG} -o ${IMAGE_TAR}

# ===== COPY FILES =====
echo "📤 Copying files to remote server..."
ssh ${REMOTE_USER}@${REMOTE_HOST} "mkdir -p ${REMOTE_DIR}"
scp ${IMAGE_TAR} ${COMPOSE_FILE} ${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_DIR}

# ===== DEPLOY REMOTELY =====
echo "🚀 Deploying on remote server..."
ssh ${REMOTE_USER}@${REMOTE_HOST} << EOF
  set -e

  echo "📁 Ensuring remote directory exists..."
  mkdir -p ${REMOTE_DIR}
  cd ${REMOTE_DIR}

  echo "📥 Loading Docker image..."
  docker load -i ${IMAGE_TAR}

  echo "▶️ Exporting variables for docker-compose..."
  export IMAGE_NAME=${IMAGE_NAME}
  export IMAGE_TAG=${IMAGE_TAG}
  export BRANCH_NAME=${BRANCH_NAME} 
  export PORT_MAPPING=${PORT_MAPPING}

  echo "🛑 Stopping existing container (if any)..."
  IMAGE_NAME=${IMAGE_NAME} IMAGE_TAG=${IMAGE_TAG} BRANCH_NAME=${BRANCH_NAME} PORT_MAPPING=${PORT_MAPPING} \
  docker compose -p ${BRANCH_NAME} down || true

  echo "▶️ Exporting variables for docker-compose..."
  export IMAGE_NAME=${IMAGE_NAME}
  export IMAGE_TAG=${IMAGE_TAG}
  export BRANCH_NAME=${BRANCH_NAME}
  export PORT_MAPPING=${PORT_MAPPING}

  echo "▶️ Starting container with docker-compose..."
  # Export variables so docker-compose can use them
  IMAGE_NAME=${IMAGE_NAME} IMAGE_TAG=${IMAGE_TAG} BRANCH_NAME=${BRANCH_NAME} PORT_MAPPING=${PORT_MAPPING} \
  docker compose -p ${BRANCH_NAME} up -d

  echo "📦 Running containers:"
  docker ps | grep ${CONTAINER_NAME} || true

  echo "🧹 Removing image tar after load..."
  rm -f ${IMAGE_TAR}

EOF

# ===== CLEANUP =====
rm -f ${IMAGE_TAR}

echo "🎉 Deployment successful!"

