{% from "hana/map.jinja" import hana with context %}
{% set host = grains['host'] %}

{% if hana.primary.host == host %}

include:
  - .enable_primary

{% else %}

include:
  - .enable_secondary

{% endif %}
