# Ansible Bare Metal Provisioning

This project uses Ansible to provision a bare-metal (or VM) Ubuntu 24.04 system, following best practices for maintainability and testing.

---

## 📦 Requirements

Install the following tools:

- Python 3.10+ (with `venv`)
- Ansible 9.x+ (`pip install "ansible>=9,<10"`)
- Molecule (`pip install molecule[docker]`)
- Docker (for Molecule)
- Vagrant (for VM-based local testing)
- VirtualBox (if using Vagrant on Mac)
- SSH access to your target bare metal or remote server

---

## 🚀 Setup on macOS/Linux

```bash
make deps           # Setup Python virtualenv with Ansible
source .venv/bin/activate
make lint           # Lint the Ansible playbooks
```

---

## 🧪 Local Dev & Testing Options

### 1. Vagrant VM (Ubuntu 24.04)

```bash
make vagrant-up     # Boots VM and provisions it
```

### 2. Run against your own machine (bare metal Ubuntu)

```bash
make deploy-local   # Uses localhost with connection=local
```

### 3. Deploy to remote machine

Edit `inventory.ini` with your server’s info, then run:

```bash
make deploy-remote
```

---

## ✅ Role-Level Molecule Testing

Each role includes [Molecule](https://molecule.readthedocs.io/) tests using Docker and Ubuntu 24.04.

To test all roles:

```bash
make molecule-test
```

You can also test roles individually:

```bash
cd roles/webserver
molecule test
```

Each role includes:
- `converge.yml` to apply the role
- `verify.yml` to validate:
  - Nginx is installed and running
  - Promtail config exists
  - Users are created and sudoers files exist
  - Sysctl values are correctly applied

---

## 📂 Project Structure

```
.
├── site.yml                # Entrypoint playbook
├── roles/
│   ├── webserver/
│   ├── log_forwarder/
│   ├── user_management/
│   └── system_tuning/
├── group_vars/             # Per-group overrides
├── inventory.ini
├── Makefile                # Helper tasks
├── Vagrantfile
└── README.md
```

---

## 🧠 Best Practices Followed

✅ Role-based structure  
✅ Defaults in `defaults/main.yml`  
✅ Environment overrides in `group_vars/`  
✅ Tags for targeted execution (`--tags webserver`, etc.)  
✅ Molecule testing with Docker  
✅ Promtail & Nginx templating  
✅ Custom sysctl tuning  

---

Happy automating! 🛠️


---

### Re-run Ansible on Vagrant

If Vagrant is already running and you just want to re-apply your Ansible playbook:

```bash
make rerun-ansible
```


---

### Cleaning up Vagrant environment

If you're getting SSH fingerprint mismatch or host key verification errors:

```bash
make clean
```

This removes:
- The `.venv` environment
- Vagrant machine
- Old SSH known_hosts entries (`[127.0.0.1]:2222`, `[127.0.0.1]:50022`)


---

## 🛠️ Running Against a Remote Server

To provision a remote Ubuntu 24.04 bare metal server:

### 1. ✏️ Edit the `inventory.ini`

Replace with the IP or domain of your remote host:

```ini
[remote_servers]
baremetal-test ansible_host=<REMOTE_IP> ansible_user=root ansible_ssh_private_key_file=~/.ssh/id_rsa

[remote_servers:vars]
ansible_become=true
ansible_become_method=sudo
```

---

### 2. ✅ Install dependencies (one-time setup)

```bash
make deps
```

This sets up a Python virtual environment and installs all required Ansible collections and roles.

---

### 3. 🚀 Provision the remote machine

```bash
make provision-remote
```

This uses the `remote_servers` inventory group and provisions the remote host with:
- Nginx
- UFW firewall (ports 22, 80)
- Promtail (forwarding to Loki)
- User management (`devops`, `bob`)

---

### 4. 🧪 Optional: Lint check

```bash
make lint-all
```

Checks for Ansible and YAML best practices using `ansible-lint` and `yamllint`.

---

**Tested on:** Ubuntu 24.04  
**Idempotent:** ✅  
**SSH required:** Port 22 must be open on the remote machine

