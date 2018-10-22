package org.gestouch.extensions.starling;

import openfl.geom.Rectangle;
import starling.display.Stage;
import openfl.geom.Point;
import starling.core.Starling;

class StarlingUtils
{
	/**
	 * Transforms real global point (in the scope of flash.display::Stage) into
	 * starling stage "global" coordinates.
	 */
	public static function adjustGlobalPoint(starling:Starling, point:Point):Point
	{
		var vp:Rectangle = starling.viewPort;
		var stStage:Stage = starling.stage;

		if (vp.x != 0 || vp.y != 0 ||
			stStage.stageWidth != vp.width || stStage.stageHeight != vp.height)
		{
			point = point.clone();

			// Same transformation they do in Starling
			// WTF!? https://github.com/PrimaryFeather/Starling-Framework/issues/72
			point.x = stStage.stageWidth * (point.x - vp.x) / vp.width;
			point.y = stStage.stageHeight * (point.y - vp.y) / vp.height;
		}

		return point;
	}
}
