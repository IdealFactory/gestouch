package org.gestouch.core;

import openfl.Vector;
import org.gestouch.input.NativeInputAdapter;
import openfl.Lib;
import openfl.display.Stage;
import openfl.geom.Point;

class TouchesManager
{
	private var _gesturesManager:GesturesManager;
	private var _touchesMap:Map<Int, Touch> = new Map<Int, Touch>();
	private var _hitTesterPrioritiesMap:Map<ITouchHitTester, Int> = new Map<ITouchHitTester, Int>();
	private var _hitTesters:Vector<ITouchHitTester> = new Vector<ITouchHitTester>();

	public function new(gesturesManager:GesturesManager)
	{
		_gesturesManager = gesturesManager;
	}

	public var activeTouchesCount(get, null):Int;
	private function get_activeTouchesCount():Int
	{
		return activeTouchesCount;
	}

	public function getTouches(target:Dynamic = null):Vector<Touch>
	{
		var touches:Vector<Touch> = new Vector<Touch>();
		if (target == null || Std.is(target, Stage))
		{
			// return all touches
			var i:Int = 0;
			for (touch in _touchesMap)
			{
				touches[i++] = touch;
			}
		}

		return touches;
	}

	@:allow(org.gestouch.core.Gestouch)
	private function addTouchHitTester(touchHitTester:ITouchHitTester, priority:Int = 0):Void
	{
		if (touchHitTester == null)
		{
			throw "Argument must be non null.";
		}

		if (_hitTesters.indexOf(touchHitTester) == -1)
		{
			_hitTesters.push(touchHitTester);
		}

		_hitTesterPrioritiesMap[touchHitTester] = priority;
		// Sort hit testers using their priorities
		_hitTesters.sort(hitTestersSorter);
	}

	@:allow(org.gestouch.core.Gestouch)
	private function removeTouchHitTester(touchHitTester:ITouchHitTester):Void
	{
		if (touchHitTester == null)
		{
			throw "Argument must be non null.";
		}

		var index:Int = _hitTesters.indexOf(touchHitTester);
		if (index == -1)
		{
			throw "This touchHitTester is not registered.";
		}

		_hitTesters.splice(index, 1);
		_hitTesterPrioritiesMap.remove(touchHitTester);
	}

	@:allow(org.gestouch.input.NativeInputAdapter)
	private function onTouchBegin(touchID:Int, x:Float, y:Float, possibleTarget:Dynamic = null):Bool
	{
		if (_touchesMap.exists(touchID))
			return false;// touch with specified ID is already registered and being tracked

		var location:Point = new Point(x, y);

		for (registeredTouch in _touchesMap)
		{
			// Check if touch at the same location exists.
			// In case we listen to both TouchEvents and MouseEvents, one of them will come first
			// (right now looks like MouseEvent dispatched first, but who know what Adobe will
			// do tomorrow). This check helps to filter out the one comes after.

			// NB! According to the tests with some IR multitouch frame and Windows computer
			// TouchEvent comes first, but the following MouseEvent has slightly offset location
			// (1px both axis). That is why Point#distance() used instead of Point#equals()
			if (Point.distance(cast(registeredTouch, Touch).location, location) < 2)
				return false;
		}

		var touch:Touch = createTouch();
		touch.id = touchID;

		var target:Dynamic = null;
		var altTarget:Dynamic = null;
		for (hitTester in _hitTesters)
		{
			target = cast(hitTester, ITouchHitTester).hitTest(location, possibleTarget);
			if (target)
			{
				if (Std.is(target, Stage))
				{
					// NB! Target is flash.display::Stage is a special case. If it is true, we want
					// to give a try to a lower-priority (Stage3D) hit-testers.
					altTarget = target;
					continue;
				}
				else
				{
					// We found a target.
					break;
				}
			}
		}

		if (target == null && altTarget == null)
		{
			throw "No target found for Touch. " +
					"Something is wrong, at least one of ITouchHitTester should return hit-test object. " +
					"@see Gestouch.addTouchHitTester().";
		}

		if (target != null)
		{
			touch.target = target;
		}
		else if (altTarget != null)
		{
			touch.target = altTarget;
		}

		touch.setLocation(x, y, Lib.getTimer());

		_touchesMap[touchID] = touch;
		activeTouchesCount++;

		_gesturesManager.onTouchBegin(touch);

		return true;
	}

	@:allow(org.gestouch.input.NativeInputAdapter)
	private function onTouchMove(touchID:Int, x:Float, y:Float):Void
	{
		if (!_touchesMap.exists(touchID))
			return;// touch with specified ID isn't registered

		var touch:Touch = _touchesMap[touchID];
		if (touch.updateLocation(x, y, Lib.getTimer()))
		{
			// NB! It appeared that native TOUCH_MOVE event is dispatched also when
			// the location is the same, but size has changed. We are only interested
			// in location at the moment, so we shall ignore irrelevant calls.

			_gesturesManager.onTouchMove(touch);
		}
	}

	@:allow(org.gestouch.input.NativeInputAdapter)
	private function onTouchEnd(touchID:Int, x:Float, y:Float):Void
	{
		if (!_touchesMap.exists(touchID))
			return;// touch with specified ID isn't registered

		var touch:Touch = _touchesMap[touchID];
		touch.updateLocation(x, y, Lib.getTimer());

		_touchesMap.remove(touchID);
		activeTouchesCount--;

		_gesturesManager.onTouchEnd(touch);

		touch.target = null;
	}

	@:allow(org.gestouch.input.NativeInputAdapter)
	private function onTouchCancel(touchID:Int, x:Float, y:Float):Void
	{
		if (!_touchesMap.exists(touchID))
			return;// touch with specified ID isn't registered

		var touch:Touch = _touchesMap[touchID];
		touch.updateLocation(x, y, Lib.getTimer());

		_touchesMap.remove(touchID);
		activeTouchesCount--;

		_gesturesManager.onTouchCancel(touch);

		touch.target = null;
	}

	private function createTouch():Touch
	{
		return new Touch();
	}

	/**
	 * Sorts from higher priority to lower. Items with the same priority keep the order
	 * of addition, e.g.:
	 * add(a), add(b), add(c, -1), add(d, 1) will be ordered to
	 * d, a, b, c
	 */
	private function hitTestersSorter(x:ITouchHitTester, y:ITouchHitTester):Int
	{
		var d:Int = cast(_hitTesterPrioritiesMap.get(x), Int) - cast(_hitTesterPrioritiesMap.get(y), Int);
		if (d > 0)
			return -1;
		else if (d < 0)
			return 1;

		return _hitTesters.indexOf(x) > _hitTesters.indexOf(y) ? 1 : -1;
	}
}
