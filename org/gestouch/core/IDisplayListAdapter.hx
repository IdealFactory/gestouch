package org.gestouch.core;

import openfl.Vector;
interface IDisplayListAdapter extends IGestureTargetAdapter
{
	function getHierarchy(target:Dynamic):Vector<Dynamic>;
	function reflect():Class<Dynamic>;
}
