import QtQuick
import QtQuick.Controls
import QtQuick.Window

ApplicationWindow {
    id: window
    width: 800
    height: 480
    visible: true
    color: "black"
    title: qsTr("HUD with Dynamic Lanes & Animated Arrow + Center Red Lane Effect")

    // ===== 공통 유틸 =====
    function isNum(x)        { return typeof x === "number" && isFinite(x) }
    function toInt(x, d)     { return isNum(x) ? Math.floor(x) : d }
    function clamp(x,a,b)    { return (x < a) ? a : (x > b) ? b : x }

    // MQTT object가 아직 바인드 안되었을 수 있으므로 safe getters
   function tl() {            // totalLanes
    let t = mqtt ? toInt(mqtt.totalLanes, 3) : 3
    return clamp(t, 1, 20)
    }
    function cl() {            // currentLane
        let c = mqtt ? toInt(mqtt.currentLane, 1) : 1
        return clamp(c, 1, tl())
    }
    function al() {            // ambulanceLane
        let a = mqtt ? toInt(mqtt.ambulanceLane, 1) : 1
        return clamp(a, 1, tl())
    }
    function ad() {            // avoidDir
        let v = mqtt ? toInt(mqtt.avoidDir, 0) : 0
        return clamp(v, 0, 2)
    }
    function st() {            // state
        return (mqtt && typeof mqtt.state === "string") ? mqtt.state : "idle"
    }


    // 전역 보정값
    property int outerMargin: 150
    property int laneLineWidth: 3
    property int carIconHeight: 160

    // ✅ ETA는 문자열 버퍼만 UI가 참조
    property string etaText: ""

    Item {
        id: roadArea
        anchors.fill: parent
        anchors.leftMargin: outerMargin
        anchors.rightMargin: outerMargin

        // 0/NaN/비정상 값 방지
        property real laneSpacing: Math.max(1, width / tl())

        // ===== 차선 라인 =====
        Repeater {
            id: laneRepeater
            // 모델 음수/0 방지
            model: tl() + 1
            Item {
                id: lineSlot
                property int lw: Math.max(1, laneLineWidth)
                width: lw
                height: parent ? parent.height : 0
                y: 0

                // 마지막 라인은 우측 경계로 보정
                x: (index === tl()) ? Math.max(0, roadArea.width - lw)
                                    : Math.round(index * roadArea.laneSpacing)

                Rectangle {
                    anchors.fill: parent
                    color: "white"
                    visible: (index === 0 || index === tl())
                }

                Repeater {
                    // 중간 점선: 모델 안전화
                    model: (index > 0 && index < tl()) ? 10 : 0
                    Rectangle {
                        width: lineSlot.lw
                        height: 30
                        color: "white"
                        opacity: 0.9
                        x: -(lineSlot.lw / 2)
                        y: index * 60
                    }
                }
            }
        }

        // ===== 빨간 점선(응급차 레인) =====
        Canvas {
            id: redLaneEffect
            anchors.fill: parent
            z: 5
            property real progress: 0.0
            visible: (st() === "samePath")

            onPaint: {
                const ctx = getContext && getContext("2d")
                if (!ctx) return
                ctx.clearRect(0, 0, width, height)

                if (st() !== "samePath") return

                const t = tl()
                const a = al()
                if (!isFinite(t) || t <= 0 || !isFinite(a)) return

                const laneX = (a - 0.5) * roadArea.laneSpacing
                const fromY = height + 100
                const toY   = height - 580

                ctx.lineWidth = 15
                ctx.strokeStyle = "#FF0000"
                ctx.lineCap = "butt"

                const segmentLength = 50
                const gap = 60
                const offset = (progress % 1) * (segmentLength + gap)
                const arrowSize = 30

                for (let y = fromY - offset; y > toY; y -= (segmentLength + gap)) {
                    const y1 = Math.max(y - segmentLength, toY)

                    ctx.beginPath()
                    ctx.moveTo(laneX, y)
                    ctx.lineTo(laneX, y1)
                    ctx.stroke()

                    ctx.beginPath()
                    ctx.fillStyle = "#FF0000"
                    ctx.moveTo(laneX, y1 - arrowSize)
                    ctx.lineTo(laneX - arrowSize / 2, y1)
                    ctx.lineTo(laneX + arrowSize / 2, y1)
                    ctx.closePath()
                    ctx.fill()
                }
            }

            Timer {
                interval: 50
                running: redLaneEffect.visible
                repeat: true
                onTriggered: {
                    redLaneEffect.progress = (redLaneEffect.progress + 0.05) % 1.0
                    redLaneEffect.requestPaint()
                }
            }
        }

        // ===== 차량 아이콘 =====
        Image {
            id: car
            source: "file:///home/rbhud/HUD/assets/Car.svg"
            z: 20
            width: 100
            height: carIconHeight
            fillMode: Image.PreserveAspectFit
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 20

            // NaN 방지
            x: clamp(((cl() - 0.5) * roadArea.laneSpacing) - width / 2, -width, roadArea.width)

            Behavior on x {
                NumberAnimation { duration: 300; easing.type: Easing.InOutQuad }
            }

            onStatusChanged: {
                // 리소스 로드 실패 시 로그 (크래시 방지는 아니지만 디버그 도움)
                if (status === Image.Error) console.warn("Car.svg load failed:", source)
            }
        }

        // ===== 회피 화살표 =====
        Canvas {
            id: laneChangeArrow
            anchors.fill: parent
            z: 10
            property real progress: 0.0
            visible: (st() === "samePath")

            onPaint: {
                const ctx = getContext && getContext("2d")
                if (!ctx) return
                ctx.clearRect(0, 0, width, height)

                if (st() !== "samePath") return

                const t  = tl()
                const c0 = cl()
                const ad = ad()
                if (!isFinite(t) || t <= 0) return

                let targetLane = c0
                if (ad === 1) targetLane++
                else if (ad === 2) targetLane--
                targetLane = clamp(targetLane, 1, t)

                const startX = (c0 - 0.5) * roadArea.laneSpacing
                const startY = height - (carIconHeight + 20)
                const endX   = (targetLane - 0.5) * roadArea.laneSpacing

                const up1    = 90
                const diagDy = 90
                const down3  = 80

                const P0 = {x:startX, y:startY}
                const P1 = {x:startX, y:startY - up1}
                const P2 = {x:endX,  y:P1.y - diagDy}
                const P3 = {x:endX,  y:P2.y - down3}

                function dist(a,b){ const dx=a.x-b.x, dy=a.y-b.y; return Math.sqrt(dx*dx+dy*dy) }
                const L1 = dist(P0,P1), L2 = dist(P1,P2), L3 = dist(P2,P3), Ltot = Math.max(1, L1+L2+L3)
                let drawLen = clamp(progress, 0, 1) * Ltot

                ctx.beginPath()
                ctx.lineWidth = 22
                ctx.strokeStyle = "#39FF14"
                ctx.lineCap = "round"
                ctx.lineJoin = "round"
                ctx.moveTo(P0.x, P0.y)

                function lineToClamped(from, to, remain) {
                    const seg = dist(from,to)
                    if (remain >= seg) { ctx.lineTo(to.x,to.y); return remain - seg }
                    if (remain > 0) {
                        const t = remain / seg
                        ctx.lineTo(from.x + (to.x-from.x)*t, from.y + (to.y-from.y)*t)
                        return 0
                    }
                    return 0
                }

                let r = drawLen
                r = lineToClamped(P0,P1,r)
                r = lineToClamped(P1,P2,r)
                r = lineToClamped(P2,P3,r)
                ctx.stroke()

                if (progress >= 1.0) {
                    const arrow = 35
                    ctx.beginPath()
                    ctx.fillStyle = "#39FF14"
                    ctx.moveTo(P3.x, P3.y - arrow)
                    ctx.lineTo(P3.x - arrow/2, P3.y + 4)
                    ctx.lineTo(P3.x + arrow/2, P3.y + 4)
                    ctx.closePath()
                    ctx.fill()
                }
            }

            Timer {
                id: arrowTimer
                interval: 30
                running: false
                repeat: true
                onTriggered: {
                    laneChangeArrow.progress += 0.02
                    if (laneChangeArrow.progress >= 1.0) laneChangeArrow.progress = 0.0
                    laneChangeArrow.requestPaint()
                }
            }

            function startAnimation() {
                progress = 0.0
                arrowTimer.start()
            }
        }
    }

    // ===== HUD Overlay =====
    Item {
        id: hudOverlay
        anchors.fill: parent
        z: 9999

        Row {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.topMargin: 20
            anchors.leftMargin: 20
            spacing: 8

            Column {
                spacing: 6
                visible: (st() === "samePath")
                Text {
                    id: etaLabel
                    text: "ETA"
                    font.pixelSize: 70
                    color: "white"
                    font.bold: true
                }
                Text {
                    text: window.etaText
                    font.pixelSize: 70
                    font.family: "Noto Sans"
                    color: "lightgreen"
                }
            }

            Image {
                source: "file:///home/rbhud/HUD/assets/siren.png"
                width: 150
                height: 150
                anchors.verticalCenter: etaLabel.verticalCenter
                visible: (st() === "samePath" || st() === "nearby")
                onStatusChanged: if (status === Image.Error) console.warn("siren.png load failed:", source)
                SequentialAnimation on opacity {
                    loops: Animation.Infinite
                    NumberAnimation { from: 1.0; to: 0.2; duration: 500 }
                    NumberAnimation { from: 0.2; to: 1.0; duration: 500 }
                }
            }
        }
    }

    // ===== MQTT 이벤트 바인딩 (널 타겟 안전) =====
    Connections {
        target: (typeof mqtt !== "undefined") ? mqtt : null

        onEtaChanged: {
            if (!mqtt) { window.etaText = ""; return }
            if (typeof mqtt.eta === "string") {
                window.etaText = mqtt.eta
            } else if (isNum(mqtt.eta)) {
                const sec = Math.max(0, Math.floor(mqtt.eta))
                const m = Math.floor(sec / 60)
                const s = sec % 60
                window.etaText = m + "m " + s + "s"
            } else {
                window.etaText = ""
            }
        }

        onAvoidDirChanged: {
            if (st() === "samePath") {
                laneChangeArrow.startAnimation()
                redLaneEffect.progress = 0.0
                redLaneEffect.requestPaint()
            }
        }
        onCurrentLaneChanged: {
            if (st() === "samePath") {
                laneChangeArrow.startAnimation()
                redLaneEffect.progress = 0.0
                redLaneEffect.requestPaint()
            }
        }
        onStateChanged: {
            if (st() === "samePath") {
                laneChangeArrow.startAnimation()
                redLaneEffect.progress = 0.0
                redLaneEffect.requestPaint()
            } else {
                window.etaText = ""
            }
        }
    }
}
