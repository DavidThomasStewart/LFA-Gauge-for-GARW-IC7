import QtQuick 2.3
import QtGraphicalEffects 1.0
import "assets"

Item {
    id: root

    ////////// MISCELLANEOUS VARIABLES ///////////////////////////////////////
    property real indentpixelsize: 45
    property int membank2_byte7: rpmtest.can203data[10];
    property int inputs: rpmtest.inputsdata
    property int fontsmall: 26
    property int fontlarge: 36
    property int udp_message: rpmtest.udp_packetdata
    // onUdp_messageChanged: console.log(" UDP is "+udp_message)

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
    property int odometer: rpmtest.odometer0data/10*0.62 //TODO Hardcoded to mi, need to consider km
    property int tripmeter: rpmtest.tripmileage0data*0.62 //TODO Hardcoded to mi, need to consider km
    property real odopixelsize: 36

    ////////// RPM VARIABLES /////////////////////////////////////////////////
    property real rpm: rpmtest.rpmdata
    onRpmChanged:  if (rpm < 500) blackcentre.scale = 1.4

    property real rpmlimit: 7000
    onRpmlimitChanged: redline.requestPaint()

    property real shiftvalue: 0
    property real rpmdamping: 5
    property real rpmscaling: 0

    ////////// SPEED VARIABLES ///////////////////////////////////////////////
    property real speed: rpmtest.speeddata
    property int speedunits: 1 //TODO: Set to MI for now
    property int mph: (speed * 0.62)

    ////////// GAUGE SLIDER VARIABLES ////////////////////////////////////////
    property int gaugeopen: 0
    property int gaugeoffset: (150 - gaugeopen);
    property bool gaugevisibility: (gaugeopen > 40)
    property real gaugeopacity: (gaugeopen > 75) ? ((gaugeopen - 75) / 75) : 0

    ////////// COOLANT VARIABLES /////////////////////////////////////////////
    property real watertemp: rpmtest.watertempdata
    property real waterhigh: 0
    property real waterlow: 0
    property real waterunits: 0
    property int watertempf: ((watertemp * 9/5)+32) * gaugeopacity

    ////////// FUEL VARIABLES ////////////////////////////////////////////////
    property real fuel: rpmtest.fueldata;
    property real fuelhigh: 0
    property real fuellow: 10
    property real fuelunits
    property real fueldamping: 5
    property real fuellevel : (fuel * gaugeopacity)

    ////////// OIL VARIABLES /////////////////////////////////////////////////
    property real oiltemp: rpmtest.oiltempdata
    property real oiltemphigh: 10
    property real oiltemplow: 90
    property real oiltempunits: 0
    property int oiltempf: ((oiltemp * 9/5) + 32) * gaugeopacity

    property real oilpressure: rpmtest.oilpressuredata
    property real oilpressurehigh: 0
    property real oilpressurelow: 10
    property real oilpressureunits: 0
    property real oilpress : (oilpressure * gaugeopacity)

    ////////// BATTERY VARIABLES /////////////////////////////////////////////
    property real batteryvoltage: rpmtest.batteryvoltagedata
    property real batterylow: 0

    ////////// AITFLOW VARIABLES /////////////////////////////////////////////
    property real o2: rpmtest.o2data
    property real afrlow: 0
    property real afrhigh: 0
    property real map: rpmtest.mapdata
    property real maf: rpmtest.mafdata

    ////////// TRANSAXLE GEAR VARIABLES //////////////////////////////////////
    property real gearpos: rpmtest.geardata
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
        default: return "-"; // 100 is the value that says do not display gear position
    }

    ////////// GAUGE DIGITS 0-10 POINT LOCATIONS /////////////////////////////
    property var digitList: [
        { x: 209, y: 388 },
        { x: 128, y: 365 },
        { x: 69, y: 305 },
        { x: 40, y: 218 },
        { x: 62, y: 130 },
        { x: 125, y: 75 },
        { x: 209, y: 52 },
        { x: 293, y: 75 },
        { x: 353, y: 130 },
        { x: 377, y: 218 },
        { x: 355, y: 305 }
    ]

    ////////// FONT //////////////////////////////////////////////////////////
    FontLoader{id:gauge_font; source: "swiss721.ttf"}

    ////////// CENTER DIAL ///////////////////////////////////////////////////
    Item{
        id: centre_dial
        x: 180

        // OPEN GAUGES ON IGNITION START
        Timer{
            id: gaugeopen_timer
            interval: 20
            repeat: true

            running: if (root.gaugeopen >=0 && root.gaugeopen < 150) true;
                else false

            onTriggered: if (root.ignition) {
                gaugeclose_timer.stop();
                root.gaugeopen += 2;
            }
        }

        // CLOSE GAUGES ON IGNITION STOP
        // TODO: When ignition is turned back after this is closed the gauges are already fully open. Why?
        Timer{
            id: gaugeclose_timer
            interval: 20
            repeat: true

            running: if (root.gaugeopen >= 0) true;
                else false

            onTriggered: if (!root.ignition && root.gaugeopen >= 0) {
                root.gaugeopen = (root.gaugeopen > 0) ? root.gaugeopen - 2 : 0;
                if (root.rpm > 0)
                    root.rpm = 0;
                // TODO: Do we want to do a slow opacity fade of the center gauge here?
            }
        }

        Image {
            id: rpm_needle
            x: 211
            y: 280
            z: 5
            width: 24
            height: 1
            scale: 1
            smooth: true
            fillMode: Image.Stretch
            antialiasing: true
            rotation: 0
            source: "assets/new_needle.png"
            visible:false
            opacity: 1

            property real rpm: root.rpm
            property real rpm_mathed:(rpm*0.03)
            property real needlefollower:rpmshadowneedleRotation.angle

            onNeedlefollowerChanged: rever.requestPaint()

            Timer{
                id: grow
                interval: 50
                repeat: true

                running: if (parent.height < 150 && root.rpm > 100) true;
                    else false

                onTriggered: if (root.rpm > 100) {
                    parent.height += 20
                    shrink.stop()
                }
            }

            Timer{
                id: shrink
                interval: 50
                repeat: true

                running: if (parent.height > 0 && root.rpm < 100) true;
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

            horizontalOffset: if (rpmshadowneedleRotation.angle < 180)
                -15 + (rpmshadowneedleRotation.angle / 7);
            else 
                37 - (rpmshadowneedleRotation.angle / 7)
           
            transform: Rotation {
                id: rpmshadowneedleRotation
                origin.x: 12;
                origin.y: -30
                angle: Math.min(Math.max(0, (rpm_needle.rpm_mathed)), 360) // [needle angle]

                Behavior on angle {
                    SpringAnimation {
                        spring: 1.4
                        damping: 0.16
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

            property real angle: (root.settings2 * 40 * 0.03) // -13.85
            property string colour: if (bezelred.visible) "red"; else if (bezelblue.visible) "blue"; else "white"

            onPaint: {
                var ctx = getContext("2d")
                ctx.clearRect(0,0,root.width, root.height);
                ctx.lineWidth = 60
                ctx.strokeStyle = rever.colour
                ctx.beginPath()
                ctx.arc(220, 243, 170, 1.55, (rpmshadowneedleRotation.angle/57)+1.55, false)
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
            height: 500
            antialiasing: true;
            smooth: true;
            opacity:1

            property real angle: (root.rpmlimit*0.03)//-13.85
            property real lineend: if((root.settings&0x20)==0x20)280;else 299

            onPaint: {
                var ctx = getContext("2d")
                ctx.clearRect(0,0,root.width, root.height);
                ctx.lineWidth = 60
                ctx.strokeStyle = "red"
                ctx.beginPath()
                ctx.arc(220, 243, 170, (redline.angle/57)+1.55, (redline.lineend/57)+1.55, false)
                ctx.stroke()
                ctx.closePath()
            }
        }

        ////////// LFA BACKGROUND ////////////////////////////////////////////
        Image {
            id: lfa_ring
            x: -15
            y: 4
            z: -10
            width: 472
            height: 471
            source: "assets/lfa_ring.png"
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
        }

        ////////// RIGHT GAUGE SLIDER ////////////////////////////////////////
        Image {
            id: right_gauges
            x: 312 + root.gaugeopen
            y: 54
            z: -12
            width: 122
            height: 380
            source: "assets/right_gauges.png"
        }

        ////////// TURN INDICATORS ///////////////////////////////////////////
        Image {
            id: left_indicator
            x: -172
            y: 40
            z: 40
            width: 42
            height: 44
            source: "assets/left_indicator.png"
            visible: (root.leftindicator)
        }

        Image {
            id: right_indicator
            x: 572
            y: 40
            z: 40
            width: 42
            height: 44
            source: "assets/right_indicator.png"
            visible: (root.rightindicator)
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
            visible: root.seatbelt
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
            visible: root.doorswitch
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
            visible: root.brake|root.handbrake 
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
            visible: root.airbag
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
            visible: root.battery
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
            visible: root.abs
        }

        ////////// INSIDE GAUGE INDICATORS /////////////////////////////
        Image {
            id: high_beam
            x: 203
            y: 102
            z: 3
            width: 39
            height: 28
            fillMode: Image.PreserveAspectCrop
            rotation: 0
            source: "assets/high_beam.png"
            visible: root.mainbeam
        }

        Image {
            id: mil_warning
            x: 203
            y: 345
            z: 3
            width: 40
            height: 30
            fillMode: Image.PreserveAspectCrop
            rotation: 0
            source: "assets/mil_warning.png"
            visible: root.mil
        }

        ////////// SPEED GAUGE ///////////////////////////////////////////////
        Text {
            id: speedmph
            x: 148
            y: 119
            z: 50
            width: 150
            height: 50 
            color: "#ffffff"
            text: if (root.speedunits === 0){
                    root.speed.toFixed(0)
                }
                else{
                    root.mph.toFixed(0)
                }
            style: Text.Outline
            horizontalAlignment: Text.AlignHCenter
            font.family: gauge_font.name
            font.pixelSize: root.odopixelsize * 1.6
            font.bold: true
        }

        Text {
            id: mphlabel
            x: 215
            y: 183
            z: 50
            width: 15
            height: 33
            color: "#cfcfcf"
            text: if (root.speedunits === 0){
                    "KPH"
                }
                else{
                    "MPH"
                }
            style: Text.Outline
            horizontalAlignment: Text.AlignHCenter
            font.family: gauge_font.name
            font.pixelSize: root.odopixelsize / 2
            font.bold: true
        }

        Rectangle {
            x: 150
            y: 211
            z: 50
            width: 150
            height: 3
            color: "#5f5f5f"
            radius: 0
            border.color: "#5f5f5f"
            border.width: 0
        }

        ////////// GEAR SELECTION GAUGE //////////////////////////////////////
        Text {
            id: gearlabel
            x: 215
            y: 210
            z: 50
            width: 15
            height: 33
            color: "#ffffff"
            text: root.gearinfo
            style: Text.Outline
            horizontalAlignment: Text.AlignHCenter
            font.family: gauge_font.name
            font.pixelSize: root.odopixelsize * 1.4
            font.bold: true
            visible: (root.gearpos > 0) // TODO: When should it be displayed?
        }

        ////////// TRIP DISPLAY //////////////////////////////////////////////
        Text {
            id: triplabel
            x: 193
            y: 285
            z: 50
            width: 15
            height: 33
            color: "#cfcfcf"
            text: "TRIP"
            style: Text.Outline
            horizontalAlignment: Text.AlignRight
            font.family: gauge_font.name
            font.pixelSize: root.odopixelsize / 2
            font.bold: false
        }

        Text {
            id: trip
            x: 240
            y: 285
            z: 50
            width: 15
            height: 33
            color: "#cfcfcf"
            text: if (root.speedunits === 0)
                tripmeter/.62 + " km"
                else if(root.speedunits === 1)
                (tripmeter / 10).toFixed(1) + "  miles"
                else
                tripmeter
            style: Text.Outline
            horizontalAlignment: Text.AlignLeft
            font.family: gauge_font.name
            font.pixelSize: root.odopixelsize / 2
            font.bold: false
        }

        ////////// RANGE DISPLAY /////////////////////////////////////////////
        Text {
            id: rangelabel
            x: 193
            y: 307
            z: 50
            width: 15
            height: 33
            color: "#cfcfcf"
            text: "RANGE"
            style: Text.Outline
            horizontalAlignment: Text.AlignRight
            font.family: gauge_font.name
            font.pixelSize: root.odopixelsize / 2
            font.bold: false
        }

        Text {
            id: range
            x: 240
            y: 307
            z: 50
            width: 15
            height: 33
            color: "#cfcfcf"
            text: if (root.speedunits === 0)
                root.speed.toFixed(0) + " km"
                else if(root.speedunits === 1)
                (mph / 10).toFixed(1) + "  miles"
                else
                root.speed.toFixed(0) // TODO: Hardcoded to speed currently. Do a range calculaion, given odometer reading and fuel level over time...
            style: Text.Outline
            horizontalAlignment: Text.AlignLeft
            font.family: gauge_font.name
            font.pixelSize: root.odopixelsize / 2
            font.bold: false
        }

        ////////// RPM TEXT //////////////////////////////////////////////////
        Text {
            id: rpmlabel1
            x: 268
            y: 398
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
        }

        Text {
            id: rpmlabel2
            x: 268
            y: 416
            z: 50
            width: 15
            height: 33
            color: "#cfcfcf"
            text: "RPM"
            style: Text.Outline
            horizontalAlignment: Text.AlignRight
            font.family: gauge_font.name
            font.pixelSize: root.odopixelsize / 3
            font.bold: false
        }

        ////////// COOLANT INDICATORS ////////////////////////////////////////
        Image {
            id: coolant_temp_warning
            x: -55 + root.gaugeoffset
            y: 147
            z: -11
            width: 33
            height: 24
            source: "assets/coolant_temp_warning.png"
            visible: root.gaugevisibility && (root.watertemp >= 100)
            opacity: root.gaugeopacity
        }

        Rectangle {
            x: -135 + root.gaugeoffset
            y: if (root.waterunits === 0) {
                    if (root.watertemp > 120)
                        60
                    else if (root.watertemp > 80)
                        240 - ((root.watertemp-67)*3.33)
                    else
                        240
                }
                else {
                    if (root.watertempf > 240)
                        60
                    else if (root.watertempf > 120)
                        240 - ((root.watertempf-90)*1.2)
                    else
                        240
                }
            z: -50
            width: 86
            height: 205 - y
            color: "#e3eef6"
            radius: 0
            border.width: 0
            visible: root.gaugevisibility
            opacity: root.gaugeopacity
        }

        Text {
            id: coolant_temp
            x: -45 + root.gaugeoffset
            y: 172
            z: -11
            width: 15
            height: 33
            color: if (root.watertemp >= 100) "#ff0000"; else "#dfdfdf" // TODO: hardcoded
            text: if (root.waterunits === 0)
                        root.watertemp.toFixed(0) + " °C"
                    else
                        root.watertempf + " °F"
            style: Text.Outline
            horizontalAlignment: Text.AlignHCenter
            font.family: gauge_font.name
            font.pixelSize: root.odopixelsize / 3
            font.bold: false
            visible: root.gaugevisibility
            opacity: root.gaugeopacity
        }

        Text {
            id: coolant_temp_upper_label
            x: -30 + root.gaugeoffset
            y: 49
            z: 60
            width: 15
            height: 33
            color: "#dfdfdf"
            text: if (root.waterunits === 0)
                    "120"
                  else
                    "240"
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
            x: -80 + root.gaugeoffset
            y: 121
            z: 60
            width: 15
            height: 33
            color: "#dfdfdf"
            text: if (root.waterunits === 0)
                    "100"
                  else
                    "180"
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
            x: -107 + root.gaugeoffset
            y: 196
            z: 60
            width: 15
            height: 33
            color: "#dfdfdf"
            text: if (root.waterunits === 0)
                    "80"
                  else
                     "120"
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
            x: -144 + root.gaugeoffset
            y: 229 
            z: 60
            width: 15
            height: 33
            color: "#afafaf"
            text: if (root.speedunits === 0)
                (root.odometer).toFixed(0) + " KM"
                else if(root.speedunits === 1)
                root.odometer + " MI"
                else
                root.odometer
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
            x: -60 + root.gaugeoffset
            y: 306
            z: -11
            width: 35
            height: 27
            source: "assets/fuel_level_warning.png"
            visible: root.gaugevisibility && (root.fuellevel < 20)
            opacity: root.gaugeopacity
        }

        Rectangle {
            x: -135 + root.gaugeoffset
            y: ((100 - root.fuellevel) * 1.45) + 282
            z: -50
            width: 86
            height: 429 - y
            color: ((root.fuellevel < root.fuellow) ? "#ff0000" : "#e3eef6")
            radius: 0
            border.width: 0
            visible: root.gaugevisibility
            opacity: root.gaugeopacity
        }

        Text {
            id: fuel_level
            x: -48 + root.gaugeoffset
            y: 332
            z: -11
            width: 15
            height: 33
            color: if (root.fuellevel < 20) "#ff0000"; else "#dfdfdf"
            text: root.fuellevel.toFixed(0) + "%"
            style: Text.Outline
            horizontalAlignment: Text.AlignHCenter
            font.family: gauge_font.name
            font.pixelSize: root.odopixelsize / 3
            font.bold: false
            visible: root.gaugevisibility
            opacity: root.gaugeopacity
        }

        Text {
            id: fuel_level_full_label
            x: -112 + root.gaugeoffset
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
            x: -35 + root.gaugeoffset
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
            x: 462 - root.gaugeoffset
            y: 147
            z: -11
            width: 40
            height: 28
            source: "assets/oil_temperature_warning.png"
            visible: root.gaugevisibility && (root.oiltemp > 100)
            opacity: root.gaugeopacity
        }

        Rectangle {
            x: 491 - root.gaugeoffset
            y: if (root.oiltempunits === 0) {
                    if (root.oiltemp > 120)
                        60
                    else if (root.oiltemp > 80)
                        240 - ((root.oiltemp-67)*3.33)
                    else
                        240            
            }
            else {
                if (root.oiltempf > 240)
                    60
                else if (root.oiltempf > 120)
                    240 - ((root.oiltempf-90)*1.2)
                else
                    240
            }
            z: -50
            width: 86
            height: 205 - y
            color: "#e3eef6"
            radius: 0
            border.width: 0
            visible: root.gaugevisibility
            opacity: root.gaugeopacity
        }

        Text {
            id: oil_temperature
            x: 474 - root.gaugeoffset
            y: 172
            z: -11
            width: 15
            height: 33
            color: if (root.oiltemp >= 100) "#ff0000"; else "#dfdfdf" // TODO: hardcoded
            text: if (root.oiltempunits === 0)
                    root.oiltemp.toFixed(0) + " °C"
                  else
                    root.oiltempf + " °F"
            style: Text.Outline
            horizontalAlignment: Text.AlignHCenter
            font.family: gauge_font.name
            font.pixelSize: root.odopixelsize / 3
            font.bold: false
            visible: root.gaugevisibility
            opacity: root.gaugeopacity
        }

        Text {
            id: oil_temperature_upper_label
            x: 462 - root.gaugeoffset
            y: 49
            z: 60
            width: 15
            height: 33
            color: "#dfdfdf"
            text: if (root.oiltempunits === 0)
                    "120"
                  else
                     "240"
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
            x: 512 - root.gaugeoffset
            y: 121
            z: 60
            width: 15
            height: 33
            color: "#dfdfdf"
            text: if (root.oiltempunits === 0)
                    "100"
                  else
                     "180"
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
            x: 537 - root.gaugeoffset
            y: 196
            z: 60
            width: 15
            height: 33
            color: "#dfdfdf"
            text: if (root.oiltempunits === 0)
                    "80"
                  else
                     "120"
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
            x: 569 - gaugeoffset
            y: 229
            z: 60
            width: 15
            height: 33
            color: "#afafaf"
            text: rpm + "  RPM"
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
            x: 462 - root.gaugeoffset
            y: 314
            z: -11
            width: 41
            height: 19
            source: "assets/oil_pressure_warning.png"
            visible: root.gaugevisibility && (root.oil || (root.oilpress < 1 && root.rpm > 900))
            opacity: root.gaugeopacity
        }

        Rectangle {
            x: 491 - root.gaugeoffset
            y: if (root.oilpressureunits === 0)
                    ((100 - root.oilpress) * 1.45) + 282
                else {
                    if ((root.oilpress*14.504) > 125)
                        282
                    else
                        ((100 - (root.oilpress*14.504)) * 1.45) + 282
                }
            z: -50
            width: 86
            height: 429 - y
            color: ((root.oilpress < 1) ? "#ff0000" : "#e3eef6")
            radius: 0
            border.width: 0
            visible: root.gaugevisibility
            opacity: root.gaugeopacity
        }

        Text {
            id: oil_pressure
            x: 473 - root.gaugeoffset
            y: 332
            z: -11
            width: 15
            height: 33
            color: if ((root.gaugeopen >= 150) && (root.oil || root.oilpress < 1) && (root.rpm > 900)) "#ff0000"; else "#dfdfdf"
            text: if (root.oilpressureunits === 0)
                    root.oilpress.toFixed(1) + " bar"
                  else
                    (root.oilpress*14.504).toFixed(0) + " psi"
            style: Text.Outline
            horizontalAlignment: Text.AlignHCenter
            font.family: gauge_font.name
            font.pixelSize: root.odopixelsize / 3
            font.bold: false
            visible: root.gaugevisibility
            opacity: root.gaugeopacity
        }

        Text {
            id: oil_pressure_upper_label
            x: 537 - root.gaugeoffset
            y: 272
            z: 60
            width: 15
            height: 33
            color: "#dfdfdf"
            text: if (root.oilpressureunits === 0)
                    "100"
                  else
                    "100"
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
            x: 512 - root.gaugeoffset
            y: 346
            z: 60
            width: 15
            height: 33
            color: "#dfdfdf"
            text: if (root.oilpressureunits === 0)
                    "50"
                  else
                    "50"
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
            x: 462 - root.gaugeoffset
            y: 420
            z: 60
            width: 15
            height: 33
            color: "#dfdfdf"
            text: if (root.oilpressureunits === 0)
                    "0"
                  else
                    "0"
            style: Text.Outline
            horizontalAlignment: Text.AlignRight
            font.family: gauge_font.name
            font.bold: false
            font.pixelSize: root.odopixelsize / 2.75
            visible: root.gaugevisibility
            opacity: root.gaugeopacity
        }

        ////////// LFA BACKGROUND ////////////////////////////////////////////
        Image {
            id: bezel
            x: 0
            y: 0
            z: -4
            smooth: true
            source: "assets/bezel_gray_0_0_.png"
        }

        Image {
            id: bezelblue
            x: 0
            y: 0
            z: -3
            smooth: true
            source: "assets/bezel_blue_0_0_.png";
            visible: if((root.symbols&0x08) == 0x08)true;else false
        }

        Image {
            id: bezelred
            x: 0
            y: 0
            z: -2
            smooth: true
            source:"assets/bezel_red_0_0_.png";
            visible: if(root.rpm>(root.settings2*40))true;else false
        }

        Image {
            id: white_indent
            x: 0
            y: 0
            smooth: false
            source: "assets/white_indents_0_0.png"
            z: 4
        }

        Image {
            id: blackcentre
            x: 0
            y: 0
            z: 0
            source: "assets/black_centre_0_0.png"
            scale: 1.4

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
                font.pixelSize: root.odopixelsize
                font.bold: true
            }
        }

        ////////// GAUGE DIAL INDENTS ////////////////////////////////////////
        Image {
            id: white_indent1
            x: 122
            y: 0
            z: 3
            width: 200
            height: 480
            fillMode: Image.PreserveAspectCrop
            rotation: 60
            source: "assets/white_indents_0_0.png"
        }

        Image {
            id: white_indent2
            x: 122
            y: 0
            z: 3
            width: 200
            height: 480
            fillMode: Image.PreserveAspectCrop
            rotation: 90
            source: "assets/white_indents_0_0.png"
            visible: if((root.settings&0x20)==0x20)false;else true
        }
    }
}
