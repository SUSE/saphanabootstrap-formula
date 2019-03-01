{%- from "hana/map.jinja" import hana with context -%}
{% set host = grains['host'] %}

{% for node in hana.nodes %}
{% if node.host == host and node.primary is defined %}

{{  node.primary.name }}:
    hana.sr_primary_enabled:
      - sid: {{  node.sid }}
      - inst: {{  node.instance }}
      - password: {{  node.password }}
      {% if node.primary.userkey is defined %}
      - userkey:
        - key: {{  node.primary.userkey.key }}
        - environment: {{  node.primary.userkey.environment }}
        - key_user: {{  node.primary.userkey.key_user }}
        - key_password: {{  node.primary.userkey.key_password }}
        - database: {{  node.primary.userkey.database }}
      {% endif %}
      {% if node.primary.backup is defined %}
      - backup:
        {% if node.primary.backup.key is defined %}
        - key: {{  node.primary.backup.key }}
        {% else %}
        - key_user: {{  node.primary.backup.key_user }}
        - key_password: {{  node.primary.backup.key_password }}
        {% endif %}
        - database: {{  node.primary.backup.database }}
        - file: {{  node.primary.backup.file }}
      {% endif %}

{% endif %}
{% endfor %}
