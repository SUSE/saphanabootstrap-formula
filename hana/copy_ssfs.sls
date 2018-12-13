{%- from "hana/map.jinja" import hana with context -%}

{% set host = grains['host'] %}

{% for node in hana.nodes %}
{% if node.host == host and node.secondary is defined and node.system_replication.system_replication_options == "Secondary" %}

add-network-repo:
  pkgrepo.managed:
    - name: network
    - baseurl: https://download.opensuse.org/repositories/network/SLE_12_SP3
    - gpgautoimport: True

install-sshpass:
  pkg.installed:
    - name: sshpass
    - refresh: False
    - fromrepo: network
    - require:
      - add-network-repo

{% for prim_node in hana.nodes %}
{% if node.secondary.remote_host == prim_node.host and prim_node.primary is defined and prim_node.system_replication.system_replication_options == "Primary"%}
{% set primary_pass = prim_node.password %}

copy-ssfs-data:
  cmd.run:
    - name: sshpass -p '{{ primary_pass }}' scp  -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null
            {{ node.sid }}adm@{{ node.secondary.remote_host }}:/usr/sap/{{ node.sid.upper() }}/SYS/global/security/rsecssfs/data/SSFS_{{ node.sid.upper() }}.DAT
            /usr/sap/{{ node.sid.upper() }}/SYS/global/security/rsecssfs/data/SSFS_{{ node.sid.upper() }}.DAT
    - runas: {{ node.sid }}adm
    - password: {{ node.password }}
    - require:
      - install-sshpass

copy-ssfs-key:
  cmd.run:
    - name: sshpass -p '{{ primary_pass }}' scp  -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null
            {{ node.sid }}adm@{{ node.secondary.remote_host }}:/usr/sap/{{ node.sid.upper() }}/SYS/global/security/rsecssfs/key/SSFS_{{ node.sid.upper() }}.KEY
            /usr/sap/{{ node.sid.upper() }}/SYS/global/security/rsecssfs/key/SSFS_{{ node.sid.upper() }}.KEY
    - runas: {{ node.sid }}adm
    - password: {{ node.password }}
    - require:
      - install-sshpass

{% endif %}
{% endfor %}
{% endif %}
{% endfor %}
