package wii {
	
	import flash.events.*;
	
	public class WiiMoteButtonEvent extends Event {
		
		public static const PRESSED	:String = "pressed";
		public static const RELEASED:String = "released";
		
		public var buttonName		:String;
		public var wiiMoteIndex		:int;
		
		public function WiiMoteButtonEvent(type:String, bubbles:Boolean=true, cancelable:Boolean=false, bName:String="a", wIdx:int=0):void {
			super(type, bubbles, cancelable);
			buttonName = bName.toLowerCase();
			wiiMoteIndex = wIdx;
		}
		
		public override function clone():Event {
			return new WiiMoteButtonEvent(type, bubbles, cancelable, buttonName, wiiMoteIndex);
		}
		
		public override function toString():String {
			return formatToString("WiiMoteButtonEvent", "type", "bubbles", "cancelable", "eventPhase", "buttonName", "wiiMoteIndex");
		}
		
	}
	
}