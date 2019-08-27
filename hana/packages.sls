#required packages to install SAP HANA

{% if grains['os_family'] == 'Suse' %}
install-patterns-sap-hana:
  pkg.latest:
    - name: patterns-sap-hana
    - refresh: True
    - retry:
        attempts: 5
        interval: 15

{% else %}
install_required_packages:
  pkg.installed:
    - retry:
        attempts: 3
        interval: 15
    - pkgs:
      - libnuma1
      - libltdl7

{% endif %}

# Install shaptools depending on the os and python version
{% if grains['pythonversion'][0] == 2 %}
python-shaptools:
{% else %}
python3-shaptools:
{% endif %}
  pkg.installed:
    - retry:
        attempts: 3
        interval: 15
    - resolve_capabilities: true
