{% from "hana/map.jinja" import cluster with context %}

include:
  - hana.packages
  - hana.pre_validation
  - hana.install
  - hana.enable_primary
  - hana.enable_secondary
