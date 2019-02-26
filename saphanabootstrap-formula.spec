#
# spec file for package saphanabootstrap-formula
#
# Copyright (c) 2018 SUSE LLC, Nuernberg, Germany.
#
# All modifications and additions to the file contributed by third parties
# remain the property of their copyright owners, unless otherwise agreed
# upon. The license for this file, and modifications and additions to the
# file, is the same license as for the pristine package itself (unless the
# license for the pristine package is not an Open Source License, in which
# case the license is the MIT License). An "Open Source License" is a
# license that conforms to the Open Source Definition (Version 1.9)
# published by the Open Source Initiative.

# Please submit bugfixes or comments via http://bugs.opensuse.org/
#


# See also http://en.opensuse.org/openSUSE:Specfile_guidelines

Name:           saphanabootstrap-formula
Version:        0.1.0
Release:        1
Summary:        SAP HANA platform deployment formula

License:        Apache-2.0
Url:            https://github.com/SUSE/%{name}
Source0:        %{name}-%{version}.tar.gz
BuildRoot:      %{_tmppath}/%{name}-%{version}-build
BuildArch:      noarch
Requires:       salt-saphana
Requires:       habootstrap-formula

%define fname hana
%define fdir  %{_datadir}/susemanager/formulas
%define ftemplates templates

%description
SAP HANA deployment salt formula

# package to deploy on SUMA specific path.
%package suma
Summary:        SAP HANA platform deployment formula (SUMA specific)
Requires:       salt-saphana
Requires:       habootstrap-formula-suma

%description suma
SAP HANA deployment salt formula (SUMA specific)

%prep
%setup -q

%build

%install
pwd
mkdir -p %{buildroot}/srv/salt/
cp -R %{fname} %{buildroot}/srv/salt/
cp -R %{ftemplates} %{buildroot}/srv/salt/%{fname}/

# SUMA Specific
mkdir -p %{buildroot}%{fdir}/states/%{fname}
mkdir -p %{buildroot}%{fdir}/metadata/%{fname}
cp -R %{fname} %{buildroot}%{fdir}/states
cp -R %{ftemplates} %{buildroot}%{fdir}/states/%{fname}
cp -R form.yml %{buildroot}%{fdir}/metadata/%{fname}
if [ -f metadata.yml ]
then
  cp -R metadata.yml %{buildroot}%{fdir}/metadata/%{fname}
fi


%files
%defattr(-,root,root,-)
%license LICENSE
%doc README.md
/srv/salt/%{fname}
/srv/salt/%{fname}/%{ftemplates}

%dir %attr(0755, root, salt) /srv/salt

%files suma
%defattr(-,root,root,-)
%license LICENSE
%doc README.md
%dir %{_datadir}/susemanager
%dir %{fdir}
%dir %{fdir}/states
%dir %{fdir}/metadata
%{fdir}/states/%{fname}
%{fdir}/states/%{fname}/%{ftemplates}
%{fdir}/metadata/%{fname}

%dir %attr(0755, root, salt) %{_datadir}/susemanager
%dir %attr(0755, root, salt) %{fdir}
%dir %attr(0755, root, salt) %{fdir}/states
%dir %attr(0755, root, salt) %{fdir}/metadata

%changelog
