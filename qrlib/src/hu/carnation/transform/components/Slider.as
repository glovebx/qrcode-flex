//Created by Action Script Viewer - http://www.buraks.com/asv
package hu.carnation.transform.components{
    import flash.display.Sprite;
    import org.casalib.math.Range;
    import flash.events.Event;
    import flash.events.MouseEvent;
    import flash.geom.Rectangle;
    import org.casalib.math.Percent;

    public class Slider extends Sprite {

        public static const LEFT_STARTPOS:Number = 6;
        public static const SLIDER_WIDTH:Number = 96;

        public var dragger:Sprite;//instance name
        private var _value:Number;
        private var _min:Number;
        private var _max:Number;
        private var _stepSize:Number;
        private var range:Range;

        public function Slider():void{
            this.addEventListener(Event.ADDED_TO_STAGE, this.init, false, 0, true);
        }

        private function init(_arg1:Event):void{
            removeEventListener(Event.ADDED_TO_STAGE, this.init);
            this.addEventListener(Event.REMOVED_FROM_STAGE, this.dispose, false, 0, true);
            this.dragger.addEventListener(MouseEvent.MOUSE_DOWN, this.startDragging, false, 0, true);
            this.dragger.addEventListener(MouseEvent.MOUSE_UP, this.stopDragging, false, 0, true);
            this.dragger.buttonMode = true;
            this.dragger.mouseChildren = false;
            this.range = new Range(this.min, this.max);
            this.dragger.x = ((this.range.getPercentOfValue(this.value).valueOf() * SLIDER_WIDTH) + LEFT_STARTPOS);
        }

        private function startDragging(_arg1:MouseEvent):void{
            _arg1.stopImmediatePropagation();
            this.dragger.startDrag(false, new Rectangle(LEFT_STARTPOS, 1, SLIDER_WIDTH, 0));
            stage.addEventListener(MouseEvent.MOUSE_UP, this.stopDragging, false, 0, true);
            this.addEventListener(MouseEvent.MOUSE_MOVE, this.onValueChanged, false, 0, true);
        }

        private function stopDragging(_arg1:MouseEvent):void{
            _arg1.stopImmediatePropagation();
            this.dragger.stopDrag();
            stage.removeEventListener(MouseEvent.MOUSE_UP, this.stopDragging);
            this.removeEventListener(MouseEvent.MOUSE_MOVE, this.onValueChanged);
        }

        private function onValueChanged(_arg1:MouseEvent):void{
            var _local2:Number = ((this.dragger.x - LEFT_STARTPOS) / SLIDER_WIDTH);
            this.value = this.range.getValueOfPercent(new Percent(_local2));
            dispatchEvent(new Event(Event.CHANGE));
        }

        public function dispose(_arg1:Event=null):void{
            removeEventListener(Event.REMOVED_FROM_STAGE, this.dispose);
            this.dragger.removeEventListener(MouseEvent.MOUSE_DOWN, this.startDragging);
            this.dragger.removeEventListener(MouseEvent.MOUSE_UP, this.stopDragging);
            stage.removeEventListener(MouseEvent.MOUSE_UP, this.stopDragging);
            this.removeEventListener(MouseEvent.MOUSE_MOVE, this.onValueChanged);
        }

        public function get value():Number{
            return (this._value);
        }

        public function set value(_arg1:Number):void{
            this._value = _arg1;
        }

        public function get min():Number{
            return (this._min);
        }

        public function set min(_arg1:Number):void{
            this._min = _arg1;
        }

        public function get max():Number{
            return (this._max);
        }

        public function set max(_arg1:Number):void{
            this._max = _arg1;
        }

        public function get stepSize():Number{
            return (this._stepSize);
        }

        public function set stepSize(_arg1:Number):void{
            this._stepSize = _arg1;
        }


    }
}//package hu.carnation.transform.components
