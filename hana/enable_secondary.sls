{%- from "hana/map.jinja" import hana with context -%}

{%- from "hana/utils.sls" import path, user with context -%}

primary-available:
  cmd.run:
    - name: until nc -z {{ hana.primary.host }} 40002; do sleep 1; done
    - timeout: 60

stop-hana-instance:
  cmd.run:
    - name: {{ path }}/HDB stop
    - runas: {{ user }}
    - require:
      - primary-available

enable-secondary:
  cmd.run:
    - name: su -lc '{{ path }}/exe/hdbnsutil -sr_register
            --name={{ hana.secondary.name }}
            --remoteHost={{ hana.primary.host }}
            --remoteInstance={{ hana.instance }}
            --replicationMode={{ hana.secondary.replication_mode }}
            --operationMode={{ hana.secondary.operation_mode }}' {{ user }}
    - runas: root
    - require:
      - stop-hana-instance

start-hana-instance:
  cmd.run:
    - name: {{ path }}/HDB start
    - runas: {{ user }}
    - require:
      - enable-secondary

secondary-enabled:
  cmd.run:
    - name: su -lc '{{ path }}/exe/hdbnsutil -sr_state | grep {{ hana.secondary.replication_mode }}' {{ user }}
    - runas: root
    - require:
      - start-hana-instance
