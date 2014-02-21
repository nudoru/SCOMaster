/*
 * Wii Cursor Data class
 * By Matt Perkins, matthew.perkins@bankofamerica.com
 * Portions of code from Andrés Santos, beck@asb-labs.com, www.asb-labs.com
 * Last updated: 6.11.08
 * 
 * Provides data from a Wiimote instance that is adjusted to fit the requirements of a Flash project:
 * 		x and y values are adjusted to the stage size
 * 		radians are converted to degrees
 */

package wii {
	
	import flash.events.*;
	import flash.geom.Point;
	
	import org.wiiflash.*;
	import org.wiiflash.events.WiimoteEvent;

	public class WiiControllerData extends EventDispatcher {

		/***********************************************************************************************
		VARIABLES
		***********************************************************************************************/
		
		private var TheWiimote			:Wiimote;
		
		// params
		private var WiiMSensorX			:Number;
		private var WiiMSensorY			:Number;
		private var WiiMPitchDeg		:int;
		private var WiiMRollDeg			:int;
		private var WiiMYawDeg			:int;
		
		private var WiiMPitchDegPrev	:int;
		private var WiiMRollDegPrev		:int;
		private var WiiMYawDegPrev		:int;
		
		private var WiiMPitchDegAry		:Array;
		private var WiiMRollDegAry		:Array;
		private var WiiMYawDegAry		:Array;
		
		// stage props
		private var StageWidth			:int;
		private var StageHeight			:int;
		
		// 'mote IR sensor props
		private var WiiMCurrentPos		:Point;		// the interpolated middle between the 2 IR sensors
		private var WiiMIR1Point		:Point = new Point(0,0);		// the left IR sensor
		private var WiiMIR2Point		:Point = new Point(0,0);		// the right IR sensor
		
		private var WiiMXAry			:Array;
		private var WiiMYAry			:Array;
		
		private var middleX				:int = 0;	// store the averaged distance between the 2 IR points
		private var middleY				:int = 0;
		
		private var SBSeparation		:Number = 7.5;	// how far apart the IR sensors are
		private var IRDistance			:Number;
		
		
		/***********************************************************************************************
		CONSTANTS
		***********************************************************************************************/
		
		// to convert radians to degrees
		private static const TO_DEG		:Number = 180 / Math.PI;
		// smoothes out roll, pitch and yaw values
		// ignore movements less then X number of degrees
		private static const WIGGLE_TOL	:int = 5;
		// length of the array for data
		private static const DATA_ARRY_LEN:int = 10;
		
		// for events
		public static const UPDATED		:String = "updated";
		
		/***********************************************************************************************
		PUBLIC GETTERS/SETTERS
		***********************************************************************************************/
		
		public function get batteryLevel():Number {
			return TheWiimote.batteryLevel;
		}
		
		// orientation of the WiiMote
		public function get pitch():int {
			return averageIntArray(WiiMPitchDegAry);
			//return WiiMPitchDeg
		}
		public function get roll():int {
			return averageIntArray(WiiMRollDegAry);
			//return WiiMRollDeg
		}
		public function get yaw():int {
			return averageIntArray(WiiMYawDegAry);
			//return WiiMYawDeg
		}
		
		// acceleration of the WiiMote (shaking or quick swings)
		public function get xaccell():Number { return WiiMSensorX }
		public function get yaccell():Number { return WiiMSensorY }
		
		// "cursor" in relation to the IRs on the sensor bar
		public function get x():int { return WiiMCurrentPos.x }
		public function get y():int { return WiiMCurrentPos.y }
		
		// "cursor" in relation to the IRs on the sensor bar
		public function get xa():int { return averageIntArray(WiiMXAry); }
		public function get ya():int { return averageIntArray(WiiMYAry); }
		
		// this isn't yes supported by WiiFlash
		// this "hack" just calculates the distance between the 2 IR sensors
		public function get z():Number {
			// have to some sensor data for this
			if (!WiiMIR1Point && !WiiMIR2Point) return 1;
			var d:Number = 1
			try {
				// in case one of the sensors drop off, not a critical error
				d = Point.distance(WiiMIR1Point, WiiMIR2Point);
				d *= .01;
			} catch (e:*) { }
			return d;
		}
		
		// IR points seen?
		public function get isIR1():Boolean {
			try {
				return TheWiimote.ir.p1;
			} catch (e:*) { }
			return false;
		}
		public function get isIR2():Boolean {
			try {
				return TheWiimote.ir.p2;
			} catch (e:*) { }
			return false;
		}
		public function get isIR3():Boolean {
			try {
				return TheWiimote.ir.p3;
			} catch (e:*) { }
			return false;
		}
		public function get isIR4():Boolean {
			try {
				return TheWiimote.ir.p4;
			} catch (e:*) { }
			return false;
		}
		
		public function get ir1point():Point { 
			// this is set in the update function
			return WiiMIR1Point;
		}
		public function get ir2point():Point { 
			// this is set in the update function
			return WiiMIR2Point;
		}
		public function get ir3point():Point { 
			var x:int = 0, y:int = 0;
			try {
				x = int(StageWidth - (TheWiimote.ir.point3.x * StageWidth));
				y = int(TheWiimote.ir.point3.y * StageHeight);
			} catch (e:*) {
				x = 0;
				y = 0;
			}
			return new Point(x, y);
		}
		public function get ir4point():Point { 
			var x:int = 0, y:int = 0;
			try{
				x = int(StageWidth - (TheWiimote.ir.point3.x * StageWidth));
				y = int(TheWiimote.ir.point3.y * StageHeight);
			} catch (e:*) {
				x = 0;
				y = 0;
			}
			return new Point(x, y);
		}
		public function get ir1size():Number { return TheWiimote.ir.size1 }
		public function get ir2size():Number { return TheWiimote.ir.size2 }
		public function get ir3size():Number { return TheWiimote.ir.size3 }
		public function get ir4size():Number { return TheWiimote.ir.size4 }
		
		/***********************************************************************************************
		CONSTRUCTOR
		***********************************************************************************************/
		
		// the stage's width and height must be passed in order for the 'mote to get to correct cursor position
		public function WiiControllerData(wm:Wiimote, initObj:Object):void {
			TheWiimote = wm;
			
			StageWidth = initObj.stagewidth;
			StageHeight = initObj.stageheight;
			
			WiiMPitchDegAry = new Array();
			WiiMRollDegAry = new Array();
			WiiMYawDegAry = new Array();
			WiiMXAry = new Array();
			WiiMYAry = new Array();
			
			initEvents()
		}
		
		/***********************************************************************************************
		EVENTS
		***********************************************************************************************/
		
		// register Wiimote events
		public function initEvents():void {
			TheWiimote.addEventListener(WiimoteEvent.UPDATE, updateWiiMoteData);
		}
		
		private function updateWiiMoteData(pEvt:WiimoteEvent):void {
			try {
				WiiMSensorX = int(TheWiimote.sensorX);
				WiiMSensorY = int(TheWiimote.sensorY);
			} catch (e:*) {
				trace("WiiMote can't see the IR sensors!");
			}
			/*
			WiiMPitchDegPrev = WiiMPitchDeg;
			WiiMRollDegPrev = WiiMRollDeg;
			WiiMYawDegPrev = WiiMYawDeg;
			
			WiiMPitchDeg = int(TheWiimote.pitch*TO_DEG);
			WiiMRollDeg = int(TheWiimote.roll*TO_DEG);
			WiiMYawDeg = int(TheWiimote.yaw*TO_DEG);

			// helps to remove the wiggle from small hand twitches and other vibrations, need to refactor to optimize for speed
			var pDelta:Number = Math.abs(Math.abs(WiiMPitchDegPrev) - Math.abs(WiiMPitchDeg));
			var rDelta:Number = Math.abs(Math.abs(WiiMRollDegPrev) - Math.abs(WiiMRollDeg));
			var yDelta:Number = Math.abs(Math.abs(WiiMYawDegPrev) - Math.abs(WiiMYawDeg));
			if(pDelta < WIGGLE_TOL) WiiMPitchDeg = WiiMPitchDegPrev;
			if(rDelta < WIGGLE_TOL) WiiMRollDeg = WiiMRollDegPrev;
			if(yDelta < WIGGLE_TOL) WiiMYawDeg = WiiMYawDegPrev;
			*/
			
			WiiMPitchDegAry = addValueToLimitedArry(WiiMPitchDegAry, int(TheWiimote.pitch * TO_DEG));
			WiiMRollDegAry = addValueToLimitedArry(WiiMRollDegAry, int(TheWiimote.roll * TO_DEG));
			WiiMYawDegAry = addValueToLimitedArry(WiiMYawDegAry, int(TheWiimote.yaw * TO_DEG));

			// if we're getting some IR data ...
			if(isIR1 || isIR2) {
				
				/* http://udon.nudoru.com/2008/02/29/wiiflash-tip-2-smoothing-out-the-edges-part-2/#comments
				 if(counter == 10) {
					this.sumRoll *= 0.9
					this.sumRoll = (this.wii.roll Math.PI * 0.5)/Math.PI * this.width
					this.irSpot.x = this.sumRoll * 0.1

					this.sumPitch *= 0.9
					this.sumPitch = (this.wii.pitch Math.PI * 0.5)/Math.PI * this.height
					this.irSpot.y = this.sumPitch * 0.1
					counter = 1
				} else {
					counter++
					this.sumRoll = (this.wii.roll Math.PI * 0.5)/Math.PI * this.width
					this.sumPitch = (this.wii.pitch Math.PI * 0.5)/Math.PI * this.height
				}
				 */ 
				
				// BEGIN modified from code by Andrés Santos
				
				// get the IR values and convert them to match the size of the stage
				var ax:int = int(StageWidth - (TheWiimote.ir.point1.x * StageWidth));
				var ay:int = int(TheWiimote.ir.point1.y * StageHeight);
				var bx:int = int(StageWidth - (TheWiimote.ir.point2.x * StageWidth));
				var by:int = int(TheWiimote.ir.point2.y * StageHeight);
				
				// sort so that IR1 is always on the left
				if(ax < bx) {
					WiiMIR1Point = new Point(ax, ay);
					WiiMIR2Point = new Point(bx, by);
				} else {
					WiiMIR1Point = new Point(bx, by);
					WiiMIR2Point = new Point(ax, ay);
				}
				
				var ir1x:int = WiiMIR1Point.x;
				var ir1y:int = WiiMIR1Point.y
				var ir2x:int = WiiMIR2Point.x;
				var ir2y:int = WiiMIR2Point.y;
				
				var theX:int = 0;
				var theY:int = 0;
				
				// can see both ir's
				if(isIR1 && isIR2) {
					middleX = (Math.max(ir1x, ir2x) - Math.min(ir1x, ir2x)) * .5;
					theX = Math.min(ir1x, ir2x) + (Math.max(ir1x, ir2x) - Math.min(ir1x, ir2x)) * .5;
				} else {
					// only see 1 ir
					if (WiiMCurrentPos.x < Math.max(ir1x, ir2x)) {
						// only see the right one
						theX = Math.max(ir1x, ir2x) - middleX;
					} else {
						// only see the left one
						theX = Math.max(ir1x, ir2x) + middleX;
					}
				}

				if(isIR1 && isIR2) {
					middleY = (Math.max(ir1y, ir2y) - Math.min(ir1y, ir2y)) * .5;
					theY = Math.min(ir1y,ir2y)+(Math.max(ir1y,ir2y)-Math.min(ir1y,ir2y)) * .5;
				} else {
					if (WiiMCurrentPos.y < Math.max(ir1y, ir2y)) {
						theY = Math.max(ir1y, ir2y) - middleY;
					} else {
						theY = Math.max(ir1y, ir2y) + middleY;
					}
				}
				
				// END
				
				WiiMCurrentPos = new Point(theX, theY);
				
				WiiMXAry = addValueToLimitedArry(WiiMXAry, theX);
				WiiMYAry = addValueToLimitedArry(WiiMYAry, theY);
				
				//var dotStep:Number = hypot((ir2x-ir1x), (ir2y-ir2x)) * 511.5;
				//IRDistance = SBSeparation * 1320 / dotStep;
				//trace(IRDistance);
			}
			
			dispatchEvent(new Event(WiiControllerData.UPDATED));
		}
		
		// euclidian distance, hypotenuse of a right angle triangle
		private function hypot(n1, n2):Number {
			return Math.sqrt((n1 * n1) + (n2 * n2));
		}
		
		private function addValueToLimitedArry(a:Array, v:int):Array{
			a.push(v);
			if (a.length > DATA_ARRY_LEN) a.shift();
			return a;
		}
		
		private function averageIntArray(a:Array):int {
			var len:int = a.length;
			var c:int = 0;
			for (var i:int = 0; i < len; i++) {
				c += int(a[i]);
			}
			return int(c / len);
		}
	}
}