package org.gestouch.core;

import openfl.Lib;
import openfl.Vector;
import openfl.display.DisplayObject;
import openfl.display.Stage;
import openfl.events.Event;
import openfl.events.IEventDispatcher;
import org.gestouch.gestures.Gesture;

class GesturesManager
{
	private var _gesturesMap:Map<Gesture, Bool> = new Map<Gesture, Bool>();
	private var _gesturesForTouchMap:Map<Touch, Vector<Gesture>> = new Map<Touch, Vector<Gesture>>();
	private var _gesturesForTargetMap:Map<{}, Vector<Gesture>> = new Map<{}, Vector<Gesture>>();
	private var _dirtyGesturesMap:Map<Gesture, Bool> = new Map<Gesture, Bool>();
	private var _dirtyGesturesCount:Int = 0;
	private var _stage:Stage;

	public function new()
	{

	}

	private function onStageAvailable(stage:Stage):Void
	{
		_stage = stage;
	}

	private function resetDirtyGestures():Void
	{
		for (gesture in _dirtyGesturesMap.keys())
		{
			gesture.reset();
		}
		_dirtyGesturesCount = 0;
		_dirtyGesturesMap = new Map<Gesture, Bool>();
		Lib.current.stage.removeEventListener(Event.ENTER_FRAME, enterFrameHandler);
	}

	@:allow(org.gestouch.gestures.Gesture)
	private function addGesture(gesture:Gesture):Void
	{
		if (gesture == null)
		{
			throw "Argument 'gesture' must be not null.";
		}

		var target:Dynamic = gesture.target;
		if (target == null)
		{
			throw "Gesture must have target.";
		}

		var targetGestures:Vector<Gesture> = _gesturesForTargetMap.get(target);
		if (targetGestures != null)
		{
			if (targetGestures.indexOf(gesture) == -1)
			{
				targetGestures.push(gesture);
			}
		}
		else
		{
			_gesturesForTargetMap.set(target, new Vector<Gesture>());
			targetGestures = _gesturesForTargetMap.get(target);
			targetGestures.push(gesture);
		}

		_gesturesMap.set(gesture, true);

		if (_stage == null)
		{
			var targetAsDO:DisplayObject = null;
			if (Std.is(target, DisplayObject))
			{
				cast(target, DisplayObject);
			}

			if (targetAsDO != null)
			{
				if (targetAsDO.stage != null)
				{
					onStageAvailable(targetAsDO.stage);
				}
				else
				{
					targetAsDO.addEventListener(Event.ADDED_TO_STAGE, gestureTarget_addedToStageHandler, false,0, true);
				}
			}
		}
	}

	@:allow(org.gestouch.gestures.Gesture)
	private function removeGesture(gesture:Gesture):Void
	{
		if (gesture == null)
		{
			throw "Argument 'gesture' must be not null.";
		}

		var target:Dynamic = gesture.target;
		// check for target because it could be already GC-ed (since target reference is weak)
		if (target !=  null)
		{
			var targetGestures:Vector<Gesture> = _gesturesForTargetMap.get(target);
			if (targetGestures.length > 1)
			{
				targetGestures.splice(targetGestures.indexOf(gesture), 1);
			}
			else
			{
				_gesturesForTargetMap.remove(target);
				if (Std.is(target, IEventDispatcher))
				{
					cast(target, IEventDispatcher).removeEventListener(Event.ADDED_TO_STAGE, gestureTarget_addedToStageHandler);
				}
			}
		}

		_gesturesMap.remove(gesture);

		gesture.reset();
	}

	@:allow(org.gestouch.gestures.Gesture)
	public function scheduleGestureStateReset(gesture:Gesture):Void
	{
		if (!_dirtyGesturesMap.exists(gesture))
		{
			_dirtyGesturesMap.set(gesture, true);
			_dirtyGesturesCount++;
			Lib.current.stage.addEventListener(Event.ENTER_FRAME, enterFrameHandler);
		}
	}

	@:allow(org.gestouch.gestures.Gesture)
	private function onGestureRecognized(gesture:Gesture):Void
	{
		var target:Dynamic = gesture.target;
		for (gesture in _gesturesMap.keys())
		{
			var otherGesture:Gesture = gesture;
			var otherTarget:Dynamic = otherGesture.target;

			// conditions for otherGesture "own properties"
			if (otherGesture != gesture &&
				target != null && otherTarget != null && //in case GC worked half way through
				otherGesture.enabled &&
				otherGesture.state == GestureState.POSSIBLE)
			{
				if (otherTarget == target ||
					gesture.targetAdapter.contains(otherTarget) ||
					otherGesture.targetAdapter.contains(target)
					)
				{
					// conditions for gestures relations
					if (gesture.canPreventGesture(otherGesture) &&
						otherGesture.canBePreventedByGesture(gesture) &&
						(gesture.gesturesShouldRecognizeSimultaneouslyCallback == null ||
						 !gesture.gesturesShouldRecognizeSimultaneouslyCallback(gesture, otherGesture)) &&
						(otherGesture.gesturesShouldRecognizeSimultaneouslyCallback == null ||
						 !otherGesture.gesturesShouldRecognizeSimultaneouslyCallback(otherGesture, gesture)))
					{
						otherGesture.setState_internal(GestureState.FAILED);
					}
				}
			}
		}
	}

