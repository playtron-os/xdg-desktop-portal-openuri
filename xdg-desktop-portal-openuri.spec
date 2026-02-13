Name:           xdg-desktop-portal-openuri
Version:        1.1.0
Release:        1%{?dist}
Summary:        A minimal xdg-desktop-portal frontend for OpenURI

License:        MIT
URL:            https://github.com/playtron-os/xdg-desktop-portal-openuri

Source0: %{name}-%{version}.tar.gz

# Runtime dependency
Requires:       xdg-utils

%global debug_package %{nil}

%description
A lightweight D-Bus service implementing org.freedesktop.portal.OpenURI
to open URLs via xdg-open, designed for minimal Fedora-based systems with Proton applications.

%prep
%setup -q

%install
mkdir -p %{buildroot}%{_bindir}
mkdir -p %{buildroot}%{_userunitdir}

install -D -m 755 %{_builddir}/%{name}-%{version}/build/%{name} %{buildroot}%{_bindir}/%{name}
install -D -m 644 %{_builddir}/%{name}-%{version}/rootfs/usr/lib/systemd/user/* %{buildroot}%{_userunitdir}/

%post
%systemd_user_post %{name}.service

%preun
%systemd_user_preun %{name}.service

%files
%{_bindir}/%{name}
%{_userunitdir}/%{name}.service

%changelog
* Tue Mar 18 2025 Ericky
- Initial commit
