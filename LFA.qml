import QtQuick 2.3
import QtGraphicalEffects 1.0
import "assets"

Item {
    id: root

    ////////// FONT //////////////////////////////////////////////////////////
    FontLoader{id:gauge_font; source: "saira.medium.ttf"}

    ////////// MISCELLANEOUS VARIABLES ///////////////////////////////////////
    property real indentpixelsize: 45
    property int membank2_byte7: rpmtest.can203data[10];
    property int inputs: rpmtest.inputsdata
    property int fontsmall: 26
    property int fontlarge: 36
    property int udp_message: rpmtest.udp_packetdata

    ////////// IC7 LCD RESOLUTION ////////////////////////////////////////////
    width: 800
    height: 480

    ////////// UPD MESSAGES FOR NAVIGATION ///////////////////////////////////
    property bool udp_up        :udp_message&0x01
    property bool udp_down      :udp_message&0x02
    property bool udp_left      :udp_message&0x04
    property bool udp_right     :udp_message&0x08

    ////////// BIT INPUTS (31 MAXIMUM) ///////////////////////////////////////
    property bool ignition      :inputs&0x01
    property bool battery       :inputs&0x02
    property bool lapmarker     :inputs&0x04
    property bool rearfog       :inputs&0x08
    property bool mainbeam      :inputs&0x10
    property bool up_joystick   :inputs&0x20 || root.udp_up
    property bool leftindicator :inputs&0x40
    property bool rightindicator:inputs&0x80
    property bool brake         :inputs&0x100
    property bool oil           :inputs&0x200
    property bool seatbelt      :inputs&0x400
    property bool sidelight     :inputs&0x800
    property bool tripreset     :inputs&0x1000
    property bool down_joystick :inputs&0x2000 || root.udp_down
    property bool doorswitch    :inputs&0x4000
    property bool airbag        :inputs&0x8000
    property bool tc            :inputs&0x10000
    property bool abs           :inputs&0x20000
    property bool mil           :inputs&0x40000
    property bool shift1_id     :inputs&0x80000
    property bool shift2_id     :inputs&0x100000
    property bool shift3_id     :inputs&0x200000
    property bool service_id    :inputs&0x400000
    property bool race_id       :inputs&0x800000
    property bool sport_id      :inputs&0x1000000
    property bool cruise_id     :inputs&0x2000000
    property bool reverse       :inputs&0x4000000
    property bool handbrake     :inputs&0x8000000
    property bool tc_off        :inputs&0x10000000
    property bool left_joy      :inputs&0x20000000 || root.udp_left
    property bool right_joy     :inputs&0x40000000 || root.udp_right

    ////////// ODOMETER VARIABLES (NON-VOLATILE STORAGE) /////////////////////
    property int odometer: rpmtest.odometer0data
    property int tripmeter: rpmtest.tripmileage0data
    property real odopixelsize: 36

    ////////// RPM VARIABLES /////////////////////////////////////////////////
    property real rpm: rpmtest.rpmdata
    property bool cranking : (root.rpm > 500)

    property real rpmlimit: 0
    onRpmlimitChanged: redline.requestPaint()

    property real shiftvalue: 0
    property real rpmdamping: 5
    property real rpmscaling: 0

    property int rpmcalc: Math.round((((((watertempf - 32) + ((oiltempf - 118) * 2)) / 300) * 6700) + 2500) / 100, 0) * 100;

    property int rpmredline: {
        if (rpmlimit === 0){
            if (rpmcalc > 8600)
                8600
            else if (rpmcalc < 2500)
                2500
            else
                rpmcalc
        }
        else
            rpmlimit
    }
    onRpmredlineChanged: redline.requestPaint()

    property int rpmshiftvalue : (shiftvalue === 0) ? ((rpmredline < 8250) ? rpmredline + 50 : 8250) : shiftvalue;

    ////////// SPEED VARIABLES ///////////////////////////////////////////////
    property real   speed: rpmtest.speeddata
    property int    speedunits: 1
    property int    speedvalue : (root.speedunits === 0) ? speed : (speed / 1.609)

    ////////// GAUGE SLIDER VARIABLES ////////////////////////////////////////
    property int    gaugemax: 170   // 135-182 is valid range
    property int    gaugeopen: 0
    property int    gaugeoffset: (gaugemax - gaugeopen);
    property bool   gaugevisibility: (gaugeopen > 40)
    property real   gaugeopacity: (gaugeopen > (gaugemax / 2)) ? ((gaugeopen - (gaugemax / 2)) / (gaugemax / 2)) : 0

    ////////// COOLANT VARIABLES /////////////////////////////////////////////
    property real   watertemp: rpmtest.watertempdata
    property real   waterhigh: 0
    property real   waterlow: 0
    property real   waterunits: 0
    property int    watertempf: ((watertemp * 9/5)+32) * gaugeopacity
    property bool   waterwarning : (waterhigh === 0 && watertempf > 212) || (waterhigh > 0 && watertempf >= waterhigh)

    ////////// FUEL VARIABLES ////////////////////////////////////////////////
    property real   fuel: rpmtest.fueldata;
    property real   fuelhigh: 0 // if fuelhigh = 0 then icons will be displayed
    property real   fuellow: 0
    property real   fuelunits
    property real   fueldamping: 5
    property real   fuellevel : (fuel * gaugeopacity)
    property bool   fuelwarning : (fuellow === 0 && fuellevel < 20) || (fuellevel <= fuellow)

                    // car stalls out at 7% fuel which is 0 range
    property real   rangefuel : (fuellevel > 6) ? ((fuellevel - 6) / 100) : 0 

                    // range calculation assumes (240 miles) with FULL tank and (165 miles) remaining when fuel drops below 100% fuel indicated
    property real   rangecalc : (fuellevel >= 100) ? (240 - tripmeter) : (rangefuel * 165)

    ////////// OIL VARIABLES /////////////////////////////////////////////////
    property real   oiltemp: rpmtest.oiltempdata
    property real   oiltemphigh: 0
    property real   oiltemplow: 0
    property real   oiltempunits: 0
    property int    oiltempf: ((oiltemp * 9 / 5) + 32) * gaugeopacity
    property bool   oiltempwarning : (oiltemphigh === 0 && oiltempf > 225) || (oiltemphigh > 0 && oiltempf >= oiltemphigh)

    property real   oilpressure: rpmtest.oilpressuredata
    property real   oilpressurehigh: root.oilpressurehigh
    property real   oilpressurelow: root.oilpressurelow
    property real   oilpressureunits: root.oilpressureunits
    property real   oilpress : (oilpressure > 0) ? oilpressure : 0
    property real   oilpresskpa : oilpress * 100
    property real   oilpresspsi : oilpress * 14.503
    property bool   oilpresswarning : (root.oil || (cranking && ((oilpressureunits === 0 && oilpresspsi < oilpressurelow) || (oilpressureunits === 1 && oilpresskpa < oilpressurelow))))

    ////////// BATTERY VARIABLES /////////////////////////////////////////////
    property real   batteryvoltage: rpmtest.batteryvoltagedata
    property real   batterylow: 0

    ////////// AIRFLOW VARIABLES /////////////////////////////////////////////
    property real   o2: rpmtest.o2data
    property real   afrlow: 0
    property real   afrhigh: 0
    property real   map: rpmtest.mapdata
    property real   maf: rpmtest.mafdata

    ////////// DISPLAY MODE CONTROL /////////////////////////////////////////
    property int    displayMode: 1 // 0 fadeIn logo, 1 dashboard (expand/run/contract), 2 fadeOut dashboard
    property bool   fadeIn: root.ignition && (displayMode === 0)
    property bool   isOpening: root.ignition && showDashboard && (root.gaugeopen >= 0) && (root.gaugeopen < root.gaugemax)
    property bool   showDashboard: (displayMode > 0)
    property bool   isClosing: (!root.ignition) && showDashboard && (root.gaugeopen >= 0)
    property bool   fadeOut: (!root.ignition) && (displayMode === 2)
    property bool   showIcons : showDashboard && (fuelhigh == 0)
    property real   rpmToUse : (isClosing) ? 0 : root.rpm
    
    ////////// TRANSAXLE GEAR VARIABLES //////////////////////////////////////
    property real   gearpos: rpmtest.geardata
    property string gearinfo: switch (gearpos) {
        case 0: return "N";
        case 1: return "1";
        case 2: return "2";
        case 3: return "3";
        case 4: return "4";
        case 5: return "5";
        case 6: return "6";
        case 7: return "7";
        case 8: return "8";
        case 9: return "P";
        case 10: return "R";
        default: return ""; // this will be neutral (not calculated)
        // 100 is the value that says do not display gear position
    }

    ////////// GAUGE DIGITS 0-10 POINT LOCATIONS /////////////////////////////
    property var digitList: [
        { x: 204, y: 393 }, // 0
        { x: 114, y: 370 }, // 1
        { x:  54, y: 307 }, // 2
        { x:  30, y: 217 }, // 3
        { x:  54, y: 131 }, // 4
        { x: 119, y:  71 }, // 5
        { x: 206, y:  47 }, // 6
        { x: 290, y:  71 }, // 7
        { x: 355, y: 131 }, // 8
        { x: 382, y: 217 }, // 9
        { x: 357, y: 307 }  // 10
    ]

    ////////// LOTUS LOGO ////////////////////////////////////////////////////
    Image {
        id: lotus_logo
        x: 0
        y: 0
        z: -300
        width: 800
        height: 480
        fillMode: Image.PreserveAspectCrop
        rotation: 0
        source: "assets/lotus_logo.png"
        opacity: 0
        visible: fadeIn

        SequentialAnimation on opacity {
            loops: 1
            running: (fadeIn)
            PropertyAnimation { to: 1; duration: 3000 }
            PauseAnimation { duration: 2000 }
            PropertyAnimation { to: 0; duration: 1000 }
            onStopped: {
                if (root.ignition) { // ignition still on
                    lotus_logo.opacity = 0
                    center_dial.visible = true
                    center_dial.opacity = 1
                    displayMode = 1 // logo is done, next stage
                }
                else { // turned off ignition during animation
                    center_dial.visible = false
                    center_dial.opacity = 1
                    displayMode = 0
                    lotus_logo.opacity = 0
                }
            }
        }    
    }

    ////////// CENTER DIAL ///////////////////////////////////////////////////
    Item{
        id: center_dial
        x: 180

        // OPEN GAUGES ON IGNITION START
        Timer{
            id: gaugeopen_timer
            interval: 30
            repeat: true
            running: isOpening

            onTriggered: if (showDashboard) {
                gaugeclose_timer.stop();

                if (root.ignition) {
                    root.gaugeopen += 3;
                }
            }
        }

        // CLOSE GAUGES ON IGNITION STOP
        Timer{
            id: gaugeclose_timer
            interval: 30
            repeat: true
            running: isClosing

            onTriggered: if (!root.ignition && root.gaugeopen >= 0) {
                root.gaugeopen = (root.gaugeopen > 0) ? root.gaugeopen - 3 : 0

                if (root.gaugeopen <= 0)
                    displayMode = 2;
            }
        }

        // fadeout sequence
        SequentialAnimation on opacity {
            loops: 1
            running: (fadeOut)
            PropertyAnimation { to: 0; duration: 1000 }
            onStopped: {
                center_dial.visible = false
                center_dial.opacity = 1
                displayMode = 0
                lotus_logo.opacity = 0
            }
        }    

        Image {
            id: rpm_needle
            x: 207
            y: 283
            z: 5
            width: 24
            height: 1
            scale: 1
            smooth: true
            fillMode: Image.Stretch
            antialiasing: true
            rotation: 0
            source: "assets/new_needle.png"
            visible: false
            opacity: 1

            property real rpm_mathed:(rpmToUse * 0.03)
            property real needlefollower:rpmshadowneedleRotation.angle

            onNeedlefollowerChanged: rever.requestPaint()

            Timer{
                id: grow
                interval: 50
                repeat: true

                running: if (parent.height < root.gaugemax && rpmToUse > 100) true;
                    else false

                onTriggered: if (rpmToUse > 100) {
                    parent.height += 20
                    shrink.stop()
                }
            }

            Timer{
                id: shrink
                interval: 50
                repeat: true

                running: if (parent.height > 0 && rpmToUse < 100) true;
                    else false

                onTriggered:parent.height -= 5
            }
        }

        ////////// RPM NEEDLE SHADOW EFFECT //////////////////////////////////
        DropShadow {
            id: rpm_needle_shadow
            anchors.fill: rpm_needle
            anchors.rightMargin: 0
            anchors.bottomMargin: 12
            anchors.leftMargin: 1
            anchors.topMargin: -12
            samples: 8
            fast:true
            color: "#90000000"
            radius: 4.0
            antialiasing: true
            cached: false
            source: rpm_needle
            z: 5
            visible: showDashboard

            horizontalOffset: if (rpmshadowneedleRotation.angle < 180)
                -15 + (rpmshadowneedleRotation.angle / 7);
            else 
                37 - (rpmshadowneedleRotation.angle / 7)
           
            transform: Rotation {
                id: rpmshadowneedleRotation
                origin.x: 12;
                origin.y: -30
                angle: Math.min(Math.max(0, (rpm_needle.rpm_mathed)), 360)

                Behavior on angle {
                    SpringAnimation {
                        spring: 2.0 // 1.6
                        damping: 0.25 // 0.25
                    }
                }
            }
        }

        ////////// RPM NEEDLE SHADOW EFFECT END //////////////////////////////
        Canvas {
            id: rever
            x: 0
            y: 0
            z: -3
            width: 500;
            height: 500
            antialiasing: true;
            smooth: true;
            opacity:0.8
            visible: showDashboard && (!isClosing) && (!fadeOut)

            property real angle: (root.settings2 * 40 * 0.03)
            property string colour: (root.rpm >= root.rpmshiftvalue) ? "red" : "#8B8B94"

            onPaint: {
                var ctx = getContext("2d")
                ctx.clearRect(0,0,root.width, root.height);
                ctx.lineWidth = 60
                ctx.strokeStyle = rever.colour
                ctx.beginPath()
                ctx.arc(220, 243, 170, 1.55, (rpmshadowneedleRotation.angle / 57) + 1.55, false)
                ctx.stroke()
                ctx.closePath()
            }
        }

        ////////// DYNAMIC REDLINE ///////////////////////////////////////////
        Canvas {
            id: redline
            x: 0
            y: 0
            z: -4
            width: 500;
            height: 500;
            antialiasing: true;
            smooth: true;
            opacity:1
            visible: (cranking) && (!isClosing) && (!fadeOut);

            function getValueColor(value) {
                var minValue = 2500;
                var maxValue = 8500;
                value = Math.max(minValue, Math.min(maxValue, value));
                var proportion = (value - minValue) / (maxValue - minValue);
                var r = Math.floor(255 - (255 * proportion));
                var rHex = r.toString(16).toUpperCase();
                if (rHex.length < 2) rHex = "0" + rHex;
                return "#FF" + rHex + "00";
            }

            property real angle: (root.rpmredline*0.0298)

            property string arcColor: getValueColor(root.rpmredline)

            onPaint: {
                var ctx = getContext("2d")
                ctx.clearRect(0, 0, root.width, root.height)
                ctx.lineWidth = 60
                ctx.strokeStyle = arcColor // Use dynamically calculated color instead of "red"
                ctx.beginPath()
                ctx.arc(220, 243, 170, (redline.angle / 57) + 1.55, (299 / 57) + 1.55, false)
                ctx.stroke()
                ctx.closePath()
            }            
        }

        ////////// LFA BACKGROUND ////////////////////////////////////////////
        Image {
            id: lfa_ring
            x: -16
            y: 4
            z: -10
            source: "assets/lfa_ring.png"
            visible: showDashboard
        }

        Image {
            id: white_indent
            x: 13
            y: 34
            z: 4
            smooth: false
            source: "assets/white_indents_0_0.png"
            visible: showDashboard            
        }

        Image {
            id: bezel
            x: 26
            y: 48
            z: -4
            smooth: true
            source: "assets/bezel_gray_0_0_.png"
            visible: showDashboard            
        }

        Image {
            id: blackcentre
            x: 0
            y: 0
            z: 0
            source: "assets/black_centre_0_0.png"
            scale: 1.4
            visible: showDashboard            

            Timer{
                interval: 50
                repeat: true

                running: if (parent.scale > 1 && root.rpm > 500) true;
                    else if (parent.scale < 1.4 && root.rpm < 500) true;
                    else false
                
                onTriggered: if (root.rpm > 500) parent.scale -= 0.04;
                    else if(root.rpm < 500) parent.scale += 0.04
            }
        }

        ////////// LEFT GAUGE SLIDER /////////////////////////////////////////
        Image {
            id: left_gauges
            x: 8 - root.gaugeopen
            y: 54
            z: -12
            width: 122
            height: 380
            source: "assets/left_gauges.png"
            visible: showDashboard            
        }

        ////////// RIGHT GAUGE SLIDER ////////////////////////////////////////
        Image {
            id: right_gauges
            x: 311 + root.gaugeopen
            y: 54
            z: -12
            width: 122
            height: 380
            source: "assets/right_gauges.png"
            visible: showDashboard            
        }

        ////////// TURN INDICATORS ///////////////////////////////////////////
        Image {
            id: left_indicator
            x: -172
            y: 37
            z: 40
            width: 42
            height: 44
            source: "assets/left_indicator.png"
            visible: showDashboard && root.leftindicator
        }

        Image {
            id: right_indicator
            x: 572
            y: 37
            z: 40
            width: 42
            height: 44
            source: "assets/right_indicator.png"
            visible: showDashboard && root.rightindicator
        }

        ////////// LOWER LEFT WARNING INDICATORS /////////////////////////////
        Image {
            id: seatbelt_warning
            x: -178
            y: 385
            z: 3
            width: 40
            height: 45
            fillMode: Image.PreserveAspectCrop
            rotation: 0
            source: "assets/seatbelt_warning.png"
            visible: showIcons && root.seatbelt
        }

        Image {
            id: door_open
            x: -175
            y: 430
            z: 3
            width: 27
            height: 40
            fillMode: Image.PreserveAspectCrop
            rotation: 0
            source: "assets/door_open.png"
            visible: showIcons && root.doorswitch
        }

        Image {
            id: brake_warning
            x: -137
            y: 450
            z: 3
            width: 51
            height: 17
            fillMode: Image.PreserveAspectCrop
            rotation: 0
            source: "assets/brake_warning.png"
            visible: showIcons && (root.brake | root.handbrake)
        }

        ////////// LOWER RIGHT WARNING INDICATORS /////////////////////////////
        Image {
            id: airbag_warning
            x: 574
            y: 391
            z: 3
            width: 48
            height: 41
            fillMode: Image.PreserveAspectCrop
            rotation: 0
            source: "assets/airbag_warning.png"
            visible: showIcons && root.airbag
        }

        Image {
            id: battery_warning
            x: 525
            y: 440
            z: 3
            width: 40
            height: 30
            fillMode: Image.PreserveAspectCrop
            rotation: 0
            source: "assets/battery_warning.png"
            visible: showIcons && root.battery
        }

        Image {
            id: abs_warning
            x: 562
            y: 430
            z: 3
            width: 64
            height: 52
            fillMode: Image.PreserveAspectCrop
            rotation: 0
            source: "assets/abs_warning.png"
            visible: showIcons && root.abs
        }

        ////////// INSIDE GAUGE INDICATORS /////////////////////////////
        Image {
            id: high_beam
            x: 200
            y: 102
            z: 3
            width: 39
            height: 28
            fillMode: Image.PreserveAspectCrop
            rotation: 0
            source: "assets/high_beam.png"
            visible: showDashboard && root.mainbeam
        }

        Image {
            id: mil_warning
            x: 200
            y: 349
            z: 3
            width: 40
            height: 30
            fillMode: Image.PreserveAspectCrop
            rotation: 0
            source: "assets/mil_warning.png"
            visible: showIcons && root.mil
        }

        ////////// SPEED & GEAR SELECTION GAUGES /////////////////////////////
        Text {
            id: speedmph
            x: 144
            y: 120
            z: 6
            width: 150
            height: 50 
            color: "#ffffff"
            text: (isClosing)? "0" : speedvalue.toFixed(0)
            style: Text.Outline
            horizontalAlignment: Text.AlignHCenter
            font.family: gauge_font.name
            font.pixelSize: root.odopixelsize * 1.75
            font.bold: true
            visible: showDashboard
        }

        Text {
            id: mphlabel
            x: 211
            y: 193
            z: 6
            width: 15
            height: 33
            color: "#cfcfcf"
            text: (root.speedunits === 0) ? "KPH" : "MPH"
            style: Text.Outline
            horizontalAlignment: Text.AlignHCenter
            font.family: gauge_font.name
            font.pixelSize: root.odopixelsize / 2
            font.bold: true
            visible: showDashboard
        }

        Rectangle {
            x: 144
            y: 220
            z: 6
            width: 150
            height: 2
            color: "#5f5f5f"
            radius: 0
            border.color: "#5f5f5f"
            border.width: 0
            visible: showDashboard
        }

        Text {
            id: gearlabel
            x: 211
            y: 209
            z: 6
            width: 15
            height: 33
            color: "#ffffff"
            text: (!isClosing) ? root.gearinfo : ""
            style: Text.Outline
            horizontalAlignment: Text.AlignHCenter
            font.family: gauge_font.name
            font.pixelSize: root.odopixelsize * 1.5
            font.bold: true
            visible: showDashboard && (root.gearpos > 0)
        }

        ////////// TRIP & RANGE DISPLAYS /////////////////////////////////////
        Text {
            id: triplabel
            x: (root.speedunits === 0) ? 192 : 181
            y: 288
            z: 6
            width: 15
            height: 33
            color: "#cfcfcf"
            text: "TRIP"
            style: Text.Outline
            horizontalAlignment: Text.AlignRight
            font.family: gauge_font.name
            font.pixelSize: root.odopixelsize / 2
            font.bold: false
            visible: showDashboard
        }

        Text {
            id: trip
            x: (root.speedunits === 0) ? 283 : 290
            y: 288
            z: 6
            width: 15
            height: 33
            color: "#cfcfcf"
            text: root.tripmeter.toFixed(1) + ((root.speedunits === 0) ? " km" : " miles")
            style: Text.Outline
            horizontalAlignment: Text.AlignRight
            font.family: gauge_font.name
            font.pixelSize: root.odopixelsize / 2
            font.bold: false
            visible: showDashboard
        }

        Text {
            id: rangelabel
            x: (root.speedunits === 0) ? 192 : 181
            y: 310
            z: 6
            width: 15
            height: 33
            color: "#cfcfcf"
            text: "RANGE"
            style: Text.Outline
            horizontalAlignment: Text.AlignRight
            font.family: gauge_font.name
            font.pixelSize: root.odopixelsize / 2
            font.bold: false
            visible: showDashboard
        }

        Text {
            id: range
            x: (root.speedunits === 0) ? 283 : 290
            y: 310
            z: 6
            width: 15
            height: 33
            color: (root.fuelwarning) ? ((root.rangecalc < 1) ? "red" : "#ffcf00") : "#cfcfcf"
            text: root.rangecalc.toFixed(1) + ((root.speedunits === 0) ? " km" : " miles")
            style: Text.Outline
            horizontalAlignment: Text.AlignRight
            font.family: gauge_font.name
            font.pixelSize: root.odopixelsize / 2
            font.bold: false
            visible: showDashboard
        }

        ////////// RPM TEXT //////////////////////////////////////////////////
        Text {
            id: rpmlabel1
            x: 259
            y: 402
            z: 50
            width: 15
            height: 33
            color: "#cfcfcf"
            text: "x1000"
            style: Text.Outline
            horizontalAlignment: Text.AlignRight
            font.family: gauge_font.name
            font.pixelSize: root.odopixelsize / 3
            font.bold: false
            visible: showDashboard
        }

        Text {
            id: rpmlabel2
            x: 257
            y: 413
            z: 50
            width: 15
            height: 33
            color: "#cfcfcf"
            text: "r/min"
            style: Text.Outline
            horizontalAlignment: Text.AlignRight
            font.family: gauge_font.name
            font.pixelSize: root.odopixelsize / 3
            font.bold: false
            visible: showDashboard
        }

        ////////// COOLANT INDICATORS ////////////////////////////////////////
        Image {
            id: coolant_temp_warning
            x: (95 - root.gaugemax) + root.gaugeoffset
            y: 147
            z: -11
            width: 33
            height: 24
            source: "assets/coolant_temp_warning.png"
            visible: root.gaugevisibility && root.waterwarning
            opacity: root.gaugeopacity
        }

        Rectangle {
            id: water_temp_rect
            x: (15 - root.gaugemax) + root.gaugeoffset
            y: if (root.waterunits !== 0) {
                    if (root.watertemp > 120)
                        59
                    else if (root.watertemp < 80)
                        240
                    else
                        240 - ((root.watertemp - 67) * 3.33)
                }
                else {
                    if (root.watertempf >= 240)
                        59
                    else if (root.watertempf < 120)
                        240
                    else
                        240 - ((root.watertempf - 90) * 1.2)
                }
            z: -50
            width: 86
            height: 205 - y
            radius: 0
            border.width: 0
            visible: root.gaugevisibility
            opacity: root.gaugeopacity

            SequentialAnimation {
                id: waterwarning_animation
                loops: Animation.Infinite
                running: false

                PropertyAnimation {
                    target: water_temp_rect
                    property: "color"
                    from: "red"
                    to: "#3f0000"
                    duration: 250
                }

                PropertyAnimation {
                    target: water_temp_rect
                    property: "color"
                    from: "#3f0000"
                    to: "red"
                    duration: 125
                }
            }

            property int waterTemp: (root.watertempf)
            onWaterTempChanged: {
                if (root.waterwarning) {
                    waterwarning_animation.restart()
                } else {
                    waterwarning_animation.stop()
                    color = ((root.watertempf < 180) ? "#00ffff" : "#e3eef6")
                }
            }
        }

        Text {
            id: coolant_temp
            x: (104 - root.gaugemax) + root.gaugeoffset
            y: 171
            z: -11
            width: 15
            height: 33
            color: (root.waterwarning) ? "red" : "#e3eef6"
            text: (root.waterunits !== 0) ? root.watertemp.toFixed(0) + " °C" : root.watertempf + " °F" 
            style: Text.Outline
            horizontalAlignment: Text.AlignHCenter
            font.family: gauge_font.name
            font.pixelSize: root.odopixelsize / 2.5
            font.bold: false
            visible: root.gaugevisibility
            opacity: root.gaugeopacity
        }

        Text {
            id: coolant_temp_upper_label
            x: (121 - root.gaugemax) + root.gaugeoffset
            y: 49
            z: 60
            width: 15
            height: 33
            color: "#dfdfdf"
            text: (root.waterunits !== 0) ? "120" : "240"
            style: Text.Outline
            horizontalAlignment: Text.AlignRight
            font.family: gauge_font.name
            font.pixelSize: root.odopixelsize / 2.75
            font.bold: false
            visible: root.gaugevisibility
            opacity: root.gaugeopacity
        }

        Text {
            id: coolant_temp_middle_label
            x: (70 - root.gaugemax) + root.gaugeoffset
            y: 121
            z: 60
            width: 15
            height: 33
            color: "#dfdfdf"
            text: (root.waterunits !== 0) ? "100" : "180"
            style: Text.Outline
            horizontalAlignment: Text.AlignRight
            font.family: gauge_font.name
            font.pixelSize: root.odopixelsize / 2.75
            font.bold: false
            visible: root.gaugevisibility
            opacity: root.gaugeopacity
        }

        Text {
            id: coolant_temp_lower_label
            x: (44 - root.gaugemax) + root.gaugeoffset
            y: 195
            z: 60
            width: 15
            height: 33
            color: "#dfdfdf"
            text: (root.waterunits !== 0) ? "80" : "120"
            style: Text.Outline
            horizontalAlignment: Text.AlignRight
            font.family: gauge_font.name
            font.pixelSize: root.odopixelsize / 2.75
            font.bold: false
            visible: root.gaugevisibility
            opacity: root.gaugeopacity
        }

        ////////// ODOMETER INDICATOR ////////////////////////////////////////
        Text {
            id: odometer_display
            x: (6 - root.gaugemax) + root.gaugeoffset
            y: 229 
            z: 60
            width: 15
            height: 33
            color: "#afafaf"
            text: root.odometer.toFixed(0) + ((root.speedunits === 0) ? " KM" : " MI")
            style: Text.Outline
            horizontalAlignment: Text.AlignLeft
            font.family: gauge_font.name
            font.bold: false
            font.pixelSize: root.odopixelsize / 1.75
            visible: root.gaugevisibility
            opacity: root.gaugeopacity
        }

        ////////// FUEL INDICATOR ////////////////////////////////////////////
        Image {
            id: fuel_level_warning
            x: (90 - root.gaugemax) + root.gaugeoffset
            y: 306
            z: -11
            width: 35
            height: 27
            source: "assets/fuel_level_warning.png"
            visible: root.gaugevisibility && root.fuelwarning
            opacity: root.gaugeopacity
        }

        Rectangle {
            x: (15 - root.gaugemax) + root.gaugeoffset
            y: ((100 - root.fuellevel) * 1.45) + 283
            z: -50
            width: 86
            height: 429 - y
            color: (root.fuelwarning) ? "red" : "#e3eef6"
            radius: 0
            border.width: 0
            visible: root.gaugevisibility
            opacity: root.gaugeopacity
        }

        Text {
            id: fuel_level
            x: (102 - root.gaugemax) + root.gaugeoffset
            y: 331
            z: -11
            width: 15
            height: 33
            color: (root.fuelwarning) ? "red" : "#dfdfdf"
            text: root.fuellevel.toFixed(0) + "%"
            style: Text.Outline
            horizontalAlignment: Text.AlignHCenter
            font.family: gauge_font.name
            font.pixelSize: root.odopixelsize / 2.5
            font.bold: false
            visible: root.gaugevisibility
            opacity: root.gaugeopacity
        }

        Text {
            id: fuel_level_full_label
            x: (38 - root.gaugemax) + root.gaugeoffset
            y: 272
            z: 60
            width: 15
            height: 33
            color: "#dfdfdf"
            text: "F"
            style: Text.Outline
            font.family: gauge_font.name
            font.pixelSize: root.odopixelsize / 2.25
            font.bold: false
            horizontalAlignment: Text.AlignLeft
            visible: root.gaugevisibility
            opacity: root.gaugeopacity
        }

        Text {
            id: fuel_level_empty_label
            x: (115 - root.gaugemax) + root.gaugeoffset
            y: 417
            z: 60
            width: 15
            height: 33
            color: "#dfdfdf"
            text: "E"
            style: Text.Outline
            font.family: gauge_font.name
            font.pixelSize: root.odopixelsize / 2.25
            font.bold: false
            horizontalAlignment: Text.AlignLeft
            visible: root.gaugevisibility
            opacity: root.gaugeopacity
        }

        ////////// OIL TEMPERATURE INDICATOR /////////////////////////////////
        Image {
            id: oil_temperature_warning
            x: (311 + root.gaugemax) - root.gaugeoffset
            y: 147
            z: -11
            width: 40
            height: 28
            source: "assets/oil_temperature_warning.png"
            visible: root.gaugevisibility && root.oiltempwarning
            opacity: root.gaugeopacity
        }

        Rectangle {
            id: oil_temp_rect
            x: (340 + root.gaugemax) - root.gaugeoffset
            y: if (root.oiltempunits !== 0) {
                    if (root.oiltemp > 130)
                        59
                    else if (root.oiltemp < 50)
                        205
                    else
                        205 - ((root.oiltemp - 50) * 1.8125)
                }
                else {
                    if (root.oiltempf >= 240)
                        59
                    else if (root.oiltempf < 120)
                        240
                    else
                        240 - ((root.oiltempf - 90) * 1.2)
                }
            z: -50
            width: 86
            height: 205 - y
            radius: 0
            border.width: 0
            visible: root.gaugevisibility
            opacity: root.gaugeopacity

            SequentialAnimation {
                id: oilwarning_animation
                loops: Animation.Infinite
                running: false

                PropertyAnimation {
                    target: oil_temp_rect
                    property: "color"
                    from: "red"
                    to: "#3f0000"
                    duration: 250
                }

                PropertyAnimation {
                    target: oil_temp_rect
                    property: "color"
                    from: "#3f0000"
                    to: "red"
                    duration: 125
                }
            }

            property int oilTemp: (root.oiltempf)
            onOilTempChanged: {
                if (root.oiltempwarning) {
                    oilwarning_animation.restart()
                } else {
                    oilwarning_animation.stop()
                    color = ((root.oiltempf < 180) ? "#00ffff" : "#e3eef6")
                }
            }
        }

        Text {
            id: oil_temperature
            x: (322 + root.gaugemax) - root.gaugeoffset
            y: 171
            z: -11
            width: 15
            height: 33
            color: (root.oiltempwarning) ? "red" : "#e3eef6"
            text: (root.oiltempunits !== 0) ? root.oiltemp.toFixed(0) + " °C" : root.oiltempf + " °F"
            style: Text.Outline
            horizontalAlignment: Text.AlignHCenter
            font.family: gauge_font.name
            font.pixelSize: root.odopixelsize / 2.5
            font.bold: false
            visible: root.gaugevisibility
            opacity: root.gaugeopacity
        }

        Text {
            id: oil_temperature_upper_label
            x: (315 + root.gaugemax) - root.gaugeoffset
            y: 49
            z: 60
            width: 15
            height: 33
            color: "#dfdfdf"
            text: (root.oiltempunits !== 0) ? "130" : "240"
            style: Text.Outline
            horizontalAlignment: Text.AlignRight
            font.family: gauge_font.name
            font.pixelSize: root.odopixelsize / 2.75
            font.bold: false
            visible: root.gaugevisibility
            opacity: root.gaugeopacity
        }

        Text {
            id: oil_temperature_middle_label
            x: (365 + root.gaugemax) - root.gaugeoffset
            y: 121
            z: 60
            width: 15
            height: 33
            color: "#dfdfdf"
            text: (root.oiltempunits !== 0) ? "90" : "180"
            style: Text.Outline
            horizontalAlignment: Text.AlignRight
            font.family: gauge_font.name
            font.pixelSize: root.odopixelsize / 2.75
            font.bold: false
            visible: root.gaugevisibility
            opacity: root.gaugeopacity
        }

        Text {
            id: oil_temperature_lower_level
            x: (392 + root.gaugemax) - root.gaugeoffset
            y: 195
            z: 60
            width: 15
            height: 33
            color: "#dfdfdf"
            text: (root.oiltempunits !== 0) ? "50" : "120"
            style: Text.Outline
            horizontalAlignment: Text.AlignRight
            font.family: gauge_font.name
            font.pixelSize: root.odopixelsize / 2.75
            font.bold: false
            visible: root.gaugevisibility
            opacity: root.gaugeopacity
        }

        ////////// RPM INDICATOR /////////////////////////////////////////////
        Text {
            id: rpm_display
            x: (418 + root.gaugemax) - gaugeoffset
            y: 229
            z: 60
            width: 15
            height: 33
            color: "#afafaf"
            text: rpmToUse + "  RPM"
            style: Text.Outline
            horizontalAlignment: Text.AlignRight
            font.family: gauge_font.name
            font.pixelSize: root.odopixelsize / 1.75
            font.bold: false
            visible: root.gaugevisibility
            opacity: root.gaugeopacity
        }

        ////////// OIL PRESSURE INDICATOR ////////////////////////////////////
        Image {
            id: oil_pressure_warning
            x: (311 + root.gaugemax) - root.gaugeoffset
            y: 314
            z: -11
            width: 41
            height: 19
            source: "assets/oil_pressure_warning.png"
            visible: root.gaugevisibility && root.oilpresswarning
            opacity: root.gaugeopacity
        }

        Rectangle {
            x: (340 + root.gaugemax) - root.gaugeoffset
            y: if (root.oilpressureunits !== 0) {
                    if (root.oilpresskpa > 800)
                        283
                    else if (root.oilpresskpa < 0)
                        429
                    else
                        ((800 - root.oilpresskpa) / 5.517241) + 283
                }
                else {
                    if (root.oilpresspsi > 100)
                        283
                    else if (root.oilpresspsi < 0)
                        429
                    else
                        ((100 - root.oilpresspsi) * 1.47) + 283
                }
            z: -50
            width: 86
            height: 429 - y
            color: (root.oilpresswarning) ? "red" : "#e3eef6"
            radius: 0
            border.width: 0
            visible: root.gaugevisibility
            opacity: root.gaugeopacity
        }

        Text {
            id: oil_pressure
            x: (324 + root.gaugemax) - root.gaugeoffset
            y: 331
            z: -11
            width: 15
            height: 33
            color: (root.gaugeopen >= root.gaugemax && root.oilpresswarning) ? "red" : "#dfdfdf"
            text: (root.oilpressureunits !== 0) ? root.oilpresskpa.toFixed(0) + " kPa" : root.oilpresspsi.toFixed(0) + " psi"
            style: Text.Outline
            horizontalAlignment: Text.AlignHCenter
            font.family: gauge_font.name
            font.pixelSize: root.odopixelsize / 2.5
            font.bold: false
            visible: root.gaugevisibility
            opacity: root.gaugeopacity
        }

        Text {
            id: oil_pressure_upper_label
            x: (396 + root.gaugemax) - root.gaugeoffset
            y: 272
            z: 60
            width: 15
            height: 33
            color: "#dfdfdf"
            text: (root.oilpressureunits !== 0) ? "800" : "100"
            style: Text.Outline
            horizontalAlignment: Text.AlignRight
            font.family: gauge_font.name
            font.pixelSize: root.odopixelsize / 2.75
            font.bold: false
            visible: root.gaugevisibility
            opacity: root.gaugeopacity
        }

        Text {
            id: oil_pressure_middle_label
            x: (371 + root.gaugemax) - root.gaugeoffset
            y: 346
            z: 60
            width: 15
            height: 33
            color: "#dfdfdf"
            text: (root.oilpressureunits !== 0) ? "400" : "50"
            style: Text.Outline
            horizontalAlignment: Text.AlignRight
            font.family: gauge_font.name
            font.pixelSize: root.odopixelsize / 2.75
            font.bold: false
            visible: root.gaugevisibility
            opacity: root.gaugeopacity
        }

        Text {
            id: oil_pressure_lower_label
            x: (321 + root.gaugemax) - root.gaugeoffset
            y: 420
            z: 60
            width: 15
            height: 33
            color: "#dfdfdf"
            text: "0"
            style: Text.Outline
            horizontalAlignment: Text.AlignRight
            font.family: gauge_font.name
            font.bold: false
            font.pixelSize: root.odopixelsize / 2.75
            visible: root.gaugevisibility
            opacity: root.gaugeopacity
        }

        ////////// 0-10 GAUGE NUMBERS ////////////////////////////////////////
        Repeater {
            model: digitList.length
            delegate: Text {
                x: digitList[index].x
                y: digitList[index].y
                z: 2
                width: 24
                height: 37
                color: "#ffffff"
                text: index
                style: Text.Outline
                horizontalAlignment: Text.AlignRight
                font.family: gauge_font.name
                font.pixelSize: root.odopixelsize / 1.15
                font.bold: true
                visible: showDashboard            
            }
        }
    }
}
