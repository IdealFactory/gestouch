package org.gestouch.extensions.native;

import openfl.display.DisplayObject;
import openfl.display.Stage;
import openfl.geom.Point;
import org.gestouch.core.ITouchHitTester;

class NativeTouchHitTester implements ITouchHitTester
{
	private var stage:Stage;

	public function new(stage:Stage)
	{
		if (stage == null)
		{
			throw "Missing stage argument.";
		}

		this.stage = stage;
	}

	public function hitTest(point:Point, possibleTarget:Dynamic = null):Dynamic
	{
		if (possibleTarget != null && Std.is(possibleTarget, DisplayObject))
		{
			return possibleTarget;
		}

		// Fallback target detection through getObjectsUnderPoint
		return DisplayObjectUtils.getTopTarget(stage, point);
	}
}
