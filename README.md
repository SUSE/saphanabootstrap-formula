# SAP HANA replication bootstrap salt formula

Salt formula to bootstrap and manage a multi SAP HANA platform environment.

## Features

The formula provides the capability to create a multi node SAP HANA environment. Here some features:
- Install one or multiple SAP HANA instances (in one or multiple nodes)
- Setup a System replication configuration between two SAP HANA nodes
- Extract the required files from the provided `.tar`, `.sar`, `.exe` files
- Apply saptune to the nodes with the needed SAP notes
- Enable all of the pre-requirements to setup a HA cluster in top of SAP HANA system replication cluster
- Install and configure the [handb_exporter](https://github.com/SUSE/hanadb_exporter)

## Installation

The project can be installed in many ways, including but not limited to:

1. [RPM](#rpm)
2. [Manual clone](#manual-clone)

### RPM

On openSUSE or SUSE Linux Enterprise you can just use the `zypper` system package manager:
```shell
zypper install saphanabootstrap-formula
```

**Important!** This will install the formula in `/usr/share/salt-formulas/states/hana`. Make sure that `/usr/share/salt-formulas/states` entry is correctly configured in your salt minion configuration `file_roots` entry if the formula is used in a masterless mode.

You can find the latest development repositories at [SUSE's Open Build Service](https://build.opensuse.org/package/show/network:ha-clustering:sap-deployments:devel/saphanabootstrap-formula).

### Manual clone

```
git clone https://github.com/SUSE/saphanabootstrap-formula
cp -R cluster /srv/salt
```

**Important!** The formulas depends on [salt-shaptools](https://github.com/SUSE/salt-shaptools) package, so make sure it is installed properly if you follow the manual installation (the package can be installed as a RPM package too).

## Usage

To use the formula the `hana` entry must be included in the salt execution `top.sls` file. Here an example to execute the hana formula in all of the nodes:

```
# This file is /srv/salt/top.sls
base:
  '*':
    - hana
```

To configure the execution a pillar file is needed. Here an example of a pillar file for this formula: [pillar.example](https://github.com/SUSE/saphanabootstrap-formula/blob/master/pillar.example)
This file must be stored in `/srv/pillar` as `hana.sls` and the same folder must contain a `top.sls` to use it. For example:

```
# This file is /srv/pillar/top.sls
base:
  '*':
    - hana
```

**Important!** The hostnames and minion names of the hana nodes must match the output of the `hostname` command.


### Salt pillar encryption

Pillars are expected to contain private data such as user passwords required for the automated installation or other operations. Therefore, such pillar data need to be stored in an encrypted state, which can be decrypted during pillar compilation.

SaltStack GPG renderer provides a secure encryption/decryption of pillar data. The configuration of GPG keys and procedure for pillar encryption are desribed in the Saltstack documentation guide:

- [SaltStack pillar encryption](https://docs.saltstack.com/en/latest/topics/pillar/#pillar-encryption)

- [SALT GPG RENDERERS](https://docs.saltstack.com/en/latest/ref/renderers/all/salt.renderers.gpg.html)

**Note:**
- Only passwordless gpg keys are supported, and the already existing keys cannot be used.

- If a masterless approach is used (as in the current automated deployment) the gpg private key must be imported in all the nodes. This might require the copy/paste of the keys.

## OBS Packaging

The CI will automatically publish new releases to SUSE's Open Build Service every time a pull request is merged in the `master` branch. For that, update the new package version in [saphanabootstrap-formula.spec](https://github.com/SUSE/saphanabootstrap-formula/blob/master/saphanabootstrap-formula.spec) and
add the new changes in [saphanabootstrap-formula.changes](https://github.com/SUSE/saphanabootstrap-formula/blob/master/saphanabootstrap-formula.changes).

The new version will published at:
- https://build.opensuse.org/package/show/network:ha-clustering:sap-deployments:devel/saphanabootstrap-formula
- https://build.opensuse.org/package/show/openSUSE:Factory/saphanabootstrap-formula (only if the spec file version is increased)
