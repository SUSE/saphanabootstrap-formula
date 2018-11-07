{%- from "hana/map.jinja" import hana with context -%}
{% set host = grains['host'] %}

{%- from "hana/utils.sls" import path, user with context -%}

start-hana-instance:
  cmd.run:
    - name: {{ path }}/HDB start
    - runas: {{ user }}

{% if hana.primary.backup is defined and hana.primary.host == host %}
include:
  - .backup
#{% endif %}


enable-primary:
  cmd.run:
    - name: su -lc '{{ path }}/exe/hdbnsutil -sr_enable --name={{ hana.primary.name }}' {{ user }}
    - runas: root
    - require:
      - start-hana-instance
      {% if hana.primary.backup is defined and hana.primary.host == host %}
      - create-backup
      - copy-ssfs-data
      - copy-ssfs-key
      #{% endif %}

primary-enabled:
  cmd.run:
    - name: su -lc '{{ path }}/exe/hdbnsutil -sr_state | grep primary' {{ user }}
    - runas: root
    - require:
      - enable-primary
