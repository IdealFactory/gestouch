package org.gestouch.gestures;

import openfl.geom.Point;
import org.gestouch.core.GestureState;
import org.gestouch.core.Touch;

@:keepSub
class PanGesture extends AbstractContinuousGesture
{
	public var slop:Float = Gesture.DEFAULT_SLOP;
	/**
	 * Used for initial slop overcome calculations only.
	 */
	public var direction:Int = PanGestureDirection.NO_DIRECTION;

	public function new(target:Dynamic = null)
	{
		super(target);
		_offsetX = 0;
		_offsetY = 0;
	}


	private var _maxNumTouchesRequired:Int = 1024;
	public var maxNumTouchesRequired(get, set):Int;
	private function get_maxNumTouchesRequired():Int
	{
		return _maxNumTouchesRequired;
	}
	private function set_maxNumTouchesRequired(value:Int):Int
	{
		if (_maxNumTouchesRequired == value)
			return _maxNumTouchesRequired;

		if (value < minNumTouchesRequired)
			throw "maxNumTouchesRequired must be not less then minNumTouchesRequired";

		_maxNumTouchesRequired = value;

		return _maxNumTouchesRequired;
	}

	public var minNumTouchesRequired(get, set):Int;
	private var _minNumTouchesRequired:Int = 1;
	private function get_minNumTouchesRequired():Int
	{
		return _minNumTouchesRequired;
	}
	private function set_minNumTouchesRequired(value:Int):Int
	{
		if (_minNumTouchesRequired == value)
			return _minNumTouchesRequired;

		if (value > maxNumTouchesRequired)
			throw "minNumTouchesRequired must be not greater then maxNumTouchesRequired";

		_minNumTouchesRequired = value;

		return _minNumTouchesRequired;
	}

	public var offsetX(get, never):Float;
	private var _offsetX:Float;
	private function get_offsetX():Float
	{
		return _offsetX;
	}

	public var offsetY(get, never):Float;
	private var _offsetY:Float;
	private function get_offsetY():Float
	{
		return _offsetY;
	}

	override public function reflect():Class<Dynamic>
	{
		return PanGesture;
	}

	override public function onTouchBegin(touch:Touch):Void
	{
		if (touchesCount > maxNumTouchesRequired)
		{
			failOrIgnoreTouch(touch);
			return;
		}

		if (touchesCount >= minNumTouchesRequired)
		{
			updateLocation();
		}
	}

	override public function onTouchMove(touch:Touch):Void
	{
		if (touchesCount < minNumTouchesRequired)
			return;

		var prevLocationX:Float;
		var prevLocationY:Float;

		if (state == GestureState.POSSIBLE)
		{
			prevLocationX = location.x;
			prevLocationY = location.y;
			updateLocation();

			// Check if finger moved enough for gesture to be recognized
			var locationOffset:Point = touch.locationOffset;
			if (direction == PanGestureDirection.VERTICAL)
			{
				locationOffset.x = 0;
			}
			else if (direction == PanGestureDirection.HORIZONTAL)
			{
				locationOffset.y = 0;
			}

			if (locationOffset.length > slop || slop != slop)//faster isNaN(slop)
			{
				// NB! += instead of = for the case when this gesture recognition is delayed via requireGestureToFail
				_offsetX += location.x - prevLocationX;
				_offsetY += location.y - prevLocationY;

				setState(GestureState.BEGAN);
			}
		}
		else if (state == GestureState.BEGAN || state == GestureState.CHANGED)
		{
			prevLocationX = location.x;
			prevLocationY = location.y;
			updateLocation();
			_offsetX = location.x - prevLocationX;
			_offsetY = location.y - prevLocationY;

			setState(GestureState.CHANGED);
		}
	}

	override public function onTouchEnd(touch:Touch):Void
	{
		if (touchesCount < minNumTouchesRequired)
		{
			if (state == GestureState.POSSIBLE)
			{
				setState(GestureState.FAILED);
			}
			else
			{
				setState(GestureState.ENDED);
			}
		}
		else
		{
			updateLocation();
		}
	}

	override public function resetNotificationProperties():Void
	{
		super.resetNotificationProperties();

		_offsetX = _offsetY = 0;
	}
}
