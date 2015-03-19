//Created by Action Script Viewer - http://www.buraks.com/asv
package com.greensock.transform{
    import flash.events.EventDispatcher;
    import flash.display.Shape;
    import flash.utils.Dictionary;
    import flash.geom.Rectangle;
    import flash.display.Sprite;
    import flash.display.DisplayObjectContainer;
    import flash.display.Stage;
    import flash.geom.Point;
    import flash.events.Event;
    import flash.events.KeyboardEvent;
    import flash.ui.Keyboard;
    import flash.display.DisplayObject;
    import flash.utils.getDefinitionByName;
    import flash.events.MouseEvent;
    import flash.text.TextField;
    import com.greensock.events.TransformEvent;
    import com.greensock.transform.utils.MatrixTools;
    import flash.geom.Matrix;
    import flash.utils.getTimer;
    import flash.ui.Mouse;
    import flash.display.Graphics;

    public class TransformManager extends EventDispatcher {

        public static const VERSION:Number = 1.886;
        public static const SCALE_NORMAL:String = "scaleNormal";
        public static const SCALE_WIDTH_AND_HEIGHT:String = "scaleWidthAndHeight";
        private static const _DEG2RAD:Number = (Math.PI / 180);//0.0174532925199433
        private static const _RAD2DEG:Number = (180 / Math.PI);//57.2957795130823

        private static var _currentCursor:Shape;
        private static var _cursorManager:TransformManager;
        private static var _keysDown:Object;
        private static var _keyListenerInits:Dictionary = new Dictionary();
        private static var _keyDispatcher:EventDispatcher = new EventDispatcher();
        private static var _tempDeselectedItem:TransformItem;
        public static var scaleCursor:Shape;
        public static var rotationCursor:Shape;
        public static var moveCursor:Shape;

        private var _allowDelete:Boolean;
        private var _allowMultiSelect:Boolean;
        private var _hideCenterHandle:Boolean;
        private var _multiSelectMode:Boolean;
        private var _ignoreEvents:Boolean;
        private var _autoDeselect:Boolean;
        private var _constrainScale:Boolean;
        private var _lockScale:Boolean;
        private var _scaleFromCenter:Boolean;
        private var _lockRotation:Boolean;
        private var _lockPosition:Boolean;
        private var _arrowKeysMove:Boolean;
        private var _selConstrainScale:Boolean;
        private var _selLockScale:Boolean;
        private var _selLockRotation:Boolean;
        private var _selLockPosition:Boolean;
        private var _selHasTextFields:Boolean;
        private var _selHasScaleLimits:Boolean;
        private var _lineColor:uint;
        private var _handleColor:uint;
        private var _handleSize:Number;
        private var _paddingForRotation:Number;
        private var _selectedItems:Array;
        private var _forceSelectionToFront:Boolean;
        private var _items:Array;
        private var _ignoredObjects:Array;
        private var _enabled:Boolean;
        private var _bounds:Rectangle;
        private var _selection:Sprite;
        private var _dummyBox:Sprite;
        private var _handles:Array;
        private var _handlesDict:Dictionary;
        private var _parent:DisplayObjectContainer;
        private var _stage:Stage;
        private var _origin:Point;
        private var _trackingInfo:Object;
        private var _initted:Boolean;
        private var _isFlex:Boolean;
        private var _edges:Sprite;
        private var _lockCursor:Boolean;
        private var _onUnlock:Function;
        private var _onUnlockParam:Event;
        private var _dispatchScaleEvents:Boolean;
        private var _dispatchMoveEvents:Boolean;
        private var _dispatchRotateEvents:Boolean;
        private var _isTransforming:Boolean;
        private var _prevScaleX:Number = 0;
        private var _prevScaleY:Number = 0;
        private var _lockOrigin:Boolean;
        private var _lastClickTime:uint = 0;

        public function TransformManager($vars:Object=null){
            if (TransformItem.VERSION < 1.87){
                throw (new Error("TransformManager Error: You have an outdated TransformManager-related class file. You may need to clear your ASO files. Please make sure you're using the latest version of TransformManager and TransformItem, available from www.greensock.com."));
            };
            if ($vars == null){
                $vars = {};
            };
            this.init($vars);
        }

        private static function initKeyListeners($stage:DisplayObjectContainer):void{
            if (!($stage in _keyListenerInits)){
                _keysDown = {};
                $stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
                $stage.addEventListener(KeyboardEvent.KEY_UP, onKeyRelease);
                $stage.addEventListener(Event.DEACTIVATE, clearKeys);
                _keyListenerInits[$stage] = $stage;
            };
        }

        public static function isKeyDown($keyCode:uint):Boolean{
            if (_keysDown == null){
                throw (new Error("Key class has yet been initialized."));
            };
            return (Boolean(($keyCode in _keysDown)));
        }

        private static function onKeyPress($e:KeyboardEvent):void{
            var kbe:KeyboardEvent;
            _keysDown[$e.keyCode] = true;
            if (((($e.keyCode == Keyboard.DELETE)) || (($e.keyCode == Keyboard.BACKSPACE)))){
                _keyDispatcher.dispatchEvent(new KeyboardEvent("pressDelete"));
            } else {
                if (((($e.keyCode == Keyboard.SHIFT)) || (($e.keyCode == Keyboard.CONTROL)))){
                    _keyDispatcher.dispatchEvent(new KeyboardEvent("pressMultiSelectKey"));
                } else {
                    if (((((((($e.keyCode == Keyboard.UP)) || (($e.keyCode == Keyboard.DOWN)))) || (($e.keyCode == Keyboard.LEFT)))) || (($e.keyCode == Keyboard.RIGHT)))){
                        kbe = new KeyboardEvent("pressArrowKey", true, false, $e.charCode, $e.keyCode, $e.keyLocation, $e.ctrlKey, $e.altKey, $e.shiftKey);
                        _keyDispatcher.dispatchEvent(kbe);
                    };
                };
            };
        }

        private static function onKeyRelease($e:KeyboardEvent):void{
            if (((($e.keyCode == Keyboard.SHIFT)) || (($e.keyCode == Keyboard.CONTROL)))){
                _keyDispatcher.dispatchEvent(new KeyboardEvent("releaseMultiSelectKey"));
            };
            delete _keysDown[$e.keyCode];
        }

        private static function clearKeys($e:Event):void{
            _keysDown = {};
        }

        private static function setDefault($value, $default){
            if ($value == undefined){
                return ($default);
            };
            return ($value);
        }

        private static function bringToFront($o:DisplayObject):void{
            if ($o.parent != null){
                $o.parent.setChildIndex($o, ($o.parent.numChildren - 1));
            };
        }

        public static function positiveAngle($a:Number):Number{
            var revolution:Number = (Math.PI * 2);
            return (((($a % revolution) + revolution) % revolution));
        }

        public static function acuteAngle($a:Number):Number{
            if ($a != ($a % Math.PI)){
                $a = ($a % (Math.PI * 2));
                if ($a < -(Math.PI)){
                    return ((Math.PI + ($a % Math.PI)));
                };
                if ($a > Math.PI){
                    return ((-(Math.PI) + ($a % Math.PI)));
                };
            };
            return ($a);
        }


        protected function init($vars:Object):void{
            this._allowDelete = setDefault($vars.allowDelete, false);
            this._allowMultiSelect = setDefault($vars.allowMultiSelect, true);
            this._autoDeselect = setDefault($vars.autoDeselect, true);
            this._constrainScale = setDefault($vars.constrainScale, false);
            this._lockScale = setDefault($vars.lockScale, false);
            this._scaleFromCenter = setDefault($vars.scaleFromCenter, false);
            this._lockRotation = setDefault($vars.lockRotation, false);
            this._lockPosition = setDefault($vars.lockPosition, false);
            this._arrowKeysMove = setDefault($vars.arrowKeysMove, false);
            this._forceSelectionToFront = setDefault($vars.forceSelectionToFront, true);
            this._lineColor = setDefault($vars.lineColor, 3381759);
            this._handleColor = setDefault($vars.handleFillColor, 0xFFFFFF);
            this._handleSize = setDefault($vars.handleSize, 8);
            this._paddingForRotation = setDefault($vars.paddingForRotation, 12);
            this._hideCenterHandle = setDefault($vars.hideCenterHandle, false);
            this._multiSelectMode = (this._ignoreEvents = false);
            this._bounds = $vars.bounds;
            this._enabled = true;
            _keyDispatcher.addEventListener("pressDelete", this.onPressDelete, false, 0, true);
            _keyDispatcher.addEventListener("pressArrowKey", this.onPressArrowKey, false, 0, true);
            _keyDispatcher.addEventListener("pressMultiSelectKey", this.onPressMultiSelectKey, false, 0, true);
            _keyDispatcher.addEventListener("releaseMultiSelectKey", this.onReleaseMultiSelectKey, false, 0, true);
            this._items = (($vars.items) || ([]));
            this._selectedItems = [];
            this.ignoredObjects = (($vars.ignoredObjects) || ([]));
            this._handles = [];
            this._handlesDict = new Dictionary();
            if ($vars.targetObjects != undefined){
                this.addItems($vars.targetObjects);
            };
        }

        protected function initParent($parent:DisplayObjectContainer):void{
            var i:int;
            if (((!(this._initted)) && ((this._parent == null)))){
                try {
                    this._isFlex = Boolean(getDefinitionByName("mx.managers.SystemManager"));
                } catch($e:Error) {
                    _isFlex = false;
                };
                this._parent = $parent;
                i = (this._items.length - 1);
                while (i > -1) {
                    this._items[i].targetObject.removeEventListener(Event.ADDED_TO_STAGE, this.onTargetAddedToStage);
                    i = (i - 1);
                };
                if (this._parent.stage == null){
                    this._parent.addEventListener(Event.ADDED_TO_STAGE, this.initStage, false, 0, true);
                } else {
                    this.initStage();
                };
            };
        }

        protected function onTargetAddedToStage($e:Event):void{
            this.initParent($e.target.parent);
        }

        protected function initStage($e:Event=null):void{
            var i:int;
            this._parent.removeEventListener(Event.ADDED_TO_STAGE, this.initStage);
            this._stage = this._parent.stage;
            initKeyListeners(this._stage);
            this._stage.addEventListener(MouseEvent.MOUSE_DOWN, this.checkForDeselect, false, 0, true);
            this._stage.addEventListener(Event.DEACTIVATE, this.onReleaseMultiSelectKey, false, 0, true);
            this.initSelection();
            this.initScaleCursor();
            this.initMoveCursor();
            this.initRotationCursor();
            this._initted = true;
            if (this._selectedItems.length != 0){
                if (this._forceSelectionToFront){
                    i = (this._selectedItems.length - 1);
                    while (i > -1) {
                        bringToFront(this._selectedItems[i].targetObject);
                        i--;
                    };
                };
                this.calibrateConstraints();
                this.updateSelection();
            };
        }

        public function addItem($targetObject:DisplayObject, $scaleMode:String="scaleNormal", $hasSelectableText:Boolean=false):TransformItem{
            if (((($targetObject == this._dummyBox)) || (($targetObject == this._selection)))){
                return (null);
            };
            var props:Array = ["constrainScale", "scaleFromCenter", "lockScale", "lockRotation", "lockPosition", "autoDeselect", "allowDelete", "bounds", "enabled", "forceSelectionToFront"];
            var newVars:Object = {"manager":this};
            var i:uint;
            while (i < props.length) {
                newVars[props[i]] = this[props[i]];
                i++;
            };
            var existingItem:TransformItem = this.getItem($targetObject);
            if (existingItem != null){
                existingItem.update(null);
                return (existingItem);
            };
            newVars.scaleMode = ((($targetObject is TextField)) ? SCALE_WIDTH_AND_HEIGHT : $scaleMode);
            newVars.hasSelectableText = ((($targetObject is TextField)) ? true : $hasSelectableText);
            var newItem = new TransformItem($targetObject, newVars);
            newItem.addEventListener(TransformEvent.SELECT, this.onSelectItem);
            newItem.addEventListener(TransformEvent.DESELECT, this.onDeselectItem);
            newItem.addEventListener(TransformEvent.MOUSE_DOWN, this.onMouseDownItem);
            newItem.addEventListener(TransformEvent.SELECT_MOUSE_DOWN, this.onPressMove);
            newItem.addEventListener(TransformEvent.SELECT_MOUSE_UP, this.onReleaseMove);
            newItem.addEventListener(TransformEvent.UPDATE, this.onUpdateItem);
            newItem.addEventListener(TransformEvent.SCALE, this.onUpdateItem);
            newItem.addEventListener(TransformEvent.ROTATE, this.onUpdateItem);
            newItem.addEventListener(TransformEvent.MOVE, this.onUpdateItem);
            newItem.addEventListener(TransformEvent.ROLL_OVER_SELECTED, this.onRollOverSelectedItem);
            newItem.addEventListener(TransformEvent.ROLL_OUT_SELECTED, this.onRollOutSelectedItem);
            newItem.addEventListener(TransformEvent.DESTROY, this.onDestroyItem);
            this._items.push(newItem);
            if (!this._initted){
                if ($targetObject.parent == null){
                    $targetObject.addEventListener(Event.ADDED_TO_STAGE, this.onTargetAddedToStage, false, 0, true);
                } else {
                    this.initParent($targetObject.parent);
                };
            };
            return (newItem);
        }

        public function addItems($targetObjects:Array, $scaleMode:String="scaleNormal", $hasSelectableText:Boolean=false):Array{
            var a:Array = [];
            var i:uint;
            while (i < $targetObjects.length) {
                a.push(this.addItem($targetObjects[i], $scaleMode, $hasSelectableText));
                i++;
            };
            return (a);
        }

        public function removeItem($item):void{
            var i:int;
            var item:TransformItem = this.findObject($item);
            if (item != null){
                item.selected = false;
                item.removeEventListener(TransformEvent.SELECT, this.onSelectItem);
                item.removeEventListener(TransformEvent.DESELECT, this.onDeselectItem);
                item.removeEventListener(TransformEvent.MOUSE_DOWN, this.onMouseDownItem);
                item.removeEventListener(TransformEvent.SELECT_MOUSE_DOWN, this.onPressMove);
                item.removeEventListener(TransformEvent.SELECT_MOUSE_UP, this.onReleaseMove);
                item.removeEventListener(TransformEvent.UPDATE, this.onUpdateItem);
                item.removeEventListener(TransformEvent.SCALE, this.onUpdateItem);
                item.removeEventListener(TransformEvent.ROTATE, this.onUpdateItem);
                item.removeEventListener(TransformEvent.MOVE, this.onUpdateItem);
                item.removeEventListener(TransformEvent.ROLL_OVER_SELECTED, this.onRollOverSelectedItem);
                item.removeEventListener(TransformEvent.ROLL_OUT_SELECTED, this.onRollOutSelectedItem);
                item.removeEventListener(TransformEvent.DESTROY, this.onDestroyItem);
                i = (this._items.length - 1);
                while (i > -1) {
                    if (item == this._items[i]){
                        this._items.splice(i, 1);
                        item.destroy();
                        break;
                    };
                    i--;
                };
            };
        }

        public function removeAllItems():void{
            var item:TransformItem;
            var i:int = (this._items.length - 1);
            while (i > -1) {
                item = this._items[i];
                item.selected = false;
                item.removeEventListener(TransformEvent.SELECT, this.onSelectItem);
                item.removeEventListener(TransformEvent.DESELECT, this.onDeselectItem);
                item.removeEventListener(TransformEvent.MOUSE_DOWN, this.onMouseDownItem);
                item.removeEventListener(TransformEvent.SELECT_MOUSE_DOWN, this.onPressMove);
                item.removeEventListener(TransformEvent.SELECT_MOUSE_UP, this.onReleaseMove);
                item.removeEventListener(TransformEvent.UPDATE, this.onUpdateItem);
                item.removeEventListener(TransformEvent.SCALE, this.onUpdateItem);
                item.removeEventListener(TransformEvent.ROTATE, this.onUpdateItem);
                item.removeEventListener(TransformEvent.MOVE, this.onUpdateItem);
                item.removeEventListener(TransformEvent.ROLL_OVER_SELECTED, this.onRollOverSelectedItem);
                item.removeEventListener(TransformEvent.ROLL_OUT_SELECTED, this.onRollOutSelectedItem);
                item.removeEventListener(TransformEvent.DESTROY, this.onDestroyItem);
                this._items.splice(i, 1);
                item.destroy();
                i--;
            };
        }

        public function addIgnoredObject($object:DisplayObject):void{
            var i:uint;
            while (i < this._ignoredObjects.length) {
                if (this._ignoredObjects[i] == $object){
                    return;
                };
                i++;
            };
            this.removeItem($object);
            this._ignoredObjects.push($object);
        }

        public function removeIgnoredObject($object:DisplayObject):void{
            var i:uint;
            while (i < this._ignoredObjects.length) {
                if (this._ignoredObjects[i] == $object){
                    this._ignoredObjects.splice(i, 1);
                };
                i++;
            };
        }

        private function onDestroyItem($e:TransformEvent):void{
            this.removeItem($e.target);
        }

        private function setOrigin($p:Point):void{
            var local:Point;
            var bounds:Rectangle;
            var i:int;
            if (!this._lockOrigin){
                this._lockOrigin = true;
                this._origin = $p;
                local = this._dummyBox.globalToLocal(this._parent.localToGlobal($p));
                bounds = this._dummyBox.getBounds(this._dummyBox);
                this._dummyBox.graphics.clear();
                this._dummyBox.graphics.beginFill(26367, 1);
                this._dummyBox.graphics.drawRect((bounds.x - local.x), (bounds.y - local.y), bounds.width, bounds.height);
                this._dummyBox.graphics.endFill();
                this._dummyBox.x = this._origin.x;
                this._dummyBox.y = this._origin.y;
                this.enforceSafetyZone();
                i = (this._selectedItems.length - 1);
                while (i > -1) {
                    this._selectedItems[i].origin = this._origin;
                    i--;
                };
                this.plotHandles();
                this.renderSelection();
                this._lockOrigin = false;
            };
        }

        private function enforceSafetyZone():void{
            var locks:Array;
            var prevLockPosition:Boolean;
            var prevLockScale:Boolean;
            var b:Rectangle;
            var recordLocks:Function = function ():Array{
                var a:Array = [];
                var i:int = (_selectedItems.length - 1);
                while (i > -1) {
                    a[i] = {
                        "position":_selectedItems[i].lockPosition,
                        "scale":_selectedItems[i].lockScale
                    };
                    i--;
                };
                return (a);
            };
            var restoreLocks:Function = function ($a:Array):void{
                var i:int = ($a.length - 1);
                while (i > -1) {
                    _selectedItems[i].lockPosition = $a[i].position;
                    _selectedItems[i].lockScale = $a[i].scale;
                    i--;
                };
            };
            var shiftSelection:Function = function ($x:Number, $y:Number):void{
                _dummyBox.x = (_dummyBox.x + $x);
                _dummyBox.y = (_dummyBox.y + $y);
                var i:int = (_selectedItems.length - 1);
                while (i > -1) {
                    _selectedItems[i].move($x, $y, false, false);
                    i--;
                };
                _origin.x = (_origin.x + $x);
                _origin.y = (_origin.y + $y);
            };
            var shiftSelectionScale:Function = function ($scale:Number):void{
                var i:int;
                var o:Point = _origin.clone();
                _origin.x = (_bounds.x + (_bounds.width / 2));
                _origin.y = (_bounds.y + (_bounds.height / 2));
                i = (_selectedItems.length - 1);
                while (i > -1) {
                    _selectedItems[i].origin = _origin;
                    i--;
                };
                scaleSelection($scale, $scale, false);
                _origin.x = o.x;
                _origin.y = o.y;
                i = (_selectedItems.length - 1);
                while (i > -1) {
                    _selectedItems[i].origin = _origin;
                    i--;
                };
                updateSelection();
            };
            if (this._bounds != null){
                prevLockPosition = this._selLockPosition;
                prevLockScale = this._selLockScale;
                this._selLockPosition = false;
                this._selLockScale = false;
                if (!this._bounds.containsPoint(this._origin)){
                    locks = recordLocks();
                    if (this._bounds.left > this._origin.x){
                        (shiftSelection((this._bounds.left - this._origin.x), 0));
                    } else {
                        if (this._bounds.right < this._origin.x){
                            (shiftSelection((this._bounds.right - this._origin.x), 0));
                        };
                    };
                    if (this._bounds.top > this._origin.y){
                        (shiftSelection(0, (this._bounds.top - this._origin.y)));
                    } else {
                        if (this._bounds.bottom < this._origin.y){
                            (shiftSelection(0, (this._bounds.bottom - this._origin.y)));
                        };
                    };
                };
                if (this._selectedItems.length != 0){
                    if (locks == null){
                        locks = recordLocks();
                    };
                    if (this._handles[0].point == null){
                        this.plotHandles();
                    };
                    b = this.getSelectionRect();
                    if ((this._bounds.width - b.width) < 0.2){
                        (shiftSelectionScale((1 - (0.22 / b.width))));
                    };
                    b = this.getSelectionRect();
                    if ((this._bounds.height - b.height) < 0.2){
                        (shiftSelectionScale((1 - (0.22 / b.height))));
                    };
                    if (Math.abs((b.top - this._bounds.top)) < 0.1){
                        (shiftSelection(0, 0.1));
                    };
                    if (Math.abs((b.bottom - this._bounds.bottom)) < 0.1){
                        (shiftSelection(0, -0.1));
                    };
                    if (Math.abs((b.left - this._bounds.left)) < 0.1){
                        (shiftSelection(0.1, 0));
                    };
                    if (Math.abs((b.right - this._bounds.right)) < 0.1){
                        (shiftSelection(-0.1, 0));
                    };
                };
                if (locks != null){
                    (restoreLocks(locks));
                };
                this._selLockPosition = prevLockPosition;
                this._selLockScale = prevLockScale;
            };
        }

        protected function onPressDelete($e:Event=null):void{
            var deletedItems:Array;
            var item:TransformItem;
            var multiple:Boolean;
            var i:int;
            if (((this._enabled) && (this._allowDelete))){
                deletedItems = [];
                multiple = Boolean((this._selectedItems.length > 1));
                i = this._selectedItems.length;
                while (i--) {
                    item = this._selectedItems[i];
                    if (item.onPressDelete($e, multiple)){
                        deletedItems[deletedItems.length] = item;
                    };
                };
                if (deletedItems.length > 0){
                    dispatchEvent(new TransformEvent(TransformEvent.DELETE, deletedItems));
                };
            };
        }

        public function deleteSelection($e:Event=null):void{
            var item:TransformItem;
            var deletedItems:Array = [];
            var i:int = (this._selectedItems.length - 1);
            while (i > -1) {
                item = this._selectedItems[i];
                item.deleteObject();
                deletedItems.push(item);
                i--;
            };
            if (deletedItems.length != 0){
                dispatchEvent(new TransformEvent(TransformEvent.DELETE, deletedItems));
            };
        }

        private function onPressArrowKey($e:KeyboardEvent=null):void{
            var moveAmount:int;
            if (((((((this._arrowKeysMove) && (this._enabled))) && (!((this._selectedItems.length == 0))))) && (!((this._stage.focus is TextField))))){
                moveAmount = 1;
                if (isKeyDown(Keyboard.SHIFT)){
                    moveAmount = 10;
                };
                switch ($e.keyCode){
                    case Keyboard.UP:
                        this.moveSelection(0, -(moveAmount));
                        dispatchEvent(new TransformEvent(TransformEvent.FINISH_INTERACTIVE_MOVE, this._selectedItems.slice()));
                        break;
                    case Keyboard.DOWN:
                        this.moveSelection(0, moveAmount);
                        dispatchEvent(new TransformEvent(TransformEvent.FINISH_INTERACTIVE_MOVE, this._selectedItems.slice()));
                        break;
                    case Keyboard.LEFT:
                        this.moveSelection(-(moveAmount), 0);
                        dispatchEvent(new TransformEvent(TransformEvent.FINISH_INTERACTIVE_MOVE, this._selectedItems.slice()));
                        break;
                    case Keyboard.RIGHT:
                        this.moveSelection(moveAmount, 0);
                        dispatchEvent(new TransformEvent(TransformEvent.FINISH_INTERACTIVE_MOVE, this._selectedItems.slice()));
                        break;
                };
            };
        }

        public function centerOrigin():void{
            this.setOrigin(this.getSelectionCenter());
        }

        public function getSelectionCenter():Point{
            var bounds:Rectangle = this._dummyBox.getBounds(this._dummyBox);
            return (this._parent.globalToLocal(this._dummyBox.localToGlobal(new Point((bounds.x + (bounds.width / 2)), (bounds.y + (bounds.height / 2))))));
        }

        public function getSelectionBounds(targetCoordinateSpace:DisplayObject=null):Rectangle{
            if (((this._parent.contains(this._dummyBox)) && (!((this._selectedItems.length == 0))))){
                if (targetCoordinateSpace){
                    return (this._dummyBox.getBounds(targetCoordinateSpace));
                };
                return (this._dummyBox.getBounds(this._parent));
            };
            return (null);
        }

        public function getSelectionBoundsWithHandles(targetCoordinateSpace:DisplayObject=null):Rectangle{
            if (((this._parent.contains(this._selection)) && (!((this._selectedItems.length == 0))))){
                if (targetCoordinateSpace){
                    return (this._selection.getBounds(targetCoordinateSpace));
                };
                return (this._selection.getBounds(this._parent));
            };
            return (null);
        }

        public function getUnrotatedSelectionWidth():Number{
            var bounds:Rectangle = this._dummyBox.getBounds(this._dummyBox);
            return ((bounds.width * MatrixTools.getScaleX(this._dummyBox.transform.matrix)));
        }

        public function getUnrotatedSelectionHeight():Number{
            var bounds:Rectangle = this._dummyBox.getBounds(this._dummyBox);
            return ((bounds.height * MatrixTools.getScaleY(this._dummyBox.transform.matrix)));
        }

        public function getItem($targetObject:DisplayObject):TransformItem{
            var i:int = (this._items.length - 1);
            while (i > -1) {
                if (this._items[i].targetObject == $targetObject){
                    return (this._items[i]);
                };
                i--;
            };
            return (null);
        }

        private function findObject($item):TransformItem{
            if (($item is DisplayObject)){
                return (this.getItem($item));
            };
            if (($item is TransformItem)){
                return ($item);
            };
            return (null);
        }

        private function updateItemProp($prop:String, $value):void{
            var i:int = (this._items.length - 1);
            while (i > -1) {
                this._items[i][$prop] = $value;
                i--;
            };
        }

        private function removeParentListeners():void{
            if (((!((this._parent == null))) && (!((this._stage == null))))){
                this._stage.removeEventListener(MouseEvent.MOUSE_UP, this.onReleaseMove);
                this._stage.removeEventListener(MouseEvent.MOUSE_MOVE, this.onMouseMoveMove);
                this._stage.removeEventListener(MouseEvent.MOUSE_MOVE, this.onMouseMoveRotate);
                this._stage.removeEventListener(MouseEvent.MOUSE_MOVE, this.onMouseMoveScale);
            };
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

        public function destroy():void{
            this.deselectAll();
            _keyDispatcher.removeEventListener("pressDelete", this.onPressDelete);
            _keyDispatcher.removeEventListener("pressArrowKey", this.onPressArrowKey);
            _keyDispatcher.removeEventListener("pressMultiSelectKey", this.onPressMultiSelectKey);
            _keyDispatcher.removeEventListener("releaseMultiSelectKey", this.onReleaseMultiSelectKey);
            if (this._stage != null){
                this._stage.removeEventListener(Event.DEACTIVATE, this.onReleaseMultiSelectKey);
            };
            this.removeParentListeners();
            var i:int = (this._items.length - 1);
            while (i > -1) {
                this._items[i].destroy();
                i--;
            };
            dispatchEvent(new TransformEvent(TransformEvent.DESTROY, this._items.slice()));
        }

        public function moveSelectionDepthDown():void{
            this.moveSelectionDepth(-1);
        }

        public function moveSelectionDepthUp():void{
            this.moveSelectionDepth(1);
        }

        private function moveSelectionDepth(direction:int=1):void{
            var curDepths:Array;
            var i:int;
            var newDepths:Array;
            var hitGap:Boolean;
            if (((((((((this._enabled) && (!((this._selectedItems.length == 0))))) && (!((this._parent == null))))) && (this._parent.contains(this._dummyBox)))) && (this._parent.contains(this._selection)))){
                curDepths = [];
                i = (this._items.length - 1);
                while (i > -1) {
                    if (this._items[i].targetObject.parent == this._parent){
                        curDepths.push({
                            "depth":this._parent.getChildIndex(this._items[i].targetObject),
                            "item":this._items[i]
                        });
                    };
                    i--;
                };
                curDepths.sortOn("depth", Array.NUMERIC);
                newDepths = [];
                hitGap = false;
                if (direction == -1){
                    newDepths.push(curDepths[0].item.targetObject);
                    if (!curDepths[0].item.selected){
                        hitGap = true;
                    };
                    i = 1;
                    while (i < curDepths.length) {
                        if (((curDepths[i].item.selected) && (hitGap))){
                            newDepths.splice(-1, 0, curDepths[i].item.targetObject);
                        } else {
                            newDepths.push(curDepths[i].item.targetObject);
                            if (((!(curDepths[i].item.selected)) && (!(hitGap)))){
                                hitGap = true;
                            };
                        };
                        i++;
                    };
                } else {
                    newDepths.push(curDepths[(curDepths.length - 1)].item.targetObject);
                    if (!curDepths[(curDepths.length - 1)].item.selected){
                        hitGap = true;
                    };
                    i = (curDepths.length - 2);
                    while (i > -1) {
                        if (((curDepths[i].item.selected) && (hitGap))){
                            newDepths.splice(1, 0, curDepths[i].item.targetObject);
                        } else {
                            newDepths.unshift(curDepths[i].item.targetObject);
                            if (((!(curDepths[i].item.selected)) && (!(hitGap)))){
                                hitGap = true;
                            };
                        };
                        i--;
                    };
                };
                i = 0;
                while (i < newDepths.length) {
                    this._parent.setChildIndex(newDepths[i], curDepths[i].depth);
                    i++;
                };
                dispatchEvent(new TransformEvent(TransformEvent.DEPTH_CHANGE, this._items.slice()));
            };
        }

        private function checkForDeselect($e:MouseEvent=null):void{
            var i:int;
            var x:Number;
            var y:Number;
            var deselectedItem:TransformItem;
            var handle_obj:Object;
            if (((((!((this._selectedItems.length == 0))) && (!((this._parent == null))))) && (!((this._parent.root == null))))){
                i = this._selectedItems.length;
                x = $e.stageX;
                y = $e.stageY;
                deselectedItem = _tempDeselectedItem;
                _tempDeselectedItem = null;
                if (this._selection.hitTestPoint(x, y, true)){
                    return;
                };
                if (deselectedItem){
                    if (deselectedItem.targetObject.hitTestPoint(x, y, true)){
                        return;
                    };
                };
                while (i--) {
                    if (this._selectedItems[i].targetObject.hitTestPoint(x, y, true)){
                        return;
                    };
                };
                i = this._ignoredObjects.length;
                while (i--) {
                    if (this._ignoredObjects[i].hitTestPoint(x, y, true)){
                        return;
                    };
                };
                for each (handle_obj in this._handlesDict) {
                    if (Sprite(handle_obj.handle).hitTestPoint(x, y, true)){
                        return;
                    };
                };
                if (this._autoDeselect){
                    this.deselectAll();
                } else {
                    dispatchEvent(new TransformEvent(TransformEvent.CLICK_OFF, this._selectedItems.slice(), $e));
                };
            };
        }

        private function onMouseDownItem($e:TransformEvent):void{
            if (isKeyDown(Keyboard.CONTROL)){
                $e.target.selected = !($e.target.selected);
                if (!$e.target.selected){
                    _tempDeselectedItem = ($e.target as TransformItem);
                };
            } else {
                $e.target.selected = true;
            };
            if (!$e.target.hasSelectableText){
                this._stage.stageFocusRect = false;
                this._stage.focus = $e.target.targetObject;
            };
        }

        private function onMouseDownSelection($e:MouseEvent):void{
            this._stage.addEventListener(MouseEvent.MOUSE_UP, this.onReleaseMove, false, 0, true);
            this.onPressMove($e);
        }

        public function selectItem($item, $addToSelection:Boolean=false):TransformItem{
            var previousMode:Boolean;
            var item:TransformItem = this.findObject($item);
            if (item == null){
                trace("TransformManager Error: selectItem() and selectItems() only work with objects that have a TransformItem associated with them. Make sure you create one by calling TransformManager.addItem() before attempting to select it.");
            } else {
                if (!item.selected){
                    previousMode = this._multiSelectMode;
                    this._multiSelectMode = $addToSelection;
                    this._ignoreEvents = true;
                    item.selected = true;
                    this._ignoreEvents = false;
                    this._multiSelectMode = previousMode;
                    dispatchEvent(new TransformEvent(TransformEvent.SELECTION_CHANGE, [item]));
                };
            };
            return (item);
        }

        public function deselectItem($item):TransformItem{
            var item:TransformItem = this.findObject($item);
            if (item != null){
                item.selected = false;
            };
            return (item);
        }

        public function selectItems($items:Array, $addToSelection:Boolean=false):Array{
            var i:uint;
            var j:uint;
            var item:TransformItem;
            var selectedItem:TransformItem;
            var found:Boolean;
            var validItems:Array = [];
            this._ignoreEvents = true;
            i = 0;
            while (i < $items.length) {
                item = this.findObject($items[i]);
                if (item != null){
                    validItems.push(item);
                };
                i++;
            };
            if (!$addToSelection){
                i = 0;
                while (i < this._selectedItems.length) {
                    selectedItem = this._selectedItems[i];
                    found = false;
                    j = 0;
                    while (j < validItems.length) {
                        if (validItems[j] == selectedItem){
                            found = true;
                            break;
                        };
                        j++;
                    };
                    if (!found){
                        selectedItem.selected = false;
                    };
                    i++;
                };
            };
            var previousMode:Boolean = this._multiSelectMode;
            this._multiSelectMode = true;
            i = 0;
            while (i < validItems.length) {
                validItems[i].selected = true;
                i++;
            };
            this._multiSelectMode = previousMode;
            this._ignoreEvents = false;
            dispatchEvent(new TransformEvent(TransformEvent.SELECTION_CHANGE, validItems));
            return (validItems);
        }

        public function deselectAll():void{
            var oldItems:Array = this._selectedItems.slice();
            this._ignoreEvents = true;
            var i:int = (this._selectedItems.length - 1);
            while (i > -1) {
                this._selectedItems[i].selected = false;
                i--;
            };
            this._ignoreEvents = false;
            dispatchEvent(new TransformEvent(TransformEvent.SELECTION_CHANGE, oldItems));
        }

        public function isSelected($item):Boolean{
            var item:TransformItem = this.findObject($item);
            if (item != null){
                return (item.selected);
            };
            return (false);
        }

        private function onSelectItem($e:TransformEvent):void{
            var i:int;
            var previousIgnore:Boolean = this._ignoreEvents;
            this._ignoreEvents = true;
            var changed:Array = [($e.target as TransformItem)];
            if (!this._multiSelectMode){
                i = (this._selectedItems.length - 1);
                while (i > -1) {
                    changed.push(this._selectedItems[i]);
                    this._selectedItems[i].selected = false;
                    this._selectedItems.splice(i, 1);
                    i--;
                };
            };
            this._selectedItems.push($e.target);
            if (this._initted){
                if (this._forceSelectionToFront){
                    i = (this._selectedItems.length - 1);
                    while (i > -1) {
                        bringToFront(this._selectedItems[i].targetObject);
                        i--;
                    };
                };
                this.calibrateConstraints();
                this.updateSelection();
            };
            this._ignoreEvents = previousIgnore;
            if (!this._ignoreEvents){
                dispatchEvent(new TransformEvent(TransformEvent.SELECTION_CHANGE, changed));
            };
        }

        private function calibrateConstraints():void{
            this._selConstrainScale = this._constrainScale;
            this._selLockScale = this._lockScale;
            this._selLockRotation = this._lockRotation;
            this._selLockPosition = this._lockPosition;
            this._selHasTextFields = (this._selHasScaleLimits = false);
            var i:int = (this._selectedItems.length - 1);
            while (i > -1) {
                if (this._selectedItems[i].constrainScale){
                    this._selConstrainScale = true;
                };
                if (this._selectedItems[i].lockScale){
                    this._selLockScale = true;
                };
                if (this._selectedItems[i].lockRotation){
                    this._selLockRotation = true;
                };
                if (this._selectedItems[i].lockPosition){
                    this._selLockPosition = true;
                };
                if (this._selectedItems[i].scaleMode != SCALE_NORMAL){
                    this._selHasTextFields = true;
                };
                if (this._selectedItems[i].hasScaleLimits){
                    this._selHasScaleLimits = true;
                };
                i--;
            };
        }

        private function onDeselectItem($e:TransformEvent):void{
            var i:int = (this._selectedItems.length - 1);
            while (i > -1) {
                if (this._selectedItems[i] == $e.target){
                    this._selectedItems.splice(i, 1);
                    this.updateSelection();
                    if (!this._ignoreEvents){
                        dispatchEvent(new TransformEvent(TransformEvent.SELECTION_CHANGE, [($e.target as TransformItem)]));
                    };
                    if (!this.mouseIsOverSelection(true)){
                        this.swapCursorOut();
                    };
                    return;
                };
                i--;
            };
        }

        private function onUpdateItem($e:TransformEvent):void{
            if (!this._ignoreEvents){
                if ($e.type == TransformEvent.UPDATE){
                    this.calibrateConstraints();
                };
                if ((($e.target.selected) && (!(this._isTransforming)))){
                    this.updateSelection(true);
                    dispatchEvent(new TransformEvent(TransformEvent.UPDATE, [$e.target]));
                };
            };
        }

        public function updateSelection($centerOrigin:Boolean=true):void{
            var r:Rectangle;
            var ti:TransformItem;
            var t:DisplayObject;
            var m:Matrix;
            if (this._selectedItems.length != 0){
                if (this._dummyBox.parent != this._parent){
                    this._parent.addChild(this._dummyBox);
                };
                this._dummyBox.transform.matrix = new Matrix();
                this._dummyBox.graphics.clear();
                this._dummyBox.graphics.beginFill(26367, 1);
                if (this._selectedItems.length == 1){
                    ti = this._selectedItems[0];
                    t = ti.targetObject;
                    if (((!(t.hasOwnProperty("content"))) && (!((t.width == 0))))){
                        m = t.transform.matrix;
                        t.transform.matrix = new Matrix();
                        r = t.getBounds(t);
                        this._dummyBox.graphics.drawRect(r.x, r.y, t.width, t.height);
                        this._dummyBox.transform.matrix = (t.transform.matrix = m);
                    } else {
                        r = t.getBounds(t);
                        this._dummyBox.graphics.drawRect(r.x, r.y, r.width, r.height);
                        this._dummyBox.transform.matrix = t.transform.matrix;
                    };
                } else {
                    r = this.getSelectionRect();
                    this._dummyBox.graphics.drawRect(r.x, r.y, r.width, r.height);
                };
                this._dummyBox.graphics.endFill();
                if ((($centerOrigin) || ((this._origin == null)))){
                    this.centerOrigin();
                } else {
                    this.setOrigin(this._origin);
                };
                if (this._selection.parent != this._parent){
                    this._parent.addChild(this._selection);
                };
                this.renderSelection();
                bringToFront(this._selection);
            } else {
                if (this._parent != null){
                    if (this._selection.parent == this._parent){
                        this._parent.removeChild(this._selection);
                    };
                    if (this._dummyBox.parent == this._parent){
                        this._parent.removeChild(this._dummyBox);
                    };
                };
            };
        }

        private function renderSelection():void{
            var m:Matrix;
            var rotation:Number;
            var flip:Boolean;
            var p:Point;
            var finishPoint:Point;
            var i:int;
            if (this._initted){
                m = this._dummyBox.transform.matrix;
                this._selection.graphics.clear();
                this._selection.graphics.lineStyle(1, this._lineColor, 1, false, "none");
                this._edges.graphics.clear();
                this._edges.graphics.lineStyle(10, 0xFF0000, 0, false, "none");
                rotation = this._dummyBox.rotation;
                flip = false;
                if ((MatrixTools.getDirectionX(m) * MatrixTools.getDirectionY(m)) < 0){
                    flip = true;
                };
                i = (this._handles.length - 1);
                while (i > -1) {
                    p = m.transformPoint(this._handles[i].point);
                    this._handles[i].handle.x = p.x;
                    this._handles[i].handle.y = p.y;
                    this._handles[i].handle.rotation = rotation;
                    if (flip){
                        this._handles[i].handle.rotation = (this._handles[i].handle.rotation + this._handles[i].flipRotation);
                    };
                    if (i == 8){
                        this._selection.graphics.moveTo(p.x, p.y);
                        this._edges.graphics.moveTo(p.x, p.y);
                        finishPoint = p;
                    } else {
                        if (i > 4){
                            this._selection.graphics.lineTo(p.x, p.y);
                            this._edges.graphics.lineTo(p.x, p.y);
                        };
                    };
                    i--;
                };
                this._selection.graphics.lineTo(finishPoint.x, finishPoint.y);
                this._edges.graphics.lineTo(finishPoint.x, finishPoint.y);
            };
        }

        private function getSelectionRect():Rectangle{
            if (this._selectedItems.length == 0){
                return (new Rectangle());
            };
            var i:int = (this._selectedItems.length - 1);
            var b:Rectangle = this._selectedItems[i].targetObject.getBounds(this._parent);
            while (i--) {
                b = b.union(this._selectedItems[i].targetObject.getBounds(this._parent));
            };
            return (b);
        }

        private function initSelection():void{
            this._selection = ((this._isFlex) ? new (getDefinitionByName("mx.core.UIComponent"))() : new Sprite());
            this._selection.name = "__selection_mc";
            this._edges = new Sprite();
            this._edges.addEventListener(MouseEvent.MOUSE_DOWN, this.onMouseDownSelection, false, 0, true);
            this._selection.addChild(this._edges);
            this._dummyBox = ((this._isFlex) ? new (getDefinitionByName("mx.core.UIComponent"))() : new Sprite());
            this._dummyBox.name = "__dummyBox_mc";
            this._dummyBox.visible = false;
            this._handles = [];
            this.createHandle("c", "center", 0, 0, null);
            this.createHandle("t", "stretchV", 90, 0, "b");
            this.createHandle("r", "stretchH", 0, 0, "l");
            this.createHandle("b", "stretchV", -90, 0, "t");
            this.createHandle("l", "stretchH", 180, 0, "r");
            this.createHandle("tl", "corner", -135, -90, "br");
            this.createHandle("tr", "corner", -45, 90, "bl");
            this.createHandle("br", "corner", 45, -90, "tl");
            this.createHandle("bl", "corner", 135, 90, "tr");
            this.redrawHandles();
            this.setCursorListeners(true);
        }

        private function createHandle($name:String, $type:String, $cursorRotation:Number, $flipRotation:Number=0, $oppositeName:String=null):Object{
            var onPress:Function;
            var r:Sprite;
            var h:Sprite = new Sprite();
            h.name = $name;
            var s:Sprite = new Sprite();
            s.name = "scaleHandle";
            var handle:Object = {
                "handle":h,
                "scaleHandle":s,
                "type":$type,
                "name":$name,
                "oppositeName":$oppositeName,
                "flipRotation":$flipRotation,
                "cursorRotation":$cursorRotation
            };
            this._handlesDict[s] = handle;
            if ($type != "center"){
                if ($type == "stretchH"){
                    onPress = this.onPressStretchH;
                } else {
                    if ($type == "stretchV"){
                        onPress = this.onPressStretchV;
                    } else {
                        onPress = this.onPressScale;
                        r = new Sprite();
                        r.name = "rotationHandle";
                        r.addEventListener(MouseEvent.MOUSE_DOWN, this.onPressRotate, false, 0, true);
                        h.addChild(r);
                        this._handlesDict[r] = handle;
                        handle.rotationHandle = r;
                    };
                };
                s.addEventListener(MouseEvent.MOUSE_DOWN, onPress, false, 0, true);
            } else {
                s.addEventListener(MouseEvent.MOUSE_DOWN, this.onMouseDownSelection, false, 0, true);
            };
            h.addChild(s);
            this._selection.addChild(h);
            this._handles.push(handle);
            return (handle);
        }

        private function redrawHandles():void{
            var i:uint;
            var s:Sprite;
            var r:Sprite;
            var handleName:String;
            var rx:Number;
            var ry:Number;
            var halfH:Number = (this._handleSize / 2);
            i = 0;
            while (i < this._handles.length) {
                s = this._handles[i].scaleHandle;
                handleName = this._handles[i].name;
                s.graphics.clear();
                s.graphics.lineStyle(1, this._lineColor, 1, false, "none");
                s.graphics.beginFill(this._handleColor, 1);
                s.graphics.drawRect((0 - (this._handleSize / 2)), (0 - (this._handleSize / 2)), this._handleSize, this._handleSize);
                s.graphics.endFill();
                if (this._handles[i].type == "corner"){
                    r = this._handles[i].rotationHandle;
                    if (handleName == "tl"){
                        ry = (-(halfH) - this._paddingForRotation);
                        rx = ry;
                    } else {
                        if (handleName == "tr"){
                            rx = -(halfH);
                            ry = (-(halfH) - this._paddingForRotation);
                        } else {
                            if (handleName == "br"){
                                ry = -(halfH);
                                rx = ry;
                            } else {
                                rx = (-(halfH) - this._paddingForRotation);
                                ry = -(halfH);
                            };
                        };
                    };
                    r.graphics.clear();
                    r.graphics.lineStyle(0, this._lineColor, 0);
                    r.graphics.beginFill(0xFF0000, 0);
                    r.graphics.drawRect(rx, ry, (this._handleSize + this._paddingForRotation), (this._handleSize + this._paddingForRotation));
                    r.graphics.endFill();
                } else {
                    if (this._handles[i].type == "center"){
                        s.visible = !(this._hideCenterHandle);
                    };
                };
                i++;
            };
        }

        private function plotHandles():void{
            var r:Rectangle = this._dummyBox.getBounds(this._dummyBox);
            this._handles[0].point = new Point((r.x + (r.width / 2)), (r.y + (r.height / 2)));
            this._handles[1].point = new Point((r.x + (r.width / 2)), r.y);
            this._handles[2].point = new Point((r.x + r.width), (r.y + (r.height / 2)));
            this._handles[3].point = new Point((r.x + (r.width / 2)), (r.y + r.height));
            this._handles[4].point = new Point(r.x, (r.y + (r.height / 2)));
            this._handles[5].point = new Point(r.x, r.y);
            this._handles[6].point = new Point((r.x + r.width), r.y);
            this._handles[7].point = new Point((r.x + r.width), (r.y + r.height));
            this._handles[8].point = new Point(r.x, (r.y + r.height));
        }

        private function onPressMove($e:Event):void{
            if (!this._selLockPosition){
                this._isTransforming = true;
                this._trackingInfo = {
                    "offsetX":(this._parent.mouseX - this._dummyBox.x),
                    "offsetY":(this._parent.mouseY - this._dummyBox.y),
                    "x":this._dummyBox.x,
                    "y":this._dummyBox.y,
                    "mouseX":this._parent.mouseX,
                    "mouseY":this._parent.mouseY
                };
                this._stage.addEventListener(MouseEvent.MOUSE_MOVE, this.onMouseMoveMove, false, 0, true);
                this.swapCursorIn(moveCursor, null);
                this.lockCursor();
                this.onMouseMoveMove();
            };
        }

        private function onMouseMoveMove($e:MouseEvent=null):void{
            var x:Number = int((this._parent.mouseX - (this._dummyBox.x + this._trackingInfo.offsetX)));
            var y:Number = int((this._parent.mouseY - (this._dummyBox.y + this._trackingInfo.offsetY)));
            var totalX:Number = (this._parent.mouseX - this._trackingInfo.mouseX);
            var totalY:Number = (this._parent.mouseY - this._trackingInfo.mouseY);
            if (!isKeyDown(Keyboard.SHIFT)){
                this.moveSelection(x, y);
            } else {
                if (Math.abs(totalX) > Math.abs(totalY)){
                    this.moveSelection(x, (this._trackingInfo.y - this._dummyBox.y));
                } else {
                    this.moveSelection((this._trackingInfo.x - this._dummyBox.x), y);
                };
            };
            if ($e != null){
                $e.updateAfterEvent();
            };
        }

        public function moveSelection($x:Number, $y:Number, $dispatchEvents:Boolean=true):void{
            var safe:Object;
            var m:Matrix;
            var i:int;
            if (!this._selLockPosition){
                safe = {
                    "x":$x,
                    "y":$y
                };
                m = this._dummyBox.transform.matrix;
                this._dummyBox.x = (this._dummyBox.x + $x);
                this._dummyBox.y = (this._dummyBox.y + $y);
                if (((!((this._bounds == null))) && (!(this._bounds.containsRect(this._dummyBox.getBounds(this._parent)))))){
                    i = (this._selectedItems.length - 1);
                    while (i > -1) {
                        this._selectedItems[i].moveCheck($x, $y, safe);
                        i--;
                    };
                    m.translate(safe.x, safe.y);
                    this._dummyBox.transform.matrix = m;
                };
                this._ignoreEvents = true;
                i = (this._selectedItems.length - 1);
                while (i > -1) {
                    this._selectedItems[i].move(safe.x, safe.y, false, $dispatchEvents);
                    i--;
                };
                this._ignoreEvents = false;
                this._origin.x = this._dummyBox.x;
                this._origin.y = this._dummyBox.y;
                this.renderSelection();
                if (((((this._dispatchMoveEvents) && ($dispatchEvents))) && (((!((safe.x == 0))) || (!((safe.y == 0))))))){
                    dispatchEvent(new TransformEvent(TransformEvent.MOVE, this._selectedItems.slice()));
                };
            };
        }

        private function onReleaseMove($e:Event):void{
            var i:int;
            var clickTime:uint = getTimer();
            if ((clickTime - this._lastClickTime) < 500){
                dispatchEvent(new TransformEvent(TransformEvent.DOUBLE_CLICK, this._selectedItems.slice()));
            };
            this._lastClickTime = clickTime;
            if (!this._selLockPosition){
                this._stage.removeEventListener(MouseEvent.MOUSE_MOVE, this.onMouseMoveMove);
                this._stage.removeEventListener(MouseEvent.MOUSE_UP, this.onReleaseMove);
                this.unlockCursor();
                this._isTransforming = false;
                if (((!((this._trackingInfo.x == this._dummyBox.x))) || (!((this._trackingInfo.y == this._dummyBox.y))))){
                    dispatchEvent(new TransformEvent(TransformEvent.FINISH_INTERACTIVE_MOVE, this._selectedItems.slice()));
                    i = (this._selectedItems.length - 1);
                    while (i > -1) {
                        this._selectedItems[i].forceEventDispatch(TransformEvent.FINISH_INTERACTIVE_MOVE);
                        i--;
                    };
                };
            };
        }

        private function onPressScale($e:MouseEvent):void{
            if (((!(this._selLockScale)) && (((!(this._selHasTextFields)) || ((this._selectedItems.length == 1)))))){
                this._isTransforming = true;
                this.setScaleOrigin(($e.target as Sprite));
                this.captureScaleTrackingInfo(($e.target as Sprite));
                this._stage.addEventListener(MouseEvent.MOUSE_MOVE, this.onMouseMoveScale, false, 0, true);
                this._stage.addEventListener(MouseEvent.MOUSE_UP, this.onReleaseScale, false, 0, true);
                this.lockCursor();
                this.onMouseMoveScale();
            };
        }

        private function setScaleOrigin($pressedHandle:Sprite):void{
            var h:DisplayObject;
            bringToFront($pressedHandle.parent);
            if (this._scaleFromCenter){
                this.centerOrigin();
            } else {
                h = this._selection.getChildByName(this._handlesDict[$pressedHandle].oppositeName);
                this.setOrigin(new Point(h.x, h.y));
            };
        }

        private function onMouseMoveScale($e:MouseEvent=null):void{
            this.updateScale(true, true);
            if ($e != null){
                $e.updateAfterEvent();
            };
        }

        private function updateScale($x:Boolean=true, $y:Boolean=true):void{
            var newScaleX:Number;
            var newScaleY:Number;
            var xFactor:Number;
            var yFactor:Number;
            var angleDif:Number;
            var ti:Object = this._trackingInfo;
            var mx:Number = (this._parent.mouseX - ti.mouseOffsetX);
            var my:Number = (this._parent.mouseY - ti.mouseOffsetY);
            if (this._bounds != null){
                if (mx >= this._bounds.right){
                    mx = (this._bounds.right - 0.02);
                } else {
                    if (mx <= this._bounds.left){
                        mx = (this._bounds.left + 0.02);
                    };
                };
                if (my >= this._bounds.bottom){
                    my = (this._bounds.bottom - 0.02);
                } else {
                    if (my <= this._bounds.top){
                        my = (this._bounds.top + 0.02);
                    };
                };
            };
            var dx:Number = (mx - this._origin.x);
            var dy:Number = (this._origin.y - my);
            var d:Number = Math.sqrt(((dx * dx) + (dy * dy)));
            var angleToMouse:Number = Math.atan2(dy, dx);
            var constrain:Boolean = ((this._selConstrainScale) || (isKeyDown(Keyboard.SHIFT)));
            if (constrain){
                angleDif = (((angleToMouse - ti.angleToMouse) + (Math.PI * 3.5)) % (Math.PI * 2));
                if (angleDif < Math.PI){
                    d = (d * -1);
                };
                newScaleX = (d * ti.scaleRatioXConst);
                newScaleY = (d * ti.scaleRatioYConst);
            } else {
                angleToMouse = (angleToMouse + ti.angle);
                newScaleX = ((ti.scaleRatioX * Math.cos(angleToMouse)) * d);
                newScaleY = ((ti.scaleRatioY * Math.sin(angleToMouse)) * d);
            };
            if ((((($x) || (constrain))) && ((((newScaleX > 0.001)) || ((newScaleX < -0.001)))))){
                xFactor = (newScaleX / this._prevScaleX);
            } else {
                xFactor = 1;
            };
            if ((((($y) || (constrain))) && ((((newScaleY > 0.001)) || ((newScaleY < -0.001)))))){
                yFactor = (newScaleY / this._prevScaleY);
            } else {
                yFactor = 1;
            };
            this.scaleSelection(xFactor, yFactor);
        }

        public function scaleSelection($sx:Number, $sy:Number, $dispatchEvents:Boolean=true):void{
            var i:int;
            var m:Matrix;
            var m2:Matrix;
            var angle:Number;
            var skew:Number;
            var safe:Object;
            if (((!(this._selLockScale)) && (((!(this._selHasTextFields)) || ((((((this._selectedItems.length == 1)) && (($sx > 0)))) && (($sy > 0)))))))){
                m = this._dummyBox.transform.matrix;
                m2 = m.clone();
                angle = MatrixTools.getAngle(m);
                skew = MatrixTools.getSkew(m);
                if (((!((angle == -(skew)))) && ((Math.abs(((angle + skew) % (Math.PI - 0.01))) < 0.01)))){
                    skew = -(angle);
                };
                MatrixTools.scaleMatrix(m, $sx, $sy, angle, skew);
                this._dummyBox.transform.matrix = m;
                safe = {
                    "sx":$sx,
                    "sy":$sy
                };
                if (((this._selHasScaleLimits) || (((!((this._bounds == null))) && (!(this._bounds.containsRect(this._dummyBox.getBounds(this._parent)))))))){
                    i = (this._selectedItems.length - 1);
                    while (i > -1) {
                        this._selectedItems[i].scaleCheck(safe, angle, skew);
                        i--;
                    };
                    MatrixTools.scaleMatrix(m2, safe.sx, safe.sy, angle, skew);
                    this._dummyBox.transform.matrix = m2;
                };
                this._ignoreEvents = true;
                i = (this._selectedItems.length - 1);
                while (i > -1) {
                    this._selectedItems[i].scaleRotated(safe.sx, safe.sy, angle, skew, false, $dispatchEvents);
                    i--;
                };
                this._ignoreEvents = false;
                this._prevScaleX = (this._prevScaleX * safe.sx);
                this._prevScaleY = (this._prevScaleY * safe.sy);
                this.renderSelection();
                if (((((this._dispatchScaleEvents) && ($dispatchEvents))) && (((!((safe.sx == 1))) || (!((safe.sy == 1))))))){
                    dispatchEvent(new TransformEvent(TransformEvent.SCALE, this._selectedItems.slice()));
                };
            };
        }

        public function flipSelectionHorizontal():void{
            if (((this._enabled) && (!((this._selectedItems.length == 0))))){
                this.scaleSelection(-1, 1);
            };
        }

        public function flipSelectionVertical():void{
            if (((this._enabled) && (!((this._selectedItems.length == 0))))){
                this.scaleSelection(1, -1);
            };
        }

        private function onReleaseScale($e:MouseEvent):void{
            var m:Matrix;
            var i:int;
            if (!this._selLockScale){
                this._stage.removeEventListener(MouseEvent.MOUSE_UP, this.onReleaseScale);
                this._stage.removeEventListener(MouseEvent.MOUSE_MOVE, this.onMouseMoveScale);
                this.unlockCursor();
                this.centerOrigin();
                m = this._dummyBox.transform.matrix;
                this._isTransforming = false;
                if (((!((this._trackingInfo.scaleX == MatrixTools.getScaleX(m)))) || (!((this._trackingInfo.scaleY == MatrixTools.getScaleY(m)))))){
                    dispatchEvent(new TransformEvent(TransformEvent.FINISH_INTERACTIVE_SCALE, this._selectedItems.slice()));
                    i = (this._selectedItems.length - 1);
                    while (i > -1) {
                        this._selectedItems[i].forceEventDispatch(TransformEvent.FINISH_INTERACTIVE_SCALE);
                        i--;
                    };
                };
            };
        }

        private function captureScaleTrackingInfo($handle:Sprite):void{
            var handlePoint:Point = this._parent.globalToLocal($handle.localToGlobal(new Point(0, 0)));
            var mdx:Number = (handlePoint.x - this._origin.x);
            var mdy:Number = (this._origin.y - handlePoint.y);
            var distanceToMouse:Number = Math.sqrt(((mdx * mdx) + (mdy * mdy)));
            var angleToMouse:Number = Math.atan2(mdy, mdx);
            var m:Matrix = this._dummyBox.transform.matrix;
            var angle:Number = MatrixTools.getAngle(m);
            var skew:Number = MatrixTools.getSkew(m);
            var correctedAngle:Number = (angleToMouse + angle);
            var scaleX:Number = (this._prevScaleX = MatrixTools.getScaleX(m));
            var scaleY:Number = (this._prevScaleY = MatrixTools.getScaleY(m));
            this._trackingInfo = {
                "scaleRatioX":(scaleX / (Math.cos(correctedAngle) * distanceToMouse)),
                "scaleRatioY":(scaleY / (Math.sin(correctedAngle) * distanceToMouse)),
                "scaleRatioXConst":(scaleX / distanceToMouse),
                "scaleRatioYConst":(scaleY / distanceToMouse),
                "angleToMouse":positiveAngle(angleToMouse),
                "angle":angle,
                "skew":skew,
                "mouseX":this._parent.mouseX,
                "mouseY":this._parent.mouseY,
                "scaleX":scaleX,
                "scaleY":scaleY,
                "mouseOffsetX":(this._parent.mouseX - handlePoint.x),
                "mouseOffsetY":(this._parent.mouseY - handlePoint.y),
                "handle":$handle
            };
        }

        private function onPressStretchH($e:MouseEvent):void{
            if (!this._selLockScale){
                this._isTransforming = true;
                this.setScaleOrigin(($e.target as Sprite));
                this.captureScaleTrackingInfo(($e.target as Sprite));
                this._stage.addEventListener(MouseEvent.MOUSE_MOVE, this.onMouseMoveStretchH, false, 0, true);
                this._stage.addEventListener(MouseEvent.MOUSE_UP, this.onReleaseStretchH, false, 0, true);
                this.lockCursor();
                this.onMouseMoveStretchH();
            };
        }

        private function onMouseMoveStretchH($e:MouseEvent=null):void{
            this.updateScale(true, false);
            if ($e != null){
                $e.updateAfterEvent();
            };
        }

        private function onReleaseStretchH($e:MouseEvent):void{
            var m:Matrix;
            var i:int;
            if (!this._selLockScale){
                this._stage.removeEventListener(MouseEvent.MOUSE_UP, this.onReleaseStretchH);
                this._stage.removeEventListener(MouseEvent.MOUSE_MOVE, this.onMouseMoveStretchH);
                this.unlockCursor();
                this.centerOrigin();
                this._isTransforming = false;
                m = this._dummyBox.transform.matrix;
                if (((!((this._trackingInfo.scaleX == MatrixTools.getScaleX(m)))) || (!((this._trackingInfo.scaleY == MatrixTools.getScaleY(m)))))){
                    dispatchEvent(new TransformEvent(TransformEvent.FINISH_INTERACTIVE_SCALE, this._selectedItems.slice()));
                    i = (this._selectedItems.length - 1);
                    while (i > -1) {
                        this._selectedItems[i].forceEventDispatch(TransformEvent.FINISH_INTERACTIVE_SCALE);
                        i--;
                    };
                };
            };
        }

        private function onPressStretchV($e:MouseEvent):void{
            if (!this._selLockScale){
                this._isTransforming = true;
                this.setScaleOrigin(($e.target as Sprite));
                this.captureScaleTrackingInfo(($e.target as Sprite));
                this._stage.addEventListener(MouseEvent.MOUSE_MOVE, this.onMouseMoveStretchV, false, 0, true);
                this._stage.addEventListener(MouseEvent.MOUSE_UP, this.onReleaseStretchV, false, 0, true);
                this.lockCursor();
                this.onMouseMoveStretchV();
            };
        }

        private function onMouseMoveStretchV($e:MouseEvent=null):void{
            this.updateScale(false, true);
            if ($e != null){
                $e.updateAfterEvent();
            };
        }

        private function onReleaseStretchV($e:MouseEvent):void{
            var m:Matrix;
            var i:int;
            if (!this._selLockScale){
                this._stage.removeEventListener(MouseEvent.MOUSE_UP, this.onReleaseStretchV);
                this._stage.removeEventListener(MouseEvent.MOUSE_MOVE, this.onMouseMoveStretchV);
                this.unlockCursor();
                this.centerOrigin();
                this._isTransforming = false;
                m = this._dummyBox.transform.matrix;
                if (((!((this._trackingInfo.scaleX == MatrixTools.getScaleX(m)))) || (!((this._trackingInfo.scaleY == MatrixTools.getScaleY(m)))))){
                    dispatchEvent(new TransformEvent(TransformEvent.FINISH_INTERACTIVE_SCALE, this._selectedItems.slice()));
                    i = (this._selectedItems.length - 1);
                    while (i > -1) {
                        this._selectedItems[i].forceEventDispatch(TransformEvent.FINISH_INTERACTIVE_SCALE);
                        i--;
                    };
                };
            };
        }

        private function onPressRotate($e:MouseEvent):void{
            var mdx:Number;
            var mdy:Number;
            var angleToMouse:Number;
            var angle:Number;
            if (!this._selLockRotation){
                this._isTransforming = true;
                this.centerOrigin();
                mdx = (this._parent.mouseX - this._origin.x);
                mdy = (this._origin.y - this._parent.mouseY);
                angleToMouse = Math.atan2(mdy, mdx);
                angle = (this._dummyBox.rotation * _DEG2RAD);
                this._trackingInfo = {
                    "angleToMouse":positiveAngle(angleToMouse),
                    "angle":angle,
                    "mouseX":this._parent.mouseX,
                    "mouseY":this._parent.mouseY,
                    "rotation":this._dummyBox.rotation,
                    "handle":$e.target
                };
                this._stage.addEventListener(MouseEvent.MOUSE_MOVE, this.onMouseMoveRotate, false, 0, true);
                this._stage.addEventListener(MouseEvent.MOUSE_UP, this.onReleaseRotate, false, 0, true);
                this.lockCursor();
                this.onMouseMoveRotate();
            };
        }

        private function onMouseMoveRotate($e:MouseEvent=null):void{
            var angleIncrement:Number;
            var ti:Object = this._trackingInfo;
            var dx:Number = (this._parent.mouseX - this._origin.x);
            var dy:Number = (this._origin.y - this._parent.mouseY);
            var angleToMouse:Number = Math.atan2(dy, dx);
            var angleDifference:Number = (ti.angleToMouse - Math.atan2(dy, dx));
            var newAngle:Number = (angleDifference + ti.angle);
            if (isKeyDown(Keyboard.SHIFT)){
                angleIncrement = (Math.PI * 0.25);
                newAngle = (Math.round((newAngle / angleIncrement)) * angleIncrement);
            };
            newAngle = (newAngle - (this._dummyBox.rotation * _DEG2RAD));
            if (Math.abs(newAngle) > (0.25 * _DEG2RAD)){
                this.rotateSelection((newAngle % (Math.PI * 2)));
            };
            if ($e != null){
                $e.updateAfterEvent();
            };
        }

        public function rotateSelection($angle:Number, $dispatchEvents:Boolean=true):void{
            var i:int;
            var m:Matrix;
            var m2:Matrix;
            var safe:Object;
            if (!this._selLockRotation){
                m = this._dummyBox.transform.matrix;
                m2 = m.clone();
                m.tx = (m.ty = 0);
                m.rotate($angle);
                m.tx = this._origin.x;
                m.ty = this._origin.y;
                this._dummyBox.transform.matrix = m;
                safe = {"angle":$angle};
                if (((!((this._bounds == null))) && (!(this._bounds.containsRect(this._dummyBox.getBounds(this._parent)))))){
                    i = (this._selectedItems.length - 1);
                    while (i > -1) {
                        this._selectedItems[i].rotateCheck(safe);
                        i--;
                    };
                    m2.tx = (m2.ty = 0);
                    m2.rotate(safe.angle);
                    m2.tx = this._origin.x;
                    m2.ty = this._origin.y;
                    this._dummyBox.transform.matrix = m2;
                };
                this._ignoreEvents = true;
                i = (this._selectedItems.length - 1);
                while (i > -1) {
                    this._selectedItems[i].rotate(safe.angle, false, $dispatchEvents);
                    i--;
                };
                this._ignoreEvents = false;
                this.renderSelection();
                if (((((this._dispatchRotateEvents) && ($dispatchEvents))) && (!(((safe.angle % (Math.PI * 2)) == 0))))){
                    dispatchEvent(new TransformEvent(TransformEvent.ROTATE, this._selectedItems.slice()));
                };
            };
        }

        private function onReleaseRotate($e:MouseEvent):void{
            var i:int;
            if (!this._selLockRotation){
                this._stage.removeEventListener(MouseEvent.MOUSE_UP, this.onReleaseRotate);
                this._stage.removeEventListener(MouseEvent.MOUSE_MOVE, this.onMouseMoveRotate);
                this.unlockCursor();
                this._isTransforming = false;
                if (this._trackingInfo.rotation != this._dummyBox.rotation){
                    dispatchEvent(new TransformEvent(TransformEvent.FINISH_INTERACTIVE_ROTATE, this._selectedItems.slice()));
                    i = (this._selectedItems.length - 1);
                    while (i > -1) {
                        this._selectedItems[i].forceEventDispatch(TransformEvent.FINISH_INTERACTIVE_ROTATE);
                        i--;
                    };
                };
            };
        }

        private function swapCursorIn($cursor:Shape, $handle:Object):void{
            if (_currentCursor != $cursor){
                if (_currentCursor != null){
                    this.swapCursorOut(null);
                };
                _currentCursor = $cursor;
                _cursorManager = this;
                Mouse.hide();
                this._stage.addChild(_currentCursor);
                this._stage.addEventListener(MouseEvent.MOUSE_MOVE, this.snapCursor);
                if ($handle != null){
                    _currentCursor.rotation = ($handle.handle.rotation + $handle.cursorRotation);
                };
                _currentCursor.visible = true;
                bringToFront(_currentCursor);
                this.snapCursor();
            };
        }

        private function swapCursorOut($e:Event=null):void{
            if (_currentCursor != null){
                if (this._lockCursor){
                    this._onUnlock = this.swapCursorOut;
                    this._onUnlockParam = $e;
                } else {
                    this._stage.removeEventListener(MouseEvent.MOUSE_MOVE, this.snapCursor);
                    if (_cursorManager == this){
                        Mouse.show();
                        _currentCursor.visible = false;
                        _currentCursor = null;
                    };
                };
            };
        }

        private function snapCursor($e:MouseEvent=null):void{
            _currentCursor.x = _currentCursor.stage.mouseX;
            _currentCursor.y = _currentCursor.stage.mouseY;
            if ($e != null){
                $e.updateAfterEvent();
            };
        }

        private function onRollOverScale($e:MouseEvent):void{
            if (((!(this._selLockScale)) && (((!(this._selHasTextFields)) || ((this._selectedItems.length == 1)))))){
                if (this._lockCursor){
                    this._onUnlock = this.onRollOverScale;
                    this._onUnlockParam = $e;
                } else {
                    this.swapCursorIn(scaleCursor, this._handlesDict[$e.target]);
                };
            };
        }

        private function onRollOverRotate($e:MouseEvent):void{
            if (!this._selLockRotation){
                if (this._lockCursor){
                    this._onUnlock = this.onRollOverRotate;
                    this._onUnlockParam = $e;
                } else {
                    this.swapCursorIn(rotationCursor, this._handlesDict[$e.target]);
                };
            };
        }

        private function onRollOverMove($e:Event=null):void{
            if (!this._selLockPosition){
                if (this._lockCursor){
                    this._onUnlock = this.onRollOverMove;
                    this._onUnlockParam = $e;
                } else {
                    this.swapCursorIn(moveCursor, null);
                };
            };
        }

        private function onRollOverSelectedItem($e:TransformEvent):void{
            if (((!(this._selLockPosition)) && (!($e.items[0].hasSelectableText)))){
                if (this._lockCursor){
                    this._onUnlock = this.onRollOverSelectedItem;
                    this._onUnlockParam = $e;
                } else {
                    this.swapCursorIn(moveCursor, null);
                };
            };
        }

        private function onRollOutSelectedItem($e:TransformEvent):void{
            this.swapCursorOut(null);
        }

        private function setCursorListeners($on:Boolean=true):void{
            var s:Sprite;
            var r:Sprite;
            var i:int;
            i = (this._handles.length - 1);
            while (i > -1) {
                s = this._handles[i].handle.getChildByName("scaleHandle");
                r = this._handles[i].handle.getChildByName("rotationHandle");
                if (this._handles[i].handle.name != "c"){
                    if ($on){
                        s.addEventListener(MouseEvent.ROLL_OVER, this.onRollOverScale, false, 0, true);
                        s.addEventListener(MouseEvent.ROLL_OUT, this.swapCursorOut, false, 0, true);
                        if (r != null){
                            r.addEventListener(MouseEvent.ROLL_OVER, this.onRollOverRotate, false, 0, true);
                            r.addEventListener(MouseEvent.ROLL_OUT, this.swapCursorOut, false, 0, true);
                        };
                    } else {
                        s.removeEventListener(MouseEvent.ROLL_OVER, this.onRollOverScale);
                        s.removeEventListener(MouseEvent.ROLL_OUT, this.swapCursorOut);
                        if (r != null){
                            r.removeEventListener(MouseEvent.ROLL_OVER, this.onRollOverRotate);
                            r.removeEventListener(MouseEvent.ROLL_OUT, this.swapCursorOut);
                        };
                    };
                } else {
                    if ($on){
                        s.addEventListener(MouseEvent.ROLL_OVER, this.onRollOverMove, false, 0, true);
                        s.addEventListener(MouseEvent.ROLL_OUT, this.swapCursorOut, false, 0, true);
                    } else {
                        s.removeEventListener(MouseEvent.ROLL_OVER, this.onRollOverMove);
                        s.removeEventListener(MouseEvent.ROLL_OUT, this.swapCursorOut);
                    };
                };
                i--;
            };
            if ($on){
                this._edges.addEventListener(MouseEvent.ROLL_OVER, this.onRollOverMove, false, 0, true);
                this._edges.addEventListener(MouseEvent.ROLL_OUT, this.swapCursorOut, false, 0, true);
            } else {
                this._edges.removeEventListener(MouseEvent.ROLL_OVER, this.onRollOverMove);
                this._edges.removeEventListener(MouseEvent.ROLL_OUT, this.swapCursorOut);
            };
        }

        protected function lockCursor():void{
            this._lockCursor = true;
            this._onUnlock = null;
            this._onUnlockParam = null;
        }

        protected function unlockCursor():void{
            this._lockCursor = false;
            if (this._onUnlock != null){
                this._onUnlock(this._onUnlockParam);
            };
        }

        protected function mouseIsOverSelection($ignoreSelectableTextItems:Boolean=false):Boolean{
            var i:int;
            if ((((this._selectedItems.length == 0)) || ((this._stage == null)))){
                return (false);
            };
            if (this._selection.hitTestPoint(this._stage.mouseX, this._stage.mouseY, true)){
                return (true);
            };
            i = (this._selectedItems.length - 1);
            while (i > -1) {
                if (((this._selectedItems[i].targetObject.hitTestPoint(this._stage.mouseX, this._stage.mouseY, true)) && (!(((this._selectedItems[i].hasSelectableText) && ($ignoreSelectableTextItems)))))){
                    return (true);
                };
                i--;
            };
            return (false);
        }

        private function initScaleCursor():void{
            var ln:Number;
            var s:Graphics;
            var clr:uint;
            var lw:uint;
            var i:uint;
            if (scaleCursor == null){
                ln = 9;
                scaleCursor = new Shape();
                s = scaleCursor.graphics;
                i = 0;
                while (i < 2) {
                    if (i == 0){
                        clr = 0xFFFFFF;
                        lw = 5;
                    } else {
                        clr = 0;
                        lw = 2;
                    };
                    s.lineStyle(lw, clr, 1, false, null, "square", "miter", 3);
                    s.beginFill(clr, 1);
                    s.moveTo(-(ln), 0);
                    s.lineTo((2 - ln), -1.5);
                    s.lineTo((2 - ln), 1.5);
                    s.lineTo(-(ln), 0);
                    s.endFill();
                    s.moveTo((2 - ln), 0);
                    s.lineTo(-3, 0);
                    s.moveTo(-(ln), 0);
                    s.beginFill(clr, 1);
                    s.moveTo(ln, 0);
                    s.lineTo((ln - 2), -1.5);
                    s.lineTo((ln - 2), 1.5);
                    s.lineTo(ln, 0);
                    s.endFill();
                    s.moveTo(3, 0);
                    s.lineTo((ln - 2), 0);
                    s.moveTo(3, 0);
                    i++;
                };
                this._stage.addChild(scaleCursor);
                scaleCursor.visible = false;
            };
        }

        private function initRotationCursor():void{
            var aw:Number;
            var sb:Number;
            var r:Graphics;
            var clr:uint;
            var lw:uint;
            var i:uint;
            if (rotationCursor == null){
                aw = 2;
                sb = 6;
                rotationCursor = new Shape();
                r = rotationCursor.graphics;
                i = 0;
                while (i < 2) {
                    if (i == 0){
                        clr = 0xFFFFFF;
                        lw = 5;
                    } else {
                        clr = 0;
                        lw = 2;
                    };
                    r.lineStyle(lw, clr, 1, false, null, "square", "miter", 3);
                    r.beginFill(clr, 1);
                    r.moveTo(0, -(sb));
                    r.lineTo(0, (-(sb) - aw));
                    r.lineTo(aw, (-(sb) - aw));
                    r.lineTo(0, -(sb));
                    r.endFill();
                    r.beginFill(clr, 1);
                    r.moveTo(0, sb);
                    r.lineTo(0, (sb + aw));
                    r.lineTo(aw, (sb + aw));
                    r.lineTo(0, sb);
                    r.endFill();
                    r.lineStyle(lw, clr, 1, false, null, "none", "miter", 3);
                    r.moveTo((aw / 2), (-(sb) - (aw / 2)));
                    r.curveTo((aw * 4.5), 0, (aw / 2), (sb + (aw / 2)));
                    r.moveTo(0, 0);
                    i++;
                };
                this._stage.addChild(rotationCursor);
                rotationCursor.visible = false;
            };
        }

        private function initMoveCursor():void{
            var ln:Number;
            var s:Graphics;
            var clr:uint;
            var lw:uint;
            var i:uint;
            if (moveCursor == null){
                ln = 10;
                moveCursor = new Shape();
                s = moveCursor.graphics;
                i = 0;
                while (i < 2) {
                    if (i == 0){
                        clr = 0xFFFFFF;
                        lw = 5;
                    } else {
                        clr = 0;
                        lw = 2;
                    };
                    s.lineStyle(lw, clr, 1, false, null, "square", "miter", 3);
                    s.beginFill(clr, 1);
                    s.moveTo(-(ln), 0);
                    s.lineTo((2 - ln), -1.5);
                    s.lineTo((2 - ln), 1.5);
                    s.lineTo(-(ln), 0);
                    s.endFill();
                    s.beginFill(clr, 1);
                    s.moveTo((2 - ln), 0);
                    s.lineTo(ln, 0);
                    s.moveTo(ln, 0);
                    s.lineTo((ln - 2), -1.5);
                    s.lineTo((ln - 2), 1.5);
                    s.lineTo(ln, 0);
                    s.endFill();
                    s.beginFill(clr, 1);
                    s.moveTo(0, -(ln));
                    s.lineTo(-1.5, (2 - ln));
                    s.lineTo(1.5, (2 - ln));
                    s.lineTo(0, -(ln));
                    s.endFill();
                    s.beginFill(clr, 1);
                    s.moveTo(0, (2 - ln));
                    s.lineTo(0, ln);
                    s.moveTo(0, ln);
                    s.lineTo(-1.5, (ln - 2));
                    s.lineTo(1.5, (ln - 2));
                    s.lineTo(0, ln);
                    s.endFill();
                    i++;
                };
                this._stage.addChild(moveCursor);
                moveCursor.visible = false;
            };
        }

        private function onPressMultiSelectKey($e:Event=null):void{
            if (((this._allowMultiSelect) && (!(this._multiSelectMode)))){
                this._multiSelectMode = true;
            };
        }

        private function onReleaseMultiSelectKey($e:Event=null):void{
            if (((this._multiSelectMode) && (this._allowMultiSelect))){
                this._multiSelectMode = false;
            };
        }

        public function exportFullXML():XML{
            var i:int;
            var xmlItems:XML = <items></items>
            ;
            var l:uint = this._items.length;
            i = 0;
            while (i < l) {
                xmlItems.appendChild(this.exportItemXML(this._items[i].targetObject));
                i++;
            };
            var settings:XML = this.exportSettingsXML();
            var xml:XML = <transformManager></transformManager>
            ;
            xml.appendChild(settings);
            xml.appendChild(xmlItems);
            return (xml);
        }

        public function applyFullXML(xml:XML, defaultParent:DisplayObjectContainer, placeholderColor:uint=0xCCCCCC):Array{
            var node:XML;
            var mc:DisplayObject;
            var isMissing:Boolean;
            var numChildren:uint;
            var i:int;
            this.applySettingsXML(xml.settings[0]);
            var parent:DisplayObjectContainer = ((this._parent) || (defaultParent));
            var missing:Array = [];
            var all:Array = [];
            var list:XMLList = xml.items[0].item;
            for each (node in list) {
                isMissing = Boolean((parent.getChildByName(xml.@name) == null));
                mc = this.applyItemXML(node, parent, placeholderColor);
                all.push({
                    "level":Number(node.@level),
                    "mc":mc,
                    "node":node
                });
                if (isMissing){
                    missing.push(mc);
                };
            };
            all.sortOn("level", (Array.NUMERIC | Array.DESCENDING));
            numChildren = parent.numChildren;
            i = all.length;
            while (i--) {
                if ((((all[i].level < numChildren)) && ((all[i].mc.parent == parent)))){
                    parent.setChildIndex(all[i].mc, all[i].level);
                };
            };
            return (missing);
        }

        public function exportItemXML(targetObject:DisplayObject):XML{
            var xml:XML = <item></item>
            ;
            var item:TransformItem = this.getItem(targetObject);
            var m:Matrix = targetObject.transform.matrix;
            var bounds:Rectangle = targetObject.getBounds(targetObject);
            xml.@name = targetObject.name;
            xml.@level = (((targetObject.parent)!=null) ? targetObject.parent.getChildIndex(targetObject) : 0);
            xml.@a = m.a;
            xml.@b = m.b;
            xml.@c = m.c;
            xml.@d = m.d;
            xml.@tx = m.tx;
            xml.@ty = m.ty;
            xml.@xOffset = bounds.x;
            xml.@yOffset = bounds.y;
            xml.@rawWidth = bounds.width;
            xml.@rawHeight = bounds.height;
            xml.@scaleMode = (((item)!=null) ? item.scaleMode : TransformManager.SCALE_NORMAL);
            xml.@hasSelectableText = (((item)!=null) ? uint(item.hasSelectableText) : 0);
            xml.@minScaleX = (((item)!=null) ? item.minScaleX : -(Infinity));
            xml.@maxScaleX = (((item)!=null) ? item.maxScaleX : Infinity);
            xml.@minScaleY = (((item)!=null) ? item.minScaleY : -(Infinity));
            xml.@maxScaleY = (((item)!=null) ? item.maxScaleY : Infinity);
            return (xml);
        }

        public function applyItemXML(xml:XML, defaultParent:DisplayObjectContainer=null, placeholderColor:uint=0xCCCCCC):DisplayObject{
            var i:int;
            var g:Graphics;
            var parent:DisplayObjectContainer = ((this._parent) || (defaultParent));
            var mc:DisplayObject = parent.getChildByName(xml.@name);
            if (mc == null){
                i = this._items.length;
                while (i--) {
                    if (TransformItem(this._items[i]).targetObject.name == xml.@name){
                        mc = TransformItem(this._items[i]).targetObject;
                        break;
                    };
                };
            };
            if (mc == null){
                mc = ((this._isFlex) ? new (getDefinitionByName("mx.core.UIComponent"))() : new Sprite());
                mc.name = xml.@name;
                g = (mc as Sprite).graphics;
                g.beginFill(placeholderColor, 1);
                g.drawRect(Number(xml.@xOffset), Number(xml.@yOffset), Number(xml.@rawWidth), Number(xml.@rawHeight));
                g.endFill();
                parent.addChild(mc);
            };
            if (xml.@scaleMode == TransformManager.SCALE_WIDTH_AND_HEIGHT){
                mc.width = Number(xml.@rawWidth);
                mc.height = Number(xml.@rawHeight);
            };
            mc.transform.matrix = new Matrix(Number(xml.@a), Number(xml.@b), Number(xml.@c), Number(xml.@d), Number(xml.@tx), Number(xml.@ty));
            if ((((parent.numChildren > xml.@level)) && ((mc.parent == parent)))){
                parent.setChildIndex(mc, xml.@level);
            };
            var item:TransformItem = this.addItem(mc, xml.@scaleMode, Boolean(uint(xml.@hasSelectableText)));
            item.minScaleX = Number(xml.@minScaleX);
            item.maxScaleX = Number(xml.@maxScaleX);
            item.minScaleY = Number(xml.@minScaleY);
            item.maxScaleY = Number(xml.@maxScaleY);
            return (mc);
        }

        public function exportSettingsXML():XML{
            var settings:XML = <settings></settings>
            ;
            settings.@allowDelete = uint(this.allowDelete);
            settings.@allowMultiSelect = uint(this.allowMultiSelect);
            settings.@autoDeselect = uint(this.autoDeselect);
            settings.@constrainScale = uint(this.constrainScale);
            settings.@lockScale = uint(this.lockScale);
            settings.@scaleFromCenter = uint(this.scaleFromCenter);
            settings.@lockRotation = uint(this.lockRotation);
            settings.@lockPosition = uint(this.lockPosition);
            settings.@arrowKeysMove = uint(this.arrowKeysMove);
            settings.@forceSelectionToFront = uint(this.forceSelectionToFront);
            settings.@lineColor = this.lineColor;
            settings.@handleColor = this.handleFillColor;
            settings.@handleSize = this.handleSize;
            settings.@paddingForRotation = this.paddingForRotation;
            settings.@hideCenterHandle = uint(this.hideCenterHandle);
            settings.@hasBounds = (((this._bounds)==null) ? 0 : 1);
            if (this._bounds != null){
                settings.@boundsX = this._bounds.x;
                settings.@boundsY = this._bounds.y;
                settings.@boundsWidth = this._bounds.width;
                settings.@boundsHeight = this._bounds.height;
            };
            return (settings);
        }

        public function applySettingsXML(xml:XML):void{
            this.allowDelete = Boolean(uint(xml.@allowDelete));
            this.allowMultiSelect = Boolean(uint(xml.@allowMultiSelect));
            this.autoDeselect = Boolean(uint(xml.@autoDeselect));
            this.constrainScale = Boolean(uint(xml.@constrainScale));
            this.lockScale = Boolean(uint(xml.@lockScale));
            this.scaleFromCenter = Boolean(uint(xml.@scaleFromCenter));
            this.lockRotation = Boolean(uint(xml.@lockRotation));
            this.lockPosition = Boolean(uint(xml.@lockPosition));
            this.arrowKeysMove = Boolean(uint(xml.@arrowKeysMove));
            this.forceSelectionToFront = Boolean(uint(xml.@forceSelectionToFront));
            this.lineColor = uint(xml.@lineColor);
            this.handleFillColor = uint(xml.@handleColor);
            this.handleSize = Number(xml.@handleSize);
            this.paddingForRotation = Number(xml.@paddingForRotation);
            this.hideCenterHandle = Boolean(uint(xml.@hideCenterHandle));
            if (Boolean(uint(xml.@hasBounds))){
                this.bounds = new Rectangle(Number(xml.@boundsX), Number(xml.@boundsY), Number(xml.@boundsWidth), Number(xml.@boundsHeight));
            };
        }

        public function get enabled():Boolean{
            return (this._enabled);
        }

        public function set enabled($b:Boolean):void{
            this._enabled = $b;
            this.updateItemProp("enabled", $b);
            if (!$b){
                this.swapCursorOut();
                this.removeParentListeners();
            };
        }

        public function get selectionScaleX():Number{
            return (MatrixTools.getScaleX(this._dummyBox.transform.matrix));
        }

        public function set selectionScaleX($n:Number):void{
            this.scaleSelection(($n / this.selectionScaleX), 1);
        }

        public function get selectionScaleY():Number{
            return (MatrixTools.getScaleY(this._dummyBox.transform.matrix));
        }

        public function set selectionScaleY($n:Number):void{
            this.scaleSelection(1, ($n / this.selectionScaleY));
        }

        public function get selectionRotation():Number{
            return (this._dummyBox.rotation);
        }

        public function set selectionRotation($n:Number):void{
            this.rotateSelection((($n - this.selectionRotation) * _DEG2RAD));
        }

        public function get selectionX():Number{
            return (this._dummyBox.x);
        }

        public function set selectionX($n:Number):void{
            this._dummyBox.x = $n;
        }

        public function get selectionY():Number{
            return (this._dummyBox.y);
        }

        public function set selectionY($n:Number):void{
            this._dummyBox.y = $n;
        }

        public function get items():Array{
            return (this._items);
        }

        public function get targetObjects():Array{
            var a:Array = [];
            var i:uint;
            while (i < this._items.length) {
                a.push(this._items[i].targetObject);
                i++;
            };
            return (a);
        }

        public function get selectedTargetObjects():Array{
            var a:Array = [];
            var i:uint;
            while (i < this._selectedItems.length) {
                a.push(this._selectedItems[i].targetObject);
                i++;
            };
            return (a);
        }

        public function set selectedTargetObjects($a:Array):void{
            this.selectItems($a, false);
        }

        public function get selectedItems():Array{
            return (this._selectedItems);
        }

        public function set selectedItems($a:Array):void{
            this.selectItems($a, false);
        }

        public function get constrainScale():Boolean{
            return (this._constrainScale);
        }

        public function set constrainScale($b:Boolean):void{
            this._constrainScale = $b;
            this.updateItemProp("constrainScale", $b);
            this.calibrateConstraints();
        }

        public function get lockScale():Boolean{
            return (this._lockScale);
        }

        public function set lockScale($b:Boolean):void{
            this._lockScale = $b;
            this.updateItemProp("lockScale", $b);
            this.calibrateConstraints();
        }

        public function get scaleFromCenter():Boolean{
            return (this._scaleFromCenter);
        }

        public function set scaleFromCenter($b:Boolean):void{
            this._scaleFromCenter = $b;
        }

        public function get lockRotation():Boolean{
            return (this._lockRotation);
        }

        public function set lockRotation($b:Boolean):void{
            this._lockRotation = $b;
            this.updateItemProp("lockRotation", $b);
            this.calibrateConstraints();
        }

        public function get lockPosition():Boolean{
            return (this._lockPosition);
        }

        public function set lockPosition($b:Boolean):void{
            this._lockPosition = $b;
            this.updateItemProp("lockPosition", $b);
            this.calibrateConstraints();
        }

        public function get allowMultiSelect():Boolean{
            return (this._allowMultiSelect);
        }

        public function set allowMultiSelect($b:Boolean):void{
            this._allowMultiSelect = $b;
            if (!$b){
                this._multiSelectMode = false;
            };
        }

        public function get allowDelete():Boolean{
            return (this._allowDelete);
        }

        public function set allowDelete($b:Boolean):void{
            this._allowDelete = $b;
            this.updateItemProp("allowDelete", $b);
        }

        public function get autoDeselect():Boolean{
            return (this._autoDeselect);
        }

        public function set autoDeselect($b:Boolean):void{
            this._autoDeselect = $b;
        }

        public function get lineColor():uint{
            return (this._lineColor);
        }

        public function set lineColor($n:uint):void{
            this._lineColor = $n;
            this.redrawHandles();
            this.updateSelection();
        }

        public function get handleFillColor():uint{
            return (this._handleColor);
        }

        public function set handleFillColor($n:uint):void{
            this._handleColor = $n;
            this.redrawHandles();
        }

        public function get handleSize():Number{
            return (this._handleSize);
        }

        public function set handleSize($n:Number):void{
            this._handleSize = $n;
            this.redrawHandles();
        }

        public function get paddingForRotation():Number{
            return (this._paddingForRotation);
        }

        public function set paddingForRotation($n:Number):void{
            this._paddingForRotation = $n;
            this.redrawHandles();
        }

        public function get bounds():Rectangle{
            return (this._bounds);
        }

        public function set bounds($r:Rectangle):void{
            this._bounds = $r;
            this.updateItemProp("bounds", $r);
        }

        public function get forceSelectionToFront():Boolean{
            return (this._forceSelectionToFront);
        }

        public function set forceSelectionToFront($b:Boolean):void{
            this._forceSelectionToFront = $b;
        }

        public function get arrowKeysMove():Boolean{
            return (this._arrowKeysMove);
        }

        public function set arrowKeysMove($b:Boolean):void{
            this._arrowKeysMove = $b;
        }

        public function get ignoredObjects():Array{
            return (this._ignoredObjects.slice());
        }

        public function set ignoredObjects($a:Array):void{
            this._ignoredObjects = [];
            var i:uint;
            while (i < $a.length) {
                if (($a[i] is DisplayObject)){
                    this._ignoredObjects.push($a[i]);
                } else {
                    trace((("TRANSFORMMANAGER WARNING: An attempt was made to add " + $a[i]) + " to the ignoredObjects Array but it is NOT a DisplayObject, so it was not added."));
                };
                i++;
            };
        }

        public function get hideCenterHandle():Boolean{
            return (this._hideCenterHandle);
        }

        public function set hideCenterHandle($b:Boolean):void{
            this._hideCenterHandle = $b;
            this.redrawHandles();
        }


    }
}//package com.greensock.transform
