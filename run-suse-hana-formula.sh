#! /bin/bash

salt-call --local \
 --log-level=debug \
 --log-file=/var/log/salt-hana-formula.log \
 --log-file-level=debug \
 --retcode-passthrough \
 --force-color \
 --config=/usr/share/salt-formulas/config/hana \
 state.highstate saltenv=base
