//http://www.wiili.org/forum/5dof-tracking-(using-sensor-bar)-t1180.html

// My best IR Mouse Script, with 5DOF Tracking
// By Carl Kenner

// Change these values:
var SensorBarSeparation = 7.5 inches  // distance between middles of two sensor bar dots
var NoYawAllowed = true  // Calculates X if no yaw is allowed, otherwise calculates Yaw but not X
var IRMulX = 1.2
var IRMulY = 1.2
var IROffsetX = 0  // add to mouse.x
var IROffsetY = 0  // add to mouse.y
var IRLeftButton = Wiimote.A
var IRRightButton = Wiimote.B


// Compensate for roll
var c = cos(Smooth(wiimote.roll, 10))
var s = sin(Smooth(wiimote.roll, 10))
if (wiimote.dot1vis) {
  var dot1x = c*(511.5-wiimote.dot1x)/511.5 - s*(wiimote.dot1y-383.5)/511.5
  var dot1y = s*(511.5-wiimote.dot1x)/511.5 + c*(wiimote.dot1y-383.5)/511.5
}
if (wiimote.dot2vis) {
  var dot2x = c*(511.5-wiimote.dot2x)/511.5 - s*(wiimote.dot2y-383.5)/511.5
  var dot2y = s*(511.5-wiimote.dot2x)/511.5 + c*(wiimote.dot2y-383.5)/511.5
}

// if both dots are visible check which is which && how far apart
if (wiimote.dot1vis && wiimote.dot2vis){
  if (dot1x <= dot2x){
    var leftdot = 1
    var dotdeltay = dot2y - dot1y
  } else {
    var leftdot = 2
    var dotdeltay = dot1y - dot2y
  }
  var dotdeltax = abs(dot1x-dot2x)
  var DotSep = hypot(dotdeltax, dotdeltay) * 511.5
  var IRDistance = SensorBarSeparation * 1320 / DotSep
}

// sort out the position of the left && right dots
if (leftdot = 1) {
  if (wiimote.dot1vis && wiimote.dot2vis) {
    var LeftDotX = dot1x
    var LeftDotY = dot1y
    var LeftDotVis = true
    var RightDotX = dot2x
    var RightDotY = dot2y
    var RightDotVis = true
  } else if (wiimote.dot1vis) {
    if (hypot(leftdotx- dot1x,var leftdoty- dot1y) <= hypot(rightdotx- dot1x,var rightdoty- dot1y)) {
      // is the real dot 1
      var LeftDotX = dot1x
      var LeftDotY = dot1y
      var RightDotX = dot1x + var dotdeltax
      var RightDotY = dot1y + var dotdeltay
      var LeftDotVis = true
      var RightDotVis = false
	} else{
      // was originally dot 2, but now called dot 1.
      var leftdot = 2 // this dot (1) is actually the right dot
      var LeftDotX = dot1x - var dotdeltax
      var LeftDotY = dot1y - var dotdeltay
      var RightDotX = dot1x
      var RightDotY = dot1y
      var RightDotVis = true
      var LeftDotVis = false
    }
  } else if (wiimote.dot2vis) {
    var LeftDotX = dot2x - var dotdeltax
    var LeftDotY = dot2y - var dotdeltay
    var RightDotX = dot2x
    var RightDotY = dot2y
    var RightDotVis = true
    var LeftDotVis = false
  }
} else if (leftdot = 2) {
  if (wiimote.dot1vis && wiimote.dot2vis) {
    var LeftDotX = dot2x
    var LeftDotY = dot2y
    var LeftDotVis = true
    var RightDotX = dot1x
    var RightDotY = dot1y
    var RightDotVis = true
  } else if (wiimote.dot1vis) {
    if (hypot(leftdotx- dot1x,var leftdoty- dot1y) <= hypot(rightdotx- dot1x,var rightdoty- dot1y)) {
      var leftdot = 1 // dot 1 is now the left dot
      var LeftDotX = dot1x
      var LeftDotY = dot1y
      var RightDotX = dot1x + var dotdeltax
      var RightDotY = dot1y + var dotdeltay
      var LeftDotVis = true
      var RightDotVis = false
	} else {
      // the real dot 1 (on the right)
      var LeftDotX = dot1x - var dotdeltax
      var LeftDotY = dot1y - var dotdeltay
      var RightDotX = dot1x
      var RightDotY = dot1y
      var RightDotVis = true
      var LeftDotVis = false
    }
  } else if (wiimote.dot2vis) {
    var RightDotX = dot2x + var dotdeltax
    var RightDotY = dot2y + var dotdeltay
    var LeftDotX = dot2x
    var LeftDotY = dot2y
    var LeftDotVis = true
    var RightDotVis = false
  }
} else {
  var LeftDotX = dot1x
  var LeftDotY = dot1y
  var RightDotX = LeftDotX
  var RightDotY = LeftDotY
  var LeftDotVis = true
  var RightDotVis = true
}


