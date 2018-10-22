# gestouch (haxe)
A multitouch gesture recognition library.

This is a Haxe port of the original library by fijot @ [https://github.com/fljot/Gestouch](https://github.com/fljot/Gestouch) and licensed under the same license as the original library.

This is intended to be used with OpenFL and Starling

## Quickstart
After the Starling instance has been instantiated simply call
```
Gestouch.init();
```
All gestures dispatch events of type GestureEvent:  
*GestureEvent.GESTURE_STATE_CHANGE*  
*GestureEvent.GESTURE_IDLE*  
*GestureEvent.GESTURE_POSSIBLE*  
*GestureEvent.GESTURE_FAILED*

Discrete gestures also dispatch:  
*GestureEvent.GESTURE_RECOGNIZED*

Continuous gestures also dispatch:  
*GestureEvent.GESTURE_BEGAN*  
*GestureEvent.GESTURE_CHANGED*  
*GestureEvent.GESTURE_ENDED*

Example TapGesture:
```
_tapGesture = new TapGesture(this);
_tapGesture.addEventListener(GestureEvent.GESTURE_RECOGNIZED, onTap);

private function onTap(e:GestureEvent):Void
{
    // handle tap gesture!;
}
```


## Advanced Usage

```
_panGesture = new PanGesture(this);
_panGesture.addEventListener(GestureEvent.GESTURE_BEGAN, onPanGestureBegan);
_panGesture.addEventListener(GestureEvent.GESTURE_CHANGED, onPanGesture);
_panGesture.addEventListener(GestureEvent.GESTURE_ENDED, onPanGestureEnded);

private function onPanGesture(e:GestureEvent):Void
{
    var gesture:PanGesture = cast(e.target, PanGesture);
    var effectiveScale:Point = getEffectiveScale(this);
    this.x += gesture.offsetX * Starling.current.stage.stageWidth / Starling.current.viewPort.width * (1 / effectiveScale.x);
    this.y += gesture.offsetY * Starling.current.stage.stageHeight / Starling.current.viewPort.height * (1 / effectiveScale.y);
}
		
private function getEffectiveScale(dob:DisplayObjectContainer, scale:Point = null):Point
{
    if (scale == null)
    {
        scale = new Point(1.0, 1.0);
    }

    if (dob.parent != null)
    {
        scale.x *= dob.parent.scaleX;
        scale.y *= dob.parent.scaleY;

        return getEffectiveScale(dob.parent, scale);
    }

    return scale;
}
```