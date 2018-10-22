package org.gestouch.gestures;

import org.gestouch.core.Gestouch;
import org.gestouch.core.GestureState;
import org.gestouch.core.GesturesManager;
import org.gestouch.core.IGestureTargetAdapter;
import org.gestouch.core.Touch;
import org.gestouch.events.GestureEvent;
import openfl.events.EventDispatcher;
import openfl.geom.Point;
import openfl.system.Capabilities;

class Gesture extends EventDispatcher
{
	/**
	 * Threshold for screen distance they must move to count as valid input
	 * (not an accidental offset on touch),
	 * based on 20 pixels on a 252ppi device.
	 */
	public static var DEFAULT_SLOP:Int = Math.round(20 / 252 * openfl.system.Capabilities.screenDPI);

	/**
	 * If a gesture should receive a touch.
	 * Callback signature: function(gesture:Gesture, touch:Touch):Bool
	 *
	 * @see Touch
	 */
	public var gestureShouldReceiveTouchCallback:Gesture->Touch->Bool;
	/**
	 * If a gesture should be recognized (transition from state POSSIBLE to state RECOGNIZED or BEGAN).
	 * Returning <code>false</code> causes the gesture to transition to the FAILED state.
	 *
	 * Callback signature: function(gesture:Gesture):Bool
	 *
	 * @see state
	 * @see GestureState
	 */
	public var gestureShouldBeginCallback:Gesture->Bool;
	/**
	 * If two gestures should be allowed to recognize simultaneously.
	 *
	 * Callback signature: function(gesture:Gesture, otherGesture:Gesture):Bool
	 */
	public var gesturesShouldRecognizeSimultaneouslyCallback:Gesture->Gesture->Bool;

	private var _gesturesManager:GesturesManager = Gestouch.gesturesManager;
	/**
	 * Map (generic object) of tracking touch points, where keys are touch points IDs.
	 */
	private var _touchesMap:Map<Int, Touch> = new Map<Int, Touch>();

	/**
	 * List of gesture we require to fail.
	 * @see requireGestureToFail()
	 */
	private var _gesturesToFail:Map<Gesture, Bool> = new Map<Gesture, Bool>();
	private var _pendingRecognizedState:GestureState;

	public function new(target:Dynamic = null)
	{
		super();

		preinit();

		enabled = true;
		_touchesCount = 0;
		_location = new Point();
		this.target = target;
	}

	public var targetAdapter(get, never):IGestureTargetAdapter;
	private var _targetAdapter:IGestureTargetAdapter;
	private function get_targetAdapter():IGestureTargetAdapter
	{
		return _targetAdapter;
	}

	/**
	 * FIXME
	 * InteractiveObject (DisplayObject) which this gesture is tracking the actual gesture motion on.
	 *
	 * <p>Could be some image, component (like map) or the larger view like Stage.</p>
	 *
	 * <p>You can change the target in the runtime, e.g. you have a gallery
	 * where only one item is visible at the moment, so use one gesture instance
	 * and change the target to the currently visible item.</p>
	 *
	 * @see http://help.adobe.com/en_US/FlashPlatform/reference/actionscript/3/flash/display/InteractiveObject.html
	 */
	public var target(get, set):Dynamic;
	private function get_target():Dynamic
	{
		if (_targetAdapter != null)
		{
			return _targetAdapter.target;
		}
		return null;
	}
	private function set_target(value:Dynamic):Dynamic
	{
		var target:Dynamic = this.target;
		if (target == value)
			return null;

		uninstallTarget(target);
		if (value != null)
		{
			_targetAdapter = Gestouch.createGestureTargetAdapter(value);
		}
		else
		{
			_targetAdapter = null;
		}
		installTarget(value);

		return value;
	}

	public var enabled(get, set):Bool;
	private var _enabled:Bool;
	private function get_enabled():Bool
	{
		return _enabled;
	}
	private function set_enabled(value:Bool):Bool
	{
		if (enabled == value)
			return value;

		_enabled = value;

		if (!_enabled)
		{
			if (state == GestureState.POSSIBLE)
			{
				setState(GestureState.FAILED);
			}
			else if (state == GestureState.BEGAN || state == GestureState.CHANGED)
			{
				setState(GestureState.CANCELLED);
			}
		}

		return value;
	}

	public var state(get, null):GestureState = GestureState.POSSIBLE;
	private function get_state():GestureState
	{
		return state;
	}

	public var idle(get, null):Bool = true;
	private function get_idle():Bool
	{
		return idle;
	}

	/**
	 * Amount of currently tracked touch points.
	 *
	 * @see #_touches
	 */
	public var touchesCount(get, never):Int;
	private var _touchesCount:Int;
	private function get_touchesCount():Int
	{
		return _touchesCount;
	}

	/**
	 * Virtual central touch point among all tracking touch points (geometrical center).
	 */
	public var location(get, never):Point;
	private var _location:Point;
	private function get_location():Point
	{
		return _location.clone();
	}

