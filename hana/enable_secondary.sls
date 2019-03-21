{%- from "hana/map.jinja" import hana with context -%}
{% set host = grains['host'] %}

{% for node in hana.nodes %}
{% if node.host == host and node.secondary is defined %}
include:
  - .primary_available
  - .copy_ssfs

{{  node.secondary.name }}:
  hana.sr_secondary_registered:
    - sid: {{  node.sid }}
    - inst: {{  node.instance }}
    - password: {{  node.password }}
    - remote_host: {{  node.secondary.remote_host }}
    - remote_instance: {{  node.secondary.remote_instance }}
    - replication_mode: {{  node.secondary.replication_mode }}
    - operation_mode: {{  node.secondary.operation_mode }}
    - require:
      - primary-available

{% endif %}
{% endfor %}
