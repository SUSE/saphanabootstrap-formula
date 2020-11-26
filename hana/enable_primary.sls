{%- from "hana/map.jinja" import hana with context -%}
{% set host = grains['host'] %}

{% for node in hana.nodes if node.host == host and node.primary is defined %}

{{ node.primary.name }}:
    hana.sr_primary_enabled:
      - sid: {{ node.sid }}
      - inst: {{ node.instance }}
      - password: {{ node.password }}
      {% if node.primary.userkey is defined %}
      - userkey:
        - key_name: {{ node.primary.userkey.key_name }}
        - environment: {{ node.primary.userkey.environment }}
        - user_name: {{ node.primary.userkey.user_name }}
        - user_password: {{ node.primary.userkey.user_password }}
        - database: {{ node.primary.userkey.database }}
      {% endif %}
      {% if node.primary.backup is defined %}
      - backup:
        {% if node.primary.backup.key_name is defined %}
        - key_name: {{ node.primary.backup.key_name }}
        {% else %}
        - user_name: {{ node.primary.backup.user_name }}
        - user_password: {{ node.primary.backup.user_password }}
        {% endif %}
        - database: {{ node.primary.backup.database }}
        - file: {{ node.primary.backup.file }}
      {% endif %}
      - require:
        - hana_install_{{ node.host+node.sid }}

{% endfor %}
