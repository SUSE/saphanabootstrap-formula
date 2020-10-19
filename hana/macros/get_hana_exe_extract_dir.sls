{% macro get_hana_exe_extract_dir(hana) -%}
{%- set hana_extract_dir = hana.hana_extract_dir %}
    {#- Below is temporary workaround to update the software installation path when using unrar for HANA multipart rar archive#}
    {#- TODO: Find better solution to set or detect the correct extraction path when extracting multipart rar archive#}
    {#- Below logic finds the extraction location based on name of multipart exe archive filename#}
    {%- if hana.hana_archive_file is defined and hana.hana_archive_file.endswith((".exe", ".EXE")) %}
    {%- set archive_base_name = salt['file.basename']( hana.hana_archive_file.split('.')[0]) %}
    {%- set archive_name = archive_base_name.split('_')[0] %}
    {%- set hana_extract_dir = hana_extract_dir| path_join(archive_name) %}
    {%- endif %}
{{- hana_extract_dir }}
{%- endmacro %}