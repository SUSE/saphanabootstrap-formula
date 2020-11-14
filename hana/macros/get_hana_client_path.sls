{% macro get_hana_client_path(hana) -%}
{%- from 'hana/macros/get_hana_exe_extract_dir.sls' import get_hana_exe_extract_dir with context %}
    {#- If hana archive used for installation is sar format, it will not contain the hana client, so we need to provide a hana client #}
    {#- One of the following paths is used for hana client based on pillar entries: 1. hana_client_software_path 2. hana_client_extract_dir 3. hana_extract_dir #}
    {%- if hana.hana_client_software_path is defined %}
    {%- set hana_client_path = hana.hana_client_software_path %}
    {%- elif hana.hana_client_archive_file is defined and hana.hana_archive_file is defined and hana.hana_archive_file.endswith((".sar", ".SAR")) %}
    {%- set hana_client_path = hana.hana_client_extract_dir %}
    {%- else %}
    {%- set hana_client_path = get_hana_exe_extract_dir(hana) %}
    {%- endif %}
{{- hana_client_path }}
{%- endmacro %}