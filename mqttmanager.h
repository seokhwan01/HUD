#ifndef MQTTMANAGER_H
#define MQTTMANAGER_H

#include <QObject>
#include <QtMqtt/QMqttClient>
#include <QtMqtt/QMqttTopicFilter>
#include <QtMqtt/QMqttSubscription>
#include <QtMqtt/QMqttTopicName>

class MqttManager : public QObject {
    Q_OBJECT
    Q_PROPERTY(QString eta READ eta NOTIFY etaChanged)
    Q_PROPERTY(int totalLanes READ totalLanes NOTIFY totalLanesChanged)
    Q_PROPERTY(int currentLane READ currentLane NOTIFY currentLaneChanged)
    Q_PROPERTY(int avoidDir READ avoidDir NOTIFY avoidDirChanged)
    Q_PROPERTY(int ambulanceLane READ ambulanceLane NOTIFY ambulanceLaneChanged)
    Q_PROPERTY(QString state READ state NOTIFY stateChanged)

public:
    explicit MqttManager(QObject *parent = nullptr);

    QString eta() const { return m_eta; }
    int totalLanes() const { return m_totalLanes; }
    int currentLane() const { return m_currentLane; }
    int avoidDir() const { return m_avoidDir; }
    int ambulanceLane() const { return m_ambulanceLane; }
    QString state() const { return m_state; }

    void connectToBroker();

signals:
    void etaChanged();
    void totalLanesChanged();
    void currentLaneChanged();
    void avoidDirChanged();
    void ambulanceLaneChanged();
    void stateChanged();

private slots:
    void onMessageReceived(const QByteArray &message,
                           const QMqttTopicName &topic);   // ✅ Qt6 스타일

private:
    QMqttClient *m_client;
    QString m_eta;
    int m_totalLanes = 3;
    int m_currentLane = 2;
    int m_avoidDir = 0;
    int m_ambulanceLane = 2;
    QString m_state = "idle";
};

#endif // MQTTMANAGER_H


// #ifndef MQTTMANAGER_H
// #define MQTTMANAGER_H

// #include <QObject>
// #include <QMqttClient>

// class MqttManager : public QObject {
//     Q_OBJECT
//     Q_PROPERTY(QString eta READ eta NOTIFY etaChanged)
//     Q_PROPERTY(int totalLanes READ totalLanes NOTIFY totalLanesChanged)
//     Q_PROPERTY(int currentLane READ currentLane NOTIFY currentLaneChanged)
//     Q_PROPERTY(int avoidDir READ avoidDir NOTIFY avoidDirChanged)
//     Q_PROPERTY(int ambulanceLane READ ambulanceLane NOTIFY ambulanceLaneChanged)
//     Q_PROPERTY(QString state READ state NOTIFY stateChanged)

// public:
//     explicit MqttManager(QObject *parent = nullptr);

//     // Getter 함수
//     QString eta() const { return m_eta; }
//     int totalLanes() const { return m_totalLanes; }
//     int currentLane() const { return m_currentLane; }
//     int avoidDir() const { return m_avoidDir; }
//     int ambulanceLane() const { return m_ambulanceLane; }
//     QString state() const { return m_state; }

//     void connectToBroker();

// signals:
//     void etaChanged();
//     void totalLanesChanged();
//     void currentLaneChanged();
//     void avoidDirChanged();
//     void ambulanceLaneChanged();
//     void stateChanged();

// private slots:
//     void onMessageReceived(const QByteArray &message, const QMqttTopicName &topic);

// private:
//     QMqttClient *m_client;
//     QString m_eta;
//     int m_totalLanes = 3;
//     int m_currentLane = 2;
//     int m_avoidDir = 0;
//     int m_ambulanceLane = 2;
//     QString m_state = "idle";
// };

// #endif // MQTTMANAGER_H
