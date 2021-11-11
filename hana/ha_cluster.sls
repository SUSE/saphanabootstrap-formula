{%- from "hana/map.jinja" import hana with context -%}
{% set host = grains['host'] %}

{% if hana.scale_out %}
{% set sr_hook_path = '/usr/share/SAPHanaSR-ScaleOut' %}
{% set sr_hook_multi_target = sr_hook_path + '/SAPHanaSrMultiTarget.py' %}
{% set sr_hook = sr_hook_path + '/SAPHanaSR.py' %}
remove_SAPHanaSR:
  pkg.removed:
    - pkgs:
      - SAPHanaSR
      - SAPHanaSR-doc

install_SAPHanaSR:
  pkg.installed:
    - pkgs:
      - SAPHanaSR-ScaleOut
      - SAPHanaSR-ScaleOut-doc

{% else %}
{% set sr_hook_path = '/usr/share/SAPHanaSR' %}
{% set sr_hook_multi_target = sr_hook_path + '/SAPHanaSrMultiTarget.py' %}
{% set sr_hook = sr_hook_path + '/SAPHanaSR.py' %}
remove_SAPHanaSR:
  pkg.removed:
    - pkgs:
      - SAPHanaSR-ScaleOut
      - SAPHanaSR-ScaleOut-doc

install_SAPHanaSR:
  pkg.installed:
    - pkgs:
      - SAPHanaSR
      - SAPHanaSR-doc
{% endif %}

{% for node in hana.nodes if node.host == host %}

{% set instance = '{:0>2}'.format(node.instance) %}
{% set sap_instance = '{}_{}'.format(node.sid, instance) %}

# Update sudoers to allow crm operations to the sidadm
{% set tmp_sudoers = '/tmp/sudoers' %}
{% set sudoers = '/etc/sudoers.d/SAPHanaSR' %}

sudoers_create_{{ sap_instance }}:
  file.managed:
    - name: {{ tmp_sudoers }}
    - contents: |
        {%- if hana.scale_out %}
        # SAPHanaSR-ScaleOut needs for {{ sr_hook_multi_target }}
        {%- else %}
        # SAPHanaSR needs for {{ sr_hook }}
        {%- endif %}
        {{ node.sid.lower() }}adm ALL=(ALL) NOPASSWD: /usr/sbin/crm_attribute -n hana_{{ node.sid.lower() }}_site_srHook_*
        # be compatible with non-multi-target mode
        {{ node.sid.lower() }}adm ALL=(ALL) NOPASSWD: /usr/sbin/crm_attribute -n hana_{{ node.sid.lower() }}_*
    - require:
      - pkg: install_SAPHanaSR

sudoers_check_{{ sap_instance }}:
  cmd.run:
    - name: /usr/sbin/visudo -c -f {{ tmp_sudoers }}
    - require:
      - file: {{ tmp_sudoers }}

sudoers_edit_{{ sap_instance }}:
  file.copy:
    - name: {{ sudoers }}
    - source: {{ tmp_sudoers }}
    - force: true
    - require:
      - sudoers_check_{{ sap_instance }}

# remove old entries from /etc/sudoers (migration to new /etc/sudoers.d/SAPHanaSR file)
sudoers_remove_old_entries_{{ sap_instance }}_srHook:
  file.replace:
    - name: /etc/sudoers
    - pattern: '.*({{ node.sid.lower() }}(adm|_(glob|site)).*(SOK|srHook)|SAPHanaSR.*needs).*'
    - repl: ''

# Add SAPHANASR hook
# It would be better to get the text from /usr/share/SAPHanaSR/samples/global.ini