// Find the imaginary middle dot
var MiddleDotX = (leftdotx + rightdotx)/2
var MiddleDotY = (leftdoty +  rightdoty)/2
var MiddleDotVis = wiimote.dot1vis || wiimote.dot2vis

if (MiddleDotVis) {
  var TotalPitch = atan2(511.5- MiddleDotY,1320) + Wiimote.Pitch
  var DotYaw = atan2(-511.5- MiddleDotX,1320) // assume yaw is 0
  var WiimoteYawNoX = atan2(511.5- MiddleDotX,1320)
  var WiimoteXNoYaw = -sin(dotyaw)- IRDistance
  var WiimoteY = -sin(totalpitch)- IRDistance
  var WiimoteZ = (-sqrt(sqr(IRDistance) - sqr(WiimoteY)))- IRDistance/RemoveUnits(IRDistance)
}

// scale it to the screen range 0 to 1
var IRx = IRMulX- middledotx/2 + 0.5 + IROffsetX
var IRy = IRMulY- middledoty*1023/767/2 + 0.5 +  IROffsetY
var IRvis = wiimote.dot1vis || wiimote.dot2vis
var IROnScreen = 0 <= IRx <= 1  &&  0 <= IRy <= 1

// is it off the screen?
var IRTooFarLeft = IRx < 0 or (IRx < 0.1 && (!IRvis))
var IRTooFarRight = IRx > 1 or (IRx > 1-0.1 && (!IRvis))
var IRTooFarUp = IRy < 0 or (IRy < 0.1 && (!IRvis))
var IRTooFarDown = IRy > 1 or (IRy > 1-0.1 && (!IRvis))

// Heavily smooth small movements, but do zero lag for quick movements
var MoveAmount = 1024*hypot(delta(IRx), delta(IRy))
if (smooth(MoveAmount) > 12) {
  var SmoothX = IRx
  var SmoothY = IRy
  var LastSureFrame = PIE.Frame
} else if ((PIE.frame-LastSureFrame) > 18) {
  var SmoothX = Smooth(IRx, 18, 4/1024)
  var SmoothY = Smooth(IRy, 18, 4/1024)
} else if ((PIE.frame-LastSureFrame) > 14) {
  var SmoothX = Smooth(IRx, 14, 4/1024)
  var SmoothY = Smooth(IRy, 14, 4/1024)
} else if ((PIE.frame-LastSureFrame) > 10) {
  var SmoothX = Smooth(IRx, 10, 4/1024)
  var SmoothY = Smooth(IRy, 10, 4/1024)
} else if ((PIE.frame-LastSureFrame) > 6) {
  var SmoothX = Smooth(IRx, 6, 4/1024)
  var SmoothY = Smooth(IRy, 6, 4/1024)
} else if ((PIE.frame-LastSureFrame) > 2) {
  var SmoothX = Smooth(IRx, 2, 4/1024)
  var SmoothY = Smooth(IRy, 2, 4/1024)
}

// Freeze the mouse cursor while they start pressing the button
// otherwise it will make the cursor jump
var Freeze = (IRLeftButton or var IRRightButton) && KeepDown(pressed(IRLeftButton) or pressed(IRRightButton), 600ms)

// Only change the mouse position if pointing at the screen
// otherwise they can still use a real mouse
if ((IRvis && (!Freeze)) {
  mouse.x = SmoothX
  mouse.y = SmoothY
}

// delay the buttons slightly so we have time to freeze the cursor (is that needed?)
mouse.LeftButton = IRLeftButton && (!KeepDown(pressed(IRLeftButton), 40ms))
mouse.RightButton = IRRightButton && (!KeepDown(pressed(IRRightButton), 40ms))

if (NoYawAllowed) {
  debug = 'X: '- WiimoteXNoYaw+',  Y: '- WiimoteY+',  Z: '- WiimoteZ+',    Yaw: 0,  Pitch: '+Wiimote.Pitch+',  Roll: '+Wiimote.Roll
} else{
  debug = 'X: 0,  Y: '- WiimoteY+',  Z: '- WiimoteZ+',    Yaw: '- WiimoteYawNoX+',  Pitch: '+Wiimote.Pitch+',  Roll: '+Wiimote.Roll
}