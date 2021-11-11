TEMPLATE = aux

TARGET = harbour-dskeyboard

QT += quick qml

OTHER_FILES += \
    qml/.qml \
    qml/layouts/*.conf \
    rpm/*.*

install_qml.path = /usr/share/maliit/plugins/com/jolla
install_qml.files = qml/*.qml
INSTALLS += install_qml

install_layouts.path = /usr/share/maliit/plugins/com/jolla/layouts
install_layouts.files = $${OUT_PWD}/qml/layouts/layouts_$${TARGET}.conf
install_layouts.CONFIG = no_check_exist
install_layouts.extra += mkdir -p $${OUT_PWD}/qml/layouts && sed s/%TARGET%/$${TARGET}/g < $${PWD}/qml/layouts/layouts.conf > $${OUT_PWD}/qml/layouts/layouts_$${TARGET}.conf
INSTALLS += install_layouts
