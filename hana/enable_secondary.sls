{%- from "hana/map.jinja" import hana with context -%}
{% set host = grains['host'] %}

{% for node in hana.nodes if node.host == host and node.secondary is defined %}

# The primary password is retrieved in this order
# 1. If the primary node is defined in the pillar, primary password will be used
# 2. If secondary.primary_pass is defined this password will be used
# 3. The secondary machine password will be used
{% set password = {} %}

{% for prim_node in hana.nodes if node.secondary.remote_host == prim_node.host and prim_node.primary is defined %}
{% do password.update({'primary': prim_node.password }) %}
{% endfor %}

{% if password.primary is not defined and node.secondary.primary_password is defined %}
{% do password.update({'primary': node.secondary.primary_password }) %}
{% elif password.primary is not defined %}
{% do password.update({'primary': node.password }) %}
{% endif %}

{{ node.secondary.name }}:
  hana.sr_secondary_registered:
    - sid: {{ node.sid }}
    - inst: {{ node.instance }}
    - password: {{ node.password }}
    - remote_host: {{ node.secondary.remote_host }}
    - remote_instance: {{ node.secondary.remote_instance }}
    - replication_mode: {{ node.secondary.replication_mode }}
    - operation_mode: {{ node.secondary.operation_mode }}
    - timeout: {{ node.secondary.primary_timeout|default(100) }}
    - interval: {{ node.secondary.interval|default(10) }}
    - primary_pass: {{ password.primary }}
    - require:
      - hana_install_{{ node.host+node.sid }}

{% endfor %}
