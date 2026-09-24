/****************************************************************************
**  LFA instrument cluster — single-file build for the GARW IC7 (Qt 5.12,
**  800x480). LFA.qml (gauge dial) and LFA_main.qml have been combined into
**  this one component: the gauge is the root, so all of its bindings resolve
**  directly. Config is resolved at startup between /opt/Garw_IC7/screen_configs/
**  LFA_config.txt and /opt/IC7/screen_configs/LFA_config.txt (whichever the unit
**  uses). The settings menu is a D-pad-driven scrolling list
**  (GTDash-style) wired to the LFA settings. Set
**  rpmtest.DISABLE_WARNING_OVERLAY = "YES_WARNINGS_HANDLED_LOCALLY" to hide
**  the bottom-row warning lamps when warnings are handled elsewhere.
****************************************************************************/
import QtQuick 2.3
import FileIO 1.0
import QtGraphicalEffects 1.0
import "assets"

Item {
    id: root

    ////////// FONT //////////////////////////////////////////////////////////
    FontLoader{id:gauge_font; source: "saira.medium.ttf"}

    ////////// MISCELLANEOUS VARIABLES ///////////////////////////////////////
    property int inputs: rpmtest.inputsdata
    property int udp_message: rpmtest.udp_packetdata

    ////////// CONFIG / STATE (merged from LFA_main) //////////////////////////
    property string colorscheme: "green"
    property int    red:   255
    property int    green: 128
    property int    blue:  100
    property real   night_time_hue: 0

    ////////// SETTINGS MENU STATE (GTDash-style menu, adapted to LFA) /////////
    property bool  settings_on_off: false
    property bool  menu_on_off: rpmtest.settings_on_offdata & 0x02
    onSettings_on_offChanged: {
        if (settings_on_off) rpmtest.settings_on_offdata = rpmtest.settings_on_offdata | 0x01
        else                 rpmtest.settings_on_offdata = rpmtest.settings_on_offdata & ~0x01
    }
    property int   sel: 0
    property int   settingsRev: 0
    property bool  pUp: false
    property bool  pDown: false
    property bool  pLeft: false
    property bool  pRight: false
    property int   upHold: 0
    property int   downHold: 0
    property bool  upArmed: false
    property bool  downArmed: false
    property color accent: Qt.rgba(red/255, green/255, blue/255, 1)

    ////////// ECU ASCII STATUS TEXT (CAN canasciidata, ported from GTDash) /////
    // Raw read stays reactive; absent on the host -> "" (line hidden).
    property string canAsciiRaw: rpmtest.canasciidata
    readonly property string canAsciiStr: {
        var src = root.canAsciiRaw;
        if (!src) return "";
        var out = "";
        for (var i = 0; i < src.length; i++) {
            var c = src.charCodeAt(i);
            if (c >= 32 && c < 127) out += src.charAt(i);   // printable ASCII only
        }
        return root.canAsciiCollapse(out.trim());
    }
    function canAsciiSameRotation(a, b) {
        if (a.indexOf(" ") >= 0 || b.indexOf(" ") < 0) return false;
        var x = a.split(" ").join(""), y = b.split(" ").join("");
        if (!x.length || x.length !== y.length || x === y) return false;
        return (x + x).indexOf(y) >= 0;
    }
    function canAsciiSeverity(s) {
        if (!s) return 0;
        return (s.indexOf("FAULT") >= 0 || s === "TPMS") ? 2 : 1;   // 2 = fault, 1 = info
    }
    function canAsciiCollapse(out) {
        if (!out.length) return "";
        var w = out.split(/\s+/);
        if (w.length >= 2) {
            var f = w[0], s = w[1];
            if (f.length < s.length && s.substring(s.length - f.length) === f) w.shift();
        }
        if (w.length >= 2) {
            var e = w[w.length - 1], q = w[w.length - 2];
            if (e.length < q.length && q.substring(0, e.length) === e) w.pop();
        }
        var c = [];
        for (var a = 0; a < w.length; a++)
            if (a === 0 || w[a] !== w[a - 1]) c.push(w[a]);
        var n = c.length;
        for (var pp = 1; pp <= (n >> 1); pp++) {
            if (n % pp !== 0) continue;
            var rep = true;
            for (var j = pp; j < n; j++) { if (c[j] !== c[j - pp]) { rep = false; break; } }
            if (rep) return c.slice(0, pp).join(" ");
        }
        return c.join(" ");
    }

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
    property int odometer: (speedunits==0 ? rpmtest.odometer0data : rpmtest.odometer0data*0.62) / 10
    property int tripmeter: (speedunits==0 ? rpmtest.tripmileage0data : rpmtest.tripmileage0data*0.62) / 10
    property real odopixelsize: 36

    ////////// RPM VARIABLES /////////////////////////////////////////////////
    property real rpm: rpmtest.rpmdata
    property bool cranking : (root.rpm > 500)

    property real rpmlimit: 0
    onRpmlimitChanged: redline.requestPaint()

    property real shiftvalue: 0
    property real rpmdamping: 5

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
    property real   fuel: rpmtest.fueldata
    property real   fuelhigh: 0 // if fuelhigh = 0 then icons will be displayed
    property real   fuellow: 0
    property real   fuelunits
    property real   fueldamping: 5
    // ---- fuel-bar damping (ported from GTDash) -----------------------------
    // Tank fuel sloshes under cornering/braking/hills, so the level is eased
    // toward the live reading with a velocity limit; rapid slosh averages out
    // because the bar can only move so fast. fueldamping 0 = raw/instant,
    // 1 = light (~1-2s settle) ... 9 = heavy (slow ~8-10s glide). Feeds fuellevel.
    readonly property real fuelVel: Math.max(8.0, 75.0 - (fueldamping - 1) * 8.0) // %/sec for damp 1..9
    property real   fuelDisplay: 0
    Behavior on fuelDisplay { SmoothedAnimation { velocity: root.fuelVel } }
    onFuelChanged: fuelDisplay = fuel
    readonly property real fuelSmoothed : (fueldamping <= 0) ? fuel : fuelDisplay
    property real   fuellevel : (fuelSmoothed * gaugeopacity > 100) ? 100 : (fuelSmoothed * gaugeopacity)
    property bool   fuelwarning : (fuellow === 0 && fuellevel < 20) || (fuellevel <= fuellow)

                    // car stalls out at 7% fuel which is 0 range
    property real   rangefuel : (fuellevel > 6) ? ((fuellevel - 6) / 100) : 0 

                    // range calculation assumes (240 miles) with FULL tank and (165 miles) remaining when fuel drops below 100% fuel indicated
    property real   rangecalc : (fuellevel >= 100) ? (240 - tripmeter) : (rangefuel * 165)
    property real   rangecalcText : (rangecalc < 0) ? 0 : rangecalc

    ////////// OIL VARIABLES /////////////////////////////////////////////////
    property real   oiltemp: rpmtest.oiltempdata
    property real   oiltemphigh: 0
    property real   oiltemplow: 0
    property real   oiltempunits: 0
    property int    oiltempf: ((oiltemp * 9 / 5) + 32) * gaugeopacity
    property bool   oiltempwarning : (oiltemphigh === 0 && oiltempf > 240) || (oiltemphigh > 0 && oiltempf >= oiltemphigh)

    property real   oilpressure: rpmtest.oilpressuredata
    property real   oilpressurehigh: root.oilpressurehigh
    property real   oilpressurelow: root.oilpressurelow
    property real   oilpressureunits: root.oilpressureunits
    property real   oilpress : (oilpressure > 0) ? oilpressure : 0
    property real   oilpresskpa : oilpress * 100
    property real   oilpresspsi : oilpress * 14.503
    property bool   oilpresswarning : (root.oil || (cranking && oilpressurelow > 0 && oilpresskpa <= oilpressurelow) || (oilpressurehigh > 0 && oilpresskpa >= oilpressurehigh))   // thresholds stored canonically in kPa

    ////////// DISPLAY MODE CONTROL /////////////////////////////////////////
    property int    displayMode: 1 // 0 fadeIn logo, 1 dashboard (expand/run/contract), 2 fadeOut dashboard
    property bool   showLogoOnStart: true   // SHOW LOGO ON START: play the Lotus logo fade-in on power-up
    property bool   fadeIn: root.ignition && (displayMode === 0)
    property bool   isOpening: root.ignition && showDashboard && (root.gaugeopen >= 0) && (root.gaugeopen < root.gaugemax)
    property bool   showDashboard: (displayMode > 0)
    property bool   isClosing: (!root.ignition) && showDashboard && (root.gaugeopen >= 0)
    property bool   fadeOut: (!root.ignition) && (displayMode === 2)
    // LFA draws its own warning telltales (below). It tells the host firmware to suppress
    // the firmware's OWN built-in warning overlay via DISABLE_WARNING_OVERLAY, which is WRITTEN
    // in Component.onCompleted (matching GTDash). fuelhigh==0 is the WARNING ICONS menu toggle.
    property bool   showIcons : showDashboard && (fuelhigh == 0)
    property real   rpmToUse : (isClosing) ? 0 : root.rpm
    
    ////////// TRANSAXLE GEAR VARIABLES //////////////////////////////////////
    property real   gearpos: rpmtest.geardata
    property string gearinfo: {
        if (reverse) return "R";          // reverse input bit (inputs & 0x4000000) forces R
        switch (gearpos) {
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
        visible: fadeIn && showLogoOnStart

        SequentialAnimation on opacity {
            loops: 1
            running: (fadeIn)
            PropertyAnimation { to: 1; duration: showLogoOnStart ? 3000 : 0 }
            PauseAnimation { duration: showLogoOnStart ? 2000 : 0 }
            PropertyAnimation { to: 0; duration: showLogoOnStart ? 1000 : 0 }
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

                // Needle response driven by RPM DAMPING (0 = snappy/lively .. 10 = heavy/smooth).
                // Higher rpmdamping softens the spring (lower stiffness) and raises the spring
                // damping (less overshoot), so the needle filters RPM flutter at the cost of speed.
                Behavior on angle {
                    SpringAnimation {
                        spring:  Math.max(1.2, 3.5 - root.rpmdamping * 0.23)   // 0 -> 3.5 stiff ... 10 -> 1.2 soft
                        damping: Math.min(1.0, 0.20 + root.rpmdamping * 0.08)  // 0 -> 0.20 lively ... 10 -> 1.0 no overshoot
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
            visible: showDashboard && (cranking) && (!isClosing) && (!fadeOut);

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
            text: root.rangecalcText.toFixed(1) + ((root.speedunits === 0) ? " km" : " miles")
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

            // Idle (non-alarm) color: BLUE below the LOW setting (AUTO->180), WHITE in range.
            // Bound to the live temp and the low setting so it also tracks a settings change.
            readonly property color idleColor: (root.watertempf < (root.waterlow > 0 ? root.waterlow : 180)) ? "#00ffff" : "#e3eef6"
            // Red flash driven off the warning flag directly (robust vs binding-evaluation order).
            property bool waterWarn: root.waterwarning
            onWaterWarnChanged: {
                if (waterWarn) {
                    waterwarning_animation.restart()
                } else {
                    waterwarning_animation.stop()
                    color = idleColor
                }
            }
            onIdleColorChanged: if (!waterWarn) color = idleColor
            Component.onCompleted: { if (waterWarn) waterwarning_animation.restart(); else color = idleColor }
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

            readonly property color idleColor: (root.oiltempf < (root.oiltemplow > 0 ? root.oiltemplow : 180)) ? "#00ffff" : "#e3eef6"
            property bool oilTempWarn: root.oiltempwarning
            onOilTempWarnChanged: {
                if (oilTempWarn) {
                    oilwarning_animation.restart()
                } else {
                    oilwarning_animation.stop()
                    color = idleColor
                }
            }
            onIdleColorChanged: if (!oilTempWarn) color = idleColor
            Component.onCompleted: { if (oilTempWarn) oilwarning_animation.restart(); else color = idleColor }
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
            id: oil_pressure_rect
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
            color: "#e3eef6"
            radius: 0
            border.width: 0
            visible: root.gaugevisibility
            opacity: root.gaugeopacity

            SequentialAnimation {
                id: oilpreswarning_animation
                loops: Animation.Infinite
                running: false

                PropertyAnimation {
                    target: oil_pressure_rect
                    property: "color"
                    from: "red"
                    to: "#3f0000"
                    duration: 250
                }

                PropertyAnimation {
                    target: oil_pressure_rect
                    property: "color"
                    from: "#3f0000"
                    to: "red"
                    duration: 125
                }
            }

            // Drive the flash directly off the warning flag so it fires exactly when the
            // warning toggles (robust against binding-evaluation order, and it also reacts
            // to a threshold change in settings, not only to a live-value change).
            property bool oilPressWarn: root.oilpresswarning
            onOilPressWarnChanged: {
                if (oilPressWarn) {
                    oilpreswarning_animation.restart()
                } else {
                    oilpreswarning_animation.stop()
                    color = "#e3eef6"
                }
            }
            Component.onCompleted: if (oilPressWarn) oilpreswarning_animation.restart()
        }

        Text {
            id: oil_pressure
            x: (324 + root.gaugemax) - root.gaugeoffset
            y: 331
            z: -11
            width: 15
            height: 33
            color: (root.gaugeopen >= root.gaugemax && root.oilpresswarning) ? "red" : "#dfdfdf"
            text: root.oilpressureunits === 1 ? root.oilpress.toFixed(1) + " BAR" : root.oilpressureunits === 2 ? root.oilpresskpa.toFixed(0) + " kPa" : root.oilpresspsi.toFixed(0) + " psi"
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
            text: root.oilpressureunits === 1 ? "8" : root.oilpressureunits === 2 ? "800" : "100"
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
            text: root.oilpressureunits === 1 ? "4" : root.oilpressureunits === 2 ? "400" : "50"
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

    ////////// CONFIG FILE I/O (GTDash-style: resolve between the two IC7 paths) //
    // Some IC7 builds use /opt/Garw_IC7/..., others /opt/IC7/.... cfgPath holds
    // the resolved path; cfgCandidates is the search order (first existing config
    // wins; on a fresh unit the first directory that accepts a write wins).
    property string cfgPath: "/opt/Garw_IC7/screen_configs/LFA_config.txt"
    readonly property var cfgCandidates: [
        "/opt/Garw_IC7/screen_configs/LFA_config.txt",
        "/opt/IC7/screen_configs/LFA_config.txt"
    ]
    FileIO {
        id: config_file
        source: root.cfgPath
        onError: console.log("LFA FileIO: " + msg)
    }

    // IC7 FileIO READ CONTRACT: one line per open, and only the FIRST
    // readopenfile() after each open works (the index selects the line). So to
    // read line i: openforreading(); s = readopenfile(i); close(). Re-open per line.
    function rline(i) {
        var s = "";
        try { config_file.openforreading(); s = config_file.readopenfile(i); config_file.close(); }
        catch (e) { console.log("LFA: read line " + i + " failed (" + e + ")"); }
        return s;
    }
    // Pick the directory that exists on this unit: prefer a candidate that already
    // holds a readable config; else the first whose directory accepts a write;
    // else fall back to the last candidate. Runs once at startup, before loadConfig.
    function resolveCfgPath() {
        var i, s;
        for (i = 0; i < root.cfgCandidates.length; i++) {
            root.cfgPath = root.cfgCandidates[i];
            s = rline(0);
            if (s !== "" && s !== undefined && s !== null) return;   // existing config here
        }
        for (i = 0; i < root.cfgCandidates.length; i++) {
            root.cfgPath = root.cfgCandidates[i];
            saveConfig();                                            // seed defaults
            s = rline(0);
            if (s !== "" && s !== undefined && s !== null) return;   // write stuck -> dir exists
        }
        root.cfgPath = root.cfgCandidates[root.cfgCandidates.length - 1];   // fallback
    }
    // LFA config line order (unchanged from the original LFA_config.txt schema).
    // Returns true if a usable config was read, false if missing/empty.
    function loadConfig() {
        function pI(s, def) { return (s !== "" && s !== undefined && s !== null) ? parseInt(s)   : def; }
        function pF(s, def) { return (s !== "" && s !== undefined && s !== null) ? parseFloat(s) : def; }
        var s0 = rline(0);
        var found = (s0 !== "" && s0 !== undefined && s0 !== null);
        if (!found) return false;
        root.colorscheme       = s0;                              // line 0 (string)
        root.red               = pI(rline(1),  root.red);
        root.green             = pI(rline(2),  root.green);
        root.blue              = pI(rline(3),  root.blue);
        root.waterlow          = pI(rline(4),  root.waterlow);
        root.waterhigh         = pI(rline(5),  root.waterhigh);
        root.waterunits        = pI(rline(6),  root.waterunits);
        root.fuellow           = pI(rline(7),  root.fuellow);
        root.fuelhigh          = pI(rline(8),  root.fuelhigh);
        root.fuelunits         = pI(rline(9),  root.fuelunits);
        root.oiltemplow        = pI(rline(10), root.oiltemplow);
        root.oiltemphigh       = pI(rline(11), root.oiltemphigh);
        root.oiltempunits      = pI(rline(12), root.oiltempunits);
        root.oilpressurelow    = pI(rline(13), root.oilpressurelow);
        root.oilpressurehigh   = pI(rline(14), root.oilpressurehigh);
        root.oilpressureunits  = pI(rline(15), root.oilpressureunits);
        root.speedunits        = pI(rline(16), root.speedunits);
        root.rpmlimit          = pI(rline(17), root.rpmlimit);
        root.shiftvalue        = pI(rline(18), root.shiftvalue);
        root.night_time_hue    = pF(rline(19), root.night_time_hue);
        // lines 20,21 reserved (were batterylow/batteryhigh - removed, unused)
        root.rpmdamping        = pI(rline(22), root.rpmdamping);
        root.fueldamping       = pI(rline(23), root.fueldamping);
        root.showLogoOnStart   = (pI(rline(24), 1) !== 0);
        return found;
    }
    // Write the whole file in a SINGLE writetoopenfile() call (round-trips with
    // the per-line reader above). Same 25-line order as loadConfig.
    function saveConfig() {
        try {
            var vals = [root.colorscheme, root.red, root.green, root.blue,
                        root.waterlow, root.waterhigh, root.waterunits,
                        root.fuellow, root.fuelhigh, root.fuelunits,
                        root.oiltemplow, root.oiltemphigh, root.oiltempunits,
                        root.oilpressurelow, root.oilpressurehigh, root.oilpressureunits,
                        root.speedunits, root.rpmlimit, root.shiftvalue, root.night_time_hue.toFixed(2),
                        "0", "0",                                 // 20,21 reserved (were battery low/high)
                        root.rpmdamping, root.fueldamping,
                        (root.showLogoOnStart ? 1 : 0)];
            var out = "";
            for (var i = 0; i < vals.length; i++) out += String(vals[i]) + "\n";
            config_file.open();
            config_file.writetoopenfile(out);
            config_file.close();
        } catch (e) { console.log("LFA: could not write config (" + e + ")"); }
    }
    Component.onCompleted: {
        // Tell the host firmware that warnings are handled locally so it does NOT draw its own
        // warning-light overlay over the dash (matching GTDash). The property is absent on older
        // firmware / the desktop sim, so the write is guarded with try/catch.
        try { rpmtest.DISABLE_WARNING_OVERLAY = "YES_WARNINGS_HANDLED_LOCALLY"; } catch (e) {}
        resolveCfgPath();                 // pick /opt/Garw_IC7 vs /opt/IC7 (whichever exists)
        if (!loadConfig()) saveConfig();  // fresh unit -> seed defaults so the file exists
        fuelDisplay = fuel;               // start the damped fuel bar at the live level
        displayMode = showLogoOnStart ? 0 : 1;  // arm the logo fade-in (0) so it plays on EVERY power-up
                                                // regardless of ignition timing; or skip to dashboard (1)
    }


    ////////// SETTINGS MENU — model, D-pad nav, hold-to-ramp, overlay /////////
    FontLoader { id: basicfont; source: "basic.ttf" }

    readonly property var items: [
        { k: "red",   label: "RED" },
        { k: "green", label: "GREEN" },
        { k: "blue",  label: "BLUE" },
        { k: "whi",   label: "WATER HIGH" },
        { k: "wlo",   label: "WATER LOW" },
        { k: "wun",   label: "WATER UNIT" },
        { k: "flo",   label: "FUEL LOW" },
        { k: "othi",  label: "OIL TEMP HIGH" },
        { k: "otlo",  label: "OIL TEMP LOW" },
        { k: "otun",  label: "OIL TEMP UNIT" },
        { k: "ophi",  label: "OIL PRESS HIGH" },
        { k: "oplo",  label: "OIL PRESS LOW" },
        { k: "opun",  label: "OIL PRESS UNIT" },
        { k: "speed", label: "SPEED UNIT" },
        { k: "limit", label: "RPM LIMIT" },
        { k: "shift", label: "SHIFT RPM" },
        { k: "rdamp", label: "RPM DAMPING" },
        { k: "fdmp",  label: "FUEL DAMPING" },
        { k: "night", label: "NIGHTLIGHT" },
        { k: "wicon", label: "WARNING ICONS" },
        { k: "logo",  label: "SHOW LOGO" },
        { k: "exit",  label: "EXIT" }
    ]
    readonly property var noRamp: ["wun","otun","opun","speed","rdamp","fdmp","night","wicon","logo","exit"]
    function isRampable(k) { return noRamp.indexOf(k) === -1; }
    function clamp(v, lo, hi) { return Math.max(lo, Math.min(hi, v)); }
    // --- temperature unit helpers -------------------------------------------
    // Coolant / oil-temp thresholds are stored internally in °F (warnings compare in
    // °F and the config persists °F), so the physical threshold never changes when the
    // display unit flips. These make the MENU row temp-aware: show and step the value in
    // whichever unit is selected. 0 stays the "use built-in default" sentinel.
    function f2c(f) { return (f - 32) * 5 / 9; }
    function c2f(c) { return c * 9 / 5 + 32; }
    function tempDisp(fval, isC) {
        if (fval === 0) return "0\u00B0";                                     // 0 = default / auto
        return (isC ? Math.round(f2c(fval)) : Math.round(fval)) + (isC ? "\u00B0C" : "\u00B0F");
    }
    function tempStep(fval, dir, isC) {
        if (!isC) return clamp(fval + dir, 0, 300);                            // step in °F
        var c = (fval === 0) ? 0 : Math.round(f2c(fval));                      // step in °C ...
        c = clamp(c + dir, 0, 150);
        return (c === 0) ? 0 : Math.round(c2f(c));                             // ... stored back as °F
    }

    // --- oil-pressure unit helpers ------------------------------------------
    // Native oilpressuredata is BAR. Thresholds are stored canonically in kPa; the
    // menu shows/steps them in the selected unit (0=PSI, 1=BAR, 2=kPa) and the warning
    // compares physically, so screen and settings always agree. 0 = disabled.
    function kpa2psi(k) { return k * 0.145038; }
    function psi2kpa(p) { return p * 6.894757; }
    function pressDisp(kpaVal, u) {
        if (u === 1) return (kpaVal / 100).toFixed(1) + " BAR";
        if (u === 2) return Math.round(kpaVal) + " kPa";
        return Math.round(kpa2psi(kpaVal)) + " PSI";
    }
    function pressStep(kpaVal, dir, u) {
        if (u === 1) { var b = Math.round((kpaVal / 100 + dir * 0.1) * 10) / 10; return clamp(Math.round(b * 100), 0, 1400); }   // 0.1 BAR
        if (u === 2) return clamp(kpaVal + dir * 5, 0, 1400);                                                                     // 5 kPa
        var p = Math.round(kpa2psi(kpaVal)) + dir; return clamp(Math.round(psi2kpa(p)), 0, 1400);                                 // 1 PSI
    }

    function applyValue(dir) {
        var k = items[sel].k;
        switch (k) {
        case "red":   root.red   = ((root.red   + dir) % 256 + 256) % 256; break;
        case "green": root.green = ((root.green + dir) % 256 + 256) % 256; break;
        case "blue":  root.blue  = ((root.blue  + dir) % 256 + 256) % 256; break;
        case "whi":   root.waterhigh = root.tempStep(root.waterhigh, dir, root.waterunits === 1); break;
        case "wlo":   root.waterlow  = root.tempStep(root.waterlow,  dir, root.waterunits === 1); break;
        case "wun":   root.waterunits = (root.waterunits === 0) ? 1 : 0; break;
        case "wicon": root.fuelhigh = (root.fuelhigh == 0) ? 1 : 0; break;   // fuelhigh is the hide-icons flag: 0 = ON, !=0 = OFF
        case "logo":  root.showLogoOnStart = !root.showLogoOnStart; break;
        case "flo":   root.fuellow  = clamp(root.fuellow  + dir, 0, 100); break;
        case "othi":  root.oiltemphigh = root.tempStep(root.oiltemphigh, dir, root.oiltempunits === 1); break;
        case "otlo":  root.oiltemplow  = root.tempStep(root.oiltemplow,  dir, root.oiltempunits === 1); break;
        case "otun":  root.oiltempunits = (root.oiltempunits === 0) ? 1 : 0; break;
        case "ophi":  root.oilpressurehigh = root.pressStep(root.oilpressurehigh, dir, root.oilpressureunits); break;
        case "oplo":  root.oilpressurelow  = root.pressStep(root.oilpressurelow,  dir, root.oilpressureunits); break;
        case "opun":  root.oilpressureunits = ((root.oilpressureunits + dir) % 3 + 3) % 3; break;
        case "speed": root.speedunits = ((root.speedunits + dir) % 3 + 3) % 3; break;
        case "limit": root.rpmlimit   = ((root.rpmlimit   + dir * 100) % 9100 + 9100) % 9100; break;
        case "shift": root.shiftvalue = ((root.shiftvalue + dir * 100) % 9100 + 9100) % 9100; break;
        case "rdamp": root.rpmdamping = ((root.rpmdamping + dir) % 11 + 11) % 11; break;
        case "fdmp":  root.fueldamping = clamp(root.fueldamping + dir, 0, 9); break;
        case "night": root.night_time_hue = clamp(root.night_time_hue + dir * 0.05, 0, 1); break;
        case "exit":  if (dir > 0) { saveConfig(); closeMenu(); return; } break;
        }
        root.settingsRev += 1;
    }

    function valueText(k) {
        switch (k) {
        case "red":   return String(root.red);
        case "green": return String(root.green);
        case "blue":  return String(root.blue);
        case "whi":   return root.tempDisp(root.waterhigh, root.waterunits === 1);
        case "wlo":   return root.tempDisp(root.waterlow,  root.waterunits === 1);
        case "wun":   return root.waterunits === 1 ? "\u00B0C" : "\u00B0F";
        case "wicon": return root.fuelhigh == 0 ? "ON" : "OFF";
        case "logo":  return root.showLogoOnStart ? "ON" : "OFF";
        case "flo":   return String(Math.round(root.fuellow));
        case "othi":  return root.tempDisp(root.oiltemphigh, root.oiltempunits === 1);
        case "otlo":  return root.tempDisp(root.oiltemplow,  root.oiltempunits === 1);
        case "otun":  return root.oiltempunits === 1 ? "\u00B0C" : "\u00B0F";
        case "ophi":  return root.pressDisp(root.oilpressurehigh, root.oilpressureunits);
        case "oplo":  return root.pressDisp(root.oilpressurelow,  root.oilpressureunits);
        case "opun":  return root.oilpressureunits === 1 ? "BAR" : root.oilpressureunits === 2 ? "kPa" : "PSI";
        case "speed": return root.speedunits === 0 ? "KM/H" : "MPH";
        case "limit": return String(root.rpmlimit);
        case "shift": return String(root.shiftvalue);
        case "rdamp": return String(root.rpmdamping);
        case "fdmp":  return String(Math.round(root.fueldamping));
        case "night": return root.night_time_hue === 0 ? "OFF" : root.night_time_hue.toFixed(2);
        case "exit":  return "SAVE";
        }
        return "";
    }

    function openMenu()  { settings_on_off = true; sel = 0; upArmed = false; downArmed = false; upHold = 0; downHold = 0; }
    function closeMenu() { settings_on_off = false; }
    function moveSel(dir){ sel = ((sel + dir) % items.length + items.length) % items.length; }

    function evalEdges() {
        var u = up_joystick, dn = down_joystick, l = left_joy, r = right_joy;
        if (!settings_on_off) {
            if (u && !pUp && !menu_on_off) openMenu();
        } else {
            if (l && !pLeft)  moveSel(-1);
            if (r && !pRight) moveSel(1);
            if (u && !pUp)   { applyValue(1);  upHold = 0; }
            if (dn && !pDown){ applyValue(-1); downHold = 0; }
        }
        pUp = u; pDown = dn; pLeft = l; pRight = r;
    }
    Connections {
        target: rpmtest
        ignoreUnknownSignals: true
        function onInputsdataChanged()     { root.evalEdges(); }
        function onUdp_packetdataChanged() { root.evalEdges(); }
    }
    Timer { interval: 50; running: true; repeat: true; onTriggered: root.evalEdges() }
    Timer {   // hold-to-ramp for numeric rows (only while the menu is open)
        interval: 90; running: root.settings_on_off; repeat: true
        onTriggered: {
            if (root.settings_on_off && root.isRampable(root.items[root.sel].k)) {
                if (root.up_joystick) {
                    if (root.upArmed) { root.upHold += 1;
                        var ru = Math.max(1, 3 - Math.floor((root.upHold - 2) / 5));
                        if (root.upHold > 2 && root.upHold % ru === 0) root.applyValue(1);
                    }
                } else { root.upArmed = true; root.upHold = 0; }
                if (root.down_joystick) {
                    if (root.downArmed) { root.downHold += 1;
                        var rd = Math.max(1, 3 - Math.floor((root.downHold - 2) / 5));
                        if (root.downHold > 2 && root.downHold % rd === 0) root.applyValue(-1);
                    }
                } else { root.downArmed = true; root.downHold = 0; }
            }
        }
    }

    ////////// SETTINGS OVERLAY: panel + ListView ////////////////////////////
    Item {
        id: menu
        anchors.fill: parent
        z: 100
        visible: root.settings_on_off
        readonly property int visibleRows: 11
        readonly property int rowH: 30

        Rectangle { anchors.fill: parent; color: "#03050c"; opacity: 0.82 }

        Rectangle {
            id: panel
            width: 540; height: 444; anchors.centerIn: parent
            radius: 16; color: "#0a0f1a"; border.color: "#1e2a44"; border.width: 2

            Text {
                text: "LFA SETTINGS"; color: "#ffffff"
                font.pixelSize: 24; font.bold: true; font.family: basicfont.name
                anchors.horizontalCenter: parent.horizontalCenter; y: 14
            }
            Rectangle { x: 40; y: 50; width: parent.width - 80; height: 3; color: root.accent }

            ListView {
                id: menuList
                x: 22; y: 64
                width: parent.width - 44; height: menu.visibleRows * menu.rowH
                clip: true
                interactive: false
                model: root.items
                currentIndex: root.sel
                highlightMoveDuration: 0
                highlightRangeMode: ListView.ApplyRange
                preferredHighlightBegin: 5 * menu.rowH
                preferredHighlightEnd:   6 * menu.rowH
                delegate: Item {
                    id: row
                    width: ListView.view.width; height: menu.rowH
                    property bool current: ListView.isCurrentItem
                    Rectangle {
                        visible: row.current
                        x: 0; y: 3; width: parent.width - 30; height: menu.rowH - 6
                        radius: 7; color: root.accent; opacity: 0.26
                    }
                    Rectangle {
                        visible: row.current
                        x: 0; y: 3; width: 4; height: menu.rowH - 6; color: root.accent
                    }
                    Text {
                        text: modelData.label
                        x: 22; anchors.verticalCenter: parent.verticalCenter
                        color: row.current ? "#ffffff" : "#9fb2d0"
                        font.pixelSize: 18; font.bold: true; font.family: basicfont.name
                    }
                    Text {
                        anchors.right: parent.right; anchors.rightMargin: 34
                        anchors.verticalCenter: parent.verticalCenter
                        text: { var r = root.settingsRev; return root.valueText(modelData.k); }
                        color: row.current ? "#ffffff" : root.accent
                        font.pixelSize: 18; font.bold: true; font.family: basicfont.name
                    }
                }
            }

            Rectangle {
                visible: menuList.contentHeight > menuList.height
                x: parent.width - 26; y: 64; width: 5
                height: menu.visibleRows * menu.rowH
                radius: 2; color: "#1c2740"
                Rectangle {
                    x: 0; width: 5; radius: 2; color: root.accent
                    y: parent.height * menuList.visibleArea.yPosition
                    height: Math.max(24, parent.height * menuList.visibleArea.heightRatio)
                }
            }

            Text {
                text: "L / R  SELECT       U / D  CHANGE"
                color: "#5f6f8a"; font.pixelSize: 13; font.family: basicfont.name
                anchors.horizontalCenter: parent.horizontalCenter
                y: parent.height - 28
            }
        }
    }

    ////////// ECU ASCII STATUS LINE (settle / dwell / TPMS-fault suppression) //
    Text {
        id: canAsciiText
        z: 50
        property string pending: root.canAsciiStr
        property int  canAsciiPairs: 0
        property bool canAsciiAwaitFault: false
        property bool canAsciiInFault: false
        property bool canAsciiHushed: false
        readonly property int canAsciiSuppressAfter: 5
        readonly property int canAsciiDwellMs: 900
        onPendingChanged: canAsciiSettle.restart()
        visible: text.length > 0 && root.showDashboard
        text: ""
        x: 104; y: 450                       // just right of the BRAKE telltale (right edge ~94), aligned to it
        width: 560; height: 18
        horizontalAlignment: Text.AlignLeft; verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
        color: "#ffcf6b"
        font.family: basicfont.name; font.bold: true; font.pixelSize: 16
        Timer {
            id: canAsciiSettle
            interval: 120; repeat: false
            onTriggered: {
                var c = canAsciiText.pending;
                if (!c) {
                    canAsciiClearTimer.restart();
                } else {
                    var show = c;
                    if (c === "TPMS") {
                        if (canAsciiText.canAsciiSuppressAfter > 0
                            && canAsciiText.canAsciiPairs >= canAsciiText.canAsciiSuppressAfter)
                            canAsciiText.canAsciiHushed = true;
                        canAsciiText.canAsciiAwaitFault = true;
                        canAsciiText.canAsciiInFault = true;
                        if (canAsciiText.canAsciiHushed) show = "";
                    } else if (c === "FAULT") {
                        if (canAsciiText.canAsciiAwaitFault) {
                            canAsciiText.canAsciiAwaitFault = false;
                            if (!canAsciiText.canAsciiHushed) canAsciiText.canAsciiPairs += 1;
                        }
                        if (canAsciiText.canAsciiHushed && canAsciiText.canAsciiInFault) show = "";
                    } else {
                        canAsciiText.canAsciiAwaitFault = false;
                        canAsciiText.canAsciiInFault = false;
                    }
                    if (show && canAsciiText.text && show !== canAsciiText.text
                        && root.canAsciiSameRotation(show, canAsciiText.text)) show = canAsciiText.text;
                    if (show && canAsciiText.text && show !== canAsciiText.text
                        && root.canAsciiSeverity(show) !== 2 && canAsciiDwell.running)
                        return;
                    canAsciiClearTimer.stop();
                    if (show !== canAsciiText.text) {
                        canAsciiText.text = show;
                        if (show) canAsciiDwell.restart(); else canAsciiDwell.stop();
                    }
                }
            }
        }
        Timer {
            id: canAsciiClearTimer
            interval: 3000; repeat: false
            onTriggered: { canAsciiText.text = ""; canAsciiText.canAsciiAwaitFault = false; canAsciiText.canAsciiInFault = false; }
        }
        Timer {
            id: canAsciiDwell
            interval: canAsciiText.canAsciiDwellMs; repeat: false
            onTriggered: canAsciiSettle.restart()
        }
    }

    ////////// BLACK BACKGROUND ///////////////////////////////////////////////
    Rectangle { id: bg_rect; x: 0; y: 0; width: 800; height: 480; color: "#000000"; z: -1000 }  // backdrop: must sit BEHIND the lotus_logo (z:-300)

}
