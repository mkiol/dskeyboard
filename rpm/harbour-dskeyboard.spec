Name:       harbour-dskeyboard

# >> macros
# << macros

Summary:    Speech to Text Keyboard
Version:    1.6.0
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
&& ln -sf bg.qml %{name}_bg.qml \
&& ln -sf bn.qml %{name}_bn.qml \
&& ln -sf es.qml %{name}_ca.qml \
&& ln -sf cs.qml %{name}_cs.qml \
&& ln -sf da.qml %{name}_da.qml \
&& ln -sf de.qml %{name}_de.qml \
&& ln -sf el.qml %{name}_el.qml \
&& ln -sf en.qml %{name}_en.qml \
&& ln -sf es.qml %{name}_es.qml \
&& ln -sf et.qml %{name}_et.qml \
&& ln -sf fi.qml %{name}_fi.qml \
&& ln -sf fr.qml %{name}_fr.qml \
&& ln -sf hi.qml %{name}_hi.qml \
&& ln -sf hu.qml %{name}_hu.qml \
&& ln -sf it.qml %{name}_it.qml \
&& ln -sf kk.qml %{name}_kk.qml \
&& ln -sf lt.qml %{name}_lt.qml \
&& ln -sf lv.qml %{name}_lv.qml \
&& ln -sf nl.qml %{name}_nl.qml \
&& ln -sf no.qml %{name}_no.qml \
&& ln -sf pl.qml %{name}_pl.qml \
&& ln -sf pt.qml %{name}_pt.qml \
&& ln -sf ro.qml %{name}_ro.qml \
&& ln -sf ru.qml %{name}_ru.qml \
&& ln -sf sl.qml %{name}_sl.qml \
&& ln -sf cs.qml %{name}_sk.qml \
&& ln -sf sv.qml %{name}_sv.qml \
&& ln -sf tr.qml %{name}_tr.qml \
&& ln -sf tt.qml %{name}_tt.qml \
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
