//Created by Action Script Viewer - http://www.buraks.com/asv
package com.greensock.transform{
    import flash.events.EventDispatcher;
    import flash.display.Stage;
    import flash.display.DisplayObject;
    import flash.display.InteractiveObject;
    import flash.geom.Point;
    import flash.geom.Rectangle;
    import flash.utils.getDefinitionByName;
    import flash.text.TextField;
    import flash.events.Event;
    import com.greensock.events.TransformEvent;
    import flash.events.MouseEvent;
    import flash.text.TextFormat;
    import flash.text.TextLineMetrics;
    import flash.display.Sprite;
    import flash.display.Graphics;
    import flash.geom.Matrix;
    import com.greensock.transform.utils.MatrixTools;

    public class TransformItem extends EventDispatcher {

        public static const VERSION:Number = 1.87;
        protected static const _DEG2RAD:Number = (Math.PI / 180);//0.0174532925199433
        protected static const _RAD2DEG:Number = (180 / Math.PI);//57.2957795130823

        protected static var _proxyCount:uint = 0;

        protected var _hasSelectableText:Boolean;
        protected var _stage:Stage;
        protected var _scaleMode:String;
        protected var _target:DisplayObject;
        protected var _proxy:InteractiveObject;
        protected var _offset:Point;
        protected var _origin:Point;
        protected var _localOrigin:Point;
        protected var _baseRect:Rectangle;
        protected var _bounds:Rectangle;
        protected var _targetObject:DisplayObject;
        protected var _allowDelete:Boolean;
        protected var _constrainScale:Boolean;
        protected var _lockScale:Boolean;
        protected var _lockRotation:Boolean;
        protected var _lockPosition:Boolean;
        protected var _enabled:Boolean;
        protected var _selected:Boolean;
        protected var _minScaleX:Number;
        protected var _minScaleY:Number;
        protected var _maxScaleX:Number;
        protected var _maxScaleY:Number;
        protected var _cornerAngleTL:Number;
        protected var _cornerAngleTR:Number;
        protected var _cornerAngleBR:Number;
        protected var _cornerAngleBL:Number;
        protected var _createdManager:TransformManager;
        protected var _isFlex:Boolean;
        protected var _frameCount:uint = 0;
        protected var _dispatchScaleEvents:Boolean;
        protected var _dispatchMoveEvents:Boolean;
        protected var _dispatchRotateEvents:Boolean;

        public function TransformItem($targetObject:DisplayObject, $vars:Object){
            if (TransformManager.VERSION < 1.87){
                trace("TransformManager Error: You have an outdated TransformManager-related class file. You may need to clear your ASO files. Please make sure you're using the latest version of TransformManager, TransformItem, and TransformItemTF, available from www.greensock.com.");
            };
            this.init($targetObject, $vars);
        }

        protected static function setDefault($value, $default){
            if ($value == undefined){
                return ($default);
            };
            return ($value);
        }


        protected function init($targetObject:DisplayObject, $vars:Object):void{
            try {
                this._isFlex = Boolean(getDefinitionByName("mx.managers.SystemManager"));
            } catch($e:Error) {
                _isFlex = false;
            };
            this._targetObject = $targetObject;
            this._baseRect = this._targetObject.getBounds(this._targetObject);
            this._allowDelete = setDefault($vars.allowDelete, false);
            this._constrainScale = setDefault($vars.constrainScale, false);
            this._lockScale = setDefault($vars.lockScale, false);
            this._lockRotation = setDefault($vars.lockRotation, false);
            this._lockPosition = setDefault($vars.lockPosition, false);
            this._hasSelectableText = setDefault($vars.hasSelectableText, (((this._targetObject is TextField)) ? true : false));
            this.scaleMode = setDefault($vars.scaleMode, ((this._hasSelectableText) ? TransformManager.SCALE_WIDTH_AND_HEIGHT : TransformManager.SCALE_NORMAL));
            this.minScaleX = setDefault($vars.minScaleX, -(Infinity));
            this.minScaleY = setDefault($vars.minScaleY, -(Infinity));
            this.maxScaleX = setDefault($vars.maxScaleX, Infinity);
            this.maxScaleY = setDefault($vars.maxScaleY, Infinity);
            this._bounds = $vars.bounds;
            this.origin = new Point(this._targetObject.x, this._targetObject.y);
            if ($vars.manager == undefined){
                $vars.items = [this];
                this._createdManager = new TransformManager($vars);
            };
            if (this._targetObject.stage != null){
                this._stage = this._targetObject.stage;
            } else {
                this._targetObject.addEventListener(Event.ADDED_TO_STAGE, this.onAddedToStage, false, 0, true);
            };
            this._selected = false;
            this._enabled = !(Boolean($vars.enabled));
            this.enabled = !(this._enabled);
        }

        protected function onAddedToStage($e:Event):void{
            this._stage = this._targetObject.stage;
            try {
                this._isFlex = Boolean(getDefinitionByName("mx.managers.SystemManager"));
            } catch($e:Error) {
                _isFlex = false;
            };
            if (this._proxy != null){
                this._targetObject.parent.addChild(this._proxy);
            };
            this._targetObject.removeEventListener(Event.ADDED_TO_STAGE, this.onAddedToStage);
        }

        protected function onMouseDown($e:MouseEvent):void{
            if (this._hasSelectableText){
                dispatchEvent(new TransformEvent(TransformEvent.MOUSE_DOWN, [this]));
            } else {
                this._stage = this._targetObject.stage;
                this._stage.addEventListener(MouseEvent.MOUSE_UP, this.onMouseUp);
                dispatchEvent(new TransformEvent(TransformEvent.MOUSE_DOWN, [this], $e));
                if (this._selected){
                    dispatchEvent(new TransformEvent(TransformEvent.SELECT_MOUSE_DOWN, [this], $e));
                };
            };
        }

        protected function onMouseUp($e:MouseEvent):void{
            this._stage.removeEventListener(MouseEvent.MOUSE_UP, this.onMouseUp);
            if (((!(this._hasSelectableText)) && (this._selected))){
                dispatchEvent(new TransformEvent(TransformEvent.SELECT_MOUSE_UP, [this], $e));
            };
        }

        protected function onRollOverItem($e:MouseEvent):void{
            if (this._selected){
                dispatchEvent(new TransformEvent(TransformEvent.ROLL_OVER_SELECTED, [this], $e));
            };
        }

        protected function onRollOutItem($e:MouseEvent):void{
            if (this._selected){
                dispatchEvent(new TransformEvent(TransformEvent.ROLL_OUT_SELECTED, [this], $e));
            };
        }

        public function update($e:Event=null):void{
            this._baseRect = this._targetObject.getBounds(this._targetObject);
            this.setCornerAngles();
            if (this._proxy != null){
                this.calibrateProxy();
            };
            dispatchEvent(new TransformEvent(TransformEvent.UPDATE, [this]));
        }

        override public function addEventListener($type:String, $listener:Function, $useCapture:Boolean=false, $priority:int=0, $useWeakReference:Boolean=false):void{
            if ($type == TransformEvent.MOVE){
                this._dispatchMoveEvents = true;
            } else {
                if ($type == TransformEvent.SCALE){
                    this._dispatchScaleEvents = true;
                } else {
                    if ($type == TransformEvent.ROTATE){
                        this._dispatchRotateEvents = true;
                    };
                };
            };
            super.addEventListener($type, $listener, $useCapture, $priority, $useWeakReference);
        }

        protected function autoCalibrateProxy($e:Event=null):void{
            if (this._frameCount >= 3){
                this._targetObject.removeEventListener(Event.ENTER_FRAME, this.autoCalibrateProxy);
                if (this._targetObject.parent){
                    this._targetObject.parent.addChild(this._proxy);
                };
                this._target = this._proxy;
                this.calibrateProxy();
                this._frameCount = 0;
            } else {
                this._frameCount++;
            };
        }

        protected function createProxy():void{
            var tf:TextField;
            var isEmpty:Boolean;
            var format:TextFormat;
            var altFormat:TextFormat;
            var metrics:TextLineMetrics;
            this.removeProxy();
            if (this._hasSelectableText){
                this._proxy = ((this._isFlex) ? new (getDefinitionByName("mx.core.UITextField"))() : new TextField());
            } else {
                this._proxy = ((this._isFlex) ? new (getDefinitionByName("mx.core.UIComponent"))() : new Sprite());
            };
            _proxyCount++;
            this._proxy.name = ("__tmProxy" + _proxyCount);
            this._proxy.visible = false;
            try {
                this._target = this._proxy;
                this._targetObject.parent.addChild(this._proxy);
            } catch($e:Error) {
                _target = _targetObject;
                _targetObject.addEventListener(Event.ENTER_FRAME, autoCalibrateProxy);
            };
            this._offset = new Point(0, 0);
            if ((this._targetObject is TextField)){
                tf = (this._targetObject as TextField);
                isEmpty = false;
                if (tf.text == ""){
                    tf.text = "Y";
                    isEmpty = true;
                };
                format = tf.getTextFormat(0, 1);
                altFormat = tf.getTextFormat(0, 1);
                altFormat.align = "left";
                tf.setTextFormat(altFormat, 0, 1);
                metrics = tf.getLineMetrics(0);
                if (metrics.x == 0){
                    this._offset = new Point(-2, -2);
                };
                tf.setTextFormat(format, 0, 1);
                if (isEmpty){
                    tf.text = "";
                };
            };
            this.calibrateProxy();
        }

        protected function removeProxy():void{
            if (this._proxy != null){
                if (this._proxy.parent != null){
                    this._proxy.parent.removeChild(this._proxy);
                };
                this._proxy = null;
            };
            this._target = this._targetObject;
        }

        protected function calibrateProxy():void{
            var r:Rectangle;
            var g:Graphics;
            var m:Matrix = this._targetObject.transform.matrix;
            this._targetObject.transform.matrix = new Matrix();
            if (!this._hasSelectableText){
                r = this._targetObject.getBounds(this._targetObject);
                g = (this._proxy as Sprite).graphics;
                g.clear();
                g.beginFill(0xFF0000, 0);
                g.drawRect(r.x, r.y, this._targetObject.width, this._targetObject.height);
                g.endFill();
            };
            this._proxy.width = (this._baseRect.width = this._targetObject.width);
            this._proxy.height = (this._baseRect.height = this._targetObject.height);
            this._proxy.transform.matrix = (this._targetObject.transform.matrix = m);
        }

        protected function setCornerAngles():void{
            if (this._bounds != null){
                this._cornerAngleTL = TransformManager.positiveAngle(Math.atan2((this._bounds.y - this._origin.y), (this._bounds.x - this._origin.x)));
                this._cornerAngleTR = TransformManager.positiveAngle(Math.atan2((this._bounds.y - this._origin.y), (this._bounds.right - this._origin.x)));
                this._cornerAngleBR = TransformManager.positiveAngle(Math.atan2((this._bounds.bottom - this._origin.y), (this._bounds.right - this._origin.x)));
                this._cornerAngleBL = TransformManager.positiveAngle(Math.atan2((this._bounds.bottom - this._origin.y), (this._bounds.x - this._origin.x)));
            };
        }

        protected function reposition():void{
            var p:Point = this._target.parent.globalToLocal(this._target.localToGlobal(this._localOrigin));
            this._target.x = (this._target.x + (this._origin.x - p.x));
            this._target.y = (this._target.y + (this._origin.y - p.y));
        }

        public function onPressDelete($e:Event=null, $allowSelectableTextDelete:Boolean=false):Boolean{
            if (((((this._enabled) && (this._allowDelete))) && ((((this._hasSelectableText == false)) || ($allowSelectableTextDelete))))){
                this.deleteObject();
                return (true);
            };
            return (false);
        }

        public function deleteObject():void{
            this.selected = false;
            if (this._targetObject.parent){
                this._targetObject.parent.removeChild(this._targetObject);
            };
            this.removeProxy();
            dispatchEvent(new TransformEvent(TransformEvent.DELETE, [this]));
        }

        public function forceEventDispatch($type:String):void{
            dispatchEvent(new TransformEvent($type, [this]));
        }

        public function destroy():void{
            this.enabled = false;
            this.selected = false;
            dispatchEvent(new TransformEvent(TransformEvent.DESTROY, [this]));
        }

        public function move($x:Number, $y:Number, $checkBounds:Boolean=true, $dispatchEvent:Boolean=true):void{
            var safe:Object;
            if (!this._lockPosition){
                if ((($checkBounds) && (!((this._bounds == null))))){
                    safe = {
                        "x":$x,
                        "y":$y
                    };
                    this.moveCheck($x, $y, safe);
                    $x = safe.x;
                    $y = safe.y;
                };
                this._target.x = (this._target.x + $x);
                this._target.y = (this._target.y + $y);
                this._origin.x = (this._origin.x + $x);
                this._origin.y = (this._origin.y + $y);
                if (this._target != this._targetObject){
                    this._targetObject.x = (this._targetObject.x + $x);
                    this._targetObject.y = (this._targetObject.y + $y);
                };
                if ((((($dispatchEvent) && (this._dispatchMoveEvents))) && (((!(($x == 0))) || (!(($y == 0))))))){
                    dispatchEvent(new TransformEvent(TransformEvent.MOVE, [this]));
                };
            };
        }

        public function moveCheck($x:Number, $y:Number, $safe:Object):void{
            var r:Rectangle;
            if (this._lockPosition){
                $safe.x = ($safe.y = 0);
            } else {
                if (this._bounds != null){
                    r = this._targetObject.getBounds(this._targetObject.parent);
                    r.offset($x, $y);
                    if (!this._bounds.containsRect(r)){
                        if (this._bounds.right < r.right){
                            $x = ($x + (this._bounds.right - r.right));
                            $safe.x = int(Math.min($safe.x, $x));
                        } else {
                            if (this._bounds.left > r.left){
                                $x = ($x + (this._bounds.left - r.left));
                                $safe.x = int(Math.max($safe.x, $x));
                            };
                        };
                        if (this._bounds.top > r.top){
                            $y = ($y + (this._bounds.top - r.top));
                            $safe.y = int(Math.max($safe.y, $y));
                        } else {
                            if (this._bounds.bottom < r.bottom){
                                $y = ($y + (this._bounds.bottom - r.bottom));
                                $safe.y = int(Math.min($safe.y, $y));
                            };
                        };
                    };
                };
            };
        }

        public function scale($sx:Number, $sy:Number, $angle:Number=0, $checkBounds:Boolean=true, $dispatchEvent:Boolean=true):void{
            if (!this._lockScale){
                this.scaleRotated($sx, $sy, $angle, -($angle), $checkBounds, $dispatchEvent);
            };
        }

        public function scaleRotated($sx:Number, $sy:Number, $angle:Number, $skew:Number, $checkBounds:Boolean=true, $dispatchEvent:Boolean=true):void{
            var m:Matrix;
            var safe:Object;
            var w:Number;
            var h:Number;
            var p:Point;
            if (!this._lockScale){
                m = this._target.transform.matrix;
                if (((!(($angle == -($skew)))) && ((Math.abs((($angle + $skew) % (Math.PI - 0.01))) < 0.01)))){
                    $skew = -($angle);
                };
                if ((($checkBounds) && (!((this._bounds == null))))){
                    safe = {
                        "sx":$sx,
                        "sy":$sy
                    };
                    this.scaleCheck(safe, $angle, $skew);
                    $sx = safe.sx;
                    $sy = safe.sy;
                };
                MatrixTools.scaleMatrix(m, $sx, $sy, $angle, $skew);
                if (this._scaleMode == "scaleNormal"){
                    this._targetObject.transform.matrix = m;
                    this.reposition();
                } else {
                    this._proxy.transform.matrix = m;
                    this.reposition();
                    w = (Math.sqrt(((m.a * m.a) + (m.b * m.b))) * this._baseRect.width);
                    h = (Math.sqrt(((m.d * m.d) + (m.c * m.c))) * this._baseRect.height);
                    p = this._targetObject.parent.globalToLocal(this._proxy.localToGlobal(this._offset));
                    this._targetObject.width = w;
                    this._targetObject.height = h;
                    this._targetObject.rotation = this._proxy.rotation;
                    this._targetObject.x = p.x;
                    this._targetObject.y = p.y;
                };
                if ((((($dispatchEvent) && (this._dispatchScaleEvents))) && (((!(($sx == 1))) || (!(($sy == 1))))))){
                    dispatchEvent(new TransformEvent(TransformEvent.SCALE, [this]));
                };
            };
        }

        public function scaleCheck($safe:Object, $angle:Number, $skew:Number):void{
            var sx:Number;
            var sy:Number;
            var original:Matrix;
            var originalScaleX:Number;
            var originalScaleY:Number;
            var originalAngle:Number;
            var m:Matrix;
            var angleDif:Number;
            var skewDif:Number;
            var ratio:Number;
            var i:int;
            var corner:Point;
            var cornerAngle:Number;
            var oldLength:Number;
            var newLength:Number;
            var dx:Number;
            var dy:Number;
            var minScale:Number;
            var r:Rectangle;
            var corners:Array;
            if (this._lockScale){
                $safe.sx = ($safe.sy = 1);
            } else {
                original = this._target.transform.matrix;
                originalScaleX = MatrixTools.getScaleX(original);
                originalScaleY = MatrixTools.getScaleY(original);
                originalAngle = MatrixTools.getAngle(original);
                m = original.clone();
                MatrixTools.scaleMatrix(m, $safe.sx, $safe.sy, $angle, $skew);
                if (this.hasScaleLimits){
                    angleDif = ($angle - originalAngle);
                    skewDif = ($skew - MatrixTools.getSkew(original));
                    if ((((((angleDif == 0)) && ((skewDif < 0.0001)))) && ((skewDif > -0.0001)))){
                        sx = MatrixTools.getScaleX(m);
                        sy = MatrixTools.getScaleY(m);
                        if (Math.abs((originalAngle - MatrixTools.getAngle(m))) > (Math.PI * 0.51)){
                            sx = -(sx);
                            sy = -(sy);
                        };
                        ratio = (originalScaleX / originalScaleY);
                        if (sx > this._maxScaleX){
                            $safe.sx = (this._maxScaleX / originalScaleX);
                            if (this._constrainScale){
                                sy = ($safe.sx / ratio);
                                $safe.sy = sy;
                                if (($safe.sx * $safe.sy) < 0){
                                    sy = -(sy);
                                    $safe.sy = sy;
                                };
                            };
                        } else {
                            if (sx < this._minScaleX){
                                $safe.sx = (this._minScaleX / originalScaleX);
                                if (this._constrainScale){
                                    sy = ($safe.sx / ratio);
                                    $safe.sy = sy;
                                    if (($safe.sx * $safe.sy) < 0){
                                        sy = -(sy);
                                        $safe.sy = sy;
                                    };
                                };
                            };
                        };
                        if (sy > this._maxScaleY){
                            $safe.sy = (this._maxScaleY / originalScaleY);
                            if (this._constrainScale){
                                $safe.sx = ($safe.sy * ratio);
                                if (($safe.sx * $safe.sy) < 0){
                                    $safe.sx = ($safe.sx * -1);
                                };
                            };
                        } else {
                            if (sy < this._minScaleY){
                                $safe.sy = (this._minScaleY / originalScaleY);
                                if (this._constrainScale){
                                    $safe.sx = ($safe.sy * ratio);
                                    if (($safe.sx * $safe.sy) < 0){
                                        $safe.sx = ($safe.sx * -1);
                                    };
                                };
                            };
                        };
                        m = original.clone();
                        MatrixTools.scaleMatrix(m, $safe.sx, $safe.sy, $angle, $skew);
                    } else {
                        sx = MatrixTools.getScaleX(m);
                        sy = MatrixTools.getScaleY(m);
                        if ((((((((sx > this._maxScaleX)) || ((sx < this._minScaleX)))) || ((sy > this._maxScaleY)))) || ((sy < this._minScaleY)))){
                            $safe.sx = ($safe.sy = 1);
                            return;
                        };
                    };
                };
                this._target.transform.matrix = m;
                this.reposition();
                if (this._bounds != null){
                    if (!this._bounds.containsRect(this._target.getBounds(this._target.parent))){
                        if ($safe.sy == 1){
                            this._target.transform.matrix = original;
                            this.iterateStretchX($safe, $angle, $skew);
                        } else {
                            if ($safe.sx == 1){
                                this._target.transform.matrix = original;
                                this.iterateStretchY($safe, $angle, $skew);
                            } else {
                                minScale = 1;
                                r = this._target.getBounds(this._target);
                                corners = [new Point(r.x, r.y), new Point(r.right, r.y), new Point(r.right, r.bottom), new Point(r.x, r.bottom)];
                                i = (corners.length - 1);
                                while (i > -1) {
                                    corner = this._target.parent.globalToLocal(this._target.localToGlobal(corners[i]));
                                    if (!(((Math.abs((corner.x - this._origin.x)) < 1)) && ((Math.abs((corner.y - this._origin.y)) < 1)))){
                                        cornerAngle = TransformManager.positiveAngle(Math.atan2((corner.y - this._origin.y), (corner.x - this._origin.x)));
                                        dx = (this._origin.x - corner.x);
                                        dy = (this._origin.y - corner.y);
                                        oldLength = Math.sqrt(((dx * dx) + (dy * dy)));
                                        if ((((cornerAngle < this._cornerAngleBR)) || ((((cornerAngle > this._cornerAngleTR)) && (!((this._cornerAngleTR == 0))))))){
                                            dx = (this._bounds.right - this._origin.x);
                                            newLength = (((((dx < 1)) && (((((this._cornerAngleBR - cornerAngle) < 0.01)) || (((cornerAngle - this._cornerAngleTR) < 0.01)))))) ? 0 : (dx / Math.cos(cornerAngle)));
                                        } else {
                                            if (cornerAngle <= this._cornerAngleBL){
                                                dy = (this._bounds.bottom - this._origin.y);
                                                newLength = ((((this._cornerAngleBL - cornerAngle))<0.01) ? 0 : (dy / Math.sin(cornerAngle)));
                                            } else {
                                                if (cornerAngle < this._cornerAngleTL){
                                                    dx = (this._origin.x - this._bounds.x);
                                                    newLength = (dx / Math.cos(cornerAngle));
                                                } else {
                                                    dy = (this._origin.y - this._bounds.y);
                                                    newLength = (dy / Math.sin(cornerAngle));
                                                };
                                            };
                                        };
                                        if (newLength != 0){
                                            minScale = Math.min(minScale, (Math.abs(newLength) / oldLength));
                                        };
                                    };
                                    i--;
                                };
                                m = this._target.transform.matrix;
                                if (((((($safe.sx < 0)) && ((((this._origin.x == this._bounds.x)) || ((this._origin.x == this._bounds.right)))))) || (((($safe.sy < 0)) && ((((this._origin.y == this._bounds.y)) || ((this._origin.y == this._bounds.bottom)))))))){
                                    $safe.sx = 1;
                                    $safe.sy = 1;
                                } else {
                                    $safe.sx = ((MatrixTools.getDirectionX(m) * minScale) / MatrixTools.getDirectionX(original));
                                    $safe.sy = ((MatrixTools.getDirectionY(m) * minScale) / MatrixTools.getDirectionY(original));
                                };
                            };
                        };
                    };
                };
                this._target.transform.matrix = original;
            };
        }

        protected function iterateStretchX($safe:Object, $angle:Number, $skew:Number):void{
            var original:Matrix;
            var i:uint;
            var loops:uint;
            var base:uint;
            var m:Matrix;
            var inc:Number;
            if (this._lockScale){
                $safe.sx = ($safe.sy = 1);
            } else {
                if (((!((this._bounds == null))) && (!(($safe.sx == 1))))){
                    original = this._target.transform.matrix;
                    m = new Matrix();
                    inc = 0.01;
                    if ($safe.sx < 1){
                        inc = -0.01;
                    };
                    if ($safe.sx > 0){
                        loops = (Math.abs((($safe.sx - 1) / inc)) + 1);
                        base = 1;
                    } else {
                        base = 0;
                        loops = (($safe.sx / inc) + 1);
                    };
                    i = 1;
                    while (i <= loops) {
                        m.a = original.a;
                        m.b = original.b;
                        m.c = original.c;
                        m.d = original.d;
                        MatrixTools.scaleMatrix(m, (base + (i * inc)), 1, $angle, $skew);
                        this._target.transform.matrix = m;
                        this.reposition();
                        if (!this._bounds.containsRect(this._target.getBounds(this._target.parent))){
                            if (!((($safe.sx < 1)) && (($safe.sx > 0)))){
                                $safe.sx = (base + ((i - 1) * inc));
                            };
                            break;
                        };
                        i++;
                    };
                };
            };
        }

        protected function iterateStretchY($safe:Object, $angle:Number, $skew:Number):void{
            var original:Matrix;
            var i:uint;
            var loops:uint;
            var base:uint;
            var m:Matrix;
            var inc:Number;
            if (this._lockScale){
                $safe.sx = ($safe.sy = 1);
            } else {
                if (((!((this._bounds == null))) && (!(($safe.sy == 1))))){
                    original = this._target.transform.matrix;
                    m = new Matrix();
                    inc = 0.01;
                    if ($safe.sy < 1){
                        inc = -0.01;
                    };
                    if ($safe.sx > 0){
                        loops = (Math.abs((($safe.sy - 1) / inc)) + 1);
                        base = 1;
                    } else {
                        base = 0;
                        loops = (($safe.sy / inc) + 1);
                    };
                    i = 1;
                    while (i <= loops) {
                        m.a = original.a;
                        m.b = original.b;
                        m.c = original.c;
                        m.d = original.d;
                        MatrixTools.scaleMatrix(m, 1, (base + (i * inc)), $angle, $skew);
                        this._target.transform.matrix = m;
                        this.reposition();
                        if (!this._bounds.containsRect(this._target.getBounds(this._target.parent))){
                            if (!((($safe.sy < 1)) && (($safe.sy > 0)))){
                                $safe.sy = (base + ((i - 1) * inc));
                            };
                            break;
                        };
                        i++;
                    };
                };
            };
        }

        public function setScaleConstraints($minScaleX:Number, $maxScaleX:Number, $minScaleY:Number, $maxScaleY:Number):void{
            this.minScaleX = $minScaleX;
            this.maxScaleX = $maxScaleX;
            this.minScaleY = $minScaleY;
            this.maxScaleY = $maxScaleY;
        }

        public function rotate($angle:Number, $checkBounds:Boolean=true, $dispatchEvent:Boolean=true):void{
            var m:Matrix;
            var safe:Object;
            var p:Point;
            if (!this._lockRotation){
                if ((($checkBounds) && (!((this._bounds == null))))){
                    safe = {"angle":$angle};
                    this.rotateCheck(safe);
                    $angle = safe.angle;
                };
                m = this._targetObject.transform.matrix;
                m.rotate($angle);
                this._targetObject.transform.matrix = m;
                if (this._proxy != null){
                    m = this._proxy.transform.matrix;
                    m.rotate($angle);
                    this._proxy.transform.matrix = m;
                };
                this.reposition();
                if (this._target == this._proxy){
                    p = this._proxy.parent.globalToLocal(this._proxy.localToGlobal(this._offset));
                    this._targetObject.x = p.x;
                    this._targetObject.y = p.y;
                };
                if ((((($dispatchEvent) && (this._dispatchRotateEvents))) && (!(($angle == 0))))){
                    dispatchEvent(new TransformEvent(TransformEvent.ROTATE, [this]));
                };
            };
        }

        public function rotateCheck($safe:Object):void{
            var originalAngle:Number;
            var original:Matrix;
            var m:Matrix;
            var inc:Number;
            var i:uint;
            if (this._lockRotation){
                $safe.angle = 0;
            } else {
                if (((!((this._bounds == null))) && (!(($safe.angle == 0))))){
                    originalAngle = (this._target.rotation * _DEG2RAD);
                    original = this._target.transform.matrix;
                    m = original.clone();
                    m.rotate($safe.angle);
                    this._target.transform.matrix = m;
                    this.reposition();
                    if (!this._bounds.containsRect(this._target.getBounds(this._target.parent))){
                        m = original.clone();
                        inc = _DEG2RAD;
                        if (TransformManager.acuteAngle($safe.angle) < 0){
                            inc = (inc * -1);
                        };
                        i = 1;
                        while (i < 360) {
                            m.rotate(inc);
                            this._target.transform.matrix = m;
                            this.reposition();
                            if (!this._bounds.containsRect(this._target.getBounds(this._target.parent))){
                                $safe.angle = ((i - 1) * inc);
                                break;
                            };
                            i++;
                        };
                    };
                    this._target.transform.matrix = original;
                };
            };
        }

        public function get enabled():Boolean{
            return (this._enabled);
        }

        public function set enabled($b:Boolean):void{
            if ($b != this._enabled){
                this._enabled = $b;
                this.selected = false;
                if ($b){
                    this._targetObject.addEventListener(MouseEvent.MOUSE_DOWN, this.onMouseDown);
                    this._targetObject.addEventListener(MouseEvent.ROLL_OVER, this.onRollOverItem);
                    this._targetObject.addEventListener(MouseEvent.ROLL_OUT, this.onRollOutItem);
                } else {
                    this._targetObject.removeEventListener(MouseEvent.MOUSE_DOWN, this.onMouseDown);
                    this._targetObject.removeEventListener(MouseEvent.ROLL_OVER, this.onRollOverItem);
                    this._targetObject.removeEventListener(MouseEvent.ROLL_OUT, this.onRollOutItem);
                    if (this._stage != null){
                        this._stage.removeEventListener(MouseEvent.MOUSE_UP, this.onMouseUp);
                    };
                };
            };
        }

        public function get x():Number{
            return (this._targetObject.x);
        }

        public function set x($n:Number):void{
            this.move(($n - this._targetObject.x), 0, true, true);
        }

        public function get y():Number{
            return (this._targetObject.y);
        }

        public function set y($n:Number):void{
            this.move(0, ($n - this._targetObject.y), true, true);
        }

        public function get targetObject():DisplayObject{
            return (this._targetObject);
        }

        public function get scaleX():Number{
            return (MatrixTools.getScaleX(this._targetObject.transform.matrix));
        }

        public function set scaleX($n:Number):void{
            var o:Point = this.origin;
            this.origin = this.center;
            var m:Matrix = this._targetObject.transform.matrix;
            this.scaleRotated(($n / MatrixTools.getScaleX(m)), 1, (this._targetObject.rotation * _DEG2RAD), Math.atan2(m.c, m.d), true, true);
            this.origin = o;
        }

        public function get scaleY():Number{
            return (MatrixTools.getScaleY(this._targetObject.transform.matrix));
        }

        public function set scaleY($n:Number):void{
            var o:Point = this.origin;
            this.origin = this.center;
            var m:Matrix = this._targetObject.transform.matrix;
            this.scaleRotated(1, ($n / MatrixTools.getScaleY(m)), (this._targetObject.rotation * _DEG2RAD), Math.atan2(m.c, m.d), true, true);
            this.origin = o;
        }

        public function get width():Number{
            var s:Sprite;
            var w:Number;
            if (this._targetObject.parent != null){
                return (this._targetObject.getBounds(this._targetObject.parent).width);
            };
            s = new Sprite();
            s.addChild(this._targetObject);
            w = this._targetObject.getBounds(s).width;
            s.removeChild(this._targetObject);
            return (w);
        }

        public function set width($n:Number):void{
            var o:Point = this.origin;
            this.origin = this.center;
            this.scale(($n / this.width), 1, 0, true, true);
            this.origin = o;
        }

        public function get height():Number{
            var s:Sprite;
            var h:Number;
            if (this._targetObject.parent != null){
                return (this._targetObject.getBounds(this._targetObject.parent).height);
            };
            s = new Sprite();
            s.addChild(this._targetObject);
            h = this._targetObject.getBounds(s).height;
            s.removeChild(this._targetObject);
            return (h);
        }

        public function set height($n:Number):void{
            var o:Point = this.origin;
            this.origin = this.center;
            this.scale(1, ($n / this.height), 0, true, true);
            this.origin = o;
        }

        public function get rotation():Number{
            return ((MatrixTools.getAngle(this._targetObject.transform.matrix) * _RAD2DEG));
        }

        public function set rotation($n:Number):void{
            var o:Point = this.origin;
            this.origin = this.center;
            this.rotate((($n * _DEG2RAD) - MatrixTools.getAngle(this._targetObject.transform.matrix)), true, true);
            this.origin = o;
        }

        public function get alpha():Number{
            return (this._targetObject.alpha);
        }

        public function set alpha($n:Number):void{
            this._targetObject.alpha = $n;
        }

        public function get center():Point{
            if (this._targetObject.parent != null){
                return (this._targetObject.parent.globalToLocal(this._targetObject.localToGlobal(this.innerCenter)));
            };
            return (this.innerCenter);
        }

        public function get innerCenter():Point{
            var r:Rectangle = this._targetObject.getBounds(this._targetObject);
            return (new Point((r.x + (r.width / 2)), (r.y + (r.height / 2))));
        }

        public function get constrainScale():Boolean{
            return (this._constrainScale);
        }

        public function set constrainScale($b:Boolean):void{
            this._constrainScale = $b;
        }

        public function get lockScale():Boolean{
            return (this._lockScale);
        }

        public function set lockScale($b:Boolean):void{
            this._lockScale = $b;
        }

        public function get lockRotation():Boolean{
            return (this._lockRotation);
        }

        public function set lockRotation($b:Boolean):void{
            this._lockRotation = $b;
        }

        public function get lockPosition():Boolean{
            return (this._lockPosition);
        }

        public function set lockPosition($b:Boolean):void{
            this._lockPosition = $b;
        }

        public function get allowDelete():Boolean{
            return (this._allowDelete);
        }

        public function set allowDelete($b:Boolean):void{
            if ($b != this._allowDelete){
                this._allowDelete = $b;
                if (this._createdManager != null){
                    this._createdManager.allowDelete = $b;
                };
            };
        }

        public function get selected():Boolean{
            return (this._selected);
        }

        public function set selected($b:Boolean):void{
            if ($b != this._selected){
                this._selected = $b;
                if ($b){
                    if (this._targetObject.parent == null){
                        return;
                    };
                    if (this._targetObject.hasOwnProperty("setStyle")){
                        (this._targetObject as Object).setStyle("focusThickness", 0);
                    };
                    dispatchEvent(new TransformEvent(TransformEvent.SELECT, [this]));
                } else {
                    dispatchEvent(new TransformEvent(TransformEvent.DESELECT, [this]));
                };
            };
        }

        public function get bounds():Rectangle{
            return (this._bounds);
        }

        public function set bounds($r:Rectangle):void{
            this._bounds = $r;
            this.setCornerAngles();
        }

        public function get origin():Point{
            return (this._origin);
        }

        public function set origin($p:Point):void{
            this._origin = $p;
            if (((!((this._proxy == null))) && (!((this._proxy.parent == null))))){
                this._localOrigin = this._proxy.globalToLocal(this._proxy.parent.localToGlobal($p));
            } else {
                if (this._targetObject.parent != null){
                    this._localOrigin = this._targetObject.globalToLocal(this._targetObject.parent.localToGlobal($p));
                };
            };
            this.setCornerAngles();
        }

        public function get minScaleX():Number{
            return (this._minScaleX);
        }

        public function set minScaleX($n:Number):void{
            if ($n == 0){
                $n = ((this._targetObject.getBounds(this._targetObject).width) || (500));
                this._minScaleX = (1 / $n);
            } else {
                this._minScaleX = $n;
            };
            if (this._targetObject.scaleX < this._minScaleX){
                this._targetObject.scaleX = this._minScaleX;
            };
            if (this._selected){
                dispatchEvent(new TransformEvent(TransformEvent.UPDATE, [this]));
            };
        }

        public function get minScaleY():Number{
            return (this._minScaleY);
        }

        public function set minScaleY($n:Number):void{
            if ($n == 0){
                $n = ((this._targetObject.getBounds(this._targetObject).height) || (500));
                this._minScaleY = (1 / $n);
            } else {
                this._minScaleY = $n;
            };
            if (this._targetObject.scaleY < this._minScaleY){
                this._targetObject.scaleY = this._minScaleY;
            };
            if (this._selected){
                dispatchEvent(new TransformEvent(TransformEvent.UPDATE, [this]));
            };
        }

        public function get maxScaleX():Number{
            return (this._maxScaleX);
        }

        public function set maxScaleX($n:Number):void{
            if ($n == 0){
                $n = ((this._targetObject.getBounds(this._targetObject).width) || (0.005));
                this._maxScaleX = (0 - (1 / $n));
            } else {
                this._maxScaleX = $n;
            };
            if (this._targetObject.scaleX > this._maxScaleX){
                this._targetObject.scaleX = this._maxScaleX;
            };
            if (this._selected){
                dispatchEvent(new TransformEvent(TransformEvent.UPDATE, [this]));
            };
        }

        public function get maxScaleY():Number{
            return (this._maxScaleY);
        }

        public function set maxScaleY($n:Number):void{
            if ($n == 0){
                $n = ((this._targetObject.getBounds(this._targetObject).height) || (0.005));
                this._maxScaleY = (0 - (1 / $n));
            } else {
                this._maxScaleY = $n;
            };
            if (this._targetObject.scaleY > this._maxScaleY){
                this._targetObject.scaleY = this._maxScaleY;
            };
            if (this._selected){
                dispatchEvent(new TransformEvent(TransformEvent.UPDATE, [this]));
            };
        }

        public function set maxScale($n:Number):void{
            this.maxScaleX = (this.maxScaleY = $n);
        }

        public function set minScale($n:Number):void{
            this.minScaleX = (this.minScaleY = $n);
        }

        public function get hasScaleLimits():Boolean{
            return (((((((!((this._minScaleX == -(Infinity)))) || (!((this._minScaleY == -(Infinity)))))) || (!((this._maxScaleX == Infinity))))) || (!((this._maxScaleY == Infinity)))));
        }

        public function get scaleMode():String{
            return (this._scaleMode);
        }

        public function set scaleMode($s:String):void{
            if ($s != TransformManager.SCALE_NORMAL){
                this.createProxy();
            } else {
                this.removeProxy();
            };
            this._scaleMode = $s;
        }

        public function get hasSelectableText():Boolean{
            return (this._hasSelectableText);
        }

        public function set hasSelectableText($b:Boolean):void{
            if ($b){
                this.scaleMode = TransformManager.SCALE_WIDTH_AND_HEIGHT;
                this.allowDelete = false;
            };
            this._hasSelectableText = $b;
        }


    }
}//package com.greensock.transform
