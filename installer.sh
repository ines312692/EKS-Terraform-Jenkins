#!/bin/bash
# Java installation for jenkins

sudo apt update
sudo apt install openjdk-11-jre -y

# Jenkins installation 
curl -fsSL https://pkg.jenkins.io/debian/jenkins.io-2023.key | sudo tee \
  /usr/share/keyrings/jenkins-keyring.asc > /dev/null
echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
  https://pkg.jenkins.io/debian binary/ | sudo tee \
  /etc/apt/sources.list.d/jenkins.list > /dev/null
sudo apt-get update
sudo apt-get install jenkins -y

# Terraform Installation

sudo apt-get update && sudo apt-get install -y gnupg software-properties-common
wget -O- https://apt.releases.hashicorp.com/gpg | \
gpg --dearmor | \
sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg
gpg --no-default-keyring \
--keyring /usr/share/keyrings/hashicorp-archive-keyring.gpg \
--fingerprint
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update
sudo apt-get install terraform -y

# Installing kubernetes

curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl.sha256"
echo "$(cat kubectl.sha256)  kubectl" | sha256sum --check
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl 

# Install AWS CLI 
sudo apt install unzip 
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install




#!/bin/bash

# installer.sh - Script d'installation et de déploiement pour EKS-Terraform-Jenkins
# Compatible avec AWS Academy Labs

set -e

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Variables
CLUSTER_NAME="inescloud-cluster"
REGION="us-east-1"
GITHUB_REPO="https://github.com/ines312692/EKS-Terraform-Jenkins.git"

# Fonctions utilitaires
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Vérification des prérequis
check_prerequisites() {
    log_info "Vérification des prérequis..."

    # Vérifier AWS CLI
    if ! command -v aws &> /dev/null; then
        log_error "AWS CLI n'est pas installé. Veuillez l'installer d'abord."
        exit 1
    fi

    # Vérifier Terraform
    if ! command -v terraform &> /dev/null; then
        log_error "Terraform n'est pas installé. Veuillez l'installer d'abord."
        exit 1
    fi

    # Vérifier kubectl
    if ! command -v kubectl &> /dev/null; then
        log_error "kubectl n'est pas installé. Veuillez l'installer d'abord."
        exit 1
    fi

    # Vérifier git
    if ! command -v git &> /dev/null; then
        log_error "Git n'est pas installé. Veuillez l'installer d'abord."
        exit 1
    fi

    log_success "Tous les prérequis sont installés"
}

# Vérifier la configuration AWS
check_aws_config() {
    log_info "Vérification de la configuration AWS..."

    if ! aws sts get-caller-identity &> /dev/null; then
        log_error "AWS n'est pas configuré ou les credentials sont invalides"
        log_info "Configurez AWS avec: aws configure"
        exit 1
    fi

    # Afficher les informations de l'utilisateur
    local identity=$(aws sts get-caller-identity)
    log_success "AWS configuré correctement"
    echo "$identity" | jq '.'

    # Vérifier la région
    local current_region=$(aws configure get region)
    if [ "$current_region" != "$REGION" ]; then
        log_warning "Région actuelle: $current_region, région requise: $REGION"
        log_info "Configuration de la région $REGION..."
        aws configure set region $REGION
    fi
}

# Cloner ou mettre à jour le repository
setup_repository() {
    log_info "Configuration du repository..."

    if [ -d "EKS-Terraform-Jenkins" ]; then
        log_info "Repository existant trouvé, mise à jour..."
        cd EKS-Terraform-Jenkins
        git pull origin main
    else
        log_info "Clonage du repository..."
        git clone $GITHUB_REPO
        cd EKS-Terraform-Jenkins
    fi

    log_success "Repository configuré"
}

# Déployer l'infrastructure avec Terraform
deploy_infrastructure() {
    log_info "Déploiement de l'infrastructure avec Terraform..."

    cd terraform

    # Initialisation
    log_info "Initialisation de Terraform..."
    terraform init

    # Validation
    log_info "Validation de la configuration..."
    terraform validate

    # Planification
    log_info "Planification du déploiement..."
    terraform plan -out=tfplan

    # Demander confirmation
    read -p "Voulez-vous appliquer ce plan? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        log_info "Application