#include "mqttmanager.h"
#include <QDebug>
#include <QJsonDocument>
#include <QJsonObject>

// 🚗 생성자
MqttManager::MqttManager(QObject *parent) : QObject(parent) {
    m_client = new QMqttClient(this);
    m_client->setHostname(QStringLiteral("10.210.98.208"));
    m_client->setPort(1883);

    connect(m_client, &QMqttClient::errorChanged, this,
        [this](QMqttClient::ClientError error) {
            qWarning() << "[MQTT Error]" << error << m_client->errorString();
        });

    // 상태 로그
    connect(m_client, &QMqttClient::stateChanged, this,
        [this](QMqttClient::ClientState state) {
            qDebug() << "[MQTT State]" << state;
            if (state == QMqttClient::Connected) {
                auto sub = m_client->subscribe(QMqttTopicFilter("car/hud"));
                if (!sub)
                    qWarning() << "[MQTT] Subscribe failed!";
                else
                    qDebug() << "[MQTT] Subscribed to car/hud";
            }
        });

    // 메시지 수신 처리 (Qt6은 QMqttTopicName 사용)
    connect(m_client, &QMqttClient::messageReceived,
            this, &MqttManager::onMessageReceived);
}

// 🚗 브로커 연결
void MqttManager::connectToBroker() {
    qDebug() << "[MQTT] Connecting to broker...";
    m_client->connectToHost();
}

// 🚗 메시지 수신 처리 (Qt6: QMqttTopicName)
void MqttManager::onMessageReceived(const QByteArray &message,
                                    const QMqttTopicName &topic) {
    qDebug() << "[MQTT Received]" << topic.name() << message;

    QJsonParseError parseError;
    QJsonDocument doc = QJsonDocument::fromJson(message, &parseError);

    if (parseError.error != QJsonParseError::NoError || !doc.isObject()) {
        qWarning() << "[MQTT Parse Error]" << parseError.errorString();
        return;
    }

    QJsonObject obj = doc.object();

    if (obj.contains("eta")) {
        QString newEta = obj["eta"].toString();
        if (m_eta != newEta) {
            m_eta = newEta;
            emit etaChanged();
        }
    }
    if (obj.contains("lanes")) {   // 🔹 Python에서 보내는 그대로 유지
        int newLanes = obj["lanes"].toInt();
        if (m_totalLanes != newLanes) {
            m_totalLanes = newLanes;
            emit totalLanesChanged();
        }
    }
    if (obj.contains("currentLane")) {
        int newLane = obj["currentLane"].toInt();
        if (m_currentLane != newLane) {
            m_currentLane = newLane;
            emit currentLaneChanged();
        }
    }
    if (obj.contains("avoidDir")) {
        int newAvoid = obj["avoidDir"].toInt();
        if (m_avoidDir != newAvoid) {
            m_avoidDir = newAvoid;
            emit avoidDirChanged();
        }
    }
    if (obj.contains("ambulanceLane")) {
        int newAmb = obj["ambulanceLane"].toInt();
        if (m_ambulanceLane != newAmb) {
            m_ambulanceLane = newAmb;
            emit ambulanceLaneChanged();
        }
    }
    if (obj.contains("state")) {
        QString newState = obj["state"].toString();
        if (m_state != newState) {
            m_state = newState;
            emit stateChanged();
        }
    }
}