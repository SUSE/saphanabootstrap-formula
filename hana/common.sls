git-core:
  pkg.installed:
    - refresh: False

python-pip:
  cmd.run:
    - name: easy_install pip
    - unless: which pip

shaptools:
  pip.installed:
    - editable: git+https://github.com/arbulu89/shaptools#egg=shaptools
    - require:
      - python-pip
      - git-core
