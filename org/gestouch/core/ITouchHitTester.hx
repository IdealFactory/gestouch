package org.gestouch.core;

import openfl.geom.Point;

interface ITouchHitTester
{
	function hitTest(point:Point, possibleTarget:Dynamic = null):Dynamic;
}
