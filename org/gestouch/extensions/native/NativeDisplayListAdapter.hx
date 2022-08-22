package org.gestouch.extensions.native;

import openfl.Vector;
import openfl.utils.Object;
import openfl.display.DisplayObject;
import openfl.display.DisplayObjectContainer;
import openfl.display.Stage;
import org.gestouch.core.IDisplayListAdapter;

class NativeDisplayListAdapter implements IDisplayListAdapter
{
	private var _targetWeekStorage:Map<{}, Bool>;

	public function new(target:DisplayObject = null)
	{
		if (target != null)
		{
			_targetWeekStorage = new Map<{}, Bool>();
			_targetWeekStorage.set(target, true);
		}
	}

	public var target(get, never):Dynamic;
	private function get_target():Dynamic
	{
		for (target in _targetWeekStorage.keys())
		{
			return target;
		}
		return null;
	}

	public function contains(object:Dynamic):Bool
	{
		if (Std.is(this.target, DisplayObjectContainer))
		{
			var targetAsDOC:DisplayObjectContainer = cast(this.target, DisplayObjectContainer);
			if (Std.is(targetAsDOC, Stage))
			{
				return true;
			}

			if (Std.is(object, DisplayObject))
			{
				var objectAsDO:DisplayObject = cast(object, DisplayObject);
				return targetAsDOC.contains(objectAsDO);
			}
		}
		/**
		 * There might be case when we use some old "software" 3D library for instace,
		 * which viewport is added to classic Display List. So native stage, root and some other
		 * sprites will actually be parents of 3D objects. To ensure all gestures (both for
		 * native and 3D objects) work correctly with each other contains() method should be
		 * a bit more sophisticated.
		 * But as all 3D engines (at least it looks like that) are moving towards Stage3D layer
		 * this task doesn't seem significant anymore. So I leave this implementation as
		 * comments in case someone will actually need it.
		 * Just uncomment this and it should work.

		// else: more complex case.
		// object is not of the same type as this.target (flash.display::DisplayObject)
		// it might we some 3D library object in it's viewport (which itself is in DisplayList).
		// So we perform more general check:
		const adapter:IDisplayListAdapter = Gestouch.gestouch_internal::getDisplayListAdapter(object);
		if (adapter)
		{
			return adapter.getHierarchy(object).indexOf(this.target) > -1;
		}
		*/

		return false;
	}

	public function getHierarchy(genericTarget:Dynamic):Vector<DisplayObject>
	{
		var list:Vector<DisplayObject> = new Vector<DisplayObject>();
		var i:Int = 0;
		var target:DisplayObject = cast(genericTarget, DisplayObject);
		while (target != null)
		{
			list[i] = target;
			target = target.parent;
			i++;
		}

		return list;
	}

	public function reflect():Class<Dynamic>
	{
		return NativeDisplayListAdapter;
	}
}
