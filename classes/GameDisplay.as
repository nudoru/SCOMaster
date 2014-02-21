package {
	
	import flash.display.*;
	import flash.media.SoundChannel;

	import fl.motion.easing.*;
	import com.greensock.*;
		
	import com.nudoru.utils.*;
	
	public class GameDisplay extends Sprite {
	
		/***********************************************************************************************
		VARIABLES
		***********************************************************************************************/
		
		// ref to the main stage
		private var _StageRef				:MovieClip
		
		// the visual UI should all be in this layer
		private var _AppUILayer				:Sprite;
		// this is the holder for the UI
		private var _UIContainer			:Sprite;
		// status messages layer
		private var _StatusLayer			:Sprite;
		// flash layer
		private var _FlashLayer				:Sprite;
		
		private var _UIDropTargets			:Array;
		
		private var _CurrentHitTarget		:MovieClip;
		
		/***********************************************************************************************
		CONSTS
		***********************************************************************************************/
		
		private static const LOCOLUMNX		:int = 122;
		private static const LOCOLUMNMAXY	:int = 623;
		private static const LOWIDTH		:int = 66;
		private static const LOHEIGHT		:int = 66;
		
		/***********************************************************************************************
		GETTER/SETTER
		***********************************************************************************************/
		
		public function get appUILayer():Sprite { return _AppUILayer; }
		public function get uiContainer():Sprite { return _UIContainer; }
		
		public function get trashTarget():Sprite { return _StageRef.trash_mc }
		public function get floorTarget():Sprite { return _StageRef.floor_mc }
		
		public function get currentHitTarget():MovieClip { return _CurrentHitTarget; }
		
		/***********************************************************************************************
		CONTSRUCTOR
		***********************************************************************************************/
		
		public function GameDisplay(s:MovieClip):void {
			_StageRef = s;
			_UIDropTargets = new Array();
			
			init();
		}
		
		/***********************************************************************************************
		METHODS
		***********************************************************************************************/
		
		public function init():void {
			_AppUILayer = new Sprite();
			_AppUILayer.name = "ApplicationLayer";
			_StageRef.addChild(_AppUILayer);
			
			_UIContainer = new Sprite();
			_UIContainer.name = "UILayer";
			_AppUILayer.addChild(_UIContainer);
			
			_StatusLayer = new Sprite();
			_StatusLayer.name = "StatusLayer";
			_AppUILayer.addChild(_StatusLayer);
			
			_FlashLayer = new Sprite();
			_FlashLayer.name = "FlashLayer";
			_AppUILayer.addChild(_FlashLayer);
			
			_UIDropTargets.push(trashTarget);
			// add the floor last
			_UIDropTargets.push(floorTarget);
		}
		
		public function addLObjToColumn(o:LObject):void {
			o.render();
			o.lobjMC.x = LOCOLUMNX;
			o.lobjMC.y = -100;
		}
		
		public function sortColumn(los:Array):void {
			var len:int = los.length;
			var y:int = LOCOLUMNMAXY;
			var yspc:int = LOHEIGHT + 5;
			for (var i:int = 0; i < len; i++ ) {
				//trace(los[i].guid +" is " + los[i].position);
				// only sort the object if it's in the column
				if (los[i].position == LObject.POS_COLUMN) {
					TweenLite.to(los[i].lobjMC, 1, { x:LOCOLUMNX, y:y, rotation:0, ease:Bounce.easeOut} );
					//los[i].objSprite.y = y;
					y -= yspc;
				}
			}
		}
		
		public function isOverTrash(s:*):Boolean {
			if (trashTarget.hitTestObject(s)) return true;
			return false;
		}
		
		public function checkUITargets(los:Array):Boolean {
			var hit:Boolean = false;
			_CurrentHitTarget = undefined;
			var len:int = los.length;
			for (var lo:int = 0; lo < len; lo++ ) {
				// if the lo is being dragged
				if (los[lo].position == LObject.POS_DRAGGING) {
					// check against all of the maps spots
					for (var i:int = 0; i < _UIDropTargets.length; i++) {
						if (MovieClip(_UIDropTargets[i]).hitTestObject(los[lo].lobjMC)) {
							if (!hit) {
								MovieClip(_UIDropTargets[i]).gotoAndStop("over");
								_CurrentHitTarget = MovieClip(_UIDropTargets[i]);
							} else {
								MovieClip(_UIDropTargets[i]).gotoAndStop("out")
							}
							hit = true;
						} else {
							MovieClip(_UIDropTargets[i]).gotoAndStop("out");
						}
					}
				}
			}
			return hit;
		}
		
		// moves the oject being dragged to the top of the list
		public function spriteToUICTop(s:*):void {
			uiContainer.setChildIndex(s, uiContainer.numChildren-1);
		}
		
		public function doUIFlash():void {
			var s:UIFlash = new UIFlash();
			s.alpha = 0;
			_FlashLayer.addChild(s);
			TweenLite.to(s, .25, {alpha:1, ease:Quadratic.easeOut, onComplete: removeUIFlash, onCompleteParams: [s] } );
		}
		
		private function removeUIFlash(s:*):void {
			TweenLite.to(s, .25, {alpha:0,ease:Quadratic.easeOut, onComplete: deleteUIFlash, onCompleteParams: [s] } );
		}
		
		private function deleteUIFlash(s:*):void {
			_FlashLayer.removeChild(s);
		}
		
		public function showWinner(p:int):void {
			var x:int = 585;
			var y:int = 170;
			if (p == 2) y = 500;
			var s:Winner = new Winner();
			s.name = "pWinner";
			s.x = x;
			s.y = y;
			s.alpha = 0;
			s.scaleX = s.scaleY = 5;
			BMUtils.applyGlowFilter(s, 0xbb3300, 1, 30, 1);
			_StatusLayer.addChild(s);
			TweenLite.to(s, 1, {alpha:1, scaleX:1, scaleY:1, ease:Bounce.easeOut} );
		}
		
		public function showLoser(p:int):void {
			var x:int = 585;
			var y:int = 170;
			if (p == 2) y = 500;
			var s:Loser = new Loser();
			s.name = "pLoser";
			s.x = x;
			s.y = y;
			s.alpha = 0;
			s.scaleX = s.scaleY = 0;
			BMUtils.applyGlowFilter(s, 0x33bb00, 1, 20, 1);
			_StatusLayer.addChild(s);
			TweenLite.to(s, 2, {delay:1,alpha:1, scaleX:1, scaleY:1, ease:Bounce.easeOut, onComplete:dropLooserMC, onCompleteParams: [s] } );
		}
		
		public function dropLooserMC(s:*):void {
			TweenLite.to(s, 2, { y:"+50", rotation:rnd(10,20), delay:rnd(3,6), ease:Bounce.easeOut } );
		}
		
		public function dropLooser(lsr:int, los:Array):void {
			var len:int = los.length;
			for (var i:int = 0; i < len; i++ ) {
				if ((los[i].position == LObject.POS_PLAYER1 && lsr == 1) || (los[i].position == LObject.POS_PLAYER2 && lsr == 2)) {
					los[i].lobjMC.shine_mc.visible = false;
					BMUtils.clearAllFilters(los[i].lobjMC);
					//BMUtils.desaturate(los[i].lobjMC);
					TweenLite.to(los[i].lobjMC, rnd(1,3), { y:658, scaleX:.5, scaleY:.5, rotation:rnd(0,3)*90, delay:rnd(3,6), ease:Bounce.easeOut } );
				} else {
					spriteToUICTop(los[i].lobjMC);
				}
			}
		}
		
		public function showSevError(p:int):void {
			var x:int = 585;
			var y:int = 170;
			if (p == 2) y = 500;
			var s:SevError = new SevError();
			s.name = "pseverror";
			s.x = x;
			s.y = y;
			s.alpha = 0;
			s.scaleX = s.scaleY = 5;
			_StatusLayer.addChild(s);
			TweenLite.to(s, 1, { alpha:1, scaleX:1, scaleY:1, ease:Bounce.easeOut, onComplete: removeSevError, onCompleteParams: [s] } );
			
			var r:sndSevError = new sndSevError();
			var c:SoundChannel = r.play();
		}
		
		private function removeSevError(s:*):void {
			TweenLite.to(s, 1, {delay:1, alpha:0, scaleX:0, scaleY:0, ease:Quadratic.easeIn, onComplete: deleteSevError, onCompleteParams: [s] } );
		}
		
		private function deleteSevError(s:*):void {
			_StatusLayer.removeChild(s);
		}
		
		public function showReuse():void {
			doUIFlash();
			var x:int = 585;
			var y:int = 340;
			var s:Reuse = new Reuse();
			s.name = "preuse";
			s.x = x;
			s.y = y;
			s.alpha = 0;
			s.scaleX = s.scaleY = 5;
			_StatusLayer.addChild(s);
			TweenLite.to(s, 1, { delay:.5, alpha:1, scaleX:1, scaleY:1, ease:Bounce.easeOut, onComplete: removeReuse, onCompleteParams: [s] } );
			
			var r:sndReuse = new sndReuse();
			var c:SoundChannel = r.play();
		}
		
		private function removeReuse(s:*):void {
			TweenLite.to(s,1, {delay:1, alpha:0, scaleX:0, scaleY:0, ease:Quadratic.easeIn, onComplete: deleteReuse, onCompleteParams: [s] } );
		}
		
		private function deleteReuse(s:*):void {
			_StatusLayer.removeChild(s);
		}
		
		
		public function showMoney():void {
			var x:int = 40;
			var y:int = 320;
			var s:money = new money();
			s.name = "pMoney";
			s.x = x;
			s.y = y;
			s.alpha = 0;
			s.scaleX = s.scaleY = .1;
			_StatusLayer.addChild(s);
			BMUtils.applyGlowFilter(s, 0x00cc00, 1, 10, 1);
			TweenLite.to(s, 1, { alpha:1, y:200, scaleX:3, scaleY:3, ease:Bounce.easeOut, onComplete: removeMoney, onCompleteParams: [s] } );
			
			var r:sndChaChing = new sndChaChing();
			var c:SoundChannel = r.play();
		}
		
		private function removeMoney(s:*):void {
			TweenLite.to(s, .5, {delay:1, y:-100, alpha:0, scaleX:7, scaleY:7, ease:Quadratic.easeOut, onComplete: deleteMoney, onCompleteParams: [s] } );
		}
		
		private function deleteMoney(s:*):void {
			_StatusLayer.removeChild(s);
		}
		
		/***********************************************************************************************
		UTILITY
		***********************************************************************************************/
		
		public static function rnd(min:Number, max:Number):Number {
			return min + Math.floor(Math.random() * (max + 1 - min))
		}
		
	}
	
}