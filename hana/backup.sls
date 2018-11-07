{%- from "hana/map.jinja" import hana with context -%}

{%- from "hana/utils.sls" import path, user with context -%}
{% set sid = hana.sid.upper() %}

add-network-repo:
  pkgrepo:
    - managed
    - name: network
    - baseurl: https://download.opensuse.org/repositories/network/SLE_12_SP3
    - gpgcheck: 0
    - enabled: 1

install-sshpass:
  pkg.installed:
    - name: sshpass
    - fromrepo: network
    - require:
      - add-network-repo

create-backup:
  cmd.run:
    - name: {{ path }}/exe/hdbsql
            -U {{ hana.primary.backup.user }} -d {{ hana.primary.backup.database }}
            -p {{ hana.primary.password }}
            "BACKUP DATA FOR FULL SYSTEM USING FILE ('{{ hana.primary.backup.file }}')"
    - runas: {{ user }}
    - require:
      - start-hana-instance

copy-ssfs-data:
  cmd.run:
    - name: sshpass -p {{ hana.secondary.password }} scp /usr/sap/{{ sid }}/SYS/global/security/rsecssfs/data/SSFS_{{ sid }}.DAT
            {{ hana.secondary.host }}:/usr/sap/{{ sid }}/SYS/global/security/rsecssfs/data/SSFS_{{ sid }}.DAT
    - runas: {{ user }}
    - require:
      - start-hana-instance
      - install-sshpass

copy-ssfs-key:
  cmd.run:
    - name: sshpass -p {{ hana.secondary.password }} scp /usr/sap/{{ sid }}/SYS/global/security/rsecssfs/key/SSFS_{{ sid }}.KEY
            {{ hana.secondary.host }}:/usr/sap/{{ sid }}/SYS/global/security/rsecssfs/key/SSFS_{{ sid }}.KEY
    - runas: {{ user }}
    - require:
      - start-hana-instance
      - install-sshpass

{#
# Only available after Fluorine salt version
copy-ssfs-data:
  scp.put:
    - files:
      - /usr/sap/{{ sid }}/SYS/global/security/rsecssfs/data/SSFS_{{ sid }}.DAT
    - remote_path: /usr/sap/{{ sid }}/SYS/global/security/rsecssfs/data/SSFS_{{ sid }}.DAT
    - hostname: {{ hana.secondary.host }}

copy-ssfs-key:
  scp.put:
    - files:
      - /usr/sap/{{ sid }}/SYS/global/security/rsecssfs/key/SSFS_{{ sid }}.KEY
    - remote_path: /usr/sap/{{ sid }}/SYS/global/security/rsecssfs/key/SSFS_{{ sid }}.KEY
    - hostname: {{ hana.secondary.host }}
#}
