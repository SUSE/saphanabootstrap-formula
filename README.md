# SAP HANA replication bootstrap salt formula

Salt formula for bootstrapping and managing SAP HANA platform and system
replication.

The main purpose of the formula is to deploy easily the SAP HANA environment and
its nodes, giving the option to set them as primary or secondary nodes using
system replication.

# How to use

## Prerequisities

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
