package org.gestouch.core;

import org.gestouch.core.TouchesManager;

interface IInputAdapter
{
	var touchesManager(never, set):TouchesManager;
	function init():Void;
}
