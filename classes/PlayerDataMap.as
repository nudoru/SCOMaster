package {
	import flash.display.MovieClip;
	import flash.display.Sprite;

	import fl.motion.easing.*;
	import com.greensock.*;
	
	import com.nudoru.utils.*;
	
	public class PlayerDataMap extends Sprite {
		
		private var _PlayerID				:int;
		private var _PlayerMapSprite		:MovieClip;
		private var _Completed				:Boolean = false;
		
		private var _CourseState			:Array = [[0], [0, 0, 0], [0, 0, 0, 0, 0, 0, 0, 0, 0]];
		private var _SpriteMap				:Array = [[0], [0, 0, 0], [0, 0, 0, 0, 0, 0, 0, 0, 0]];
		
		private var _CloneCount				:int = 1;
		private var _DollarCount			:int = 1;
		
		private var _CurrentHitTarget		:MovieClip;
		private var _CurrentHitLevel		:int;
		private var _CurrentHitItem			:int;
		
		public static const STATE_EMPTY		:int = 0;
		public static const STATE_OCCUPIED	:int = 1;
		public static const STATE_REUSED	:int = 2;
		
		public function get currentHitTarget():MovieClip { return _CurrentHitTarget; }
		public function get currentHitLevel():int { return _CurrentHitLevel; }
		public function get currentHitItem():int { return _CurrentHitItem; }
		
		public function get playerMapSprite():MovieClip { return _PlayerMapSprite; }
		
		public function get isCurrentSpotOccupied():Boolean { 
			if (getCurrentSpotState() >= PlayerDataMap.STATE_OCCUPIED) return true;
			return false;
		}
		
		public function get isComplete():Boolean {
			for (var i:int = 0; i < _CourseState.length; i++) {
				for (var k:int = 0; k < _CourseState[i].length; k++) {
					if (_CourseState[i][k] == 0) return false;
				}
			}
			return true;
		}
		
		public function get dollarCount():int { return _DollarCount; }
		public function set dollarCount(value:int):void {
			showNewDollar();
			_DollarCount = value;
		}
		
		public function get cloneCount():int { return _CloneCount; }
		public function set cloneCount(value:int):void {
			showNewClone();
			_CloneCount = value;
			removeDollar();
		}
		
		public function PlayerDataMap(pid:int, ms:MovieClip):void {
			_PlayerID = pid;
			_PlayerMapSprite = ms;
			defineSpriteMap();
		}
		
		override public function toString():String {
			return "[Map '" + _PlayerID + "']";
		}
		
		private function defineSpriteMap():void {
			if (!_PlayerMapSprite) return;
			_SpriteMap[0][0] = _PlayerMapSprite.program;
			_SpriteMap[1][0] = _PlayerMapSprite.course1;
			_SpriteMap[1][1] = _PlayerMapSprite.course2;
			_SpriteMap[1][2] = _PlayerMapSprite.course3;
			_SpriteMap[2][0] = _PlayerMapSprite.lesson1;
			_SpriteMap[2][1] = _PlayerMapSprite.lesson2;
			_SpriteMap[2][2] = _PlayerMapSprite.lesson3;
			_SpriteMap[2][3] = _PlayerMapSprite.lesson4;
			_SpriteMap[2][4] = _PlayerMapSprite.lesson5;
			_SpriteMap[2][5] = _PlayerMapSprite.lesson6;
			_SpriteMap[2][6] = _PlayerMapSprite.lesson7;
			_SpriteMap[2][7] = _PlayerMapSprite.lesson8;
			_SpriteMap[2][8] = _PlayerMapSprite.lesson9;
			
		}
		
		public function resetMapToOut():void {
			for (var i:int = 0; i < _SpriteMap.length; i++) {
				for (var k:int = 0; k < _SpriteMap[i].length; k++) {
					MovieClip(_SpriteMap[i][k]).gotoAndStop("out");
				}
			}
		}
		
		public function isCourseNumOccupied(c:int):Boolean {
			if (_CourseState[1][c] == 0) return false;
			trace("course # is occupied: "+c);
			return true;
		}
		
		public function isCourseNumComplete(c:int):Boolean {
			var i:int = 0;
			if (c == 1) i = 3;
			if (c == 2) i = 6;
			if (_CourseState[1][c] == 0) return false;
			if (_CourseState[2][i] == 0) return false;
			if (_CourseState[2][i+1] == 0) return false;
			if (_CourseState[2][i + 2] == 0) return false;
			return true;
		}
		
		public function isPlaceOccupied(i:int, k:int):Boolean {
			if (_CourseState[i][k] == PlayerDataMap.STATE_OCCUPIED) return true;
			return false;
		}
		
		public function areAnyCourseLessonsOccupied(c:int):Boolean {
			trace("are any course lessons on: " + c);
			var i:int = 0;
			if (c == 1) i = 3;
			if (c == 2) i = 6;
			if (_CourseState[1][c] == PlayerDataMap.STATE_OCCUPIED) return true;
			if (_CourseState[2][i] == PlayerDataMap.STATE_OCCUPIED) return true;
			if (_CourseState[2][i+1] == PlayerDataMap.STATE_OCCUPIED) return true;
			if (_CourseState[2][i + 2] == PlayerDataMap.STATE_OCCUPIED) return true;
			return false;
		}
		
		public function setCourseNumLessonsOccupied(c:int):Boolean {
			trace("set crs: "+c+" occupied");
			var i:int = 0;
			if (c == 1) i = 3;
			if (c == 2) i = 6;
			_CourseState[1][c] = PlayerDataMap.STATE_OCCUPIED;
			_CourseState[2][i] = PlayerDataMap.STATE_OCCUPIED;
			_CourseState[2][i+1] = PlayerDataMap.STATE_OCCUPIED;
			_CourseState[2][i+2] = PlayerDataMap.STATE_OCCUPIED;
			return true;
		}
		
		public function getCourseNumberOfSprite(s:*):int {
			for (var i:int = 0; i < _CourseState[1].length; i++) {
				if (MovieClip(_SpriteMap[1][i]).hitTestObject(s)) return i;
			}
			return -1;
		}
		
		public function getCourseLessonNumberOfSprite(s:*):Array {
			var l:int = getLessonNumberOfSprite(s);
			var c:int = getCourseNumberFromLesson(l);
			return [c, l];
		}
		
		public function getLessonNumberOfSprite(s:*):int {
			for (var i:int = 0; i < _CourseState[2].length; i++) {
				if (MovieClip(_SpriteMap[2][i]).hitTestObject(s)) return i;
			}
			return -1;
		}
		
		public function getLessonSpriteCoords(c:int, l:int):Array {
			var i:int = 0;
			if (c == 1) i = 3;
			if (c == 2) i = 6;
			return [MovieClip(_SpriteMap[2][i+l]).x, MovieClip(_SpriteMap[2][i+l]).y];
		}
		
		public function getCourseNumberFromLesson(l:int):int {
			if (l == 0 || l == 1 || l == 2) return 0;
			if (l == 3 || l == 4 || l == 5) return 1;
			return 2;
		}
		
		public function getCurrentSpotState():int {
			return _CourseState[_CurrentHitLevel][_CurrentHitItem];
		}
		
		public function setCurrentSpotOccupied():void {
			_CourseState[_CurrentHitLevel][_CurrentHitItem] = PlayerDataMap.STATE_OCCUPIED;
		}
		
		public function setCurrentSpotReused():void {
			_CourseState[_CurrentHitLevel][_CurrentHitItem] = PlayerDataMap.STATE_REUSED
		}
		
		public function isValidTypeForCurrentSpot(t:String):Boolean {
			if (_CurrentHitLevel == 0 && t == "program") return true;
			if (_CurrentHitLevel == 1 && t == "course") return true;
			if (_CurrentHitLevel == 2 && t == "lesson") return true;
			return false
		}
		
		public function checkTargets(los:Array):Boolean {
			var hit:Boolean = false;
			_CurrentHitTarget = undefined;
			_CurrentHitLevel = undefined;
			_CurrentHitItem = undefined;
			var len:int = los.length;
			//trace(_PlayerID + " checking");
			for (var lo:int = 0; lo < len; lo++ ) {
				// map id matches the whoever is dragging the lobj around.
				// player 1 can't place on player 2's map, etc.
				// will be -1 if it's being dragged by the mouse, so it's ok to pass though.
				if (los[lo].draggedBy >= 0) {
					if (los[lo].draggedBy != _PlayerID) continue;
				}
				// if the lo is being dragged
				if (los[lo].position == LObject.POS_DRAGGING || los[lo].position == LObject.POS_CLONEING) {
					// check against all of the maps spots
					for (var i:int = 0; i < _SpriteMap.length; i++) {
						for (var k:int = 0; k < _SpriteMap[i].length; k++) {
							if (MovieClip(_SpriteMap[i][k]).hitTestObject(los[lo].lobjMC) && !isPlaceOccupied(i, k)) {
								if (!hit) {
									MovieClip(_SpriteMap[i][k]).gotoAndStop("over");
									_CurrentHitTarget = MovieClip(_SpriteMap[i][k]);
									_CurrentHitLevel = i;
									_CurrentHitItem = k;
									//trace(_PlayerID + " is a hit");
								} else {
									MovieClip(_SpriteMap[i][k]).gotoAndStop("out")
									//trace(_PlayerID + " already a hit");
								}
								hit = true;
								//trace(_PlayerID + " " + i + "," + k);
								//trace(Sprite(_SpriteMap[i][k]))
							} else {
								MovieClip(_SpriteMap[i][k]).gotoAndStop("out");
							}
						}
					}
				}
			}
			return hit;
		}
		
		public function isSpriteOverMap(s:*):Boolean {
			for (var i:int = 0; i < _SpriteMap.length; i++) {
				for (var k:int = 0; k < _SpriteMap[i].length; k++) {
					if (MovieClip(_SpriteMap[i][k]).hitTestObject(s)) {
						return true;
					}
				}
			}
			return false;
		}
	
		public function setCourseState(l:int, o:int,s:Boolean):void {
			_CourseState[l][o] = s;
		}
		
		public function getCourseState(l:int, o:int):Boolean {
			return _CourseState[l][o];
		}
		
		private function showNewClone():void {
			var x:int = -10;
			var y:int = 5;
			var xspc:int = 30;
			for (var i:int = 0; i < _CloneCount; i++) {
				var exists:Boolean = playerMapSprite.getChildByName("star" + i) != null;
				//trace(String("star" + i));
				//trace(playerMapSprite.getChildByName("star" + i))
				if(!exists) {
					var s:star = new star();
					s.name = "star" + i;
					s.x = x;
					s.y = y+100;
					s.alpha = 0;
					s.rotation = 270;
					s.scaleX = s.scaleY = 10;
					//BMUtils.applyGlowFilter(s, 0xffff00, 1, 9, 1);
					playerMapSprite.addChild(s);
					TweenLite.to(s, 1, { delay:1, y:y, scaleX:1, scaleY:1, alpha:1, rotation:0, ease:Quadratic.easeIn } );
				}
				x += xspc;
			}
		}
		
		private function removeDollar():void {
			if (_DollarCount <= 1) return;
			var dlr:* = playerMapSprite.getChildByName("dollar" + (_DollarCount-2));
			if (dlr != null) {
				TweenLite.to(dlr, 1, { delay:2, y:200, alpha:0, rotation:45, ease:Quadratic.easeIn, onComplete:deleteDollar, onCompleteParams: [dlr] } );
				_DollarCount--;
			}
		}
		
		private function deleteDollar(d:*):void {
			playerMapSprite.removeChild(d);
		}
		
		private function showNewDollar():void {
			var x:int = 758;
			var y:int = 5;
			var xspc:int = -20;
			for (var i:int = 0; i < _DollarCount; i++) {
				var exists:Boolean = playerMapSprite.getChildByName("dollar" + i) != null;
				//trace(String("star" + i));
				//trace(playerMapSprite.getChildByName("star" + i))
				if (!exists) {
					var s:dollar = new dollar();
					s.name = "dollar" + i;
					s.x = x;
					s.y = y+100;
					s.alpha = 0;
					s.scaleX = s.scaleY = 10;
					//BMUtils.applyGlowFilter(s, 0xffff00, 1, 9, 1);
					playerMapSprite.addChild(s);
					TweenLite.to(s, 1, { y:y, scaleX:1, scaleY:1, alpha:1, ease:Elastic.easeOut } );
				}
				x += xspc;
			}
		}
		
	}
	
}