{% from "hana/map.jinja" import hana with context %}

include:
{% if hana.install_packages is sameas true %}
  - hana.packages
{% endif %}
  - hana.pre_validation
  - hana.saptune
  - hana.extract_hana_package
  - hana.install
  - hana.enable_primary
  - hana.enable_secondary
{% if hana.ha_enabled %}
  - hana.ha_cluster
{% endif %}
  - hana.exporter
