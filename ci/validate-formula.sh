#! /bin/bash

# this script is intended to be executed via PRs travis CI
set -e

# 01: hana01

echo "==========================================="
echo " Using primary host                      "
echo "==========================================="

cp pillar.example example/pillar/hana.sls
cp example/salt/top.sls .

cat >grains <<EOF
host: hana01
EOF

cat >minion <<EOF
root_dir: $PWD
id: travis
EOF

sudo salt-call state.show_highstate --local --file-root=./ --config-dir=. --pillar-root=example/pillar --retcode-passthrough -l debug

echo
echo "==========================================="
echo " Using secondary host                      "
echo "==========================================="

cat >grains <<EOF
host: hana02
hana_inst_folder: myfold
EOF

cat >minion <<EOF
root_dir: $PWD
id: travis
EOF

sudo salt-call state.show_highstate --local --file-root=./ --config-dir=. --pillar-root=example/pillar --retcode-passthrough -l debug
