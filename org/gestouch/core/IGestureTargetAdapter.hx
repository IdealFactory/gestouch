package org.gestouch.core;

interface IGestureTargetAdapter
{
	var target(get, never):Dynamic;
	function contains(object:Dynamic):Bool;
}
