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
    - retry:
        attempts: 3
        interval: 15

{% else %}
install_required_packages:
  pkg.installed:
    - pkgs:
      - libnuma1
      - libltdl7

{% endif %}

# Install shaptools depending on the os and python version
{% if grains['pythonversion'][0] == 2 %}
python2-shaptools:
{% else %}
python3-shaptools:
{% endif %}
  pkg.installed
