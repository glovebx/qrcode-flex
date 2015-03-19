//Created by Action Script Viewer - http://www.buraks.com/asv
package com.greensock{
    import flash.utils.Dictionary;
    import flash.display.Shape;
    import flash.utils.getTimer;
    import flash.events.Event;
    import flash.events.*;
    import flash.utils.*;
    import flash.display.*;

    public class TweenNano {

        protected static var _time:Number;
        protected static var _frame:uint;
        protected static var _masterList:Dictionary = new Dictionary(false);
        protected static var _shape:Shape = new Shape();
        protected static var _tnInitted:Boolean;
        protected static var _reservedProps:Object = {
            "ease":1,
            "delay":1,
            "useFrames":1,
            "overwrite":1,
            "onComplete":1,
            "onCompleteParams":1,
            "runBackwards":1,
            "immediateRender":1,
            "onUpdate":1,
            "onUpdateParams":1
        };

        public var duration:Number;
        public var vars:Object;
        public var startTime:Number;
        public var target:Object;
        public var active:Boolean;
        public var gc:Boolean;
        public var useFrames:Boolean;
        public var ratio:Number = 0;
        protected var _ease:Function;
        protected var _initted:Boolean;
        protected var _propTweens:Array;

        public function TweenNano(_arg1:Object, _arg2:Number, _arg3:Object){
            if (!_tnInitted){
                _time = (getTimer() * 0.001);
                _frame = 0;
                _shape.addEventListener(Event.ENTER_FRAME, updateAll, false, 0, true);
                _tnInitted = true;
            };
            this.vars = _arg3;
            this.duration = _arg2;
            this.active = Boolean((((((_arg2 == 0)) && ((this.vars.delay == 0)))) && (!((this.vars.immediateRender == false)))));
            this.target = _arg1;
            if (typeof(this.vars.ease) != "function"){
                this._ease = TweenNano.easeOut;
            } else {
                this._ease = this.vars.ease;
            };
            this._propTweens = [];
            this.useFrames = Boolean((_arg3.useFrames == true));
            var _local4:Number = ((("delay" in this.vars)) ? Number(this.vars.delay) : 0);
            this.startTime = ((this.useFrames) ? (_frame + _local4) : (_time + _local4));
            var _local5:Array = _masterList[_arg1];
            if ((((((_local5 == null)) || ((int(this.vars.overwrite) == 1)))) || ((this.vars.overwrite == null)))){
                _masterList[_arg1] = [this];
            } else {
                _local5[_local5.length] = this;
            };
            if ((((this.vars.immediateRender == true)) || (this.active))){
                this.renderTime(0);
            };
        }

        public static function to(_arg1:Object, _arg2:Number, _arg3:Object):TweenNano{
            return (new (TweenNano)(_arg1, _arg2, _arg3));
        }

        public static function from(_arg1:Object, _arg2:Number, _arg3:Object):TweenNano{
            _arg3.runBackwards = true;
            if (!("immediateRender" in _arg3)){
                _arg3.immediateRender = true;
            };
            return (new (TweenNano)(_arg1, _arg2, _arg3));
        }

        public static function delayedCall(_arg1:Number, _arg2:Function, _arg3:Array=null, _arg4:Boolean=false):TweenNano{
            return (new (TweenNano)(_arg2, 0, {
                "delay":_arg1,
                "onComplete":_arg2,
                "onCompleteParams":_arg3,
                "useFrames":_arg4,
                "overwrite":0
            }));
        }

        public static function updateAll(_arg1:Event=null):void{
            var _local3:Array;
            var _local4:Object;
            var _local5:int;
            var _local6:Number;
            var _local7:TweenNano;
            _frame = (_frame + 1);
            _time = (getTimer() * 0.001);
            var _local2:Dictionary = _masterList;
            for (_local4 in _local2) {
                _local3 = _local2[_local4];
                _local5 = _local3.length;
                while (--_local5 > -1) {
                    _local7 = _local3[_local5];
                    _local6 = ((_local7.useFrames) ? _frame : _time);
                    if (((_local7.active) || (((!(_local7.gc)) && ((_local6 >= _local7.startTime)))))){
                        _local7.renderTime((_local6 - _local7.startTime));
                    } else {
                        if (_local7.gc){
                            _local3.splice(_local5, 1);
                        };
                    };
                };
                if (_local3.length == 0){
                    delete _local2[_local4];
                };
            };
        }

        public static function killTweensOf(_arg1:Object, _arg2:Boolean=false):void{
            var _local3:Array;
            var _local4:int;
            if ((_arg1 in _masterList)){
                if (_arg2){
                    _local3 = _masterList[_arg1];
                    _local4 = _local3.length;
                    while (--_local4 > -1) {
                        if (!TweenNano(_local3[_local4]).gc){
                            TweenNano(_local3[_local4]).complete(false);
                        };
                    };
                };
                delete _masterList[_arg1];
            };
        }

        private static function easeOut(_arg1:Number, _arg2:Number, _arg3:Number, _arg4:Number):Number{
            _arg1 = (_arg1 / _arg4);
            return (((-1 * _arg1) * (_arg1 - 2)));
        }


        public function init():void{
            var _local1:String;
            var _local2:Array;
            var _local3:int;
            for (_local1 in this.vars) {
                if (!(_local1 in _reservedProps)){
                    this._propTweens[this._propTweens.length] = [_local1, this.target[_local1], (((typeof(this.vars[_local1]))=="number") ? (this.vars[_local1] - this.target[_local1]) : Number(this.vars[_local1]))];
                };
            };
            if (this.vars.runBackwards){
                _local3 = this._propTweens.length;
                while (--_local3 > -1) {
                    _local2 = this._propTweens[_local3];
                    _local2[1] = (_local2[1] + _local2[2]);
                    _local2[2] = -(_local2[2]);
                };
            };
            this._initted = true;
        }

        public function renderTime(_arg1:Number):void{
            var _local2:Array;
            if (!this._initted){
                this.init();
            };
            var _local3:int = this._propTweens.length;
            if (_arg1 >= this.duration){
                _arg1 = this.duration;
                this.ratio = 1;
            } else {
                if (_arg1 <= 0){
                    this.ratio = 0;
                } else {
                    this.ratio = this._ease(_arg1, 0, 1, this.duration);
                };
            };
            while (--_local3 > -1) {
                _local2 = this._propTweens[_local3];
                this.target[_local2[0]] = (_local2[1] + (this.ratio * _local2[2]));
            };
            if (this.vars.onUpdate){
                this.vars.onUpdate.apply(null, this.vars.onUpdateParams);
            };
            if (_arg1 == this.duration){
                this.complete(true);
            };
        }

        public function complete(_arg1:Boolean=false):void{
            if (!_arg1){
                this.renderTime(this.duration);
                return;
            };
            this.kill();
            if (this.vars.onComplete){
                this.vars.onComplete.apply(null, this.vars.onCompleteParams);
            };
        }

        public function kill():void{
            this.gc = true;
            this.active = false;
        }


    }
}//package com.greensock
