# EKS-Terraform-Jenkins

Infrastructure-as-Code project to provision an Amazon EKS (Elastic Kubernetes Service) cluster with Terraform, and deploy a sample NGINX workload via Kubernetes manifests. A Jenkins pipeline (Jenkinsfile) is provided to automate Terraform init/validate/plan/apply or destroy.

Last updated: 2025-09-13 19:45 (local)

## Repository structure
- terraform/ — Terraform modules and configuration for VPC and EKS
- manifests/ — Kubernetes Deployment and Service for NGINX
- jenkins/Jenkinsfile — Jenkins Declarative Pipeline to run Terraform stages
- installer.sh — Optional helper script (if used in your environment)

## Prerequisites
- AWS account with permissions to create VPC, EKS, IAM, and related resources
- AWS CLI configured (aws configure) and credentials available to Jenkins
- Terraform v1.x installed on the Jenkins agent (or environment where you run it)
- kubectl installed to interact with the cluster after creation
- Jenkins with Credentials set:
  - AWS_ACCESS_KEY_ID (Secret Text or username/password style)
  - AWS_SECRET_ACCESS_KEY (Secret Text)

Region defaults to us-east-1 in both Terraform provider and Jenkinsfile environment.

## Quick start (Terraform locally)
1. Navigate to terraform directory:
   - PowerShell: cd .\terraform
   - Bash: cd terraform
2. Initialize: terraform init
3. Validate: terraform validate
4. Plan: terraform plan
5. Apply: terraform apply -auto-approve

After Terraform completes, update your kubeconfig so kubectl can talk to the new EKS cluster:
- aws eks update-kubeconfig --name amonkincloud-cluster --region us-east-1

## Deploy the sample app
From the repository root or manifests directory:
- kubectl apply -f manifests/deployment.yml
- kubectl apply -f manifests/service.yml

The Service is of type LoadBalancer, exposing NGINX on port 80. Obtain the external IP/hostname:
- kubectl get svc nginx-service -n default

Note: The sample deployment is minimal. Review and adjust replicas, container images, and resource requests/limits for production.

## Jenkins pipeline
The provided jenkins/Jenkinsfile includes stages:
- Checkout SCM (main branch from GitHub)
- Initializing Terraform (terraform init)
- Validating Terraform (terraform validate)
- Previewing the infrastructure (terraform plan + input approval)
- Create/Destroy an EKS cluster (terraform $action --auto-approve)

Usage notes:
- Define a Jenkins String Parameter named action with value apply or destroy, or set environment to provide $action.
- Ensure AWS credentials are configured in Jenkins Credentials with IDs matching:
  - AWS_ACCESS_KEY_ID
  - AWS_SECRET_ACCESS_KEY
- Ensure the Jenkins agent has Terraform installed and a shell (the Jenkinsfile uses sh steps). If you run on a Windows agent, switch sh to powershell or bat commands.

## Configuration
Key settings are defined in terraform/provider.tf locals:
- region: us-east-1
- name: amonkincloud-cluster (EKS cluster and VPC name)
- VPC CIDR and subnets (public/private/intra)
- EKS node group in terraform/eks.tf uses SPOT t3.large with desired size 1

Adjust as needed before running terraform apply.

## Cleanup
To destroy the infrastructure:
- Locally: terraform destroy -auto-approve (in terraform directory)
- Jenkins: run the pipeline with action set to destroy

## Troubleshooting
- If kubectl cannot connect, verify your kubeconfig: aws eks update-kubeconfig --name amonkincloud-cluster --region us-east-1
- If Jenkins sh steps fail on Windows agents, convert steps to powershell/bat equivalents.
- Validate manifests before apply: kubectl apply --dry-run=client -f manifests/
