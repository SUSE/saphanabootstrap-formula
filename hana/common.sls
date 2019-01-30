#required packages to install SAP HANA, maybe they are already installed in the
#used SLES4SAP distros
numactl:
  pkg.installed

libltdl7:
  pkg.installed

# Temporary solution to import the needed packages
add-saphana-repo:
  pkgrepo.managed:
    - name: saphana
    - baseurl: https://download.opensuse.org/repositories/home:xarbulu:sap-deployment/SLE_12_SP4/
    - gpgautoimport: True

python-shaptools:
  pkg.installed:
    - fromrepo: saphana
    - require:
      - add-saphana-repo
