package org.gestouch.core;

import haxe.ds.StringMap;
import org.gestouch.gestures.Gesture;
import org.gestouch.core.TouchesManager;
import org.gestouch.core.GesturesManager;
import org.gestouch.input.NativeInputAdapter;
import org.gestouch.extensions.native.NativeDisplayListAdapter;

class Gestouch
{
	private static var _displayListAdaptersMap:StringMap<IDisplayListAdapter> = new StringMap<IDisplayListAdapter>();

	@:isVar public static var inputAdapter(get, set):IInputAdapter;
	private static function get_inputAdapter():IInputAdapter
	{
		return inputAdapter;
	}
	private static function set_inputAdapter(value:IInputAdapter):IInputAdapter
	{
		if (inputAdapter == value)
			return null;

		inputAdapter = value;
		if (inputAdapter != null)
		{
			inputAdapter.touchesManager = touchesManager;
			inputAdapter.init();
		}

		return inputAdapter;
	}

	public static var touchesManager(get, null):TouchesManager;
	private static function get_touchesManager():TouchesManager
	{
		if (touchesManager == null)
		{
			touchesManager = new TouchesManager(gesturesManager);
		}
		return touchesManager;
	}

	public static var gesturesManager(get, null):GesturesManager;
	private static function get_gesturesManager():GesturesManager
	{
		if (gesturesManager == null)
		{
			gesturesManager = new GesturesManager();
		}
		return gesturesManager;
	}

	public static function addDisplayListAdapter(targetClass:Class<Dynamic>, adapter:IDisplayListAdapter):Void
	{
		if (targetClass == null || adapter == null)
		{
			throw "Argument error: both arguments required.";
		}

		_displayListAdaptersMap.set(Type.getClassName(targetClass), adapter);
	}

	public static function addTouchHitTester(hitTester:ITouchHitTester, priority:Int = 0):Void
	{
		touchesManager.addTouchHitTester(hitTester, priority);
	}

	public static function removeTouchHitTester(hitTester:ITouchHitTester):Void
	{
		touchesManager.removeTouchHitTester(hitTester);
	}

	@:allow(org.gestouch.gestures.Gesture)
	private static function createGestureTargetAdapter(target:Dynamic):IDisplayListAdapter
	{
		var adapter:IDisplayListAdapter = Gestouch.getDisplayListAdapter(target);
		if (adapter == null)
		{
			throw ("Cannot create adapter for target " + target +
					" of type " + Type.typeof(target) + ". " +
					"Configure first using Gestouch.addDisplayListAdapter().");
		}

		return Type.createInstance(Type.getClass(adapter), [target]);
	}

	@:allow(org.gestouch.core.GesturesManager)
	private static function getDisplayListAdapter(object:Dynamic):IDisplayListAdapter
	{
		for (key in _displayListAdaptersMap.keys())
		{
			if (Std.is(object, Type.resolveClass(key)))
			{
				return cast(_displayListAdaptersMap.get(key), IDisplayListAdapter) ;
			}
		}

		return null;
	}

	public static function init():Void
	{
//		if (Starling.current == null || Starling.current.nativeStage == null)
//		{
//			throw "Starling must be initialized and the Root class must be on the stage";
//		}
//
//		// Initialize native (default) input adapter. Needed for non-DisplayList usage.
//		if (Gestouch.inputAdapter == null)
//		{
//			Gestouch.inputAdapter = new NativeInputAdapter(Starling.current.nativeStage, true, true);
//		}
//
//		Gestouch.addDisplayListAdapter(flash.display.DisplayObject, new NativeDisplayListAdapter());
//		Gestouch.addDisplayListAdapter(starling.display.DisplayObject, new StarlingDisplayListAdapter());
//		Gestouch.addTouchHitTester(new StarlingTouchHitTester(Starling.current), -1);
	}
}
