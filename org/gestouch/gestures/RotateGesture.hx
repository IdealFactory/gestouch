package org.gestouch.gestures;

import org.gestouch.core.GestureState;
import org.gestouch.core.Touch;
import openfl.geom.Point;

@:keepSub
class RotateGesture extends AbstractContinuousGesture
{
	public var slop:Float = Gesture.DEFAULT_SLOP;

	private var _touch1:Touch;
	private var _touch2:Touch;
	private var _transformVector:Point;
	private var _thresholdAngle:Float;

	public function new(target:Dynamic = null)
	{
		super(target);
	}

	public var rotation(get, default):Float = 0;
	private function get_rotation():Float
	{
		return rotation;
	}

	override public function reflect():Class<Dynamic>
	{
		return RotateGesture;
	}

	override public function onTouchBegin(touch:Touch):Void
	{
		if (touchesCount > 2)
		{
			failOrIgnoreTouch(touch);
			return;
		}

		if (touchesCount == 1)
		{
			_touch1 = touch;
		}
		else
		{
			_touch2 = touch;

			_transformVector = _touch2.location.subtract(_touch1.location);

			// @see chord length formula
			_thresholdAngle = Math.asin(slop / (2 * _transformVector.length)) * 2;
		}
	}


	override public function onTouchMove(touch:Touch):Void
	{
		if (touchesCount < 2)
			return;

		var currTransformVector:Point = _touch2.location.subtract(_touch1.location);
		var cross:Float = (_transformVector.x * currTransformVector.y) - (currTransformVector.x * _transformVector.y);
		var dot:Float = (_transformVector.x * currTransformVector.x) + (_transformVector.y * currTransformVector.y);
		var rotation:Float = Math.atan2(cross, dot);

		if (state == GestureState.POSSIBLE)
		{
			var absRotation:Float = rotation >= 0 ? rotation : -rotation;
			if (absRotation < _thresholdAngle)
			{
				// not recognized yet
				return;
			}

			// adjust angle to avoid initial "jump"
			rotation = rotation > 0 ? rotation - _thresholdAngle : rotation + _thresholdAngle;
		}

		_transformVector.x = currTransformVector.x;
		_transformVector.y = currTransformVector.y;
		this.rotation = rotation;

		updateLocation();

		if (state == GestureState.POSSIBLE)
		{
			setState(GestureState.BEGAN);
		}
		else
		{
			setState(GestureState.CHANGED);
		}
	}


	override public function onTouchEnd(touch:Touch):Void
	{
		if (touchesCount == 0)
		{
			if (state == GestureState.BEGAN || state == GestureState.CHANGED)
			{
				setState(GestureState.ENDED);
			}
			else if (state == GestureState.POSSIBLE)
			{
				setState(GestureState.FAILED);
			}
		}
		else// == 1
		{
			if (touch == _touch1)
			{
				_touch1 = _touch2;
			}
			_touch2 = null;

			if (state == GestureState.BEGAN || state == GestureState.CHANGED)
			{
				updateLocation();
				setState(GestureState.CHANGED);
			}
		}
	}


	override public function resetNotificationProperties():Void
	{
		super.resetNotificationProperties();

		rotation = 0;
	}
}
