cp -R pillar/* /srv/pillar
cp ../pillar.example /srv/pillar/hana.sls
mkdir -p /srv/salt/hana
cp -R salt/* /srv/salt
cp -R ../hana /srv/salt
