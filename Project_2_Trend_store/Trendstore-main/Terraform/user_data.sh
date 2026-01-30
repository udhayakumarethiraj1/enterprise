#!/bin/bash
set -e

# Update system
apt-get update -y
apt-get upgrade -y

# Install basic packages
apt-get install -y \
  ca-certificates \
  curl \
  gnupg \
  lsb-release \
  software-properties-common \
  unzip \
  git

# --------------------
# Docker
# --------------------
curl -fsSL https://get.docker.com | bash
usermod -aG docker ubuntu
systemctl enable docker
systemctl start docker

# --------------------
# AWS CLI v2
# --------------------
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
./aws/install

# --------------------
# Terraform
# --------------------
curl -fsSL https://apt.releases.hashicorp.com/gpg | gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com jammy main" \
  > /etc/apt/sources.list.d/hashicorp.list

apt-get update -y
apt-get install terraform -y

# --------------------
# kubectl
# --------------------
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# --------------------
# eksctl
# --------------------
curl -sL "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_Linux_amd64.tar.gz" \
  | tar xz -C /tmp
mv /tmp/eksctl /usr/local/bin

# --------------------
# Jenkins
# --------------------
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io.key \
  | tee /usr/share/keyrings/jenkins-keyring.asc > /dev/null

echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
  https://pkg.jenkins.io/debian-stable binary/ \
  > /etc/apt/sources.list.d/jenkins.list

apt-get update -y
apt-get install -y openjdk-17-jdk jenkins

systemctl enable jenkins
systemctl start jenkins

