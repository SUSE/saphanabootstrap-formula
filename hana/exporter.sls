{%- from "hana/map.jinja" import hana with context -%}
{% set host = grains['host'] %}

{% for node in hana.nodes if node.host == host and node.exporter is defined %}

{% set instance = '{:0>2}'.format(node.instance) %}
{% set daemon_instance = '{}_{}'.format(node.sid, instance) %}
{% set config_file = '/etc/hanadb_exporter/{}.json'.format(daemon_instance) %}

{% if loop.first %}
prometheus-hanadb_exporter:
  pkg.installed:
  - retry:
      attempts: 3
      interval: 15

python3-PyHDB:
  pkg.installed:
  - retry:
      attempts: 3
      interval: 15
{% endif %}

configure_exporter_logging_{{ daemon_instance }}:
  file.managed:
    - name: /etc/hanadb_exporter/logging_config.ini
    - source: /usr/etc/hanadb_exporter/logging_config.ini
    - require:
      - prometheus-hanadb_exporter

configure_exporter_metrics_{{ daemon_instance }}:
  file.managed:
    - name: /etc/hanadb_exporter/metrics.json
    - source: /usr/etc/hanadb_exporter/metrics.json
    - require:
      - prometheus-hanadb_exporter

configure_exporter_{{ daemon_instance }}:
  file.managed:
    - source: salt://hana/templates/hanadb_exporter.j2
    - name: {{ config_file }}
    - template: jinja
    - require:
      - prometheus-hanadb_exporter
    - context: # set up context for template hanadb_exporter.j2
        sid: {{ node.sid }}

start_exporter_{{ daemon_instance }}:
  service.running:
    - name: prometheus-hanadb_exporter@{{ daemon_instance }}
    - enable: True
    - reload: True
    - require:
        - configure_exporter_{{ daemon_instance }}

{% endfor %}
