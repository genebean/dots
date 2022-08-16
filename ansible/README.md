# Ansible Bootstrapping

Temporary docs for Ansible as I work things out.

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
export PATH="$HOME/.local/bin:$PATH"
python3 -m pip install --user ansible ansible-lint
ansible-galaxy collection install jonellis.sudoers
ansible-galaxy install gantsign.oh-my-zsh
ansible-galaxy install jack1142.apt_signing_key
ansible-playbook -i ansible/ansible_hosts.yaml --ask-become-pass ansible/carbonbean.yaml --verbose
```