	@:allow(org.gestouch.core.TouchesManager)
	private function onTouchBegin(touch:Touch):Void
	{
		var gesture:Gesture;
		var i:Int;

		// This vector will contain active gestures for specific touch during all touch session.
		var gesturesForTouch:Vector<Gesture> = _gesturesForTouchMap.get(touch);
		if (gesturesForTouch == null)
		{
			gesturesForTouch = new Vector<Gesture>();
			_gesturesForTouchMap.set(touch, gesturesForTouch);
		}
		else
		{
			// touch object may be pooled in the future
			gesturesForTouch.length = 0;
		}

		var target:Dynamic = touch.target;
		var displayListAdapter:IDisplayListAdapter = Gestouch.getDisplayListAdapter(target);
		if (displayListAdapter == null)
		{
			throw "Display list adapter not found for target of type '" + Type.typeof(target) + "'.";
		}
		var hierarchy:Vector<DisplayObject> = displayListAdapter.getHierarchy(target);
		var hierarchyLength:Int = hierarchy.length;
		if (hierarchyLength == 0)
		{
			throw "No hierarchy build for target '" + target +"'. Something is wrong with that IDisplayListAdapter.";
		}
		if (_stage != null && !Std.is(hierarchy[hierarchyLength - 1], Stage))
		{
			// Looks like some non-native (non DisplayList) hierarchy
			// but we must always handle gestures with Stage target
			// since Stage is anyway the top-most parent
			hierarchy[hierarchyLength] = _stage;
		}

		// Create a sorted(!) list of gestures which are interested in this touch.
		// Sorting priority: deeper target has higher priority, recently added gesture has higher priority.
		var gesturesForTarget:Vector<Gesture>;
		for (target in hierarchy)
		{
			gesturesForTarget = _gesturesForTargetMap.get(target);
			if (gesturesForTarget != null)
			{
				i = gesturesForTarget.length;
				while (i-- > 0)
				{
					gesture = gesturesForTarget[i];
					if (gesture.enabled &&
						(gesture.gestureShouldReceiveTouchCallback == null ||
						 gesture.gestureShouldReceiveTouchCallback(gesture, touch)))
					{
						//TODO: optimize performance! decide between unshift() vs [i++] = gesture + reverse()
						gesturesForTouch.unshift(gesture);
					}
				}
			}
		}

		// Then we populate them with this touch and event.
		// They might start tracking this touch or ignore it (via Gesture#ignoreTouch())
		i = gesturesForTouch.length;
		while (i-- > 0)
		{
			gesture = gesturesForTouch[i];
			// Check for state because previous (i+1) gesture may already abort current (i) one
			if (!_dirtyGesturesMap.exists(gesture))
			{
				gesture.touchBeginHandler(touch);
			}
			else
			{
				gesturesForTouch.splice(i, 1);
			}
		}
	}

	@:allow(org.gestouch.core.TouchesManager)
	private function onTouchMove(touch:Touch):Void
	{
		var gesturesForTouch:Vector<Gesture> = _gesturesForTouchMap.get(touch);
		var gesture:Gesture;
		var i:Int = gesturesForTouch.length;
		while (i-- > 0)
		{
			gesture = gesturesForTouch[i];

			if (!_dirtyGesturesMap.exists(gesture) && gesture.isTrackingTouch(touch.id))
			{
				gesture.touchMoveHandler(touch);
			}
			else
			{
				// gesture is no more interested in this touch (e.g. ignoreTouch was called)
				gesturesForTouch.splice(i, 1);
			}
		}
	}

	@:allow(org.gestouch.core.TouchesManager)
	private function onTouchEnd(touch:Touch):Void
	{
		var gesturesForTouch:Vector<Gesture> = _gesturesForTouchMap.get(touch);
		var gesture:Gesture;
		var i:Int = gesturesForTouch.length;
		while (i-- > 0)
		{
			gesture = gesturesForTouch[i];

			if (!_dirtyGesturesMap.exists(gesture) && gesture.isTrackingTouch(touch.id))
			{
				gesture.touchEndHandler(touch);
			}
		}

		gesturesForTouch.length = 0;// release for GC

		_gesturesForTouchMap.remove(touch);
	}

	@:allow(org.gestouch.core.TouchesManager)
	private function onTouchCancel(touch:Touch):Void
	{
		var gesturesForTouch:Vector<Gesture> = _gesturesForTouchMap.get(touch);
		var gesture:Gesture;
		var i:Int = gesturesForTouch.length;
		while (i-- > 0)
		{
			gesture = gesturesForTouch[i];

			if (!_dirtyGesturesMap.exists(gesture) && gesture.isTrackingTouch(touch.id))
			{
				gesture.touchCancelHandler(touch);
			}
		}

		gesturesForTouch.length = 0;// release for GC

		_gesturesForTouchMap.remove(touch);
	}

	private function gestureTarget_addedToStageHandler(event:Event):Void
	{
		var target:DisplayObject = cast(event.target, DisplayObject);
		target.removeEventListener(Event.ADDED_TO_STAGE, gestureTarget_addedToStageHandler);
		if (_stage != null)
		{
			onStageAvailable(target.stage);
		}
	}

	private function enterFrameHandler(event:Event):Void
	{
		resetDirtyGestures();
	}
}
