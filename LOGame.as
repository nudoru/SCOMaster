/*
SCOMaster Game
programmed by Matt Perkins, matthew.perkins@bankofamerica.com, kheavy@nudoru.com

TODO:
1. sweepLOs function should use a var to switch between maps, not 2 IF blocks
2. logic change: a course with cloned objects cannot be cloned
3. logic change: a cloned lesson may only exist in one place
	if a lesson under a cloneable course is cloned, the course is no longer clonable

*/


package {
	
	import com.nudoru.utils.TimeKeeper;
	import flash.display.Sprite;
	import flash.display.MovieClip;
	import flash.text.TextField;
	import flash.events.*;
	import flash.utils.Timer;
	import flash.media.SoundChannel;
	import flash.media.SoundTransform;
	
	import fl.motion.easing.*;
	import com.greensock.*;
	
	import wii.*;
	
	public class LOGame extends MovieClip {
		
		/***********************************************************************************************
		VARIABLES
		***********************************************************************************************/

		private var _View					:GameDisplay;
		
		private var _WiiConnected			:Boolean;
		
		// wiimote objects
		private var _WMPlayerOne			:WiiMoteController;
		private var _WMPlayerTwo			:WiiMoteController;
		
		private var _WiiMotes				:Array;			// collection of the wiimote objects
		private var _LearningObjects		:Array;			// collection of the grabbable things on the stage
		
		private var _PlayerOneMap			:PlayerDataMap;
		private var _PlayerTwoMap			:PlayerDataMap;
		
		private var _GameStage				:int;
		
		private var _NewLOTimer				:Timer;			// timer to add new LOs to the column
		private var _CheckTargetsTimer		:Timer;			// check DnD over targets
		private var _WiiCursorFixTimer		:Timer;			// fix the wii cursors
		
		private var _LOTypes				:Array = ["program", "course", "lesson", "fault"];	// these are duplicated in PlayerDataMap
		private var _LOTTypesCnt			:Array = [0, 0, 0, 0];
		private var _LOTTypesCntMax			:Array = [2, 6, 18, 999];
		
		// most recent click
		private var _LastClickWMIdx			:int;
		
		// this is the object that will be dragged
		private var _WiiFollowSpriteP1		:*;
		private var _WiiCursorToFollowP1	:Sprite;
		private var _WiiFollowSpriteP2		:*;
		private var _WiiCursorToFollowP2	:Sprite;

		/***********************************************************************************************
		CONSTANTS
		***********************************************************************************************/
		
		private static const NUMPLAYERS			:int = 2;
		
		private static const EN_WII				:Boolean = true;
		
		private static const LOADDINTERVAL		:int = 2000;
		private static const CHECKDNDINTRVL		:int = 100;
		private static const MAXLOSINHOLDING	:int = 7;		// the most that can fit in the right column is 9, leave 2 for dragging to snap back
		
		private static const MAXNUMCLONES		:int = 1;
		
		private static const STG_NONE			:int = -1;
		private static const STG_INITIALIZATION	:int = 0;
		private static const STG_SELECTION		:int = 1;
		private static const STG_PLAY			:int = 2;
		private static const STG_OVER			:int = 3;
		
		/***********************************************************************************************
		EVENTS
		***********************************************************************************************/
		
		private static const GAME_TITLE		:String = "game_title";
		private static const GAME_START		:String = "game_start";
		private static const STAGE_CHANGE	:String = "stage_change";
		private static const GAME_OVER		:String = "game_over";
		
		private static const LO_ADDED		:String = "lo_added";
		private static const LO_REUSED		:String = "lo_reused";
		private static const LO_PLACED		:String = "lo_placed";
		private static const LO_PLACEERR	:String = "lo_placementerror";
		
		/***********************************************************************************************
		GETTER/SETTER
		***********************************************************************************************/
		
		public function get usingWiiControllers():Boolean {
			if (EN_WII && _WiiConnected) return true;
			return false;
		}
		
		public function get gameStage():int { return _GameStage; }
		
		public function set gameStage(value:int):void {
			if(_GameStage == value) return
			_GameStage = value;
			dispatchEvent(new Event(LOGame.STAGE_CHANGE));
		}
		
		public function get objectsInColumn():int {
			var c:int = 0;
			for (var i:int = 0; i < _LearningObjects.length; i++ ) {
				if (_LearningObjects[i].position == LObject.POS_COLUMN) c++;
			}
			return c;
		}
		
		public function get objectsBeingDragged():int {
			var c:int = 0;
			for (var i:int = 0; i < _LearningObjects.length; i++ ) {
				if (_LearningObjects[i].position == LObject.POS_DRAGGING || _LearningObjects[i].position == LObject.POS_CLONEING) c++;
			}
			return c;
		}
		
		/***********************************************************************************************
		CONTSTRUCTOR
		***********************************************************************************************/
		
		public function LOGame():void {
			_WiiConnected = false;
			_WiiMotes = new Array();
			_LearningObjects = new Array();
			gameStage = LOGame.STG_NONE;
			
			addEventListener(LOGame.GAME_START, onGameStart);
			addEventListener(LOGame.STAGE_CHANGE, onStageChange);
			addEventListener(LOGame.GAME_OVER, onGameOver);
			
			addEventListener(LOGame.LO_ADDED, onLOAdded);
			addEventListener(LOGame.LO_PLACED, onLOPlaced);
			addEventListener(LOGame.LO_REUSED, onLOReused);
			addEventListener(LOGame.LO_PLACEERR, onLOPlacementErr);
			
			initialize();
		}
		
		/***********************************************************************************************
		METHODS
		***********************************************************************************************/
		
		private function initialize():void {
			if (gameStage >= LOGame.STG_INITIALIZATION) return;
			
			trace("## initialize");
			
			gameStage = LOGame.STG_INITIALIZATION;
			_View = new GameDisplay(this);
			
			_NewLOTimer = new Timer(LOADDINTERVAL, 0);
			_CheckTargetsTimer = new Timer(CHECKDNDINTRVL, 0);
			_WiiCursorFixTimer = new Timer(250, 0);
			
			_PlayerOneMap = new PlayerDataMap(0, player1map_mc);
			_PlayerTwoMap = new PlayerDataMap(1, player2map_mc);
			
			if (EN_WII) initWiiMotes();
			initUI();
			
			gameStage = LOGame.STG_SELECTION;
			//gameStage = LOGame.STG_PLAY;
			initTitleScreen();
		}
		
		private function initWiiMotes():void {
			if (NUMPLAYERS > 0) {
				trace("Wii Mote one ...");
				_WMPlayerOne = new WiiMoteController(this);
				_WMPlayerOne.addEventListener(WiiMoteController.CONNECTED, WMPlayerOneConnect);
				_WMPlayerOne.addEventListener(WiiMoteController.CONNECT_ERROR, onWiimoteConnectError);
				_WMPlayerOne.addEventListener(WiiMoteController.CONNECT_CLOSE, onWiimoteCloseConnection);
			}
			if (NUMPLAYERS > 1) {
				trace("Wii Mote two ...");
				_WMPlayerTwo = new WiiMoteController(this);
				_WMPlayerTwo.addEventListener(WiiMoteController.CONNECTED, WMPlayerTwoConnect);
				_WMPlayerTwo.addEventListener(WiiMoteController.CONNECT_ERROR, onWiimoteConnectError);
				_WMPlayerTwo.addEventListener(WiiMoteController.CONNECT_CLOSE, onWiimoteCloseConnection);
			}
		}
		
		private function initUI():void {
			//
		}
		
		private function onUIItemOver(e:Event):void {
			e.target.gotoAndStop("over");
		}
		
		private function onUIItemOut(e:Event):void {
			e.target.gotoAndStop("out");
		}
		
		private function initTitleScreen():void {
			title_mc.start_btn.addEventListener(MouseEvent.CLICK, onStartClick);
		}
		
		private function onStartClick(e:Event):void {
			gameStage = LOGame.STG_PLAY;
		}
		
		/***********************************************************************************************
		LISTENERS
		***********************************************************************************************/
		
		private function onStageChange(e:Event):void {
			trace("stage change to: " + gameStage);
			if (gameStage == LOGame.STG_PLAY) {
				dispatchEvent(new Event(LOGame.GAME_START));
			} else if (gameStage == LOGame.STG_OVER) {
				dispatchEvent(new Event(LOGame.GAME_OVER));
			}
		}
		private function onGameStart(e:Event):void {
			trace("game start");
			title_mc.visible = false;
			
			_NewLOTimer.addEventListener(TimerEvent.TIMER, onLOTimer);
			_NewLOTimer.start();
			_CheckTargetsTimer.addEventListener(TimerEvent.TIMER, onCheckTargetsTimer);
			_CheckTargetsTimer.start();
			
			addNewLO();
			addNewLO();
			addNewLO();
			addNewLO();
			addNewLO();
			
			var st:SoundTransform = new SoundTransform(.25);
			var r:sndBG = new sndBG();
			var c:SoundChannel = r.play(0,999,st);
		}
		private function onGameOver(e:Event):void {
			trace("game over");
			_NewLOTimer.removeEventListener(TimerEvent.TIMER, onLOTimer);
			_NewLOTimer.stop();
			_CheckTargetsTimer.removeEventListener(TimerEvent.TIMER, onCheckTargetsTimer);
			_CheckTargetsTimer.stop();
			_WiiCursorFixTimer.removeEventListener(TimerEvent.TIMER, onWiiCursorFixTimer);
			_WiiCursorFixTimer.start();
			disableAllLOs();
			var r:sndGameOver = new sndGameOver();
			var c:SoundChannel = r.play();
			if (_PlayerOneMap.isComplete) {
				trace("111 PLAYER ONE WINS!");
				_View.showWinner(1);
				_View.showLoser(2);
				_View.dropLooser(2, _LearningObjects);
			}
			if (_PlayerTwoMap.isComplete) {
				trace("222 PLAYER TWO WINS!");
				_View.showWinner(2);
				_View.showLoser(1);
				_View.dropLooser(1, _LearningObjects);
			}
		}
		
		/***********************************************************************************************
		LEARNING OBJECTS INTERACTION
		***********************************************************************************************/
		
		private function onCheckTargetsTimer(e:TimerEvent):void {
			if (!objectsBeingDragged) return;
			_PlayerOneMap.checkTargets(_LearningObjects);
			_PlayerTwoMap.checkTargets(_LearningObjects);
			_View.checkUITargets(_LearningObjects);
		}
		
		private function onLOTimer(e:TimerEvent):void {
			addNewLO();
		}
		
		private function onLOAdded(e:Event):void {
			//trace("# LOs " + _LearningObjects.length);
			_View.sortColumn(_LearningObjects);
		}
		
		private function onLOReused(e:Event):void {
			//trace("lo reused");
			_View.showReuse();
		}
		
		private function onLOPlaced(e:Event):void {
			//trace("lo placed");
			var r:sndPlace = new sndPlace();
			var c:SoundChannel = r.play();
			evalAllDraggability();
			if (_PlayerOneMap.isComplete) {
				dispatchEvent(new Event(LOGame.GAME_OVER));
			}
			if (_PlayerTwoMap.isComplete) {
				dispatchEvent(new Event(LOGame.GAME_OVER));
			}
		}
		
		private function onLOPlacementErr(e:Event):void {
			//trace("sev 1 error");
		}
		
		private function addNewLO(t:int = -1):void {
			//if (objectsBeingDragged) return;
			if (objectsInColumn < MAXLOSINHOLDING) {
				var lotyp:int;
				if(t < 0) {
					lotyp = getNewLOType();
				} else {
					lotyp = t;
				}
				var lo:LObject = new LObject(_LOTypes[lotyp], _View.uiContainer);
				lo.cloned = false;
				lo.addEventListener(LObject.POSITION_UPDATE, onLOPositionChange);
				_LearningObjects.push(lo);
				_View.addLObjToColumn(lo);
				lo.lobjMC.addEventListener(MouseEvent.MOUSE_OVER, onItemOver);
				lo.lobjMC.addEventListener(MouseEvent.MOUSE_OUT, onItemOut);
				lo.lobjMC.addEventListener(MouseEvent.MOUSE_DOWN, onItemDown);
				lo.lobjMC.addEventListener(MouseEvent.MOUSE_UP, onItemUp);
				lo.lobjMC.buttonMode = true;
				lo.lobjMC.mouseChildren = false;
				dispatchEvent(new Event(LOGame.LO_ADDED));
			} else {
				//
			}
		}
		
		private function getNewLOType():int {
			var t:int
			var isOK:Boolean = false;
			do {
				t = rnd(0, 3);
				//trace("try: " + t);
				if (_LOTTypesCnt[t]++ <= _LOTTypesCntMax[t]) {
					isOK = true;
					//trace("that one's OK");
				} else {
					//trace("not ok");
				}
			} while (!isOK);
			//trace("return :"+t)
			return t;
		}
		
		private function onLOPositionChange(e:Event):void {
			//trace("lo position change");
		}
		
		private function onItemOver(e:MouseEvent):void {
			hilightLONum(int(e.target.idx_txt.text) - 1);
			if(!usingWiiControllers) return;
			var wm:Array = whichWiiMotesAreOverMe(Sprite(e.target))
			for (var i:int = 0; i < wm.length; i++) {
				// if the the 'mote is holding it, don't reset the cursor
				if (_WiiMotes[wm[i]].cursorState != WiiCursorView.CURSOR_CLOSEDHAND) {
					_WiiMotes[wm[i]].doRumbleSeconds(.1);
					_WiiMotes[wm[i]].cursorState = WiiCursorView.CURSOR_POINT;
				}
			}
		}
		
		private function onItemOut(e:MouseEvent):void {
			dimLONum(int(e.target.idx_txt.text) - 1);
			if(!usingWiiControllers) return;
			var wm:Array = whichWiiMotesAreOverMe(Sprite(e.target))
			for (var i:int = 0; i<_WiiMotes.length; i++) {
				if (!isIntInArray(i, wm)) {
					//trace("out: "+_WiiMotes[i]);
					_WiiMotes[i].cursorState = WiiCursorView.CURSOR_ARROW;
				}
			}
		}
		
		private function onItemDown(e:MouseEvent):void {
			var wm:int = -1;
			if (usingWiiControllers) wm = whichWiiMoteClickedMe(Sprite(e.target));
			startDragLONum(int(e.target.idx_txt.text) - 1, wm);
		}
		
		private function onItemUp(e:MouseEvent):void {
			var wm:Array;
			if (usingWiiControllers) wm = whichWiiMotesAreOverMe(Sprite(e.target));
			stopDragLONum(int(e.target.idx_txt.text) - 1, wm);
		}
		
		private function onItemDownClone(e:MouseEvent):void {
			var wm:int = -1;
			if (usingWiiControllers) wm = whichWiiMoteClickedMe(Sprite(e.target));
			startDragLONum(createClone(int(e.target.idx_txt.text) - 1),wm);
		}
		
		private function onItemUpClone(e:MouseEvent):void {
			var wm:Array;
			if (usingWiiControllers) wm = whichWiiMotesAreOverMe(Sprite(e.target));
			stopDragLONum(int(e.target.idx_txt.text) - 1,wm);
		}
		
		// performs a hittest for each cursor on each object, if not a hit, the it sets the cursor to an arrow
		private function onWiiCursorFixTimer(e:TimerEvent):void {
			for (var i:int; i < _WiiMotes.length; i++) {
				var isHit:Boolean = false;
				for (var k:int = 0; k < _LearningObjects.length; k++) {
					if (_LearningObjects[k].lobjMC == null) continue;
					if (_WiiMotes[i].cursorPoint == null) continue;
					if (_LearningObjects[k].lobjMC.hitTestObject(_WiiMotes[i].cursorPoint)) {
						isHit = true;
					}
				}
				if (!isHit) {
					//trace("fixing arrows");
					_WiiMotes[i].cursorState = WiiCursorView.CURSOR_ARROW;
				}
			}
		}
		
		private function hilightLONum(n:int):void {
			//TweenLite.to(_LearningObjects[n].lobjMC.hi_mc, .5, {alpha:1,ease:Quadratic.easeOut } );
		}
		
		private function dimLONum(n:int):void {
			//TweenLite.to(_LearningObjects[n].lobjMC.hi_mc, 1, {alpha:0,ease:Quadratic.easeOut } );
		}
		
		// wm is the index of the Wii mote
		private function startDragLONum(n:int,wm:int=-1):void {
			if (n < 0) return;
			TweenLite.killTweensOf(_LearningObjects[n].lobjMC);
			_View.spriteToUICTop(_LearningObjects[n].lobjMC);
			if (_LearningObjects[n].position == LObject.POS_EVALCLONE || _LearningObjects[n].position == LObject.POS_PLAYER1 || _LearningObjects[n].position == LObject.POS_PLAYER2) {
				//trace("drag "+n+", to CLONEING");
				_LearningObjects[n].position = LObject.POS_CLONEING;
			} else {
				//trace("drag "+n+", to DRAGGING");
				_LearningObjects[n].position = LObject.POS_DRAGGING;
			}
			//trace("drag: "+n+" - " + _LearningObjects[n].position);
			if (!usingWiiControllers) {
				_LearningObjects[n].draggedBy = -1;
				_LearningObjects[n].lobjMC.startDrag();
			} else {
				if (wm == 0) {
					//trace("following p1");
					_LearningObjects[n].draggedBy = 0;
					_WiiMotes[wm].cursorState = WiiCursorView.CURSOR_CLOSEDHAND;
					_WiiFollowSpriteP1 = _LearningObjects[n].lobjMC;
					_WiiCursorToFollowP1 = _WiiMotes[wm].cursor;
					_WiiFollowSpriteP1.addEventListener(Event.ENTER_FRAME, followWiiCursorP1);
				} else if (wm == 1) {
					//trace("following p2");
					_LearningObjects[n].draggedBy = 1;
					_WiiMotes[wm].cursorState = WiiCursorView.CURSOR_CLOSEDHAND;
					_WiiFollowSpriteP2 = _LearningObjects[n].lobjMC;
					_WiiCursorToFollowP2 = _WiiMotes[wm].cursor;
					_WiiFollowSpriteP2.addEventListener(Event.ENTER_FRAME, followWiiCursorP2);
				} else {
					trace("can't follow Wii mote: " + wm);
				}
			}
		}
		
		private function followWiiCursorP1(e:Event):void {
			_WiiFollowSpriteP1.x = _WiiCursorToFollowP1.x;
			_WiiFollowSpriteP1.y = _WiiCursorToFollowP1.y;
			_WiiFollowSpriteP1.rotation = _WiiCursorToFollowP1.rotation;
			//_WMPlayerOne.cursorState = WiiCursorView.CURSOR_CLOSEDHAND;
		}
		
		private function followWiiCursorP2(e:Event):void {
			_WiiFollowSpriteP2.x = _WiiCursorToFollowP2.x;
			_WiiFollowSpriteP2.y = _WiiCursorToFollowP2.y;
			_WiiFollowSpriteP2.rotation = _WiiCursorToFollowP2.rotation;
			//_WMPlayerTwo.cursorState = WiiCursorView.CURSOR_CLOSEDHAND;
		}
		
		// wm is an array of wii motes that are over the sprite
		private function stopDragLONum(n:int,wm:Array = undefined):void {
			if (n < 0) return;
			//trace("stop: " + n + " - " + _LearningObjects[n].position);
			if (_LearningObjects[n].position == LObject.POS_PLAYER1 || _LearningObjects[n].position == LObject.POS_PLAYER2) {
				//_LearningObjects[n].lobjMC.stopDrag();
				haltDragging(_LearningObjects[n].lobjMC, wm);
				sweepLOs();
				return;
			}
			if (_LearningObjects[n].position == LObject.POS_CLONEING) {
				_LearningObjects[n].position = LObject.POS_EVALCLONE;
			} else {
				_LearningObjects[n].position = LObject.POS_EVAL;
			}
			haltDragging(_LearningObjects[n].lobjMC, wm);
			sweepLOs();
		}
		
		// stops dragging from either the wiimote or mouse
		// simplifies the logic since draggins may need to stop under several circumstances
		private function haltDragging(m:*, wm:Array = undefined):void {
			if (!usingWiiControllers) {
				m.stopDrag();
			} else {
				//trace("stop wms: "+wm)
				for (var i:int = 0; i < wm.length; i++) {
					_WiiMotes[wm[i]].cursorState = WiiCursorView.CURSOR_POINT;
					if (!_WiiMotes[wm[i]].isADown) {
						//_WiiMotes[wm[i]].cursorState = WiiCursorView.CURSOR_POINT;
						if (wm[i] == 0) {
							//trace("stop one");
							_WiiFollowSpriteP1.removeEventListener(Event.ENTER_FRAME, followWiiCursorP1);
						} else {
							//trace("stop two");
							_WiiFollowSpriteP2.removeEventListener(Event.ENTER_FRAME, followWiiCursorP2);
						}
					}
				}
			}
		}
		
		private function sweepLOs():void {
			for (var i:int = 0; i < _LearningObjects.length; i++ ) {
				if (_LearningObjects[i].position == LObject.POS_EVAL || _LearningObjects[i].position == LObject.POS_EVALCLONE) {
					_LearningObjects[i].lobjMC.alpha = 1;
					var p1mt:MovieClip = _PlayerOneMap.currentHitTarget;
					var p2mt:MovieClip = _PlayerTwoMap.currentHitTarget;
					var p1isover:Boolean = _PlayerOneMap.isSpriteOverMap(_LearningObjects[i].lobjMC);
					var p2isover:Boolean = _PlayerTwoMap.isSpriteOverMap(_LearningObjects[i].lobjMC);
					var dt:MovieClip = _View.currentHitTarget;
					var isClone:Boolean = _LearningObjects[i].position == LObject.POS_EVALCLONE;
					if (_View.isOverTrash(_LearningObjects[i].lobjMC)) {
						//trace("on trash!");
						trashLO(i, !isClone);
						return;
					}
					if (!p1isover && !p2isover) {
						if (dt == _View.trashTarget || _LearningObjects[i].position == LObject.POS_EVALCLONE) {
							trace("on trash!");
							trashLO(i, !isClone);
							return;
						} else {
							//trace("on floor");
							returnLOToColumn(i);
							return;
						}
					} else {
						if (p1isover) {
							//trace("on p1 map");
							_PlayerOneMap.resetMapToOut();
							// is it a clone?
							if (isClone) {
								// dropping it on your own map?
								if (_LearningObjects[i].owner == "player1") {
									_View.showSevError(1);
									trashLO(i);
									return;
								}
							}
							// is placed by the opposite player on this map
							if (_LearningObjects[i].draggedBy == 1) {
								_View.showSevError(2);
								returnLOToColumn(i);
								return;
							}
							// is the spot aleady occupied?
							if (_PlayerOneMap.isCurrentSpotOccupied) {
								// is it a clone?
								if (isClone) {
										trashLO(i);
										return;
								}
								returnLOToColumn(i);
								return;
							}
							// is it a valid type for this spot?
							if (!_PlayerOneMap.isValidTypeForCurrentSpot(_LearningObjects[i].type)) {
								dispatchEvent(new Event(LOGame.LO_PLACEERR));
								_View.showSevError(1);
								if (isClone || _LearningObjects[i].type == "fault") {
										trashLO(i);
										return;
								}
								returnLOToColumn(i);
								return;
							}
							_PlayerOneMap.setCurrentSpotOccupied();
							if(isClone) dispatchEvent(new Event(LOGame.LO_REUSED));
							_LearningObjects[i].position = LObject.POS_PLAYER1;
							_LearningObjects[i].owner = "player1";
							_LearningObjects[i].map = _PlayerOneMap;
							_LearningObjects[i].setHomeProps(p1mt.x + _PlayerOneMap.playerMapSprite.x, p1mt.y + _PlayerOneMap.playerMapSprite.y);
							if (_LearningObjects[i].cloned) _PlayerOneMap.cloneCount++;
							TweenLite.to(_LearningObjects[i].lobjMC, .5, { x:_LearningObjects[i].homeXPos, y:_LearningObjects[i].homeYPos, rotation:0, ease:Back.easeOut } );
							if (_LearningObjects[i].type == "course") evaluateCourseObjects(i);
							dispatchEvent(new Event(LOGame.LO_PLACED));
						} else if (p2isover) {
							_PlayerTwoMap.resetMapToOut();
							if (isClone) {
								if (_LearningObjects[i].owner == "player2") {
									_View.showSevError(2);
									trashLO(i);
									return;
								}
							}
							if (_LearningObjects[i].draggedBy == 0) {
								_View.showSevError(1);
								returnLOToColumn(i);
								return;
							}
							if (_PlayerTwoMap.isCurrentSpotOccupied) {
								if (isClone) {
										trashLO(i);
										return;
								}
								returnLOToColumn(i);
								return;
							}
							if (!_PlayerTwoMap.isValidTypeForCurrentSpot(_LearningObjects[i].type)) {
								dispatchEvent(new Event(LOGame.LO_PLACEERR));
								_View.showSevError(2);
								if (isClone || _LearningObjects[i].type == "fault") {
										trashLO(i);
										return;
								}
								returnLOToColumn(i);
								return;
							}
							_PlayerTwoMap.setCurrentSpotOccupied();
							if(isClone) dispatchEvent(new Event(LOGame.LO_REUSED));
							_LearningObjects[i].position = LObject.POS_PLAYER2;
							_LearningObjects[i].owner = "player2";
							_LearningObjects[i].map = _PlayerTwoMap;
							_LearningObjects[i].setHomeProps(p2mt.x + _PlayerTwoMap.playerMapSprite.x, p2mt.y + _PlayerTwoMap.playerMapSprite.y);
							if (_LearningObjects[i].cloned) _PlayerTwoMap.cloneCount++;
							TweenLite.to(_LearningObjects[i].lobjMC, .5, { x:_LearningObjects[i].homeXPos, y:_LearningObjects[i].homeYPos, rotation:0, ease:Back.easeOut } );
							if (_LearningObjects[i].type == "course") evaluateCourseObjects(i);
							dispatchEvent(new Event(LOGame.LO_PLACED));
						} else {
							trace("over nothing?");
						}
					}
				} else {
					// do nothing
				}
			}
		}
		
		private function returnLOToColumn(i:int):void {
			_LearningObjects[i].position = LObject.POS_COLUMN;
			_View.sortColumn(_LearningObjects);
		}
		
		private function trashLO(i:int, tc:Boolean = false):void {
			//TODO reduce clone count of origional
			if (_LearningObjects[i].position == LObject.POS_EVALCLONE) _LearningObjects[_LearningObjects[i].cloneSource].cloneCount--;
			_LearningObjects[i].position = LObject.POS_TRASH;
			disableLO(i);
			//was put in the trash
			if (tc) {
				_View.showMoney();
				if (_LearningObjects[i].draggedBy < 1) {
					_PlayerOneMap.dollarCount++;
				} else {
					_PlayerTwoMap.dollarCount++;
				}
				trash_mc.gotoAndStop("out");
			} else {
				var r:sndTrash = new sndTrash();
				var c:SoundChannel = r.play();
			}
			
			TweenLite.to(_LearningObjects[i].lobjMC, 2, { scaleX:0, scaleY:0, alpha:0, ease:Back.easeInOut } );
		}
		
		private function disableAllLOs():void {
			for (var i:int = 0; i<_LearningObjects.length; i++) {
				disableLO(i);
			}
		}
		
		private function disableLO(i:int):void {
			_LearningObjects[i].lobjMC.removeEventListener(MouseEvent.MOUSE_OVER, onItemOver);
			_LearningObjects[i].lobjMC.removeEventListener(MouseEvent.MOUSE_OUT, onItemOut);
			_LearningObjects[i].lobjMC.removeEventListener(MouseEvent.MOUSE_DOWN, onItemDown);
			_LearningObjects[i].lobjMC.removeEventListener(MouseEvent.MOUSE_UP, onItemUp);
			_LearningObjects[i].lobjMC.removeEventListener(MouseEvent.MOUSE_DOWN, onItemDownClone);
			_LearningObjects[i].lobjMC.removeEventListener(MouseEvent.MOUSE_UP, onItemUpClone);
			_LearningObjects[i].lobjMC.buttonMode = false;
			_LearningObjects[i].lobjMC.star_mc.alpha = 0;
			_LearningObjects[i].cloneMode = false;
		}
		
		private function evaluateCourseObjects(i:int):void {
			if (_LearningObjects[i].type == "course" && _LearningObjects[i].cloned) {
				populateClonedCourse(i);
			}
		}
		
		private function evalAllDraggability():void {
			for (var i:int = 0; i < _LearningObjects.length; i++) {
				if ((_LearningObjects[i].position == LObject.POS_PLAYER1 || _LearningObjects[i].position == LObject.POS_PLAYER2) && _LearningObjects[i].type != "course") {
					if (_LearningObjects[i].type == "lesson" && !_LearningObjects[i].cloned && _LearningObjects[i].cloneCount < LOGame.MAXNUMCLONES) {
						setToCloneMode(i);
					} else {
						//_LearningObjects[i].lobjMC.star_mc.alpha = 0;
						disableLO(i);
					}
				}
				if (_LearningObjects[i].type == "course" && !_LearningObjects[i].cloned) {
					evalCourseDraggability(i);
				}
			}
		}
		
		private function evalCourseDraggability(i:int):void {
			// evaluates if a course object can be cloned
			if (_LearningObjects[i].position == LObject.POS_PLAYER1) {
				_LearningObjects[i].courseIndex = _PlayerOneMap.getCourseNumberOfSprite(_LearningObjects[i].lobjMC);
				if (_PlayerOneMap.isCourseNumComplete(_LearningObjects[i].courseIndex) && !(_LearningObjects[i].cloneCount >= LOGame.MAXNUMCLONES)) {
					setToCloneMode(i);
				} else {
					disableLO(i);
				}
			} else if (_LearningObjects[i].position == LObject.POS_PLAYER2) {
				_LearningObjects[i].courseIndex = _PlayerTwoMap.getCourseNumberOfSprite(_LearningObjects[i].lobjMC);
				if (_PlayerTwoMap.isCourseNumComplete(_LearningObjects[i].courseIndex) && !(_LearningObjects[i].cloneCount >= LOGame.MAXNUMCLONES)) {
					setToCloneMode(i);
				} else {
					disableLO(i);
				}
			}
		}
		
		private function populateClonedCourse(i:int):void {
			// populates the lessons under a cloned course
			if (_LearningObjects[i].position == LObject.POS_PLAYER1) {
				trace("cloned on map 1");
				_LearningObjects[i].courseIndex = _PlayerOneMap.currentHitItem//getCourseNumberOfSprite(_LearningObjects[i].lobjMC);
				if (_PlayerOneMap.areAnyCourseLessonsOccupied(_LearningObjects[i].courseIndex)) clearCourseLessons(_LearningObjects[i].courseIndex, _PlayerOneMap);
				addClonedLessonsToCourse(_LearningObjects[i].courseIndex, _PlayerOneMap, _LearningObjects[i].owner, _LearningObjects[i].position);
			} else if (_LearningObjects[i].position == LObject.POS_PLAYER2) {
				trace("cloned on map 2");
				_LearningObjects[i].courseIndex = _PlayerTwoMap.currentHitItem//getCourseNumberOfSprite(_LearningObjects[i].lobjMC);
				if (_PlayerTwoMap.areAnyCourseLessonsOccupied(_LearningObjects[i].courseIndex)) clearCourseLessons(_LearningObjects[i].courseIndex, _PlayerTwoMap);
				addClonedLessonsToCourse(_LearningObjects[i].courseIndex, _PlayerTwoMap, _LearningObjects[i].owner, _LearningObjects[i].position);
			}
		}
		
		private function clearCourseLessons(c:int, map:PlayerDataMap):void {
			trace("clear : " + c + ", " + map);
			for (var i:int = 0; i < _LearningObjects.length; i++) {
				if(_LearningObjects[i].type == "lesson" && (_LearningObjects[i].position == LObject.POS_PLAYER1 || _LearningObjects[i].position == LObject.POS_PLAYER2)) {
					var pos:Array = map.getCourseLessonNumberOfSprite(_LearningObjects[i].lobjMC);
					if (pos[1] > -1 && pos[0] == c)  {
						trace("trashing: "+pos[0]+", "+pos[1])
						trashLO(i);
					}
				}
			}
		}
		
		private function addClonedLessonsToCourse(c:int, map:PlayerDataMap, ownr:String, pos:int):void {
			var lo1:LObject = makeNewCloneLesson(ownr, pos);
			var lo2:LObject = makeNewCloneLesson(ownr, pos);
			var lo3:LObject = makeNewCloneLesson(ownr, pos);

			lo1.lobjMC.x = map.getLessonSpriteCoords(c,0)[0] + map.playerMapSprite.x;
			lo1.lobjMC.y = map.getLessonSpriteCoords(c,0)[1] + map.playerMapSprite.y;
			lo2.lobjMC.x = map.getLessonSpriteCoords(c,1)[0] + map.playerMapSprite.x;
			lo2.lobjMC.y = map.getLessonSpriteCoords(c,2)[1] + map.playerMapSprite.y;
			lo3.lobjMC.x = map.getLessonSpriteCoords(c,2)[0] + map.playerMapSprite.x;
			lo3.lobjMC.y = map.getLessonSpriteCoords(c,2)[1] + map.playerMapSprite.y;
			
			map.setCourseNumLessonsOccupied(c)
			
			map.cloneCount++;
			map.cloneCount++;
			map.cloneCount++;
			
			dispatchEvent(new Event(LOGame.LO_ADDED));
			dispatchEvent(new Event(LOGame.LO_ADDED));
			dispatchEvent(new Event(LOGame.LO_ADDED));
		}
		
		private function makeNewCloneLesson(o:String, pos:int):LObject {
			var lo:LObject = new LObject("lesson", _View.uiContainer);
			lo.addEventListener(LObject.POSITION_UPDATE, onLOPositionChange);
			_LearningObjects.push(lo);
			_View.addLObjToColumn(lo);
			lo.owner = o;
			lo.cloned = true;
			lo.position = pos;
			lo.cloneCount++;
			return lo;
		}
		
		private function setToCloneMode(i:int):void {
			if (_LearningObjects[i].cloneMode) return;
			if (_LearningObjects[i].type == "program" || _LearningObjects[i].cloned == true || _LearningObjects[i].cloneCount >= MAXNUMCLONES) { 
				disableLO(i);
				return;
			}
			_LearningObjects[i].cloneMode = true;
			if (_LearningObjects[i].cloneCount > LOGame.MAXNUMCLONES) return;
			//trace("to clone mode: " + i);
			_LearningObjects[i].lobjMC.removeEventListener(MouseEvent.MOUSE_DOWN, onItemDown);
			_LearningObjects[i].lobjMC.removeEventListener(MouseEvent.MOUSE_UP, onItemUp);
			_LearningObjects[i].lobjMC.addEventListener(MouseEvent.MOUSE_DOWN, onItemDownClone);
			_LearningObjects[i].lobjMC.addEventListener(MouseEvent.MOUSE_UP, onItemUpClone);
			
			showLOStar(i);
		}
		
		private function showLOStar(i:int):void {
			if(_LearningObjects[i].lobjMC.star_mc.alpha != 1) {
				_LearningObjects[i].lobjMC.star_mc.alpha = 0;
				_LearningObjects[i].lobjMC.star_mc.rotation = 270;
				_LearningObjects[i].lobjMC.star_mc.scaleX = _LearningObjects[i].lobjMC.star_mc.scaleY = 6;
				TweenLite.to(_LearningObjects[i].lobjMC.star_mc, .5, { scaleX:1.2, scaleY:1.2, alpha:1, rotation:5, ease:Quadratic.easeIn } );
			}
		}
		
		private function createClone(i:int):int {
			if (_LearningObjects[i].cloneCount >= LOGame.MAXNUMCLONES) {
				trace("clone count exceeded");
				disableLO(i);
				return -1;
			}
			_LearningObjects[i].cloneCount++
			var lo:LObject = new LObject(_LearningObjects[i].type, _View.uiContainer);
			lo.addEventListener(LObject.POSITION_UPDATE, onLOPositionChange);
			_LearningObjects.push(lo);
			_View.addLObjToColumn(lo);
			lo.lobjMC.addEventListener(MouseEvent.MOUSE_OVER, onItemOver);
			lo.lobjMC.addEventListener(MouseEvent.MOUSE_OUT, onItemOut);
			lo.lobjMC.addEventListener(MouseEvent.MOUSE_DOWN, onItemDown);
			lo.lobjMC.addEventListener(MouseEvent.MOUSE_UP, onItemUp);
			lo.lobjMC.buttonMode = true;
			lo.lobjMC.mouseChildren = false;
			lo.owner = _LearningObjects[i].owner;
			lo.cloned = true;
			lo.cloneSource = i;
			lo.lobjMC.x = _LearningObjects[i].lobjMC.x;
			lo.lobjMC.y = _LearningObjects[i].lobjMC.y;
			lo.lobjMC.alpha = .6;
			lo.position = LObject.POS_EVALCLONE;
			dispatchEvent(new Event(LOGame.LO_ADDED));
			return _LearningObjects.length - 1;
		}
		
		/***********************************************************************************************
		WII MOTE INTEGRATION
		***********************************************************************************************/
		
		
		// returns array of which wiimote cursors are over the sprite
		private function whichWiiMotesAreOverMe(tgt:Sprite):Array {
			var a:Array = new Array();
			for (var i:int; i < _WiiMotes.length; i++) {
				if (tgt.hitTestObject(_WiiMotes[i].cursorPoint)) {
					a.push(i);
				}
			}
			//trace("over me: " + a);
			return a;
		}
		
		// returns index of which wii mote cursor is over with the A button down
		private function whichWiiMoteClickedMe(tgt:Sprite):int {
			var wm:Array = whichWiiMotesAreOverMe(tgt);
			for (var i:int = 0; i < wm.length; i++) {
				if (tgt.hitTestObject(_WiiMotes[wm[i]].cursorPoint)) {
					if (wm.length == 1) {
						// simple test if only one cursor is over
						if(_WiiMotes[wm[i]].isADown) return wm[i];
					} else {
						// little harder if 2+ are over
						if(_WiiMotes[wm[i]].isADown && _LastClickWMIdx==wm[i]) return wm[i];
					}
				}
			}
			return -1;
		}
		
		/***********************************************************************************************
		WII MOTE SUPPORT
		***********************************************************************************************/
		
		private function WMPlayerOneConnect (pEvent:Event):void {
			trace("one connected");
			_WiiConnected = true;
			_WMPlayerOne.addEventListener(WiiMoteController.DATA_UPDATE, onWiimoteDataUpdate);
			_WMPlayerOne.addEventListener(WiiMoteButtonEvent.PRESSED, onWiimoteButtonPressed);
			_WMPlayerOne.addEventListener(WiiMoteButtonEvent.RELEASED, onWiimoteButtonReleased);
			_WMPlayerOne.addEventListener(WiiMoteController.CLICK, onWiimoteClickP1);
			_WiiMotes.push(_WMPlayerOne);
			_WiiCursorFixTimer.addEventListener(TimerEvent.TIMER, onWiiCursorFixTimer);
			_WiiCursorFixTimer.start();
		}
		
		private function WMPlayerTwoConnect (pEvent:Event):void {
			trace("two connected");
			_WiiConnected = true;
			_WMPlayerTwo.addEventListener(WiiMoteController.DATA_UPDATE, onWiimoteDataUpdate);
			_WMPlayerTwo.addEventListener(WiiMoteButtonEvent.PRESSED, onWiimoteButtonPressed);
			_WMPlayerTwo.addEventListener(WiiMoteButtonEvent.RELEASED, onWiimoteButtonReleased);
			_WMPlayerTwo.addEventListener(WiiMoteController.CLICK, onWiimoteClickP2);
			_WiiMotes.push(_WMPlayerTwo);
		}
		
		private function onWiimoteCloseConnection (pEvent:Event):void {
			trace("Wiimote closed connection")
		}
		
		//IOErrorEvent
		private function onWiimoteConnectError (pEvent:*):void {
			trace("Wiimote connection error")
		}

		private function onWiimoteDataUpdate(e:Event):void {
			//
		}
		
		private function onWiimoteButtonPressed(e:WiiMoteButtonEvent):void {
			//trace(e.buttonName + " button was pressed on " + e.wiiMoteIndex);
		}
		
		private function onWiimoteButtonReleased(e:WiiMoteButtonEvent):void {
			//trace(e.buttonName + " button was released on " + e.wiiMoteIndex);
		}
		
		//TODO - make this one function with a custom event
		private function onWiimoteClickP1 (pEvent:Event):void {
			_LastClickWMIdx = 0;
		}
		
		private function onWiimoteClickP2 (pEvent:Event):void {
			_LastClickWMIdx = 1;
		}
		
		/***********************************************************************************************
		UTILITY
		***********************************************************************************************/
		
		// is a certain number in an array?
		private function isIntInArray(n:int, a:Array):Boolean {
			for (var i:int = 0; i < a.length; i++) {
				if (int(a[i]) == n) return true;
			}
			return false;
		}
	
		public static function rnd(min:Number, max:Number):Number {
			return min + Math.floor(Math.random() * (max + 1 - min))
		}
		
	}
}