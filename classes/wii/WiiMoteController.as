/*
 * Wii Mote Controller class
 * By Matt Perkins, matthew.perkins@bankofamerica.com
 * Last updated: 6.23.08
 * 
 * TODO:
 * 	enable toggle
 * 		disable virtualmouse
 * 		lower alpha on cursor
 */

package wii {
	
	import com.senocular.ui.VirtualMouse;
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import flash.events.*;
	import flash.geom.Point;
	
	import org.wiiflash.*;
	import org.wiiflash.events.WiimoteEvent;
	import org.wiiflash.events.ButtonEvent;
	
	public class WiiMoteController extends Sprite {

		/***********************************************************************************************
		VARIABLES
		***********************************************************************************************/
		
		private var StageRef			:Sprite;
		
		private var Enabled				:Boolean;
		
		private var IsConnected			:Boolean;
		
		private static var Index		:int;
		
		private var MyIndex				:int;
		
		private var TheWiimote			:Wiimote;
		
		// the 'mote cursor
		private var TheWiiControllerData:WiiControllerData;
		
		// the cursor view
		private var TheCursor			:WiiCursorView;
		
		// the virtual mouse
		private var VMouse				:VirtualMouse;
		
		// the view layers
		private var CursorLayer			:Sprite;
		
		// the nunchuk
		private var TheNunchuk			:WiiNunchukData;
		
		// buttons
		private var LeftClickButtonName	:String = "a";
		private var DoubleClickButtonName:String = "b";
		
		public var isADown				:Boolean = false;
		public var isBDown				:Boolean = false;
		//c and z are on the nunchuk
		public var isCDown				:Boolean = false;
		public var isZDown				:Boolean = false;
		
		// stage props
		private var maxX				:int;
		private var maxY				:int;
		private var centerX				:int;
		private var centerY				:int;
		
		// enable the nunchuk analog stick to function as a button when pressed into a corner
		private var enableNKAnalogBM	:Boolean = true;
		// store the last analog position
		private var lastNunchukAnalogPosition:String = "";
		
		/***********************************************************************************************
		CONSTANTS
		***********************************************************************************************/
		
		public static const CONNECTED		:String = "connected";
		public static const CONNECT_CLOSE	:String = "connect_close";
		public static const CONNECT_ERROR	:String = "connect_error";
		public static const ENABLED			:String = "enabled";
		public static const DISABLED		:String = "disabled";
		public static const DATA_UPDATE		:String = "data_update";
		public static const CLICK			:String = "click";
		public static const DOUBLE_CLICK	:String = "double_click";
		
		/***********************************************************************************************
		PUBLIC GETTERS/SETTERS
		***********************************************************************************************/
		
		// connected successfuly to the WiiMote?
		public function get isConnected():Boolean { return IsConnected }
		
		public function get hasNunchuk():Boolean { return TheWiimote.hasNunchuk }
		
		public function get index():int { return MyIndex }
		
		public function get mBatteryLevel():Number { return TheWiiControllerData.batteryLevel }
		
		// orientation of the WiiMote
		public function get mPitch():int { return TheWiiControllerData.pitch }
		public function get mRoll():int { return TheWiiControllerData.roll }
		public function get mYaw():int { return TheWiiControllerData.yaw }
		
		// acceleration of the WiiMote (shaking or quick swings)
		public function get mXAccell():Number { return TheWiiControllerData.xaccell }
		public function get mYAccell():Number { return TheWiiControllerData.yaccell }
		
		// "cursor" in relation to the IRs on the sensor bar
		public function get mX():int { return TheWiiControllerData.x }
		public function get mY():int { return TheWiiControllerData.y }
		public function get mZ():Number { return TheWiiControllerData.z }
		
		// IR point data
		public function get mIsIR1():Boolean { return TheWiiControllerData.isIR1 }
		public function get mIsIR2():Boolean { return TheWiiControllerData.isIR2 }
		public function get mIsIR3():Boolean { return TheWiiControllerData.isIR3 }
		public function get mIsIR4():Boolean { return TheWiiControllerData.isIR4 }
		
		public function get mIR1Point():Point { return TheWiiControllerData.ir1point }
		public function get mIR2Point():Point { return TheWiiControllerData.ir2point }
		public function get mIR3Point():Point { return TheWiiControllerData.ir3point }
		public function get mIR4Point():Point { return TheWiiControllerData.ir4point }
		
		public function get mIR1Size():Number { return TheWiiControllerData.ir1size }
		public function get mIR2Size():Number { return TheWiiControllerData.ir2size }
		public function get mIR3Size():Number { return TheWiiControllerData.ir3size }
		public function get mIR4Size():Number { return TheWiiControllerData.ir4size }
		
		public function get cursor():Sprite { return TheCursor.cursor }
		public function get cursorPoint():Sprite { return TheCursor.cursorPoint }
		public function get cursorState():String { return TheCursor.state }
		public function set cursorState(s:String) { TheCursor.state = s }
		
		public function get cX():int { return TheCursor.cX }
		public function get cY():int { return TheCursor.cY }
		
		// orientation of the Nunchuk
		public function get nkPitch():int { return TheNunchuk.pitch }
		public function get nkRoll():int { return TheNunchuk.roll }
		public function get nkYaw():int { return TheNunchuk.yaw }
		
		// acceleration of the Nunchuk (shaking or quick swings)
		public function get nkXAccell():Number { return TheNunchuk.xaccell }
		public function get nkYAccell():Number { return TheNunchuk.yaccell }
		
		// analog stick of the Nunchuk
		public function get nkAnalogX():Number { return TheNunchuk.analogx }
		public function get nkAnalogY():Number { return TheNunchuk.analogy }
		public function get nkAnalogCompassDirection():String { return TheNunchuk.analogCompassDirection }
		
		public function get enabled():Boolean { return Enabled; }
		public function set enabled(value:Boolean):void {
			Enabled = value;
			if (Enabled) {
				TheCursor.enable();
				dispatchEvent(new Event(WiiMoteController.ENABLED));
			} else {
				TheCursor.disable();
				dispatchEvent(new Event(WiiMoteController.DISABLED));
			}
		}
		
		/***********************************************************************************************
		CONSTRUCTOR
		***********************************************************************************************/
		
		public function WiiMoteController(s:Sprite, i:int = 0, e:Boolean = true ):void {
			StageRef = s;
			Enabled = e;
			Index++;
			MyIndex = Index;
			
			setStageProps();
			
			IsConnected = false;
			TheWiimote = new Wiimote();
			initWiimoteEvents();
			initWiimoteButtonEvents();
			TheWiimote.connect();
		}
		
		override public function toString():String {
			return "[WiiMoteController idx: "+MyIndex+" ]"
		}
		
		private function setStageProps():void {
			maxX = StageRef.stage.stageWidth;
			maxY = StageRef.stage.stageHeight;
			centerX = maxX >> 1;
			centerY = maxY >> 1;
		}
		
		// called once the 'mote is connected successfully
		private function initialize():void {
			trace("# Initialize controller # " + MyIndex);
			
			CursorLayer = new Sprite();
			CursorLayer.name = "__wiimotecursor" + MyIndex;
			StageRef.addChild(CursorLayer);
			// for the wii mote
			TheWiiControllerData = new WiiControllerData(TheWiimote, {stagewidth:maxX, stageheight:maxY});
			initWiiCursorEvents();
			
			// for the nunchuk
			TheNunchuk = new WiiNunchukData(TheWiimote, {});
			
			// the cursor view
			TheCursor = new WiiCursorView(TheWiiControllerData, CursorLayer, MyIndex);
			// the virtual mouse
			VMouse = new VirtualMouse(StageRef.stage);
			// ignore certain view layers from the vmouse
			ignoreByVMouse(CursorLayer);
			
			this.addEventListener(WiiMoteButtonEvent.PRESSED, buttonPressed);
			this.addEventListener(WiiMoteButtonEvent.RELEASED, buttonReleased);
			
			//cursorState = WiiCursorView.CURSOR_ARROW;
		}
		
		private function initWiiCursorEvents():void {
			TheWiiControllerData.addEventListener(WiiControllerData.UPDATED, onWiiCursorUpdate)
		}
		
		private function onWiiCursorUpdate(e:Event):void {
			updateVirtualMousePosition();
			if(TheNunchuk.isConnected) checkNunchukAnalogPosition();
			dispatchEvent(new Event(WiiMoteController.DATA_UPDATE));
		}
		
		private function buttonPressed(e:WiiMoteButtonEvent):void {
			switch(e.buttonName) {
				case "a":
					isADown = true;
					break;
				case "b":
					isBDown = true;
					break;
				case "c":
					isCDown = true;
					break;
				case "z":
					isZDown = true;
					break;
				default:
					break;
			}
			if (e.buttonName == LeftClickButtonName) {
				dispatchEvent(new Event(WiiMoteController.CLICK));
				VMouse.press();
			} else if (e.buttonName == DoubleClickButtonName) {
				dispatchEvent(new Event(WiiMoteController.DOUBLE_CLICK));
				VMouse.doubleClick();
			}
		}
		
		private function buttonReleased(e:WiiMoteButtonEvent):void {
			switch(e.buttonName) {
				case "a":
					isADown = false;
					break;
				case "b":
					isBDown = false;
					break;
				case "c":
					isCDown = false;
					break;
				case "z":
					isZDown = false;
					break;
				default:
					break;
			}
			if (e.buttonName == LeftClickButtonName) {
				VMouse.release();
			}
		}
		
		// treats the nunchuk's analog controller as a button when pressed into a corner
		private function checkNunchukAnalogPosition():void {
			if (!TheNunchuk.isConnected || !enableNKAnalogBM) return;
			var currentNunchukAnalogPosition:String = TheNunchuk.analogCompassDirection
			// keeps the same event from being repeatedly fired
			if (lastNunchukAnalogPosition == currentNunchukAnalogPosition) return;
			
			// check to broadcast a released event
			if (lastNunchukAnalogPosition && lastNunchukAnalogPosition != "c" && currentNunchukAnalogPosition == "c") {
				dispatchEvent(new WiiMoteButtonEvent(WiiMoteButtonEvent.RELEASED, true, false, "nkanalog_"+lastNunchukAnalogPosition, Index));
			}
			
			// broadcast every position except center, center counts as a relase of the last "press"
			if (currentNunchukAnalogPosition && currentNunchukAnalogPosition != "c") {
				dispatchEvent(new WiiMoteButtonEvent(WiiMoteButtonEvent.PRESSED, true, false, "nkanalog_"+currentNunchukAnalogPosition, Index));
			}

			lastNunchukAnalogPosition = currentNunchukAnalogPosition;
		}
		
		/***********************************************************************************************
		EVENTS
		***********************************************************************************************/

		// register Wiimote button events
		private function initWiimoteEvents():void {
			TheWiimote.addEventListener(Event.CONNECT, onWiimoteConnect);
			TheWiimote.addEventListener(IOErrorEvent.IO_ERROR, onWiimoteConnectError);
			TheWiimote.addEventListener(Event.CLOSE, onWiimoteCloseConnection);
		}
		
		private function onWiimoteConnect (pEvent:Event):void{
			IsConnected = true;
			initialize();
			dispatchEvent(new Event(WiiMoteController.CONNECTED));
		}
		
		private function onWiimoteCloseConnection (pEvent:Event):void {
			dispatchEvent(new Event(WiiMoteController.CONNECT_CLOSE));
		}
		
		private function onWiimoteConnectError (pEvent:*):void {
			dispatchEvent(new Event(WiiMoteController.CONNECT_ERROR));
		}

		/***********************************************************************************************
		METHODS
		***********************************************************************************************/
		
		// updates the position of the virtual mouse based on the current cursor position
		private function updateVirtualMousePosition():void {
			try {
				// the virtual mouse positions is the position of the cursor sprite, not the true X and Y positions.
				// since the cusor sprite has an animated smoothing tween applied, it lags the acutal position by a few pixels
				VMouse.x = cX;
				VMouse.y = cY;
			} catch (e:*) { }
		}
		
		// set a display container to be ignored by any Wii mote's virtual mouse
		public function ignoreByVMouse(d:DisplayObject):void {
			VMouse.ignore(d);
		}
		
		public function unIgnoreByVMouse(d:DisplayObject):void {
			VMouse.unignore(d);
		}
		
		// rumbles the Wii Mote for t seconds
		public function doRumbleSeconds(t:Number):void {
			if(!IsConnected) return;
			TheWiimote.rumbleTimeout = t * 1000;
		}
		
		/***********************************************************************************************
		BUTTON EVENTS
		***********************************************************************************************/
		
		private function initWiimoteButtonEvents():void {
			TheWiimote.addEventListener(ButtonEvent.A_PRESS, onAPressed);
			TheWiimote.addEventListener(ButtonEvent.A_RELEASE, onAReleased);
			TheWiimote.addEventListener(ButtonEvent.LEFT_PRESS, onLeftPressed);
			TheWiimote.addEventListener(ButtonEvent.LEFT_RELEASE, onLeftReleased);
			TheWiimote.addEventListener(ButtonEvent.RIGHT_PRESS, onRightPressed);
			TheWiimote.addEventListener(ButtonEvent.RIGHT_RELEASE, onRightReleased);
			TheWiimote.addEventListener(ButtonEvent.UP_PRESS, onUpPressed);
			TheWiimote.addEventListener(ButtonEvent.UP_RELEASE, onUpReleased);
			TheWiimote.addEventListener(ButtonEvent.DOWN_PRESS, onDownPressed);
			TheWiimote.addEventListener(ButtonEvent.DOWN_RELEASE, onDownReleased);
			TheWiimote.addEventListener(ButtonEvent.B_PRESS, onBPressed);
			TheWiimote.addEventListener(ButtonEvent.B_RELEASE, onBReleased);
			TheWiimote.addEventListener(ButtonEvent.MINUS_PRESS, onMinusPressed);
			TheWiimote.addEventListener(ButtonEvent.MINUS_RELEASE, onMinusReleased);
			TheWiimote.addEventListener(ButtonEvent.PLUS_PRESS, onPlusPressed);
			TheWiimote.addEventListener(ButtonEvent.PLUS_RELEASE, onPlusReleased);
			TheWiimote.addEventListener(ButtonEvent.HOME_PRESS, onHomePressed);
			TheWiimote.addEventListener(ButtonEvent.HOME_RELEASE, onHomeReleased);
			TheWiimote.addEventListener(ButtonEvent.ONE_PRESS, onOnePressed);
			TheWiimote.addEventListener(ButtonEvent.ONE_RELEASE, onOneReleased);
			TheWiimote.addEventListener(ButtonEvent.TWO_PRESS, onTwoPressed);
			TheWiimote.addEventListener(ButtonEvent.TWO_RELEASE, onTwoReleased);
			
			TheWiimote.nunchuk.addEventListener(ButtonEvent.C_PRESS, onCPressed);
			TheWiimote.nunchuk.addEventListener(ButtonEvent.C_RELEASE, onCReleased);
			TheWiimote.nunchuk.addEventListener(ButtonEvent.Z_PRESS, onZPressed);
			TheWiimote.nunchuk.addEventListener(ButtonEvent.Z_RELEASE, onZReleased);
		}
		
		private function onAPressed (pEvt:ButtonEvent):void {
			dispatchEvent(new WiiMoteButtonEvent(WiiMoteButtonEvent.PRESSED, true, false, "a", Index));
		}
		
		private function onAReleased (pEvt:ButtonEvent):void {
			dispatchEvent(new WiiMoteButtonEvent(WiiMoteButtonEvent.RELEASED, true, false, "a", Index));
		}
		
		private function onMinusPressed (pEvt:ButtonEvent):void {
			dispatchEvent(new WiiMoteButtonEvent(WiiMoteButtonEvent.PRESSED, true, false, "minus", Index));
		}
		
		private function onMinusReleased (pEvt:ButtonEvent):void {
			dispatchEvent(new WiiMoteButtonEvent(WiiMoteButtonEvent.RELEASED, true, false, "minus", Index));
		}
		
		private function onPlusPressed (pEvt:ButtonEvent):void {
			dispatchEvent(new WiiMoteButtonEvent(WiiMoteButtonEvent.PRESSED, true, false, "plus", Index));
		}
		
		private function onPlusReleased (pEvt:ButtonEvent):void {
			dispatchEvent(new WiiMoteButtonEvent(WiiMoteButtonEvent.RELEASED, true, false, "plus", Index));
		}
		
		private function onHomePressed (pEvt:ButtonEvent):void {
			dispatchEvent(new WiiMoteButtonEvent(WiiMoteButtonEvent.PRESSED, true, false, "home", Index));
		}
		
		private function onHomeReleased (pEvt:ButtonEvent):void {
			dispatchEvent(new WiiMoteButtonEvent(WiiMoteButtonEvent.RELEASED, true, false, "home", Index));
		}
		
		private function onOnePressed (pEvt:ButtonEvent):void {
			dispatchEvent(new WiiMoteButtonEvent(WiiMoteButtonEvent.PRESSED, true, false, "one", Index));
		}
		
		private function onOneReleased (pEvt:ButtonEvent):void {
			dispatchEvent(new WiiMoteButtonEvent(WiiMoteButtonEvent.RELEASED, true, false, "one", Index));
		}
		
		private function onTwoPressed (pEvt:ButtonEvent):void {
			dispatchEvent(new WiiMoteButtonEvent(WiiMoteButtonEvent.PRESSED, true, false, "two", Index));
		}
		
		private function onTwoReleased (pEvt:ButtonEvent):void {
			dispatchEvent(new WiiMoteButtonEvent(WiiMoteButtonEvent.RELEASED, true, false, "two", Index));
		}
		
		private function onBPressed (pEvt:ButtonEvent):void {
			dispatchEvent(new WiiMoteButtonEvent(WiiMoteButtonEvent.PRESSED, true, false, "b", Index));
		}
		
		private function onBReleased (pEvt:ButtonEvent):void {
			dispatchEvent(new WiiMoteButtonEvent(WiiMoteButtonEvent.RELEASED, true, false, "b", Index));
		}
		
		private function onUpPressed (pEvt:ButtonEvent):void {
			dispatchEvent(new WiiMoteButtonEvent(WiiMoteButtonEvent.PRESSED, true, false, "up", Index));
		}
		
		private function onUpReleased (pEvt:ButtonEvent):void {
			dispatchEvent(new WiiMoteButtonEvent(WiiMoteButtonEvent.RELEASED, true, false, "up", Index));
		}
		
		private function onLeftPressed (pEvt:ButtonEvent):void {
			dispatchEvent(new WiiMoteButtonEvent(WiiMoteButtonEvent.PRESSED, true, false, "left", Index));
		}
		
		private function onLeftReleased (pEvt:ButtonEvent):void {
			dispatchEvent(new WiiMoteButtonEvent(WiiMoteButtonEvent.RELEASED, true, false, "left", Index));
		}
		
		private function onRightPressed (pEvt:ButtonEvent):void{
			dispatchEvent(new WiiMoteButtonEvent(WiiMoteButtonEvent.PRESSED, true, false, "right", Index));
		}
		
		private function onRightReleased (pEvt:ButtonEvent):void{
			dispatchEvent(new WiiMoteButtonEvent(WiiMoteButtonEvent.RELEASED, true, false, "right", Index));
		}
		
		private function onDownPressed (pEvt:ButtonEvent):void {
			dispatchEvent(new WiiMoteButtonEvent(WiiMoteButtonEvent.PRESSED, true, false, "down", Index));
		}
		
		private function onDownReleased (pEvt:ButtonEvent):void {
			dispatchEvent(new WiiMoteButtonEvent(WiiMoteButtonEvent.RELEASED, true, false, "down", Index));
		}
		
		private function onCPressed (pEvt:ButtonEvent):void {
			dispatchEvent(new WiiMoteButtonEvent(WiiMoteButtonEvent.PRESSED, true, false, "c", Index));
		}
		
		private function onCReleased (pEvt:ButtonEvent):void {
			dispatchEvent(new WiiMoteButtonEvent(WiiMoteButtonEvent.RELEASED, true, false, "c", Index));
		}
		
		private function onZPressed (pEvt:ButtonEvent):void {
			dispatchEvent(new WiiMoteButtonEvent(WiiMoteButtonEvent.PRESSED, true, false, "z", Index));
		}
		
		private function onZReleased (pEvt:ButtonEvent):void {
			dispatchEvent(new WiiMoteButtonEvent(WiiMoteButtonEvent.RELEASED, true, false, "z", Index));
		}
		
	}
}