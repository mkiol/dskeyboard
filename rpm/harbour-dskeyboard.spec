Name:       harbour-dskeyboard

# >> macros
# << macros

Summary:    Speech-to-text Keyboard
Version:    1.3.0
Release:    1
Group:      Qt/Qt
License:    LICENSE
BuildArch:  noarch
URL:        https://github.com/mkiol/dskeyboard
Source0:    %{name}-%{version}.tar.bz2
Requires:   sailfishsilica-qt5 >= 0.10.9, maliit-framework-wayland

%description
Speech-to-text Keyboard


%prep
%setup -q -n %{name}-%{version}

# >> setup
# << setup

%build
# >> build pre
# << build pre

%qmake5 

make %{?_smp_mflags}

# >> build post
# << build post

%install
rm -rf %{buildroot}
# >> install pre
# << install pre
%qmake5_install
cd %{buildroot}%{_datadir}/maliit/plugins/com/jolla/layouts/ \
&& ln -sf es.qml %{name}_ca.qml \
&& ln -sf fi.qml %{name}_fi.qml \
&& ln -sf cs.qml %{name}_cs.qml \
&& ln -sf en.qml %{name}_en.qml \
&& ln -sf de.qml %{name}_de.qml \
&& ln -sf es.qml %{name}_es.qml \
&& ln -sf fr.qml %{name}_fr.qml \
&& ln -sf it.qml %{name}_it.qml \
&& ln -sf pl.qml %{name}_pl.qml \
&& ln -sf ru.qml %{name}_ru.qml \
&& ln -sf uk.qml %{name}_uk.qml \
&& ln -sf zh_cn_stroke_simplified.qml %{name}_zh_cn_stroke_simplified.qml \
&& cd %{_builddir}

%post
systemctl-user restart maliit-server >/dev/null 2>&1 || :

%postun
systemctl-user restart maliit-server >/dev/null 2>&1 || :
# >> install post
# << install post

%files
%defattr(-,root,root,-)
%defattr(0644,root,root,-)
%{_datadir}/maliit/plugins/com/jolla/*.qml
%{_datadir}/maliit/plugins/com/jolla/layouts/layouts_%{name}.conf
%{_datadir}/maliit/plugins/com/jolla/layouts/%{name}_*.qml
# >> files
# << files
