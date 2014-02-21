package {
	
	import flash.events.*;
	import flash.net.*;
	
	public class SiteManager extends EventDispatcher {
		
		private var _XMLFile		:String;
		private var _XMLData		:XML;
		private var _XMLLoader		:URLLoader;
		
		public static const LOADED	:String = "loaded";
		
		public function SiteManager(d:String) {
			if(d) load(d);
		}
		
		public function load(d:String):void {
			_XMLFile = d;
			if(_XMLFile) {
				loadXML();
			}
		}
		
		private function loadXML():void {
			trace("load: "+_XMLFile);
			_XMLLoader = new URLLoader();
			_XMLLoader.addEventListener(Event.COMPLETE, onXMLLoaded);
			_XMLLoader.load(new URLRequest(_XMLFile))
		}
		
		private function onXMLLoaded(event:Event):void {
			_XMLData = new XML(_XMLLoader.data);
			parseXML();
		}
		
		private function parseXML():void {
			trace("XML loaded");
			dispatchEvent(new Event(SiteManager.LOADED));
		}
	}
	
}