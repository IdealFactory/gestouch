package org.gestouch.extensions.native;

import openfl.display.DisplayObjectContainer;
import openfl.display.DisplayObject;
import openfl.display.InteractiveObject;
import openfl.display.Stage;
import openfl.geom.Point;

class DisplayObjectUtils
{
	/**
	 * Searches display list for top most instance of InteractiveObject.
	 * Checks if mouseEnabled is true and (optionally) parent's mouseChildren.
	 * @param stage                Stage object.
	 * @param point                Global point to test.
	 * @return                    Top most InteractiveObject or Stage.
	 */
	public static function getTopTarget(stage:Stage, point:Point):InteractiveObject
	{
		// reversing so we search top down
		var targets:Array<DisplayObject> = stage.getObjectsUnderPoint(point);
		targets.reverse();

		if (targets.length <= 0) return stage;

		for (i in 0...targets.length)
		{
			var target:DisplayObject = cast(targets[i], DisplayObject);
			while (target != stage)
			{
				if (Std.is(target, InteractiveObject))
				{
					if (cast(target, InteractiveObject).mouseEnabled)
					{
						var lastMouseActive:InteractiveObject = cast(target, InteractiveObject);
						var parent:DisplayObjectContainer = target.parent;
						while (parent != null)
						{
							if (lastMouseActive == null && parent.mouseEnabled)
							{
								lastMouseActive = parent;
							}
							else if (!parent.mouseChildren)
							{
								if (parent.mouseEnabled)
								{
									lastMouseActive = parent;
								}
								else
								{
									lastMouseActive = null;
								}
							}
							parent = parent.parent;
						}

						if (lastMouseActive != null)
						{
							return lastMouseActive;
						}
						else
						{
							return stage;
						}
					}
				}
				else
				{
					target = target.parent;
				}
			}
		}

		return stage;
	}
}
