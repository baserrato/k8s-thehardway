# Kubernetes the hard way

## Compute Resources
   Creation of Azure Resources using Terraform for the Infastructure
	
	- Uses Makefile to validate, build, and destroy resources created via Terraform
	- Variables are set via a `.tfvars` file to authenticate, and configure the resources

## CA and Generating TLS Certificates

	- Creates keys and certificates to be used by the workers(client) and controllers(server)
	- Created via Ansible
	- Makefile to run the playbooks and clean up configured files.

