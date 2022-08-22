package org.gestouch.core;

import openfl.Vector;
import openfl.display.DisplayObject;
interface IDisplayListAdapter extends IGestureTargetAdapter
{
	function getHierarchy(target:Dynamic):Vector<DisplayObject>;
	function reflect():Class<Dynamic>;
}
