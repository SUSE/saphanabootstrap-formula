{%- from "hana/map.jinja" import hana with context -%}
{% set host = grains['host'] %}

{% if hana.scale_out %}
{% set hook_path = '/usr/share/SAPHanaSR-ScaleOut' %}
{% set sr_hook_multi_target = hook_path + '/SAPHanaSrMultiTarget.py' %}
{% set sr_hook = hook_path + '/SAPHanaSR.py' %}
{% set sustkover_hook = hook_path + '/susTkOver.py' %}
{% set suschksrv_hook = hook_path + '/susChkSrv.py' %}

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
{% set hook_path = '/usr/share/SAPHanaSR' %}
{% set sr_hook_multi_target = hook_path + '/SAPHanaSrMultiTarget.py' %}
{% set sr_hook = hook_path + '/SAPHanaSR.py' %}
{% set sustkover_hook = hook_path + '/susTkOver.py' %}
{% set suschksrv_hook = hook_path + '/susChkSrv.py' %}

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

# get HANA sites
{% set sites = {} %}
{% for node in hana.nodes %}
{% if node.primary is defined %}
{% do sites.update({'a': node.primary.name}) %}
{% elif node.secondary is defined %}
{% do sites.update({'b': node.secondary.name}) %}
{% endif %}
{% endfor %}

{% for node in hana.nodes if node.host == host %}

{% set instance = '{:0>2}'.format(node.instance) %}
{% set sap_instance = '{}_{}'.format(node.sid, instance) %}

# Update sudoers to allow crm operations to the sidadm
{% set sudoers = '/etc/sudoers.d/SAPHanaSR' %}

sudoers_create_{{ sap_instance }}:
  file.managed:
    - source: salt://hana/templates/ha_cluster_sudoers.j2
    - name: {{ sudoers }}
    - template: jinja
    - user: root
    - group: root
    - mode: 0440
    - check_cmd: /usr/sbin/visudo -c -f
    - require:
      - pkg: install_SAPHanaSR
    - context:
        sid: {{ node.sid }}
        sites: {{ sites }}
        sr_hook: {{ sr_hook }}
        sr_hook_multi_target: {{ sr_hook_multi_target }}
        sr_hook_string: __slot__:salt:file.grep({{ sr_hook }}, "^srHookGen = ").stdout
        sustkover_hook: {{ sustkover_hook }}
        suschksrv_hook: {{ suschksrv_hook }}

# remove old entries from /etc/sudoers (migration to new /etc/sudoers.d/SAPHanaSR file)
sudoers_remove_old_entries_{{ sap_instance }}_srHook:
  file.replace:
    - name: /etc/sudoers
    - pattern: '.*({{ node.sid.lower() }}(adm|_(glob|site)).*(SOK|srHook)|SAPHanaSR.*needs).*'
    - repl: ''

# Add SAPHANASR hook

# Only add hook if hana was installed (not on scale-out standby/workers). A restart is needed as secondary cannot register a new hook without this (e.g. via hdbsql).
{% if node.install is defined %}
configure_ha_hook_{{ sap_instance }}_multi_target:
  ini.options_present:
    - name:  /hana/shared/{{ node.sid.upper() }}/global/hdb/custom/config/global.ini
    - separator: '='
    - strict: False # do not touch rest of file
    - sections:
        ha_dr_provider_SAPHanaSrMultiTarget:
          provider: 'SAPHanaSrMultiTarget'
          path: '{{ hook_path }}'
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
          path: '{{ hook_path }}'
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
    - onlyif:
      - test -f {{ sr_hook_multi_target }}

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
    - unless:
      - test -f {{ sr_hook_multi_target }}

configure_susTkOver_hook_{{ sap_instance }}:
  ini.options_present:
    - name:  /hana/shared/{{ node.sid.upper() }}/global/hdb/custom/config/global.ini
    - separator: '='
    - strict: False # do not touch rest of file
    - sections:
        ha_dr_provider_sustkover:
          provider: 'susTkOver'
          path: '{{ hook_path }}'
          execution_order: '2'
        trace:
          ha_dr_sustkover: 'info'
    - require:
      - pkg: install_SAPHanaSR
    - onlyif:
      - test -f {{ sustkover_hook }}

configure_susChkSrv_hook_{{ sap_instance }}:
  ini.options_present:
    - name:  /hana/shared/{{ node.sid.upper() }}/global/hdb/custom/config/global.ini
    - separator: '='
    - strict: False # do not touch rest of file
    - sections:
        ha_dr_provider_suschksrv:
          provider: 'susChkSrv'
          path: '{{ hook_path }}'
          execution_order: '3'
          action_on_loss: 'stop'
        trace:
          ha_dr_suschksrv: 'info'
    - require:
      - pkg: install_SAPHanaSR
    - onlyif:
      - test -f {{ suschksrv_hook }}

# Configure system replication operation mode in the primary site
{% for secondary_node in hana.nodes if node.primary is defined and secondary_node.secondary is defined and secondary_node.secondary.remote_host == host %}
configure_replication_{{ sap_instance }}:
  module.run:
    - hana.set_ini_parameter:
      - ini_parameter_values:
        - section_name: 'system_replication'
          parameter_name: 'operation_mode'
          parameter_value: '{{ secondary_node.secondary.operation_mode }}'
      - database: SYSTEMDB
      - file_name: global.ini
      - layer: SYSTEM
      - reconfig: True
      - user_name: SYSTEM
      - user_password: {{ node.password }}
      - password: {{ node.password }}
      - sid: {{ node.sid }}
      - inst: {{ node.instance }}
{% endfor %}

# Stop SAP Hana - Only needed if global.ini was edited directelly (removed old hooks).
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
