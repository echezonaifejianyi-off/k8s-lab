This repo documents a 10-task Kubernetes sprint I ran as part of my DevOps internship at Ignite.dev. The goal was simple: go from zero Kubernetes knowledge to a fully automated, self-healing, observable application running in production on Hetzner Cloud.

By the end, a code push to main builds a Docker image, tags it with the git SHA, pushes it to Docker Hub, and rolls it out to the cluster automatically.

Stack

Cluster: k3s on Hetzner CX22 (Ubuntu 22.04)
Provisioning: Manual (Hetzner Console)
Configuration: Ansible
App: Go HTTP server
Registry: Docker Hub
Ingress: Traefik (k3s built-in)
Storage: local-path StorageClass (k3s built-in)
CI/CD: GitHub Actions
Observability: kubectl top, describe, logs, metrics-server (k3s built-in)


Repo Structure
ansible/

ansible.cfg — SSH connection settings
inventory.ini — Hetzner node address and credentials
install-k3s.yml — Task 1: installs k3s and verifies the node is Ready
kubectl-access.yml — Task 2: configures non-root kubectl access

app/

main.go — Go HTTP server with / and /healthz endpoints
Dockerfile — multi-stage build: compile on golang, run on alpine

manifests/

nginx-pod.yaml — Task 3: raw Pod, deliberately fragile
nginx-deployment.yaml — Task 4: 3-replica Deployment and ClusterIP Service
nginx-ingress.yaml — Task 5: Traefik Ingress routing myapp.local
nginx-config.yaml — Task 6: ConfigMap, Secret, and updated Deployment
nginx-storage.yaml — Task 7: PVC and Pod with persistent volume mount
myapp-deployment.yaml — Task 8: Go app Deployment, Service, and Ingress with probes

terraform/ec2/

main.tf, variables.tf, outputs.tf, terraform.tfvars — AWS EC2 provisioning used during initial setup before migrating to Hetzner

.github/workflows/

deploy.yml — Task 9: build, tag with git SHA, push to Docker Hub, deploy on push to main


How to Run
Prerequisites

Hetzner Cloud account with a CX22 server running Ubuntu 22.04
SSH key added to the server
Ansible installed on your control node (WSL Ubuntu recommended)
Docker Hub account
GitHub repository with the following secrets set:

DOCKER_USERNAME
DOCKER_PASSWORD
HETZNER_SSH_KEY



1. Configure inventory
Update ansible/inventory.ini with your server IP:
ini[k3s]
k3s-node ansible_host=<your-server-ip>

[k3s:vars]
ansible_user=root
ansible_ssh_private_key_file=~/.ssh/your-key.pem
ansible_ssh_common_args='-o StrictHostKeyChecking=no'
2. Install k3s
bash cd ansible
ansible-playbook -i inventory.ini install-k3s.yml
This installs k3s, starts the systemd service, and verifies the node is Ready.
3. Configure kubectl access
bash ansible-playbook -i inventory.ini kubectl-access.yml
This copies the kubeconfig to the root user's home directory and exports KUBECONFIG permanently.
4. Deploy the stack
bash scp -i ~/.ssh/your-key.pem manifests/*.yaml root@<your-server-ip>:~/
ssh -i ~/.ssh/your-key.pem root@<your-server-ip>
kubectl apply -f myapp-deployment.yaml
5. Add local DNS
bash echo "127.0.0.1 myapp.local" | sudo tee -a /etc/hosts
curl http://myapp.local
6. Trigger CI/CD
Push any change to main. GitHub Actions handles the rest.
bash git add .
git commit -m "your change"
git push
Watch the Actions tab. The pipeline builds, tags with the git SHA, pushes to Docker Hub, and rolls out to the cluster automatically.

Debugging Reference
Pod not starting: kubectl describe pod <name> - Events section at the bottom 
App crashed: kubectl logs <pod> --previousLast - lines before crash
High resource usage: kubectl top pods - CPU and memory per Pod
Image not found: kubectl describe pod <name> - ErrImagePull or ImagePullBackOff in Events
App running but broken: kubectl exec -it <pod> -- /bin/bash - Inspect from inside the container