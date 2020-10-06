{%- from "hana/map.jinja" import hana with context -%}

{% set pydbapi_output_dir = '/tmp/pydbapi' %}
{% set hana_extract_dir = hana.hana_extract_dir %}

# Below is temporary workaround to update the software path when using unrar for HANA multipart rar archive
# TODO: Find better solution to set or detect the correct extraction path when extracting multipart rar archive
# Below logic finds the extraction location based on name of multipart exe archive filename
{%- if hana.hana_archive_file is defined and hana.hana_archive_file.endswith((".exe", ".EXE")) %}
{% set archive_base_name = salt['file.basename']( hana.hana_archive_file.split('.')[0]) %}
{% set archive_name = archive_base_name.split('_')[0] %}
{% set hana_extract_dir = hana_extract_dir| path_join(archive_name) %}
{% endif %}

{% for node in hana.nodes if node.host == grains['host'] %}

# if we have a replicated setup we only take exporter configuration from the primary
{% if node.secondary is not defined %}
{% set exporter = node.exporter|default(None) %}
{% else %}
{% set primary = (hana.nodes|selectattr("host", "equalto", node.secondary.remote_host)|selectattr("primary", "defined")|first) %}
{% set exporter = primary.exporter|default(None) %}
{% endif %}

{% if exporter is not none %}

{% set sap_instance_nr = '{:0>2}'.format(node.instance) %}
{% set exporter_instance = '{}_HDB{}'.format(node.sid.upper(), sap_instance_nr) %}

{% if loop.first %}
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
    - software_folders: [{{ exporter.hana_client_path|default(node.install.software_path)|default(hana.software_path)|default(hana_extract_dir) }}]
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
    - reload: True
    - require:
        - hanadb_exporter_configuration_{{ exporter_instance }}

{% endif %}
{% endfor %}
