package org.gestouch.core;

import openfl.geom.Point;

class Touch
{
	public var id:Int; // Touch point ID.
	public var target:Dynamic; // The original event target for this touch (touch began with).
	public var sizeX:Float;
	public var sizeY:Float;
	public var pressure:Float;

	public function new(id:Int = 0)
	{
		this.id = id;
	}

	public var location(get, never):Point;
	private var _location:Point;
    private function get_location():Point
	{
		return _location.clone();
	}

	@:allow(org.gestouch.core.TouchesManager)
	private function setLocation(x:Float, y:Float, locTime:Int):Void
	{
		_location = new Point(x, y);
		_beginLocation = _location.clone();
		_previsouLocation = _location.clone();
		_time = locTime;
		_beginTime = locTime;
	}

	@:allow(org.gestouch.core.TouchesManager)
	private function updateLocation(x:Float, y:Float, locTime:Int):Bool
	{
		if (_location != null)
		{
			if (_location.x == x && _location.y == y)
				return false;

			_previsouLocation.x = _location.x;
			_previsouLocation.y = _location.y;
			_location.x = x;
			_location.y = y;
			_time = locTime;
		}
		else
		{
			setLocation(x, y, _time);
		}

		return true;
	}

	public var previousLocation(get, never):Point;
	private var _previsouLocation:Point;
	private function get_previousLocation():Point
	{
		return _previsouLocation.clone();
	}

	public var beginLocation(get, never):Point;
	private var _beginLocation:Point;
    private function get_beginLocation():Point
	{
		return _beginLocation.clone();
	}

	public var locationOffset(get, null):Point;
    private function get_locationOffset():Point
	{
		return _location.subtract(_beginLocation);
	}

	public var time(default, never):Int;
	private var _time:Int;
    private function get_time():Int
	{
		return _time;
	}

	@:allow(org.gestouch.core.TouchesManager)
	private function setTime(value:Int):Void
	{
		_time = value;
	}

	public var beginTime:Int;
	private var _beginTime:Int;
    private function get_beginTime():Int
	{
		return _beginTime;
	}

	@:allow(org.gestouch.core.TouchesManager)
	private function setBeginTime(value:Int):Void
	{
		_beginTime = value;
	}

	public function clone():Touch
	{
		var touch:Touch = new Touch(id);
		touch._location = _location.clone();
		touch._beginLocation = _beginLocation.clone();
		touch.target = target;
		touch.sizeX = sizeX;
		touch.sizeY = sizeY;
		touch.pressure = pressure;
		touch._time = _time;
		touch._beginTime = _beginTime;

		return touch;
	}

	public function toString():String
	{
		return "Touch [id: " + id + ", location: " + _location + ", target: " + target + ", time: " + _time + "]";
	}
}
