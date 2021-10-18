{%- from "hana/map.jinja" import hana with context -%}
{% set host = grains['host'] %}

{% if hana.scale_out %}
{% set sr_hook_path = '/usr/share/SAPHanaSR-ScaleOut' %}
remove_SAPHanaSR:
  pkg.removed:
    - pkgs:
      - SAPHanaSR
      - SAPHanaSR-doc

install_SAPHanaSR_ScaleOut:
  pkg.installed:
    - pkgs:
      - SAPHanaSR-ScaleOut
      - SAPHanaSR-ScaleOut-doc
{% else %}
{% set sr_hook_path = '/usr/share/SAPHanaSR' %}
remove_SAPHanaSR_ScaleOut:
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

# Update /etc/sudoers to allow crm operations to the sidadm
{% set tmp_sudoers = '/tmp/sudoers' %}
{% set sudoers = '/etc/sudoers' %}

sudoers_backup_{{ sap_instance }}:
  file.copy:
    - name: {{ tmp_sudoers }}
    - source: {{ sudoers }}
    - unless: cat {{ sudoers }} | grep {{ node.sid.lower() }}adm

sudoers_append_{{ sap_instance }}:
  file.append:
    - name: {{ tmp_sudoers }}
    - text: |
        {%- if hana.scale_out %}
        # SAPHanaSR-ScaleOut needs for srHook
        Cmnd_Alias SOK   = /usr/sbin/crm_attribute -n hana_{{ node.sid.lower() }}_glob_srHook -v SOK   -t crm_config -s SAPHanaSR
        Cmnd_Alias SFAIL = /usr/sbin/crm_attribute -n hana_{{ node.sid.lower() }}_glob_srHook -v SFAIL -t crm_config -s SAPHanaSR
        {{ node.sid.lower() }}adm ALL=(ALL) NOPASSWD: SOK, SFAIL
        {%- else %}
        # SAPHanaSR needs for srHook
        {{ node.sid.lower() }}adm ALL=(ALL) NOPASSWD: /usr/sbin/crm_attribute -n hana_{{ node.sid.lower() }}_site_srHook_*
        {%- endif %}
    - require:
      - sudoers_backup_{{ sap_instance }}

sudoers_check_{{ sap_instance }}:
  cmd.run:
    - name: /usr/sbin/visudo -c -f {{ tmp_sudoers }}
    - require:
      - sudoers_append_{{ sap_instance }}

sudoers_edit_{{ sap_instance }}:
  file.copy:
    - name: {{ sudoers }}
    - source: {{ tmp_sudoers }}
    - force: true
    - require:
      - sudoers_check_{{ sap_instance }}

# Add SAPHANASR hook
# It would be better to get the text from /usr/share/SAPHanaSR/samples/global.ini

# only add hook and stop/start if hana was installed (not on scale-out standby/workers)
{% if node.install is defined %}
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
