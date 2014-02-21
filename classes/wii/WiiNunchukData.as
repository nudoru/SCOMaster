/*
 * Wii Nunchuk Data class
 * By Michael Brooks and Matt Perkins
 * Last updated: 2.29.08
 * 
 * Provides data from a Wiimote instance that is adjusted to fit the requirements of a Flash project:
 * 		radians are converted to degrees
 */

package wii {
	
	import caurina.transitions.PropertyInfoObj;
	import flash.events.*;
	import flash.geom.Point;
	
	import org.wiiflash.*;
	import org.wiiflash.events.WiimoteEvent;

	public class WiiNunchukData extends EventDispatcher {

		/***********************************************************************************************
		VARIABLES
		***********************************************************************************************/
		
		private var TheWiimote			:Wiimote;
		
		// params
		private var WiiNKSensorX		:Number;
		private var WiiNKSensorY		:Number;
		private var WiiNKPitchDeg		:int;
		private var WiiNKRollDeg		:int;
		private var WiiNKYawDeg			:int;
		
		private var WiiNKPitchDegAry	:Array;
		private var WiiNKRollDegAry		:Array;
		private var WiiNKYawDegAry		:Array;
		
		private var WiiNKPitchDegPrev	:int;
		private var WiiNKRollDegPrev	:int;
		private var WiiNKYawDegPrev		:int;
		
		private var WiiNKAnalogX		:Number;
		private var WiiNKAnalogY		:Number;
		private var WiiNKAnalogCompassD	:String;
		
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
		
		public function get isConnected():Boolean {
			return TheWiimote.hasNunchuk;
		}
		
		// orientation of the Nunchuk
		public function get pitch():int {
			return averageIntArray(WiiNKPitchDegAry);
			//return WiiNKPitchDeg
		}
		public function get roll():int {
			return averageIntArray(WiiNKRollDegAry);
			//return WiiNKRollDeg
		}
		public function get yaw():int {
			return averageIntArray(WiiNKYawDegAry);
			//return WiiNKYawDeg
		}
		
		// acceleration of the Nunchuk (shaking or quick swings)
		public function get xaccell():Number { return WiiNKSensorX }
		public function get yaccell():Number { return WiiNKSensorY }
		
		// analog stick
		public function get analogx():Number { return WiiNKAnalogX }
		public function get analogy():Number { return WiiNKAnalogY }
		public function get analogCompassDirection():String { return WiiNKAnalogCompassD }
		
		/***********************************************************************************************
		CONSTRUCTOR
		***********************************************************************************************/
		
		// the stage's width and height must be passed in order for the 'mote to get to correct cursor position
		public function WiiNunchukData(wm:Wiimote, initObj:Object):void {
			TheWiimote = wm;
			
			WiiNKPitchDegAry = new Array();
			WiiNKRollDegAry = new Array();
			WiiNKYawDegAry = new Array();
			
			initEvents();
		}
		
		/***********************************************************************************************
		EVENTS
		***********************************************************************************************/
		
		// register Wiimote events
		public function initEvents():void {
			TheWiimote.addEventListener(WiimoteEvent.UPDATE, updateNunchukData);
		}
		
		private function updateNunchukData(pEvt:WiimoteEvent):void {
			if(!isConnected) return;
			
			WiiNKSensorX = int(TheWiimote.nunchuk.sensorX);
			WiiNKSensorY = int(TheWiimote.nunchuk.sensorY);

			WiiNKAnalogX = roundAnalogData(TheWiimote.nunchuk.stickX);
			WiiNKAnalogY = roundAnalogData(TheWiimote.nunchuk.stickY);
			WiiNKAnalogCompassD = getThumbstickCompass();
			
			/*
			WiiNKPitchDegPrev = WiiNKPitchDeg;
			WiiNKRollDegPrev = WiiNKRollDeg;
			WiiNKYawDegPrev = WiiNKYawDeg;
			
			WiiNKPitchDeg = int(TheWiimote.nunchuk.pitch*TO_DEG);
			WiiNKRollDeg = int(TheWiimote.nunchuk.roll*TO_DEG);
			WiiNKYawDeg = int(TheWiimote.nunchuk.yaw*TO_DEG);

			// helps to remove the wiggle from small hand twitches and other vibrations, need to refactor to optimize for speed
			var pDelta:Number = Math.abs(Math.abs(WiiNKPitchDegPrev) - Math.abs(WiiNKPitchDeg));
			var rDelta:Number = Math.abs(Math.abs(WiiNKRollDegPrev) - Math.abs(WiiNKRollDeg));
			var yDelta:Number = Math.abs(Math.abs(WiiNKYawDegPrev) - Math.abs(WiiNKYawDeg));
			if(pDelta < WIGGLE_TOL) WiiNKPitchDeg = WiiNKPitchDegPrev;
			if(rDelta < WIGGLE_TOL) WiiNKRollDeg = WiiNKRollDegPrev;
			if(yDelta < WIGGLE_TOL) WiiNKYawDeg = WiiNKYawDegPrev;
			*/
			
			WiiNKPitchDegAry = addValueToLimitedArry(WiiNKPitchDegAry, int(TheWiimote.nunchuk.pitch * TO_DEG));
			WiiNKRollDegAry = addValueToLimitedArry(WiiNKRollDegAry, int(TheWiimote.nunchuk.roll * TO_DEG));
			WiiNKYawDegAry = addValueToLimitedArry(WiiNKYawDegAry, int(TheWiimote.nunchuk.yaw * TO_DEG));
			
			dispatchEvent(new Event(WiiControllerData.UPDATED));
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
		
		private function roundAnalogData(n:Number):int {
			n *= 100;
			return int(n*2);
		}

		/***********************************************************************************************
		ANALOG STICK
		***********************************************************************************************/
		
		/*
		 * xidx and yidx form a grid
		 * 
		 *      -2  -1   0   1   2
		 *       |   |   |   |   |
		 * -2 --         n
		 * -1 --    nw       ne
		 *  0 -- w       c       e
		 *  1 --    sw       se
		 *  2 --         s
		 * 
		 */
		
		private function getThumbstickCompass():String {
			var pointSelected:String = "c";
			
			if (withinAnalogTollerance(WiiNKAnalogX, 0) && withinAnalogTollerance(WiiNKAnalogY, 97)) pointSelected = "n";
			if (withinAnalogTollerance(WiiNKAnalogX, 76) && withinAnalogTollerance(WiiNKAnalogY, 72)) pointSelected = "ne";
			if (withinAnalogTollerance(WiiNKAnalogX, 105) && withinAnalogTollerance(WiiNKAnalogY, 0)) pointSelected = "e";
			if (withinAnalogTollerance(WiiNKAnalogX, 76) && withinAnalogTollerance(WiiNKAnalogY, -75)) pointSelected = "se";
			if (withinAnalogTollerance(WiiNKAnalogX, 0) && withinAnalogTollerance(WiiNKAnalogY, -100)) pointSelected = "s";
			if (withinAnalogTollerance(WiiNKAnalogX, -70) && withinAnalogTollerance(WiiNKAnalogY, -75)) pointSelected = "sw";
			if (withinAnalogTollerance(WiiNKAnalogX, -96) && withinAnalogTollerance(WiiNKAnalogY, 0)) pointSelected = "w";
			if (withinAnalogTollerance(WiiNKAnalogX, -70) && withinAnalogTollerance(WiiNKAnalogY, 72)) pointSelected = "nw";
			
			return pointSelected;
		}
		
		private function withinAnalogTollerance(n:int,c:int):Boolean {
			var t = 7;
			if (n > (c - t) && n < (c + t)) return true;
			return false;
		}
		
	}
}