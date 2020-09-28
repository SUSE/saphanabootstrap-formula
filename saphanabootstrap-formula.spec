#
# spec file for package saphanabootstrap-formula
#
# Copyright (c) 2019 SUSE LINUX GmbH, Nuernberg, Germany.
#
# All modifications and additions to the file contributed by third parties
# remain the property of their copyright owners, unless otherwise agreed
# upon. The license for this file, and modifications and additions to the
# file, is the same license as for the pristine package itself (unless the
# license for the pristine package is not an Open Source License, in which
# case the license is the MIT License). An "Open Source License" is a
# license that conforms to the Open Source Definition (Version 1.9)
# published by the Open Source Initiative.

# Please submit bugfixes or comments via https://bugs.opensuse.org/
#


# See also http://en.opensuse.org/openSUSE:Specfile_guidelines

Name:           saphanabootstrap-formula
Version:        0
Release:        0
Summary:        SAP HANA platform deployment formula
License:        Apache-2.0

Url:            https://github.com/SUSE/%{name}
Source0:        %{name}-%{version}.tar.gz
BuildRoot:      %{_tmppath}/%{name}-%{version}-build
BuildArch:      noarch
Requires:       habootstrap-formula
Requires:       salt-shaptools
Requires:       salt-formulas-configuration
Suggests:       prometheus-hanadb_exporter >= 0.7.0

%define fname hana
%define fdir  %{_datadir}/salt-formulas
%define ftemplates templates

%description
SAP HANA deployment salt formula. This formula is capable to install
SAP HANA nodes, enable system replication and configure SLE-HA cluster
with the SAPHanaSR resource agent, using standalone salt or via SUSE Manager
formulas with forms, available on SUSE Manager 4.0.

%prep
%setup -q

%build

%install

mkdir -p %{buildroot}%{fdir}/states/%{fname}
mkdir -p %{buildroot}%{fdir}/metadata/%{fname}
mkdir -p %{buildroot}%{fdir}/config/%{fname}
mkdir -p %{buildroot}/usr/bin
mkdir -p %{buildroot}%{fdir}/config/%{fname}/pillar/%{fname}
install -m755 pillar.example %{buildroot}%{fdir}/config/%{fname}/pillar/%{fname}/hana.sls
install -m755 config/minion %{buildroot}%{fdir}/config/%{fname}/
install -m755 config/pillar/top.sls %{buildroot}%{fdir}/config/%{fname}/pillar/
install -m755  run-saphanabootstrap-formula %{buildroot}/usr/bin/run-saphanabootstrap-formula
cp -R %{fname} %{buildroot}%{fdir}/states
cp -R %{ftemplates} %{buildroot}%{fdir}/states/%{fname}
cp -R form.yml pillar.example %{buildroot}%{fdir}/metadata/%{fname}
if [ -f metadata.yml ]
then
  cp -R metadata.yml %{buildroot}%{fdir}/metadata/%{fname}
fi

%files
%defattr(-,root,root,-)
%if 0%{?sle_version} < 120300
%doc README.md LICENSE
%else
%doc README.md
%license LICENSE
%endif

%dir %attr(0755, root, salt) %{fdir}
%dir %attr(0755, root, salt) %{fdir}/states
%dir %attr(0755, root, salt) %{fdir}/metadata
%dir %attr(0755, root, salt) %{fdir}/config
%dir %attr(0755, root, salt) %{fdir}/config/hana/
%dir %attr(0755, root, salt) %{fdir}/config/hana/pillar
%dir %attr(0755, root, salt) %{fdir}/config/hana/pillar/hana

%attr(0755, root, salt) /usr/bin/run-saphanabootstrap-formula
%attr(0755, root, salt) %{fdir}/config/%{fname}/pillar/top.sls
%attr(0755, root, salt) %{fdir}/config/%{fname}/pillar/hana/hana.sls
%attr(0755, root, salt) %{fdir}/config/%{fname}/minion
%attr(0755, root, salt) %{fdir}/states/%{fname}
%attr(0755, root, salt) %{fdir}/states/%{fname}/%{ftemplates}
%attr(0755, root, salt) %{fdir}/metadata/%{fname}

%changelog