# only add hook and stop/start if hana was installed (not on scale-out standby/workers)
{% if node.install is defined %}
configure_ha_hook_{{ sap_instance }}_multi_target:
  ini.options_present:
    - name:  /hana/shared/{{ node.sid.upper() }}/global/hdb/custom/config/global.ini
    - separator: '='
    - strict: False # do not touch rest of file
    - sections:
        ha_dr_provider_SAPHanaSrMultiTarget:
          provider: 'SAPHanaSrMultiTarget'
          path: '{{ sr_hook_path }}'
          execution_order: '1'
        trace:
          ha_dr_saphanasrmultitarget: 'info'
    - require:
      - pkg: install_SAPHanaSR
    - onlyif:
      - test -f {{ sr_hook_multi_target }}

configure_ha_hook_{{ sap_instance }}:
  ini.options_present:
    - name:  /hana/shared/{{ node.sid.upper() }}/global/hdb/custom/config/global.ini
    - separator: '='
    - strict: False # do not touch rest of file
    - sections:
        ha_dr_provider_SAPHanaSR:
          provider: 'SAPHanaSR'
          path: '{{ sr_hook_path }}'
          execution_order: '1'
        trace:
          ha_dr_saphanasr: 'info'
    - require:
      - pkg: install_SAPHanaSR
    - unless:
      - test -f {{ sr_hook_multi_target }}

remove_wrong_ha_hook_{{ sap_instance }}_sections_multi_target:
  ini.sections_absent:
    - name:  /hana/shared/{{ node.sid.upper() }}/global/hdb/custom/config/global.ini
    - separator: '='
    - sections:
        ha_dr_provider_SAPHanaSR:
    - require:
      - pkg: install_SAPHanaSR
    - unless:
      - fun: file.file_exists
        path: sr_hook_multi_target

remove_wrong_ha_hook_{{ sap_instance }}_options_multi_target:
  ini.options_absent:
    - name:  /hana/shared/{{ node.sid.upper() }}/global/hdb/custom/config/global.ini
    - separator: '='
    - sections:
        trace:
          - ha_dr_saphanasr
    - require:
      - pkg: install_SAPHanaSR
    - onlyif:
      - test -f {{ sr_hook_multi_target }}

remove_wrong_ha_hook_{{ sap_instance }}_sections:
  ini.sections_absent:
    - name:  /hana/shared/{{ node.sid.upper() }}/global/hdb/custom/config/global.ini
    - separator: '='
    - sections:
        ha_dr_provider_SAPHanaSrMultiTarget:
    - require:
      - pkg: install_SAPHanaSR
    - unless:
      - test -f {{ sr_hook_multi_target }}

remove_wrong_ha_hook_{{ sap_instance }}_options:
  ini.options_absent:
    - name:  /hana/shared/{{ node.sid.upper() }}/global/hdb/custom/config/global.ini
    - separator: '='
    - sections:
        trace:
          - ha_dr_saphanasrmultitarget
    - require:
      - pkg: install_SAPHanaSR
    - onlyif:
      - fun: file.file_exists
        path: sr_hook_multi_target

# Configure system replication operation mode in the primary site
{% for secondary_node in hana.nodes if node.primary is defined and secondary_node.secondary is defined and secondary_node.secondary.remote_host == host %}
configure_replication_{{ sap_instance }}:
  ini.options_present:
    - name:  /hana/shared/{{ node.sid.upper() }}/global/hdb/custom/config/global.ini
    - separator: '='
    - strict: False # do not touch rest of file
    - sections:
        system_replication:
          operation_mode: '{{ secondary_node.secondary.operation_mode }}'
{% endfor %}

# Stop SAP Hana
stop_hana_{{ sap_instance }}:
  module.run:
    - hana.stop:
      - sid: {{ node.sid }}
      - inst: {{ node.instance }}
      - password: {{ node.password }}
    - require:
      - hana_install_{{ node.host+node.sid }}
    - onchanges:
      - ini: /hana/shared/{{ node.sid.upper() }}/global/hdb/custom/config/global.ini

# Start SAP Hana
start_hana_{{ sap_instance }}:
  module.run:
    - hana.start:
      - sid: {{ node.sid }}
      - inst: {{ node.instance }}
      - password: {{ node.password }}
    - require:
      - hana_install_{{ node.host+node.sid }}
{%- endif %}

{% endfor %}
