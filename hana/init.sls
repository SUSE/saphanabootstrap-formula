{% from "hana/map.jinja" import hana with context %}

include:
{% if hana.install_packages is sameas true %}
  - hana.packages
{% endif %}
  - hana.pre_validation
  - hana.install
  - hana.enable_primary
  - hana.enable_secondary
  - hana.enable_cost_optimized