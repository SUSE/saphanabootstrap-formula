#required packages to install SAP HANA

{% set pattern_available = 1 %}
{% if grains['os_family'] == 'Suse' %}
{% set pattern_available = salt['cmd.retcode']('zypper search patterns-sap-hana') %}
{% endif %}

{% if pattern_available == 0 %}
{% set repo = salt['pkg.info_available']('patterns-sap-hana')['patterns-sap-hana']['repository'] %}
patterns-sap-hana:
  pkg.installed:
    - fromrepo: {{ repo }}

{% else %}
install_required_packages:
  pkg.installed:
    - pkgs:
      - numactl
      - libltdl7

{% endif %}

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
