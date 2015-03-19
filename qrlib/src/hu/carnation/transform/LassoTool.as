//Created by Action Script Viewer - http://www.buraks.com/asv
package hu.carnation.transform{
    import flash.display.Sprite;
    import __AS3__.vec.Vector;
    import hu.carnation.transform.components.LassoToolWindow;
    import org.casalib.ui.Key;
    import flash.display.MovieClip;
    import flash.events.Event;
    import flash.events.MouseEvent;
    import flash.ui.Mouse;
    import org.casalib.util.StageReference;
    import flash.ui.Keyboard;
    import hu.carnation.math.GraphicsHelper;
    import flash.geom.Point;
    import __AS3__.vec.*;

    public class LassoTool extends Sprite {

        public static const CANCEL:String = "lassoCancel";
        public static const COMPLETE:String = "complete";
        public static const TOGGLE_MASK:String = "toggleMask";
        public static const CONTROLPOINTS_ADDED:String = "onControlPointsAdded";

        private var lassoPoints:Vector.<ControlPoint>;
        private var background:Sprite;
        private var guideLine:Sprite;
        private var pathEnded:Boolean = false;
        private var selectedControlPoint:ControlPoint;
        private var maskWindow:LassoToolWindow;
        private var key:Key;
        private var mouseCursorPlus:Sprite;
        private var mouseCursorMinus:Sprite;
        private var cursorLasso:MovieClip;

        public function LassoTool(x:Number=0, y:Number=0, w:Number=50, h:Number=50){
            this.lassoPoints = new Vector.<ControlPoint>();
            this.drawBackground(x, y, w, h);
            this.addEventListener(Event.ADDED_TO_STAGE, this.initialize);
        }

        private function initialize(e:Event):void{
            removeEventListener(Event.ADDED_TO_STAGE, this.initialize);
//            this.mouseCursorPlus = (new MouseCursorPlus() as Sprite);
//            addChild(this.mouseCursorPlus);
//            this.mouseCursorPlus.visible = false;
//            this.mouseCursorMinus = (new MouseCursorMinus() as Sprite);
//            addChild(this.mouseCursorMinus);
//            this.mouseCursorMinus.visible = false;
//            this.cursorLasso = (new CursorLasso() as MovieClip);
//            addChild(this.cursorLasso);
//            this.cursorLasso.visible = true;
            this.addEventListener(MouseEvent.CLICK, this.onClick, false, 0, true);
            this.addEventListener(Event.ENTER_FRAME, this.lassoUpdate, false, 0, true);
        }

        private function drawBackground(x:Number, y:Number, w:Number, h:Number):void{
            this.background = new Sprite();
            this.background.name = "background";
            this.background.graphics.beginFill(0xFFFFFF, 0.1);
            this.background.graphics.drawRect(x, y, w, h);
            this.background.graphics.endFill();
            addChildAt(this.background, 0);
        }

        private function onClick(e:MouseEvent):void{
            if (this.isPathCloseToStart()){
                this.closePath();
                this.removeEventListener(MouseEvent.CLICK, this.onClick);
                return;
            };
            if (this.isInnerPoint(mouseX, mouseY)){
                this.addPoint(mouseX, mouseY);
            } else {
                this.closePath();
                this.removeEventListener(MouseEvent.CLICK, this.onClick);
            };
        }

        private function addPoint(x:Number, y:Number, at:int=-1):void{
            var controlPoint:ControlPoint;
            if (this.lassoPoints.length == 0){
                controlPoint = new ControlPoint(x, y, true);
            } else {
                controlPoint = new ControlPoint(x, y);
            };
            addChild(controlPoint);
            if (at != -1){
                this.lassoPoints.splice((at + 1), 0, controlPoint);
                controlPoint.buttonMode = true;
                controlPoint.addEventListener(MouseEvent.MOUSE_DOWN, this.controlPointHandler, false, 0, true);
                controlPoint.addEventListener(MouseEvent.MOUSE_UP, this.controlPointHandler, false, 0, true);
            } else {
                this.lassoPoints.push(controlPoint);
            };
        }

        public function closePath():void{
            if (this.lassoPoints.length < 3){
                this.pathEnded = true;
                this.dispose();
                dispatchEvent(new Event(LassoTool.CANCEL));
            } else {
                this.pathEnded = true;
                this.updatePath();
                this.setupDrag();
            };
        }

        private function lassoUpdate(e:Event=null):void{
            if (((this.lassoPoints) && (!((this.lassoPoints.length == 0))))){
                this.updatePath();
            };
            this.cursorLassoUpdate();
            if (this.isPathCloseToStart()){
                this.cursorLasso.gotoAndStop(3);
                return;
            };
            if (this.isInnerPoint(mouseX, mouseY)){
                this.cursorLasso.gotoAndStop(1);
            } else {
                this.cursorLasso.gotoAndStop(3);
            };
        }

        protected function cursorLassoUpdate(e:Event=null):void{
            Mouse.hide();
            setChildIndex(this.cursorLasso, (numChildren - 1));
            this.cursorLasso.visible = true;
            this.cursorLasso.x = (mouseX + 6);
            this.cursorLasso.y = (mouseY - 10);
        }

        private function updatePath(e:Event=null):void{
            if (!this.guideLine){
                this.guideLine = new Sprite();
                addChildAt(this.guideLine, 0);
            };
            this.guideLine.graphics.clear();
            this.guideLine.graphics.beginFill(0xFFFFFF, 0.7);
            if (!this.pathEnded){
                this.guideLine.graphics.lineStyle(1, 2728157, 1);
            } else {
                this.guideLine.graphics.lineStyle(1, 0xFFFFFF, 1);
            };
            var cPoint:ControlPoint = (this.lassoPoints[0] as ControlPoint);
            this.guideLine.graphics.moveTo(cPoint.x, cPoint.y);
            var i:int = 1;
            while (i < this.lassoPoints.length) {
                cPoint = (this.lassoPoints[i] as ControlPoint);
                if (this.isPathCloseToStart()){
                    this.guideLine.graphics.lineStyle(1, 0xFFFFFF, 1);
                };
                this.guideLine.graphics.lineTo(cPoint.x, cPoint.y);
                i++;
            };
            if (!this.pathEnded){
                this.guideLine.graphics.lineTo(mouseX, mouseY);
            } else {
                cPoint = (this.lassoPoints[0] as ControlPoint);
                this.guideLine.graphics.lineTo(cPoint.x, cPoint.y);
            };
        }

        private function setupDrag():void{
            var cPoint:ControlPoint;
            trace("LassoTool.setupDrag() MouseShow");
            Mouse.show();
            this.removeEventListener(Event.ENTER_FRAME, this.lassoUpdate);
            this.cursorLasso.visible = false;
            dispatchEvent(new Event(CONTROLPOINTS_ADDED));
            var i:int;
            while (i < this.lassoPoints.length) {
                cPoint = (this.lassoPoints[i] as ControlPoint);
                cPoint.buttonMode = true;
                cPoint.addEventListener(MouseEvent.MOUSE_DOWN, this.controlPointHandler, false, 0, true);
                cPoint.addEventListener(MouseEvent.MOUSE_UP, this.controlPointHandler, false, 0, true);
                i++;
            };
            this.addEventListener(Event.ENTER_FRAME, this.controlPointHandler, false, 0, true);
            this.addEventListener(MouseEvent.CLICK, this.controlPointHandler, false, 0, true);
            StageReference.setStage(stage);
            this.key = Key.getInstance();
        }

        private function controlPointHandler(e:Event):void{
            var cPoint:ControlPoint = this.getControlPointUnderMouse();
            if (this.key.isDown(Keyboard.CONTROL)){
                if (cPoint){
                    this.mouseCursorPlus.visible = false;
                    setChildIndex(this.mouseCursorMinus, (numChildren - 1));
                    this.mouseCursorMinus.visible = true;
                    this.mouseCursorMinus.x = (mouseX + 14);
                    this.mouseCursorMinus.y = mouseY;
                    if (e.type == MouseEvent.CLICK){
                        this.deleteControlPoint(cPoint);
                    };
                } else {
                    if (this.getIntersectionPointUnderMouse() != -1){
                        setChildIndex(this.mouseCursorPlus, (numChildren - 1));
                        this.mouseCursorPlus.visible = true;
                        this.mouseCursorPlus.x = (mouseX + 14);
                        this.mouseCursorPlus.y = mouseY;
                        if (e.type == MouseEvent.CLICK){
                            this.addPoint(mouseX, mouseY, this.getIntersectionPointUnderMouse());
                        };
                    } else {
                        this.mouseCursorPlus.visible = false;
                    };
                    this.mouseCursorMinus.visible = false;
                };
                return;
            };
            this.mouseCursorPlus.visible = false;
            this.mouseCursorMinus.visible = false;
            cPoint = (e.currentTarget as ControlPoint);
            if (e.type == MouseEvent.MOUSE_DOWN){
                this.selectedControlPoint = cPoint;
                this.addEventListener(MouseEvent.MOUSE_MOVE, this.dragControlPoint, false, 0, true);
            } else {
                if (e.type == MouseEvent.MOUSE_UP){
                    this.removeEventListener(MouseEvent.MOUSE_MOVE, this.dragControlPoint);
                    this.selectedControlPoint = null;
                };
            };
            this.updatePath();
        }

        private function deleteControlPoint(cPoint:ControlPoint):void{
            this.lassoPoints.splice(this.lassoPoints.indexOf(cPoint), 1);
            cPoint.dispose();
            removeChild(cPoint);
            cPoint = null;
            if (this.lassoPoints.length == 2){
                this.dispose();
                dispatchEvent(new Event(CANCEL));
            };
        }

        private function dragControlPoint(e:Event=null):void{
            if (this.selectedControlPoint){
                if (this.isInnerPoint(mouseX, mouseY)){
                    this.selectedControlPoint.x = mouseX;
                    this.selectedControlPoint.y = mouseY;
                };
            };
        }

        private function isPathCloseToStart():Boolean{
            var distanceFromStart:Number;
            var cPoint:ControlPoint;
            if (this.lassoPoints.length > 2){
                cPoint = (this.lassoPoints[0] as ControlPoint);
                distanceFromStart = this.distanceTwoPoints(mouseX, cPoint.x, mouseY, cPoint.y);
                if (distanceFromStart < 8){
                    return (true);
                };
            };
            return (false);
        }

        private function distanceTwoPoints(x1:Number, x2:Number, y1:Number, y2:Number):Number{
            var dx:Number = (x1 - x2);
            var dy:Number = (y1 - y2);
            return (Math.sqrt(((dx * dx) + (dy * dy))));
        }

        private function getControlPointUnderMouse():ControlPoint{
            var cPoint:ControlPoint;
            var result:ControlPoint;
            if (!this.lassoPoints){
                return (result);
            };
            var i:int;
            while (i < this.lassoPoints.length) {
                cPoint = (this.lassoPoints[i] as ControlPoint);
                if (this.distanceTwoPoints(mouseX, cPoint.x, mouseY, cPoint.y) < (cPoint.width / 2)){
                    result = cPoint;
                    cPoint.onOver = true;
                } else {
                    cPoint.onOver = false;
                };
                i++;
            };
            return (result);
        }

        private function getIntersectionPointUnderMouse():int{
            var cPoint2:ControlPoint;
            var distance:Number;
            var cPoint:ControlPoint;
            var cPoint1:ControlPoint = (this.lassoPoints[(this.lassoPoints.length - 1)] as ControlPoint);
            var smallestDistance:Number = 1000;
            var i:int;
            while (i < this.lassoPoints.length) {
                if (i != 0){
                    cPoint1 = (this.lassoPoints[(i - 1)] as ControlPoint);
                };
                cPoint2 = (this.lassoPoints[i] as ControlPoint);
                distance = this.getMouseDistanceFromLine(cPoint1.x, cPoint2.x, cPoint1.y, cPoint2.y).dist;
                if (((!((distance == -1))) && ((distance < smallestDistance)))){
                    smallestDistance = distance;
                    cPoint = cPoint1;
                };
                i++;
            };
            if (((cPoint) && ((smallestDistance < 5)))){
                return (this.lassoPoints.indexOf(cPoint));
            };
            return (-1);
        }

        private function getMouseDistanceFromLine(x1:Number, x2:Number, y1:Number, y2:Number):Object{
            var distanceFromLineObject:Object = GraphicsHelper.getDistanceFromLine(new Point(x1, y1), new Point(x2, y2), new Point(mouseX, mouseY), true);
            return (distanceFromLineObject);
        }

        private function isInnerPoint(x1:Number, y1:Number):Boolean{
            return ((((((((mouseX > this.background.x)) && ((mouseX < (this.background.x + this.background.width))))) && ((mouseY > this.background.y)))) && ((mouseY < (this.background.y + this.background.height)))));
        }

        public function getLassoSprite():Sprite{
            return (this.guideLine);
        }

        public function lassoSpriteReturned():void{
            addChildAt(this.guideLine, 0);
            this.guideLine.x = 0;
            this.guideLine.y = 0;
        }

        public function dispose():void{
            var cPoint:ControlPoint;
            this.removeEventListener(Event.ENTER_FRAME, this.controlPointHandler);
            this.removeEventListener(Event.ENTER_FRAME, this.lassoUpdate);
            this.removeEventListener(MouseEvent.CLICK, this.onClick);
            if (this.guideLine){
                this.guideLine.graphics.clear();
            };
            if (!this.lassoPoints){
                return;
            };
            var i:int;
            while (i < this.lassoPoints.length) {
                cPoint = (this.lassoPoints[i] as ControlPoint);
                cPoint.buttonMode = false;
                cPoint.removeEventListener(MouseEvent.MOUSE_DOWN, this.controlPointHandler);
                cPoint.removeEventListener(MouseEvent.MOUSE_UP, this.controlPointHandler);
                cPoint.dispose();
                removeChild(cPoint);
                cPoint = null;
                i++;
            };
            this.lassoPoints = null;
            trace("LassoTool.dispose() Mouse Show");
            Mouse.show();
            this.cursorLasso.visible = false;
        }


    }
}//package hu.carnation.transform
