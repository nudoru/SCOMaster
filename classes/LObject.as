

package {

	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.text.TextField;
	import flash.events.*;
	
	import fl.motion.easing.*;
	import com.greensock.*;
	
	import com.nudoru.utils.*;
	
	public class LObject extends MovieClip {
		
		/***********************************************************************************************
		VARIABLES
		***********************************************************************************************/
		
		private static var __INDEX		:int;
		
		private var _GUID				:int;
		private var _Type				:String;
		private var _Owner				:String;
		private var _DraggedBy			:int;
		private var _Cloned				:Boolean;
		private var _IsCompleteCourse	:Boolean;
		private var _CourseIndex		:int;
		private var _Map				:PlayerDataMap;
		
		private var _CloneMode			:Boolean;
		private var _CloneSource		:int;
		private var _CloneCount			:int = 0;
		
		private var _LOMovieClip		:LearningObject;
		
		private var _TgtSprite			:Sprite;

		private var _Position			:int;
		
		private var _HomeXPos			:int;
		private var _HomeYPos			:int;
		private var _HomeAlpha			:Number;
		private var _HomeScale			:Number;
		private var _HomeXScale			:Number;
		private var _HomeYScale			:Number;
		
		private var _TargetXPos			:int;
		private var _TargetYPos			:int;
		private var _TargetAlpha		:Number;
		private var _TargetScale		:Number;
		private var _TargetXScale		:Number;
		private var _TargetYScale		:Number;
		
		private var _CurrentTween		:*;
		
		/***********************************************************************************************
		CONSTS
		***********************************************************************************************/
		
		public static const POS_INIT :int = -1;
		public static const POS_COLUMN :int = 0;
		public static const POS_EVAL :int = 1;
		public static const POS_PLAYER1 :int = 2;
		public static const POS_PLAYER2 :int = 3;
		public static const POS_DRAGGING :int = 4;
		public static const POS_CLONEING :int = 5;
		public static const POS_EVALCLONE :int = 6;
		public static const POS_TRASH :int = 7;
		public static const POS_REMOVED :int = 99;
		
		public static const POSITION_UPDATE	:String = "position_update";
		
		/***********************************************************************************************
		GETTER/SETTER
		***********************************************************************************************/

		public function get lobjMC():MovieClip { return _LOMovieClip; }
		
		public function get position():int { return _Position; }
		public function set position(value:int):void {
			if (_Position == value) return;
			if ((_Position == LObject.POS_PLAYER1 || _Position == LObject.POS_PLAYER2) && value == LObject.POS_COLUMN) return;
			_Position = value;
			applyPositionVisual();
			dispatchEvent(new Event(POSITION_UPDATE));
		}
		
		public function get guid():int { return _GUID; }
		
		public function get type():String { return _Type; }
		
		public function get homeXPos():int { return _HomeXPos; }
		public function get homeYPos():int { return _HomeYPos; }
		
		public function get owner():String { return _Owner; }
		public function set owner(value:String):void {
			_Owner = value;
		}
		
		public function get cloned():Boolean { return _Cloned; }
		public function set cloned(value:Boolean):void {
			_Cloned = value;
		}
		
		public function get isCompleteCourse():Boolean { return _IsCompleteCourse; }
		public function set isCompleteCourse(value:Boolean):void {
			_IsCompleteCourse = value;
		}
		
		public function get courseIndex():int { return _CourseIndex; }
		public function set courseIndex(value:int):void {
			_CourseIndex = value;
		}
		
		public function get map():PlayerDataMap { return _Map; }
		public function set map(value:PlayerDataMap):void {
			//trace("map set to: " + value);
			_Map = value;
		}
		
		public function get cloneCount():int { return _CloneCount; }
		public function set cloneCount(value:int):void {
			_CloneCount = value;
		}
		
		public function get cloneSource():int { return _CloneSource; }
		public function set cloneSource(value:int):void {
			_CloneSource = value;
		}
		
		public function get cloneMode():Boolean { return _CloneMode; }
		public function set cloneMode(value:Boolean):void {
			_CloneMode = value;
		}
		
		public function get draggedBy():int { return _DraggedBy; }
		public function set draggedBy(value:int):void {
			_DraggedBy = value;
		}

		
		/***********************************************************************************************
		CONTSRUCTOR
		***********************************************************************************************/
		
		public function LObject(t:String, s:Sprite):void {
			__INDEX++;
			
			_GUID = __INDEX;
			_Type = t;
			_TgtSprite = s;
			position = LObject.POS_INIT;
		}
		
		override public function toString():String {
			return "[LObject "+_GUID+" ]"
		}
		
		/***********************************************************************************************
		METHODS
		***********************************************************************************************/
		
		public function render():void {
			_LOMovieClip = new LearningObject();
			_TgtSprite.addChild(_LOMovieClip);
			position = LObject.POS_COLUMN;
			updateDisplay();
		}
		
		public function updateDisplay():void {
			//set based on type and position
			_LOMovieClip.gotoAndStop(type);
			_LOMovieClip.idx_txt.text = String(__INDEX);
		}
		
		public function applyPositionVisual():void {
			if (!lobjMC) return;
			lobjMC.shine_mc.visible = false;
			switch(position) {
				case LObject.POS_COLUMN:
					BMUtils.clearAllFilters(lobjMC);
					break;
				case LObject.POS_PLAYER1:
					showLOShine();
					if (cloned) {
						//BMUtils.saturate(lobjMC);
						BMUtils.applyGlowFilter(lobjMC, 0xffff00, 1, 20, 1.5);
					} else {
						BMUtils.applyGlowFilter(lobjMC, 0xff0000, 1, 20, 1);
					}
					break;
				case LObject.POS_PLAYER2:
					showLOShine();
					if (cloned) {
						//BMUtils.saturate(lobjMC);
						BMUtils.applyGlowFilter(lobjMC, 0xffff00, 1, 20, 1.5);
					} else {
						BMUtils.applyGlowFilter(lobjMC, 0x0000ff, 1, 20, 1);
					}
					break;
				case LObject.POS_DRAGGING:
					BMUtils.applyDropShadowFilter(lobjMC, 10, 45, 0x000000, .5, 10, 1);
					break;
				case LObject.POS_CLONEING:
					BMUtils.applyDropShadowFilter(lobjMC, 10, 45, 0x000000, .5, 10, 1);
					break;
				default:
					BMUtils.clearAllFilters(lobjMC);
					break;
			}
		}
		
		public function showLOShine():void {
			lobjMC.shine_mc.visible = true;
			lobjMC.shine_mc.alpha = 0;
			TweenLite.to(lobjMC.shine_mc, 1, { alpha:.75, ease:Quadratic.easeOut } );
		}
		
		public function setHomeProps(x:int,y:int):void {
			_HomeXPos = x;
			_HomeYPos = y;
		}
	}
}