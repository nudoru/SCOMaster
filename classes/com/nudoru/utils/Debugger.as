/*
Debug Log class for Ramen
Last updated 11.21.07
*/

package com.nudoru.utils {
	
	import flash.text.TextField;
	
	public class Debugger {
		
		private static var _DebugText	:Array;
		private static var _OutputField	:TextField;
		private static var _Verbose		:Boolean;
		
		public function Debugger() {
			if(!_DebugText) _DebugText = new Array();
			_Verbose = true;
		}
		
		public function addDebugText(txt:String):void {
			_DebugText.push(txt);
			updateOutputField();
			if(_Verbose) trace("# "+txt);
		}
	
		public function setOutputField(f:TextField):void {
			_OutputField = f;
		}
	
		private function updateOutputField():void {
			
			if(!_OutputField) return;
			_OutputField.text = "";
			var len:int = _DebugText.length-1;
			for(var i:int = len; i>0; i--) {
				_OutputField.appendText(_DebugText[i]+"\n");
			}
		}
	
	}
	
}