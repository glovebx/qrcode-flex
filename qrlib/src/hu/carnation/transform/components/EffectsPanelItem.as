//Created by Action Script Viewer - http://www.buraks.com/asv
package hu.carnation.transform.components{
    import com.greensock.TweenNano;
    import com.greensock.easing.Strong;
    
    //import fl.controls.ColorPicker;
    ///import fl.events.ColorPickerEvent;
	import mx.controls.ColorPicker;
	import mx.events.ColorPickerEvent;
    
    import flash.display.MovieClip;
    import flash.display.Sprite;
    import flash.events.Event;
    import flash.text.TextField;
    
    import mx.events.ColorPickerEvent;

    public class EffectsPanelItem extends Sprite {

        public static const ITEM_COLLAPSE:String = "onCollapse";

        public var bottombg:MovieClip;//instance name
        public var checkBox:CheckBox;//instance name
        public var slider:Slider;//instance name
        public var labelTf:TextField;//instance name
        public var colorPicker:ColorPicker;//instance name
        private var _opened:Boolean;
        private var _isLast:Boolean;
        private var _label:String;
        private var _min:Number;
        private var _max:Number;
        private var _stepSize:Number;
        private var _hasColorPicker:Boolean;
        private var _selected:Boolean;
        private var _value:Number;

        public function EffectsPanelItem(_arg1:String, _arg2:Number, _arg3:Number, _arg4:Number, _arg5:Number, _arg6:Boolean=false, _arg7:Boolean=false):void{
            this.label = _arg1;
            this.min = _arg2;
            this.max = _arg3;
            this.stepSize = _arg4;
            this.value = _arg5;
            this.hasColorPicker = _arg7;
            this.isLast = _arg6;
            if (_arg6){
                this.bottombg.gotoAndStop(2);
            };
            this.slider.min = _arg2;
            this.slider.max = _arg3;
            this.slider.value = _arg5;
            this.opened = false;
            this.addEventListener(Event.ADDED_TO_STAGE, this.init, false, 0, true);
        }

        private function init(_arg1:Event):void{
            removeEventListener(Event.ADDED_TO_STAGE, this.init);
            this.addEventListener(Event.REMOVED_FROM_STAGE, this.dispose, false, 0, true);
            this.checkBox.addEventListener(Event.CHANGE, this.checkBoxChange, false, 0, true);
            if (this.hasColorPicker){
                this.colorPicker.visible = false;
            };
            this.hideSlider(true);
        }

        private function checkBoxChange(_arg1:Event):void{
            this.selected = this.checkBox.selected;
            if (this.selected){
                this.showSlider();
                if (this.hasColorPicker){
                    this.colorPicker.visible = true;
                };
            } else {
                this.hideSlider();
                if (this.hasColorPicker){
                    this.colorPicker.visible = false;
                };
            };
        }

        private function sliderChange(_arg1:Event):void{
            this.value = this.slider.value;
        }

        private function dispose(_arg1:Event=null):void{
            removeEventListener(Event.REMOVED_FROM_STAGE, this.dispose);
            this.checkBox.removeEventListener(Event.CHANGE, this.checkBoxChange);
            this.slider.removeEventListener(Event.CHANGE, this.sliderChange);
        }

        private function hideSlider(_arg1:Boolean=false):void{
            this.opened = false;
            dispatchEvent(new Event(ITEM_COLLAPSE));
            this.slider.removeEventListener(Event.CHANGE, this.sliderChange);
            this.slider.visible = false;
            if (_arg1){
                this.bottombg.y = 0;
            } else {
                TweenNano.to(this.bottombg, 0.3, {
                    "y":0,
                    "ease":Strong.easeInOut
                });
            };
        }

        private function showSlider():void{
            this.opened = true;
            dispatchEvent(new Event(ITEM_COLLAPSE));
            this.slider.addEventListener(Event.CHANGE, this.sliderChange, false, 0, true);
            TweenNano.to(this.bottombg, 0.3, {
                "y":20,
                "ease":Strong.easeInOut,
                "onComplete":function (){
                    slider.visible = true;
                }
            });
        }

        public function get label():String{
            return (this._label);
        }

        public function set label(_arg1:String):void{
            this._label = _arg1;
            if (this.labelTf){
                this.labelTf.text = _arg1;
            };
        }

        public function get min():Number{
            return (this._min);
        }

        public function set min(_arg1:Number):void{
            this._min = _arg1;
            if (this.slider){
                this.slider.min = _arg1;
            };
        }

        public function get max():Number{
            return (this._max);
        }

        public function set max(_arg1:Number):void{
            this._max = _arg1;
            if (this.slider){
                this.slider.max = _arg1;
            };
        }

        public function get stepSize():Number{
            return (this._stepSize);
        }

        public function set stepSize(_arg1:Number):void{
            this._stepSize = _arg1;
            if (this.slider){
                this.slider.stepSize = _arg1;
            };
        }

        public function get hasColorPicker():Boolean{
            return (this._hasColorPicker);
        }

        public function set hasColorPicker(_arg1:Boolean):void{
            this._hasColorPicker = _arg1;
            this.colorPicker.visible = _arg1;
            if (_arg1){
                this.colorPicker.buttonMode = true;
                this.colorPicker.addEventListener(mx.events.ColorPickerEvent.CHANGE, this.onColorChange, false, 0, true);
            };
        }

        private function onColorChange(_arg1:mx.events.ColorPickerEvent):void{
            dispatchEvent(new Event(Event.CHANGE));
        }

        public function get opened():Boolean{
            return (this._opened);
        }

        public function set opened(_arg1:Boolean):void{
            this._opened = _arg1;
        }

        public function get isLast():Boolean{
            return (this._isLast);
        }

        public function set isLast(_arg1:Boolean):void{
            this._isLast = _arg1;
        }

        public function get selected():Boolean{
            return (this._selected);
        }

        public function set selected(_arg1:Boolean):void{
            this._selected = _arg1;
            dispatchEvent(new Event(Event.CHANGE));
        }

        public function get selectedColor():uint{
            return (this.colorPicker.selectedColor);
        }

        public function get value():Number{
            return (this._value);
        }

        public function set value(_arg1:Number):void{
            this._value = _arg1;
            dispatchEvent(new Event(Event.CHANGE));
        }


    }
}//package hu.carnation.transform.components
