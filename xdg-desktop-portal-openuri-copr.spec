Name:           xdg-desktop-portal-openuri
Version:        1.0.0
Release:        1%{?dist}
Summary:        A minimal xdg-desktop-portal frontend for OpenURI

License:        MIT
URL:            https://github.com/playtron-os/xdg-desktop-portal-openuri

Source0: https://github.com/playtron-os/%{name}/archive/refs/tags/v%{version}.tar.gz#/%{name}-%{version}.tar.gz

# Build dependencies
BuildRequires: make gcc glib2-devel dbus-devel gtk3-devel xdg-utils rpm-build

# Runtime dependency
Requires:       xdg-utils

%global debug_package %{nil}

%description
A lightweight D-Bus service implementing org.freedesktop.portal.OpenURI
to open URLs via xdg-open, designed for minimal Fedora-based systems with Proton applications.

%prep
%setup -q

%build
make build

%install
mkdir -p %{buildroot}%{_bindir}
mkdir -p %{buildroot}/usr/lib/systemd/user

install -D -m 755 %{_builddir}/%{name}-%{version}/build/%{name} %{buildroot}%{_bindir}/%{name}
install -D -m 644 %{_builddir}/%{name}-%{version}/rootfs/usr/lib/systemd/user/* %{buildroot}/usr/lib/systemd/user/

%post
%systemd_user_post %{name}.service

%preun
%systemd_user_preun %{name}.service

%files
/usr/bin/%{name}
/usr/lib/systemd/user/%{name}.service

%changelog
* Tue Mar 18 2025 Ericky
- Initial commit
