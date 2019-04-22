# SAP HANA replication bootstrap salt formula

Salt formula for bootstrapping and managing SAP HANA platform and system
replication.

The main purpose of the formula is to deploy easily the SAP HANA environment and
its nodes, giving the option to set them as primary or secondary nodes using
system replication.

# Requirements

The saphanabootstrap-formula package requires **salt-call 2018.3.0 (Oxygen)** or
newer versions. This package is included in the **.spec** file, so it must
be available in currently added package repositories.

# How to use

## Manual installation

In order to use this formula some steps must be executed previously:

1. Install shaptools python library.

```bash
git clone https://github.com/SUSE/shaptools.git
cd shaptools
sudo python setup.py install
```

2. Copy the [salt-saphana](https://github.com/SUSE/salt-saphana) modules and states in our salt master.

```bash
git clone https://github.com/SUSE/salt-saphana.git
# Create /srv/salt/_modules and /srv/salt/_states if they don't exist
sudo cp salt-saphana/salt/modules/* /srv/salt/_modules
sudo cp salt-saphana/salt/states/* /srv/salt/_states
```

## Install (Suse distros)

The easiest way to install the formula in SUSE distributions is using a rpm package.
For that follow the next sequence to install all the dependencies (opensuse leap 15
is used in the example):

```bash
sudo zypper addrepo zypper addrepo https://download.opensuse.org/repositories/network:ha-clustering:Factory/openSUSE_Leap_15.0/network:ha-clustering:Factory.repo
sudo zypper ref
sudo zypper in saphanabootstrap-formula
```

To use the formula in Suse Manager:
```bash
sudo zypper in saphanabootstrap-formula-suma
```

Find the package in: [saphanabootstrap-formula](https://software.opensuse.org//download.html?project=network%3Aha-clustering%3AFactory&package=saphanabootstrap-formula)

## Usage
In order to use this formula, the pillar file usage is almost mandatory (there
is a defaults file, but pillar usage is recommended).
In the pillar file, each element after *nodes* entry will be a new SAP HANA
instance (PRD, QAS, etc). A machine might have more than one HANA instance with
different sid and instance numbers (one for production and other for testing,
for example). The current [pillar.example](pillar.example), deploys one PRD
instance in hana01 machine as a primary node, and two (PRD, QAS) instances in
the second, one of the as secondary.

The needed parameters for the states are described in [salt-saphana](https://github.com/SUSE/salt-saphana).

The example folders shows how a salt environment could be created to use the formula.
Run the **deploy.sh** script to copy this structure to the salt environment (**INFO**:
The script will overwrite any file with the same names).

```bash
cd saphanabootstap-formula/example
sudo ./deploy.sh
```

## Build
To build a new deliverable (rpm package) follow the next steps (Suse distros only):

```bash
cp -R saphanabootstrap-formula saphanabootstrap-formula-${version}
tar -zcvf saphanabootstrap-formula-${version}.tar.gz saphanabootstrap-formula-${version}
sudo cp saphanabootstrap-formula-${version}.tar.gz /usr/src/packages/SOURCES
sudo cp saphanabootstrap-formula-${version}/saphanabootstrap-formula.spec /usr/src/packages/SPECS/saphanabootstrap-formula-${version}.spec
cd /usr/src/packages/SPECS
sudo rpmbuild -ba saphanabootstrap-formula-${version}.spec
```
After that the package saphanabootstrap-formula-${version}-1.x86_64.rpm should
be placed in /usr/src/packages/RPMS/x86_64


To test the package:
```bash
cd /usr/src/packages/RPMS/x86_64
sudo rpm -iv saphanabootstrap-formula-${version}-1.x86_64.rpm
```

Or better:
```bash
cd /usr/src/packages/RPMS/x86_64
sudo zypper in saphanabootstrap-formula-${version}-1.x86_64.rpm
```
