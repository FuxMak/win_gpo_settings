# Custom Ansible module - win_gpo_settings

These custom ansible module were written in order to solve specific problems in the automated deployments in either the development or production environments.

## Automatic Installation

If a module passed all checks and the official pull request has been accepted, it can be downloaded as part of a collection e.g. "community.windows" using `ansible-galaxy`

```bash
ansible-galaxy collection install community.windows
```

## Manual Installation

If a module is fully functional, but not yet qualified for an official pull request, the deployment must be done manually.

If a module is not yet fully qualified for an official pull request to the "ansible-galaxy", due to either missing code quality (ansible sanity checks), integration tests or a missing support for "check_mode", it must be deployed

Therefore a pull request could not be done up until now and the module needs to be deployed locally, using this procedure.

- Verify that the path is correct using the ansible-config dump

```bash
ansible-config dump | grep DEFAULT_MODULE_PATH
```

- Create the local module path for your user

```bash
mkdir -p "/home/$USER/.ansible/plugins/modules"
```

- Clone the git repository
- Copy the module to the local module path

```bash
cd /tmp
git clone "git@github.com:FuxMak/win_gpo_settings.git"
cp /tmp/win_gpo_settings "/home/$USER/.ansible/plugins/modules"
```

The asterisk needs to be outside the quotes, otherwise the `copy` command does not work with the wildcard.

## Contributions

Ansible (RedHat) really forces a strict development and testing procedure towards the community. Before and during the development of the module, please first of all take a look at the exisiting structure inside the repository and at the official development documentation.

- [Should you develop a module? - Ansible/RedHat](https://docs.ansible.com/ansible/latest/dev_guide/developing_modules.html)
- [General development procedure - Ansible/RedHat](https://docs.ansible.com/ansible/latest/dev_guide/developing_modules_general.html)
- [Integration tests - Ansible/RedHat](https://docs.ansible.com/ansible/latest/dev_guide/testing_integration.html#testing-integration)
