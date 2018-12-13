#
# spec file for package webserver-formula
#
# Copyright (c) 2016 SUSE LINUX GmbH, Nuernberg, Germany.
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

License:        GPLv3+
Url:            https://github.com/arbulu89/%{name}
Source0:        %{name}-%{version}.tar.gz
BuildRoot:      %{_tmppath}/%{name}-%{version}-build

%define fname hana

%description
SAP HANA deployment salt formula

%prep
%setup -q

%build

%install
pwd
mkdir -p %{buildroot}/usr/share/susemanager/formulas/states/%{fname}
mkdir -p %{buildroot}/usr/share/susemanager/formulas/metadata/%{fname}
cp -R %{fname} %{buildroot}/usr/share/susemanager/formulas/states
cp -R form.yml %{buildroot}/usr/share/susemanager/formulas/metadata/%{fname}
if [ -f metadata.yml ]
then
  cp -R metadata.yml %{buildroot}/usr/share/susemanager/formulas/metadata/%{fname}
fi

%files
%defattr(-,root,root,-)
%license LICENSE
%doc README.md
/usr/share/susemanager/formulas/states/%{fname}
/usr/share/susemanager/formulas/metadata/%{fname}

%changelog CHANGELOG.md
