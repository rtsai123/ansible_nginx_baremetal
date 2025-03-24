# Ansible Bare Metal Provisioning

This project uses Ansible to provision a bare-metal (or VM) Ubuntu 24.04 system, following best practices for maintainability and testing.

---

## ⚙️ Prerequisites

- Python 3.10+
- Ansible 9+
- `make` utility
- Access to a remote Ubuntu 24.04 bare metal machine
- SSH access (either via key or password)

### Optional for local development/testing:
- macOS (tested)
- VirtualBox
- Vagrant
- Docker (for Molecule role tests)

---

## 🏗️ Setup Instructions

Install dependencies and set up Python virtual environment:

```bash
make deps
```

---

## 🔧 Configuration Overrides

Customize global variables in `group_vars/all.yml`.

**Important: Update your Loki endpoint URL here** so Promtail knows where to send logs:

```yaml
log_forwarding:
  loki_url: "http://your-loki-instance:3100/loki/api/v1/push"
```

Other tuning parameters (like `nginx` port, worker processes, rlimits, log format) are also configurable in this file.

---

## 🚀 Running Against a Remote Server

Update the `inventory.ini` file for your server:

### Option 1: Using SSH key

```ini
[remote_servers_key]
myserver ansible_host=1.2.3.4 ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/id_rsa
```

Then run the provisioning playbook:

```bash
make provision-remote-key
```

### Option 2: Using password-based SSH

```ini
[remote_servers_pwd]
myserver ansible_host=1.2.3.4 ansible_user=ubuntu ansible_ssh_pass=yourpassword ansible_become_pass=yourpassword
```

Then run the provisioning playbook:

```bash
make provision-remote-pwd
```

---

## 📁 Role Breakdown

| Role             | Description |
|------------------|-------------|
| `system`         | Applies kernel sysctl tuning and system limits |
| `webserver`      | Installs, configures, and tunes Nginx |
| `firewall`       | Configures UFW for HTTP and SSH |
| `log_forwarding` | Installs and configures Promtail for Loki |
| `user_management`| Creates and configures users `devops` and `bob` |

---

## 🧪 Local Testing (Optional)

### Vagrant (Local Bare Metal Simulation)

```bash
make dev-rebuild   # Destroys and recreates the Vagrant VM
make provision     # Runs Ansible against the Vagrant box
```

⚠️ **Note**: Local Vagrant testing has only been verified on **macOS (Intel)** with **VirtualBox**. Apple Silicon (M1/M2) or non-macOS systems may require `Vagrantfile` modifications.

---

## 🧪 Molecule + Linting (Optional)

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
ansible_nginx_baremetal/
├── Makefile
├── README.md
├── ansible.cfg
├── inventory.ini
├── group_vars/
│   └── all.yml                 # Global variable overrides (e.g. Loki URL)
├── roles/
│   ├── firewall/
│   │   ├── defaults/
│   │   ├── handlers/
│   │   ├── meta/
│   │   ├── tasks/
│   │   ├── templates/
│   │   └── molecule/
│   ├── log_forwarding/
│   │   ├── defaults/
│   │   ├── handlers/
│   │   ├── meta/
│   │   ├── tasks/
│   │   ├── templates/
│   │   └── molecule/
│   ├── system/
│   │   ├── defaults/
│   │   ├── handlers/
│   │   ├── meta/
│   │   ├── tasks/
│   │   └── molecule/
│   ├── user_management/
│   │   ├── defaults/
│   │   ├── handlers/
│   │   ├── meta/
│   │   ├── tasks/
│   │   └── molecule/
│   └── webserver/
│       ├── defaults/
│       ├── handlers/
│       ├── meta/
│       ├── tasks/
│       ├── templates/
│       └── molecule/
├── site.yml                    # Main playbook entry point
└── Vagrantfile                 # For optional local testing (macOS/VirtualBox)

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

## 🙏 Thank You
Thanks again for the opportunity — it was a pleasure working on this take-home!