	public function reflect():Class<Dynamic>
	{
		throw "reflect() is abstract method and must be overridden.";
	}

	public function isTrackingTouch(touchID:Int):Bool
	{
		return _touchesMap.exists(touchID);
	}

	/**
	 * Cancels current tracking (interaction) cycle.
	 *
	 * <p>Could be useful to "stop" gesture for the current interaction cycle.</p>
	 */
	public function reset():Void
	{
		if (idle)
			return;// Do nothing as we are idle and there is nothing to reset

		var state:GestureState = this.state;//caching getter

		_location.x = 0;
		_location.y = 0;
		_touchesMap = new Map<Int, Touch>();
		_touchesCount = 0;
		idle = true;

		for (gesture in _gesturesToFail.keys())
		{
			var gestureToFail:Gesture = gesture;
			gestureToFail.removeEventListener(GestureEvent.GESTURE_STATE_CHANGE, gestureToFail_stateChangeHandler);
		}
		_pendingRecognizedState = null;

		if (state == GestureState.POSSIBLE)
		{
			// manual reset() call. Set to FAILED to keep our State Machine clean and stable
			setState(GestureState.FAILED);
		}
		else if (state == GestureState.BEGAN || state == GestureState.CHANGED)
		{
			// manual reset() call. Set to CANCELLED to keep our State Machine clean and stable
			setState(GestureState.CANCELLED);
		}
		else
		{
			// reset from GesturesManager after reaching one of the 4 final states:
			// (state == GestureState.RECOGNIZED ||
			// state == GestureState.ENDED ||
			// state == GestureState.FAILED ||
			// state == GestureState.CANCELLED)
			setState(GestureState.POSSIBLE);
		}
	}

	/**
	 * Remove gesture and prepare it for GC.
	 *
	 * <p>The gesture is not able to use after calling this method.</p>
	 */
	public function dispose():Void
	{
		//TODO
		reset();
		target = null;
		gestureShouldReceiveTouchCallback = null;
		gestureShouldBeginCallback = null;
		gesturesShouldRecognizeSimultaneouslyCallback = null;
		_gesturesToFail = null;
	}

	public function canBePreventedByGesture(preventingGesture:Gesture):Bool
	{
		return true;
	}

	public function canPreventGesture(preventedGesture:Gesture):Bool
	{
		return true;
	}

	/**
	 * First method, called in constructor.
	 */
	private function preinit():Void
	{
	}

	/**
	 * Called internally when changing the target.
	 *
	 * @see http://help.adobe.com/en_US/FlashPlatform/reference/actionscript/3/flash/display/InteractiveObject.html
	 */
	private function installTarget(target:Dynamic):Void
	{
		if (target != null)
		{
			_gesturesManager.addGesture(this);
		}
	}

	/**
	 * Called internally when changing the target.
	 *
	 * <p>You should remove all listeners from target here.</p>
	 *
	 * @see http://help.adobe.com/en_US/FlashPlatform/reference/actionscript/3/flash/display/InteractiveObject.html
	 */
	private function uninstallTarget(target:Dynamic):Void
	{
		if (target != null)
		{
			_gesturesManager.removeGesture(this);
		}
	}

	/**
	 * TODO: clarify usage. For now it's supported to call this method in onTouchBegin with return.
	 */
	private function ignoreTouch(touch:Touch):Void
	{
		if (_touchesMap.exists(touch.id))
		{
			_touchesMap.remove(touch.id);
			_touchesCount--;
		}
	}

	public function failOrIgnoreTouch(touch:Touch):Void
	{
		if (state == GestureState.POSSIBLE)
		{
			setState(GestureState.FAILED);
		}
		else
		{
			ignoreTouch(touch);
		}
	}

	private function onTouchBegin(touch:Touch):Void
	{
		// This is abstract method and must be overridden.
	}

	private function onTouchMove(touch:Touch):Void
	{
		// This is abstract method and must be overridden.
	}

	private function onTouchEnd(touch:Touch):Void
	{
		// This is abstract method and must be overridden.
	}

	private function onTouchCancel(touch:Touch):Void
	{

	}

