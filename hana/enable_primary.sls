{%- from "hana/map.jinja" import hana with context -%}
{% set host = grains['host'] %}

{% for node in hana.nodes %}
{% if node.host == host and node.primary is defined and node.system_replication.system_replication_options == "Primary" %}

{{  node.primary.name }}:
    hana.sr_primary_enabled:
      - sid: {{  node.sid }}
      - inst: {{  node.instance }}
      - password: {{  node.password }}
      {% if node.primary.backup is defined and node.primary.create_backup == true %}
      - backup:
        - user: {{  node.primary.backup.user }}
        - password: {{  node.primary.backup.password }}
        - database: {{  node.primary.backup.database }}
        - file: {{  node.primary.backup.file }}
      #{% endif %}
      {% if node.primary.userkey is defined and node.primary.create_userkey == true %}
      - userkey:
        - key: {{  node.primary.userkey.key }}
        - environment: {{  node.primary.userkey.environment }}
        - user: {{  node.primary.userkey.user }}
        - password: {{  node.primary.userkey.password }}
        - database: {{  node.primary.userkey.database }}
      #{% endif %}

{% endif %}
{% endfor %}
