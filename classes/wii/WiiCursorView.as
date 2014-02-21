/*
 * Wii Cursor View class
 * By Matt Perkins, matthew.perkins@bankofamerica.com
 * Last updated: 6.26.08
 */

package wii {
	
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.display.Shape;
	
	import com.nudoru.utils.SWFLoader;
	//import caurina.transitions.Tweener;
	//import fl.motion.easing.*;
	//import com.greensock.*;
	
	public class WiiCursorView extends Sprite {
		
		/***********************************************************************************************
		VARIABLES
		***********************************************************************************************/
		
		private var WiiDataProvidor		:WiiControllerData;
		
		private var PlayerID			:int;
		
		private var CursorLayer			:Sprite;
		private var CursorSprite		:Sprite;
		private var CursorPoint			:Sprite;
		
		private var CursorFile			:String = "assets/cursors";
		private var CursorLoader		:SWFLoader;
		private var CursorState			:String;
		
		/***********************************************************************************************
		CONSTANTS
		***********************************************************************************************/
		
		// for events
		public static const STAGE_CHANGE		:String = "state_change";
		
		// cursor states - frame labels in the cursor swf file
		public static const CURSOR_ARROW		:String = "default";
		public static const CURSOR_POINT		:String = "point";
		public static const CURSOR_CLOSEDHAND	:String = "closedhand";
		public static const CURSOR_BRUSH		:String = "brush";
		
		
		/***********************************************************************************************
		PUBLIC GETTERS/SETTERS
		***********************************************************************************************/
		
		public function get cursor():Sprite { return CursorSprite }
		public function get cursorPoint():Sprite { return CursorPoint }
		
		public function get cX():int { return CursorSprite.x }
		public function get cY():int { return CursorSprite.y }
		
		public function get state():String { return CursorState }
		public function set state(s:String):void {
			if (CursorState == s) return;
			CursorState = s;
			if (CursorLoader) CursorLoader.imageAdvanceToFrame(CursorState, false);
			//trace(PlayerID + " state change");
			dispatchEvent(new Event(WiiCursorView.STAGE_CHANGE));
		}
		
		/***********************************************************************************************
		CONSTRUCTOR
		***********************************************************************************************/
		
		public function WiiCursorView(d:WiiControllerData, l:Sprite, pid:int=0):void {
			WiiDataProvidor = d;
			CursorLayer = l;
			PlayerID = pid;
			
			state = WiiCursorView.CURSOR_ARROW;
			CursorSprite = new Sprite();
			CursorSprite.x = 0;
			CursorSprite.y = -100;

			loadCursorFile();
		}
		
		private function loadCursorFile():void {
			CursorLoader = new SWFLoader(CursorFile+"_p"+PlayerID+".swf", CursorSprite, { x:0, y:0, width:80, height:80 } );
			CursorLoader.addEventListener(SWFLoader.LOADED, onCursorLoaded);
		}
		
		/***********************************************************************************************
		EVENTS
		***********************************************************************************************/
		
		private function onCursorLoaded(e:Event):void {
			createCursorPoint();
			
			CursorLayer.addChild(CursorSprite);
			WiiDataProvidor.addEventListener(WiiControllerData.UPDATED, onDataUpdate);
		}
		
		private function createCursorPoint():void {
			CursorPoint = new Sprite();
			CursorPoint.x = 0;
			CursorPoint.y = 0;
			var square:Shape = new Shape();
			square.graphics.beginFill(0xff0000, 0);
			square.graphics.drawRect(0, 0, 1, 1);
			square.graphics.endFill();
			CursorPoint.addChild(square);
			CursorSprite.addChild(CursorPoint);
		}
		
		private function onDataUpdate(e:Event):void {
			var newx:int = 0;
			var newy:int = 0;
			var newr:int = 0;
			try {
				newx = WiiDataProvidor.xa;
				newy = WiiDataProvidor.ya;
				newr = WiiDataProvidor.roll;
			} catch (e:*) { 
				// no good data - the 'mote hasn't seen the IR points
				newx = 0;
				newy = 0;
				newr = 0;
			}
			
			CursorSprite.x = newx;
			CursorSprite.y = newy;
			
			//!! Tweener is much better at this. TweenLite is very choppy
			
			// the tween is added to smooth out the movement
			// if you just set the values, the movement is very choppy
			//Tweener.addTween(CursorSprite, { x:newx, y:newy, rotation:newr, time:.1, transition:"easeOutQuad" } );
			//TweenLite.killTweensOf(CursorSprite);
			//TweenLite.to(CursorSprite, .1,{x:newx, y:newy, rotation:newr, ease:Quadratic.easeOut } );
		}
		
		/***********************************************************************************************
		METHODS
		***********************************************************************************************/
		
		public function hide():void {
			CursorSprite.visible = false;
		}
		
		public function show():void {
			CursorSprite.visible = true;
		}
		
		public function enable():void {
			CursorSprite.alpha = 1;
		}
		
		public function disable():void {
			CursorSprite.alpha = .5;
		}
		
	}
	
}