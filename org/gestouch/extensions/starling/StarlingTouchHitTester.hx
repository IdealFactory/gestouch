package org.gestouch.extensions.starling;

import openfl.geom.Point;
import org.gestouch.core.ITouchHitTester;
import org.gestouch.extensions.starling.StarlingUtils;
import starling.core.Starling;
import starling.display.DisplayObject;

class StarlingTouchHitTester implements ITouchHitTester
{
	private var _starling:Starling;

	public function new(starling:Starling)
	{
		if (starling == null)
		{
			throw "Missing starling argument.";
		}

		_starling = starling;
	}

	public function hitTest(point:Point, possibleTarget:Dynamic = null):Dynamic
	{
		if (possibleTarget != null && Std.is(possibleTarget, starling.display.DisplayObject))
		{
			return possibleTarget;
		}

		point = StarlingUtils.adjustGlobalPoint(_starling, point);

		if (_starling.stage.hitTest(point, true) != null)
		{
			return _starling.stage.hitTest(point, true);
		}

		return  _starling.nativeStage;
	}
}
