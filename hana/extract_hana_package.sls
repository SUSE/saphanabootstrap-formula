{%- from "hana/map.jinja" import hana with context -%}

{%- if hana.hana_archive_file is defined %}
{% set hana_package = hana.hana_archive_file %}
{% set hana_extract_dir = hana.hana_extract_dir %}

setup_hana_extract_directory:
  file.directory:
    - name: {{ hana_extract_dir }}
    - mode: 755
    - makedirs: True

{%- if hana_package.endswith((".ZIP", ".zip", ".RAR", ".rar")) %}

extract_hana_archive:
  archive.extracted:
    - name: {{ hana_extract_dir }}
    - enforce_toplevel: False
    - source: {{ hana_package }}

{%- elif hana_package.endswith((".exe", ".EXE")) %}

{% set unrar_package = 'unrar_wrapper' if grains['osrelease_info'][0] == 15 else 'unrar' %}
install_unrar_package:
  pkg.installed:
    - name: {{ unrar_package }}

# unrar tool does not have the option to skip extracting top-level directory when using multipart exe archives#
extract_hana_multipart_archive:
  cmd.run:
    - name: unrar x {{ hana_package }}
    - cwd: {{ hana_extract_dir }}
    - require:
        - install_unrar_package

{%- elif hana_package.endswith((".sar", ".SAR")) and hana.sapcar_exe_file is defined %}

extract_hdbserver_sar_archive:
  sapcar.extracted:
    - name: {{ hana_package }}
    - sapcar_exe: {{ hana.sapcar_exe_file }}
    - output_dir: {{ hana_extract_dir }}
    - options: "-manifest SIGNATURE.SMF"

copy_signature_file_to_installer_dir:
  file.copy:
    - source: {{ hana_extract_dir }}/SIGNATURE.SMF
    - name: {{ hana_extract_dir }}/SAP_HANA_DATABASE/SIGNATURE.SMF
    - preserve: True
    - force: True
    - require:
        - extract_hdbserver_sar_archive

{%- endif %}
{%- endif %}
