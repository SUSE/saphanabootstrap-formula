{%- from "hana/map.jinja" import hana with context -%}
{% set host = grains['host'] %}

{% for node in hana.nodes %}
{% if node.host == host and node.exporter is defined %}

{% set instance = '{:0>2}'.format(node.instance) %}
{% set daemon_instance = '{}_{}'.format(node.sid, instance) %}
{% set config_file = '/etc/hanadb_exporter/{}.json'.format(daemon_instance) %}

hanadb_exporter:
  pkg.installed:
  - retry:
      attempts: 3
      interval: 15

python3-PyHDB:
  pkg.installed:
  - retry:
      attempts: 3
      interval: 15

configure_exporter:
  file.managed:
    - source: salt://hana/templates/hanadb_exporter.j2
    - name: {{ config_file }}
    - template: jinja
    - require:
      - hanadb_exporter
      - python3-PyHDB

start_exporter:
  service.running:
    - name: hanadb_exporter@{{ daemon_instance }}
    - enable: True
    - reload: True
    - require:
        - configure_exporter

{% endif %}
{% endfor %}
