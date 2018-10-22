package org.gestouch.extensions.starling;

import openfl.Vector;
import org.gestouch.core.IDisplayListAdapter;
import starling.display.DisplayObject;
import starling.display.DisplayObjectContainer;

class StarlingDisplayListAdapter implements IDisplayListAdapter
{
	private var targetWeekStorage:Map<{}, Bool>;

	public function new(target:DisplayObject = null)
	{
		if (target != null)
		{
			targetWeekStorage = new Map<{}, Bool>();
			targetWeekStorage.set(target, true);
		}
	}

	public var target(get, never):Dynamic;
	private function get_target():Dynamic
	{
		for (target in targetWeekStorage.keys())
		{
			return target;
		}
		return null;
	}

	public function contains(object:Dynamic):Bool
	{
		var targetAsDOC:DisplayObjectContainer = cast(this.target, DisplayObjectContainer);
		var objectAsDO:DisplayObject = cast(object, DisplayObject);
		return (targetAsDOC != null && objectAsDO != null && targetAsDOC.contains(objectAsDO));
	}

	public function getHierarchy(genericTarget:Dynamic):Vector<Dynamic>
	{
		var list:Vector<Dynamic> = new Vector<Dynamic>();
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
		return StarlingDisplayListAdapter;
	}
}
