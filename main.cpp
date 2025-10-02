#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QUrl>

#include "mqttmanager.h"   // ✅ MQTT 매니저 포함

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);
    QQmlApplicationEngine engine;
    // ✅ 시작 로그
    qDebug() << "🚀 HUD Application starting...";

    // ✅ MQTT 매니저 객체 생성
    MqttManager mqtt;
    mqtt.connectToBroker();  // 브로커 연결

    // ✅ QML에서 "mqtt" 라는 이름으로 접근 가능
    engine.rootContext()->setContextProperty("mqtt", &mqtt);

    // ✅ QML 파일 (절대경로 그대로 사용)
    const QUrl url = QUrl::fromLocalFile("/home/rbhud/HUD/Main.qml");
    // const QUrl url("qrc:/HUD_EX/Main.qml");

    QObject::connect(
        &engine, &QQmlApplicationEngine::objectCreated,
        &app, [url](QObject *obj, const QUrl &objUrl) {
            if (!obj && url == objUrl)
                QCoreApplication::exit(-1);
        }, Qt::QueuedConnection);

    engine.load(url);

    return app.exec();
}