	public function setState(newState:GestureState):Bool
	{
		if (state == newState && state == GestureState.CHANGED)
		{
			// shortcut for better performance

			if (hasEventListener(GestureEvent.GESTURE_STATE_CHANGE))
			{
				dispatchEvent(new GestureEvent(GestureEvent.GESTURE_STATE_CHANGE, state, state));
			}

			if (hasEventListener(GestureEvent.GESTURE_CHANGED))
			{
				dispatchEvent(new GestureEvent(GestureEvent.GESTURE_CHANGED, state, state));
			}

			resetNotificationProperties();

			return true;
		}

		if (!state.canTransitionTo(newState))
		{
			throw "You cannot change from state " + state + " to state " + newState  + ".";
		}

		if (newState != GestureState.POSSIBLE)
		{
			// in case instantly switch state in touchBeganHandler()
			idle = false;
		}

		if (newState == GestureState.BEGAN || newState == GestureState.RECOGNIZED)
		{
			var gestureToFail:Gesture;
			// first we check if other required-to-fail gestures recognized
			// TODO: is this really necessary? using "requireGestureToFail" API assume that
			// required-to-fail gesture always recognizes AFTER this one.
			for (gesture in _gesturesToFail.keys())
			{
				gestureToFail = gesture;
				if (!gestureToFail.idle &&
					gestureToFail.state != GestureState.POSSIBLE &&
					gestureToFail.state != GestureState.FAILED)
				{
					// Looks like other gesture won't fail,
					// which means the required condition will not happen, so we must fail
					setState(GestureState.FAILED);
					return false;
				}
			}
			// then we check if other required-to-fail gestures are actually tracked (not IDLE)
			// and not still not recognized (e.g. POSSIBLE state)
			for (gesture in _gesturesToFail.keys())
			{
				gestureToFail = gesture;
				if (gestureToFail.state == GestureState.POSSIBLE)
				{
					// Other gesture might fail soon, so we postpone state change
					_pendingRecognizedState = newState;

					for (gesture2 in _gesturesToFail.keys())
					{
						gestureToFail = gesture2;
						gestureToFail.addEventListener(GestureEvent.GESTURE_STATE_CHANGE, gestureToFail_stateChangeHandler, false, 0, true);
					}

					return false;
				}
				// else if gesture is in IDLE state it means it doesn't track anything,
				// so we simply ignore it as it doesn't seem like conflict from this perspective
				// (perspective of using "requireGestureToFail" API)
			}

			if (gestureShouldBeginCallback != null && !gestureShouldBeginCallback(this))
			{
				setState(GestureState.FAILED);
				return false;
			}
		}

		var oldState:GestureState = state;
		state = newState;

		if (state.isEndState)
		{
			_gesturesManager.scheduleGestureStateReset(this);
		}

		//TODO: what if RTE happens in event handlers?

		if (hasEventListener(GestureEvent.GESTURE_STATE_CHANGE))
		{
			dispatchEvent(new GestureEvent(GestureEvent.GESTURE_STATE_CHANGE, state, oldState));
		}

		if (hasEventListener(state.toEventType()))
		{
			dispatchEvent(new GestureEvent(state.toEventType(), state, oldState));
		}

		resetNotificationProperties();

		if (state == GestureState.BEGAN || state == GestureState.RECOGNIZED)
		{
			_gesturesManager.onGestureRecognized(this);
		}

		return true;
	}

	public function setState_internal(state:GestureState):Void
	{
		setState(state);
	}

	public var centralPoint:Point = new Point();
	public function updateCentralPoint():Void
	{
		var touchLocation:Point;
		var x:Float = 0;
		var y:Float = 0;
		for (touchID in _touchesMap.keys())
		{
			touchLocation = cast(_touchesMap.get(touchID), Touch).location;
			x += touchLocation.x;
			y += touchLocation.y;
		}
		centralPoint.x = x / _touchesCount;
		centralPoint.y = y / _touchesCount;
	}

	public function updateLocation():Void
	{
		updateCentralPoint();
		_location.x = centralPoint.x;
		_location.y = centralPoint.y;
	}

	public function resetNotificationProperties():Void
	{

	}

	public function touchBeginHandler(touch:Touch):Void
	{
		_touchesMap[touch.id] = touch;
		_touchesCount++;

		onTouchBegin(touch);

		if (_touchesCount == 1 && state == GestureState.POSSIBLE)
		{
			idle = false;
		}
	}


	public function touchMoveHandler(touch:Touch):Void
	{
		_touchesMap[touch.id] = touch;
		onTouchMove(touch);
	}


	public function touchEndHandler(touch:Touch):Void
	{
		_touchesMap.remove(touch.id);
		_touchesCount--;

		onTouchEnd(touch);
	}


	public function touchCancelHandler(touch:Touch):Void
	{
		_touchesMap.remove(touch.id);
		_touchesCount--;

		onTouchCancel(touch);

		if (!state.isEndState)
		{
			if (state == GestureState.BEGAN || state == GestureState.CHANGED)
			{
				setState(GestureState.CANCELLED);
			}
			else
			{
				setState(GestureState.FAILED);
			}
		}
	}


	public function gestureToFail_stateChangeHandler(event:GestureEvent):Void
	{
		if (_pendingRecognizedState == null || state != GestureState.POSSIBLE)
			return;

		if (event.newState == GestureState.FAILED)
		{
			for (gesture in _gesturesToFail.keys())
			{
				var gestureToFail:Gesture = gesture;
				if (gestureToFail.state == GestureState.POSSIBLE)
				{
					// we're still waiting for some gesture to fail
					return;
				}
			}

			// at this point all gestures-to-fail are either in IDLE or in FAILED states
			setState(_pendingRecognizedState);
		}
		else if (event.newState != GestureState.POSSIBLE)
		{
			//TODO: need to re-think this over

			setState(GestureState.FAILED);
		}
	}
}