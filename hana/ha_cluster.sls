{%- from "hana/map.jinja" import hana with context -%}
{% set host = grains['host'] %}

{% for node in hana.nodes if node.host == host %}

{% set instance = '{:0>2}'.format(node.instance) %}
{% set sap_instance = '{}_{}'.format(node.sid, instance) %}

# Stop SAP HanaError
stop_hana_{{ sap_instance }}:
  module.run:
    - hana.stop:
      - sid: {{ node.sid }}
      - inst: {{ node.instance }}
      - password: {{ node.password }}

# Add SAPHANASR hook
# It would be better to get the text from /usr/share/SAPHanaSR/samples/global.ini
configure_ha_hook_{{ sap_instance }}:
  file.append:
    - name:  /hana/shared/{{ node.sid.upper() }}/global/hdb/custom/config/global.ini
    - text: |

        [ha_dr_provider_SAPHanaSR]
        provider = SAPHanaSR
        path = /usr/share/SAPHanaSR
        execution_order = 1

        [trace]
        ha_dr_saphanasr = info
    - require:
      - stop_hana_{{ sap_instance }}

# Configure system replication operation mode in the primary site
{% for secondary_node in hana.nodes if node.primary is defined and secondary_node.secondary is defined and secondary_node.secondary.remote_host == host %}
configure_replication_{{ sap_instance }}:
  file.line:
    - name:  /hana/shared/{{ node.sid.upper() }}/global/hdb/custom/config/global.ini
    - content: operation_mode = {{ secondary_node.secondary.operation_mode }}
    - mode: ensure
    - after: \[system_replication\]
    - require:
      - stop_hana_{{ sap_instance }}
{% endfor %}

# Update /etc/sudoers to allow crm operations to the sidadm
{% set tmp_sudoers = '/tmp/sudoers' %}
{% set sudoers = '/etc/sudoers' %}

sudoers_backup_{{ sap_instance }}:
  file.copy:
    - name: {{ tmp_sudoers }}
    - source: {{ sudoers }}
    - unless: cat {{ sudoers }} | grep {{ node.sid }}adm

sudoers_append_{{ sap_instance }}:
  file.append:
    - name: {{ tmp_sudoers }}
    - text: |
        {{ node.sid }}adm ALL=(ALL) NOPASSWD: /usr/sbin/crm_attribute -n hana_{{ node.sid }}_site_srHook_*
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
      - stop_hana_{{ sap_instance }}

# Stop SAP HanaError
start_hana_{{ sap_instance }}:
  module.run:
    - hana.start:
      - sid: {{ node.sid }}
      - inst: {{ node.instance }}
      - password: {{ node.password }}
    - require:
      - stop_hana_{{ sap_instance }}

{% endfor %}
