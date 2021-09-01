{%- from "hana/map.jinja" import hana with context -%}
{%- from 'hana/macros/get_hana_client_path.sls' import get_hana_client_path with context %}

{%- set pydbapi_output_dir = '/tmp/pydbapi' %}
# first element in nodes has to be the primary
{%- set node0 = hana.nodes[0] %}
{%- set node1 = hana.nodes[1] %}
{%- set hana_client_path = get_hana_client_path(hana, node0 ) %}

# if we have a replicated setup we only take exporter configuration from the primary
{% if node0.secondary is not defined %}
{% set primary = node0 %}
{% else %}
{% set primary = (hana.nodes|selectattr("host", "equalto", node0.secondary.remote_host)|selectattr("primary", "defined")|first) %}
{% endif %}
{% set exporter = primary.exporter|default(None) %}

{% if exporter is not none %}

{% set sap_instance_nr = '{:0>2}'.format(primary.instance) %}
{% set exporter_instance = '{}_HDB{}'.format(primary.sid.upper(), sap_instance_nr) %}

install_python_pip:
  pkg.installed:
    - name: python3-pip
    - retry:
        attempts: 3
        interval: 15
    - resolve_capabilities: true

extract_pydbapi_client:
  hana.pydbapi_extracted:
    - name: PYDBAPI.TGZ
    - software_folders: [{{ hana_client_path }}]
    - output_dir: {{ pydbapi_output_dir }}
    - hana_version: '20'
    - force: true

# pip.installed cannot manage file names with regular expressions
# TODO: Improve this to use pip.installed somehow
install_pydbapi_client:
  cmd.run:
    - name: /usr/bin/python3 -m pip install {{ pydbapi_output_dir }}/hdbcli-*.tar.gz
    - require:
      - install_python_pip
      - extract_pydbapi_client

prometheus-hanadb_exporter:
  pkg.installed:
  - retry:
      attempts: 3
      interval: 15
  - require:
      - install_pydbapi_client

{% endif %}

hanadb_exporter_configuration_{{ exporter_instance }}:
  file.managed:
    - source: salt://hana/templates/hanadb_exporter.j2
    - name: /usr/etc/hanadb_exporter/{{ exporter_instance }}.json
    - template: jinja
    - require:
      - prometheus-hanadb_exporter
    - context:
        exporter: {{ exporter|yaml }}
        sap_instance_nr: "{{ sap_instance_nr }}"
        exporter_instance: {{ exporter_instance }}

{% if hana.ha_enabled %}
{% set service_status = "disabled" %}
{% set service_enabled = False %}
{% else %}
{% set service_status = "running" %}
{% set service_enabled = True %}
{% endif %}

hanadb_exporter_service_{{ exporter_instance }}:
  service.{{ service_status }}:
    - name: prometheus-hanadb_exporter@{{ exporter_instance }}
    - enable: {{ service_enabled }}
    {% if service_enabled %}
    - watch:
      - file: hanadb_exporter_configuration_{{ exporter_instance }}
    {% endif %}

{% endif %}
