# Quick WireGuard Relay on AWS

This repository provides Terraform configurations to deploy a WireGuard VPN relay on Amazon Web Services (AWS). This setup allows you to route your VPN traffic through an EC2 instance, providing a fixed public IP address and potentially bypassing network restrictions.

## Features

*   Automated deployment of an EC2 instance.
*   Automated installation and configuration of WireGuard on the EC2 instance.
*   Secure management of SSH keys for EC2 access.
*   IAM policy for secure Terraform operations.

## Prerequisites

Before you begin, ensure you have the following installed:

*   **Terraform**: [Install Terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli)
*   **AWS CLI**: [Install AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
*   **AWS Account**: Configured with appropriate permissions.

## Setup

1.  **AWS Credentials**: Ensure your AWS CLI is configured with credentials that have permissions to create EC2 instances, IAM roles, and security groups. You can configure them using `aws configure`.

2.  **Terraform Initialization**: Navigate to the root of this repository and initialize Terraform:

    ```bash
    terraform init
    ```

3.  **Generate SSH Key**: A `.pem` file named `wireguard-relay.pem` is expected for SSH access to the EC2 instance. If you don't have one, you can generate a new key pair and place it in the root of this repository, or update `main.tf` to use an existing key pair.

    ```bash
    ssh-keygen -t ecdsa -b 521 -f wireguard-relay.pem
    chmod 400 wireguard-relay.pem
    ```

4.  **Deploy Infrastructure**: Apply the Terraform configuration to deploy the WireGuard relay.

    ```bash
    terraform plan

    terraform apply
    ```

    Review the plan and type `yes` to confirm the deployment.

## Usage

After successful deployment, Terraform will output the public IP address of your WireGuard relay. The `install_wireguard.sh` script handles the server-side configuration. You can then SSH in and configure your WireGuard client to connect to this relay.

If you have a static IP for your management computer, you can uncomment the "my_ip" section in variables.tf and in the ingress rules of main.tf to have a more secure enviroment.

## Files

*   `main.tf`: The main Terraform configuration file, defining the EC2 instance, security groups, and other AWS resources.
*   `variables.tf`: Defines input variables for the Terraform configuration, such as AWS region, instance type, etc.
*   `Terraform-WireGuard-Policy.awsiam.json`: Add this policy to AWS IAM and then assign it to a new user to grant necessary permissions that user for Terraform to manage the resources.
*   `install_wireguard.sh`: A shell script executed on the EC2 instance to install and configure WireGuard.
