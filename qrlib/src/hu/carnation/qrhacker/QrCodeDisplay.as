//Created by Action Script Viewer - http://www.buraks.com/asv
package hu.carnation.qrhacker{
    import __AS3__.vec.*;
    import __AS3__.vec.Vector;
    
    import co.moodshare.pdf.MSPDF;
    
    import flash.display.Bitmap;
    import flash.display.BitmapData;
    import flash.display.BlendMode;
    import flash.display.MovieClip;
    import flash.display.Shape;
    import flash.display.Sprite;
    import flash.events.Event;
    import flash.events.KeyboardEvent;
    import flash.events.MouseEvent;
    import flash.geom.Matrix;
    import flash.geom.Point;
    import flash.geom.Rectangle;
    import flash.ui.Keyboard;
    import flash.ui.Mouse;
    
    import hu.carnation.qr.event.QrCodeEvent;
    import hu.carnation.qr.model.Model;
    import hu.carnation.qr.model.PixelVO;
    import hu.carnation.qrhacker.display.Pixel;
    import hu.carnation.qrhacker.memento.PixelMemento;
    import hu.carnation.qrhacker.memento.PixelMementoRecorder;
    
    import mx.core.FlexSprite;
    import mx.core.UIComponent;
    import mx.events.FlexEvent;
    
    import org.alivepdf.colors.RGBColor;
    import org.casalib.ui.Key;
    import org.casalib.util.StageReference;

    public class QrCodeDisplay extends UIComponent {

        public static const PIXEL_DRAW_START:String = "onPixelDrawStart";
        public static const PIXEL_DRAW_FINISH:String = "onPixelDrawFinish";

        public var isDrawing:Boolean = false;
        private var originalQrPixels:Bitmap;
        private var subPixel:UIComponent;
        private var model:Model;
        private var _originalQrPixelsActive:Boolean;
        private var undoButton:MovieClip;
        private var memento:PixelMementoRecorder;
        private var subPixelBitmapData:BitmapData;
        private var closeButton:MovieClip;
        private var size0:int;
        private var redoButton:MovieClip;
        private var pixelHolder:FlexSprite;
        private var size1:int;
        private var isMouseDown:Boolean = false;
        private var key:Key;
        private var cursorPen:MovieClip;
        private var pixelVector:Vector.<Pixel>;
        private var bgSprite:Sprite;
        private var originalQrPixelsData:BitmapData;
        private var subPixelBitmap:Bitmap;
		private var mainRef:IMain;

        public function QrCodeDisplay(model:Model, mainRef:IMain){
            if (model){
                this.model = model;
				this.mainRef = mainRef;
                this.model.addEventListener(QrCodeEvent.QRMATRIX_CHANGE, this.onQrMatrixChange, false, 0, true);
                this.model.addEventListener(QrCodeEvent.PIXELCOLOR_CHANGED, this.enableCustomColoring, false, 0, true);
                this.model.addEventListener(QrCodeEvent.PIXELSIZE_CHANGE, this.render, false, 0, true);
                this.model.addEventListener(QrCodeEvent.FOREGROUNDCOLOR_CHANGED, this.changeForegroundColor, false, 0, true);
                this.model.addEventListener(QrCodeEvent.CORNERRADIUS_CHANGED, this.cornerRadiusChange, false, 0, true);
                this.model.addEventListener(QrCodeEvent.PIXELTYPE_CHANGE, this.onPixelTypeChange, false, 0, true);
            };
            this.pixelVector = new Vector.<Pixel>();
            //this.addEventListener(Event.ADDED_TO_STAGE, this.init, false, 0, true);
			this.addEventListener(FlexEvent.CREATION_COMPLETE, this.init, false, 0, true);
        }

        private function hideOriginalQrPixels():void{
            this.subPixelBitmap.visible = true;
            this.pixelHolder.visible = true;
            this.originalQrPixels.visible = false;
        }

        public function redo():void{
            trace("QrCodeDisplay.redo()");
            this.memento.redo();
        }

        protected function changePixelColorByMouse(e:Event=null):void{
            var undoMemento:PixelMemento;
            var redoMemento:PixelMemento;
            var eraserPixel:Shape;
            var pixel:Pixel = this.getPixelUnderMouse();
            if (((pixel) && (this.isMouseDown))){
                undoMemento = new PixelMemento(pixel, PixelMemento.UNDO);
                undoMemento.isActive = pixel.pixelVO.active;
                undoMemento.hasCustomColor = pixel.pixelVO.hasCustomColor;
                undoMemento.customColor = pixel.pixelVO.customColor;
                if (this.key.isDown(Keyboard.CONTROL)){
                    eraserPixel = new Shape();
                    eraserPixel.graphics.beginFill(0, 1);
                    eraserPixel.graphics.drawRect(pixel.x, pixel.y, this.model.pixelSize, this.model.pixelSize);
                    eraserPixel.graphics.endFill();
                    this.subPixelBitmapData.draw(eraserPixel, new Matrix(), null, BlendMode.ERASE);
                    if (((!(pixel.pixelVO.hasCustomColor)) && (!(pixel.pixelVO.active)))){
                        return;
                    };
                    this.changePixelMode(pixel, false, this.model.pixelColor, false);
                    pixel.pixelVO.hasCustomColor = false;
                    pixel.pixelVO.active = false;
                } else {
                    if (((pixel.pixelVO.active) && ((pixel.pixelVO.customColor == this.model.pixelColor)))){
                        return;
                    };
                    if (((((pixel.pixelVO.active) && ((this.model.pixelColor == this.model.foregroundColor)))) && ((pixel.pixelVO.customColor == this.model.pixelColor)))){
                        return;
                    };
                    this.changePixelMode(pixel, true, this.model.pixelColor, true);
                    pixel.pixelVO.active = true;
                    pixel.pixelVO.hasCustomColor = true;
                    eraserPixel = new Shape();
                    eraserPixel.graphics.beginFill(0, 1);
                    eraserPixel.graphics.drawRect(pixel.x, pixel.y, this.model.pixelSize, this.model.pixelSize);
                    eraserPixel.graphics.endFill();
                    this.subPixelBitmapData.draw(eraserPixel, new Matrix(), null, BlendMode.ERASE);
                };
                redoMemento = new PixelMemento(pixel, PixelMemento.REDO);
                redoMemento.isActive = pixel.pixelVO.active;
                redoMemento.hasCustomColor = pixel.pixelVO.hasCustomColor;
                redoMemento.customColor = pixel.pixelVO.customColor;
                this.memento.addState(undoMemento);
                this.memento.addState(redoMemento);
                this.updatePixels();
            };
            if (this.key.isDown(Keyboard.CONTROL)){
                //this.cursorPen.gotoAndStop(2);
            } else {
                //this.cursorPen.gotoAndStop(1);
            };
        }

        protected function drawSubPixel(e:Event):void{
            var _x:int;
            var _y:int;
            if (!this.isMouseDown){
                return;
            };
            setChildIndex(this.subPixelBitmap, (numChildren - 1));
///            setChildIndex(this.cursorPen, (numChildren - 1));
			var rect:Rectangle = mainRef.getQrDisplayRegion();
            if ((((((((mouseX < 0)) || ((mouseX > rect.width)))) || ((mouseY < 0)))) || ((mouseY > rect.height)))){
                stage.dispatchEvent(new MouseEvent(MouseEvent.MOUSE_UP));
            };
            var size:int = this[("size" + (this.model.pixelType - 1))];
            if ((((((((mouseX > 0)) && ((mouseX < this.model.qrSize)))) && ((mouseY > 0)))) && ((mouseY < this.model.qrSize)))){
                _x = (int((mouseX / size)) * size);
                _y = (int((mouseY / size)) * size);
                this.subPixel.graphics.clear();
                this.subPixel.graphics.beginFill(this.model.pixelColor, 1);
                this.subPixel.graphics.drawRect(_x, _y, size, size);
                this.subPixel.graphics.endFill();
                this.subPixelBitmapData.draw(this.subPixel);
                this.subPixel.graphics.clear();
            };
        }

        public function get originalQrPixelsActive():Boolean{
            return (this._originalQrPixelsActive);
        }

        protected function updateCursorPosition(e:MouseEvent):void{
//            setChildIndex(this.cursorPen, (numChildren - 1));
//            this.cursorPen.x = mouseX;
//            this.cursorPen.y = mouseY;
            if (e.type == MouseEvent.MOUSE_MOVE){
                MouseEvent(e).updateAfterEvent();
            };
        }

        private function init(e:Event=null):void{
            //removeEventListener(Event.ADDED_TO_STAGE, this.init);
			removeEventListener(FlexEvent.CREATION_COMPLETE, this.init);
			// 如果此处侦听【FlexEvent.initialize】事件，则下面的【stage】此时会是null
            this.updatePosition();
            StageReference.setStage(stage);
            this.key = Key.getInstance();
//            this.cursorPen = (new CursorPen() as MovieClip);
//            addChild(this.cursorPen);
//            this.cursorPen.visible = false;
//            this.closeButton = (new pixelmodeExitButton() as MovieClip);
//            addChild(this.closeButton);
//            this.closeButton.x = (385 - this.x);
//            this.closeButton.y = (3 - this.y);
//            this.closeButton.visible = false;
//            this.closeButton.buttonMode = true;
//            this.closeButton.addEventListener(MouseEvent.CLICK, this.disableCustomColoring, false, 0, true);
            this.memento = new PixelMementoRecorder();
            this.memento.addEventListener(Event.CHANGE, this.onMementoChange, false, 0, true);
            this.pixelHolder = new FlexSprite();
            addChild(this.pixelHolder);
        }

        public function set originalQrPixelsActive(value:Boolean):void{
            this._originalQrPixelsActive = value;
        }

        public function updatePosition():void{
            var w:int = ((((this.model.pixelSize) && (this.model.qrMatrix))) ? (this.model.pixelSize * this.model.qrMatrix.width()) : this.width);
            var h:int = w;
			var rect:Rectangle = mainRef.getQrDisplayRegion();
            this.x = int(((rect.width - w) / 2));
            this.y = int(((rect.height - h) / 2));
            if (this.closeButton){
                this.closeButton.x = (385 - this.x);
                this.closeButton.y = (3 - this.y);
            };
        }

        public function toggleOriginalQrPixels():void{
            this.originalQrPixelsActive = !(this.originalQrPixelsActive);
            if (this.originalQrPixelsActive){
                this.showOriginalQrPixels();
            } else {
                this.hideOriginalQrPixels();
            };
        }

        public function render(event:Event=null):void{
            var pixel:Pixel;
            var pixelVO:PixelVO;
            var pixelBit:uint;
            var siblings:Vector.<Boolean>;
            var j:int;
            this.disposePixels();
            if (!this.model.qrMatrix){
                return;
            };
            var i:int;
            while (i < this.model.qrMatrix.height()) {
                j = 0;
                while (j < this.model.qrMatrix.width()) {
                    pixel = new Pixel();
                    pixelVO = new PixelVO();
                    pixelBit = 0;
                    if (this.getPixelFromMatrix(i, j)){
                        pixelVO.active = true;
                    } else {
                        pixelVO.active = false;
                    };
                    siblings = new Vector.<Boolean>(8, true);
                    if (this.getPixelFromMatrix(i, (j - 1)) == 1){
                        siblings[0] = true;
                    };
                    if (this.getPixelFromMatrix((i - 1), j) == 1){
                        siblings[1] = true;
                    };
                    if (this.getPixelFromMatrix(i, (j + 1)) == 1){
                        siblings[2] = true;
                    };
                    if (this.getPixelFromMatrix((i + 1), j) == 1){
                        siblings[3] = true;
                    };
                    if (this.getPixelFromMatrix((i - 1), (j - 1)) == 1){
                        siblings[4] = true;
                    };
                    if (this.getPixelFromMatrix((i - 1), (j + 1)) == 1){
                        siblings[5] = true;
                    };
                    if (this.getPixelFromMatrix((i + 1), (j + 1)) == 1){
                        siblings[6] = true;
                    };
                    if (this.getPixelFromMatrix((i + 1), (j - 1)) == 1){
                        siblings[7] = true;
                    };
                    pixelVO.cornerRadius = this.model.cornerRadius;
                    pixelVO.size = this.model.pixelSize;
                    pixelVO.position = new Point(j, i);
                    pixelVO.siblings = siblings;
                    pixelVO.color = this.model.foregroundColor;
                    pixelVO.hasCustomColor = false;
                    pixel.pixelVO = pixelVO;
                    this.pixelHolder.addChild(pixel);
                    pixel.updatePixel();
                    this.pixelVector.push(pixel);
                    j++;
                };
                i++;
            };
            this.updatePosition();
            if (this.originalQrPixels){
                removeChild(this.originalQrPixels);
                this.originalQrPixels = null;
            };
            this.originalQrPixelsData = new BitmapData(this.width, this.height, true, 0);
            this.originalQrPixels = new Bitmap(this.originalQrPixelsData);
            addChild(this.originalQrPixels);
            this.originalQrPixelsData.draw(this);
            setChildIndex(this.originalQrPixels, (numChildren - 1));
            this.originalQrPixels.visible = false;
        }

        protected function changeForegroundColor(event:Event):void{
            var pixel:Pixel;
            var i:int;
            while (i < this.pixelVector.length) {
                pixel = Pixel(this.pixelVector[i]);
                pixel.pixelVO.color = this.model.foregroundColor;
                pixel.updatePixel();
                i++;
            };
        }

        protected function enableCustomColoring(e:Event=null):void{
            if (!this.bgSprite){
                this.bgSprite = new Sprite();
                this.bgSprite.graphics.beginFill(0, 0);
                this.bgSprite.graphics.drawRect(0, 0, this.width, this.height);
            };
            if (!contains(this.bgSprite)){
                addChild(this.bgSprite);
            };
            stage.addEventListener(MouseEvent.MOUSE_DOWN, this.onMouseDown, false, 0, true);
            this.addEventListener(MouseEvent.MOUSE_UP, this.onMouseUp, false, 0, true);
            stage.addEventListener(MouseEvent.MOUSE_UP, this.onMouseUp, false, 0, true);
            if (this.model.pixelType == 0){
                this.removeEventListener(Event.ENTER_FRAME, this.drawSubPixel);
                this.addEventListener(Event.ENTER_FRAME, this.changePixelColorByMouse, false, 0, true);
            } else {
                if ((((this.model.pixelType == 1)) || ((this.model.pixelType == 2)))){
                    this.removeEventListener(Event.ENTER_FRAME, this.changePixelColorByMouse);
                    this.addEventListener(Event.ENTER_FRAME, this.drawSubPixel, false, 0, true);
                };
            };
            this.showCustomMousePointer();
            stage.addEventListener(KeyboardEvent.KEY_DOWN, this.keyDownHandler, false, 0, true);
            this.isDrawing = true;
            dispatchEvent(new Event(PIXEL_DRAW_START));
        }

        private function getPixelUnderMouse():Pixel{
            var pixel:Pixel;
            var i:int;
            while (i < this.pixelVector.length) {
                pixel = (this.pixelVector[i] as Pixel);
                if ((((((((mouseX > pixel.x)) && ((mouseX < (pixel.x + pixel.width))))) && ((mouseY > pixel.y)))) && ((mouseY < (pixel.y + pixel.height))))){
                    return (pixel);
                };
                i++;
            };
            return (null);
        }

        public function generateQrToPDF(pdf:MSPDF):void{
            var pixel:Pixel;
            if (!this.model.qrMatrix){
                return;
            };
            var scale:Number = this.model.pdfScale;
            var padding:Number = (pdf.getX() + ((mainRef.getQrDisplayRegion().width - (this.model.pixelSize * this.model.qrMatrix.width())) / 2));
            pdf.beginFill(new RGBColor(this.model.foregroundColor));
            var i:int;
            while (i < this.pixelVector.length) {
                pixel = Pixel(this.pixelVector[i]);
                pixel.renderToPDF(pdf, padding, scale);
                i++;
            };
        }

        protected function onMementoChange(e:Event):void{
            e.stopImmediatePropagation();
            var pixelMemento:PixelMemento = this.memento.pixelMemento;
            this.changePixelMode(pixelMemento.pixel, pixelMemento.hasCustomColor, pixelMemento.customColor, pixelMemento.isActive);
            this.updatePixels();
            dispatchEvent(new Event(Event.CHANGE));
        }

        public function disposePixels():void{
            var pixel:Pixel;
            var i:int;
            while (i < this.pixelVector.length) {
                pixel = Pixel(this.pixelVector[i]);
                pixel.dispose();
                this.pixelHolder.removeChild(pixel);
                pixel = null;
                i++;
            };
            this.pixelVector = new Vector.<Pixel>();
        }

        public function dispose():void{
            trace("QrCodeDisplay.dispose()");
            this.disposePixels();
            this.subPixelBitmapData = new BitmapData(this.width, this.width, true, 0);
            this.removeEventListener(MouseEvent.MOUSE_DOWN, this.enableCustomColoring);
            this.removeEventListener(MouseEvent.MOUSE_UP, this.disableCustomColoring);
            stage.removeEventListener(MouseEvent.MOUSE_UP, this.disableCustomColoring);
            this.removeEventListener(Event.ENTER_FRAME, this.changePixelColorByMouse);
            this.originalQrPixels.visible = false;
            this.originalQrPixels = null;
            removeChild(this.originalQrPixels);
            this.originalQrPixelsData = null;
        }

        public function disableCustomColoring(e:Event=null):void{
            if (!this.isDrawing){
                return;
            };
            this.hideOriginalQrPixels();
            if (this.bgSprite){
                if (contains(this.bgSprite)){
                    removeChild(this.bgSprite);
                };
            };
            stage.removeEventListener(MouseEvent.MOUSE_DOWN, this.onMouseDown);
            this.removeEventListener(MouseEvent.MOUSE_UP, this.onMouseUp);
            stage.removeEventListener(MouseEvent.MOUSE_UP, this.onMouseUp);
            this.removeEventListener(Event.ENTER_FRAME, this.changePixelColorByMouse);
            this.removeEventListener(Event.ENTER_FRAME, this.drawSubPixel);
            this.hideCustomMousePointer();
            this.memento.reset();
            stage.removeEventListener(KeyboardEvent.KEY_DOWN, this.keyDownHandler);
            this.isDrawing = false;
            dispatchEvent(new Event(PIXEL_DRAW_FINISH));
        }

        private function showOriginalQrPixels():void{
            this.subPixelBitmap.visible = false;
            this.pixelHolder.visible = false;
            this.originalQrPixels.visible = true;
            setChildIndex(this.originalQrPixels, (numChildren - 1));
        }

        public function resetAllCustomPixelColor():void{
            trace("QrCodeDisplay.resetAllCustomPixelColor()");
            if (this.subPixel){
                this.subPixel.graphics.clear();
            };
            if (this.subPixelBitmap){
                removeChild(this.subPixelBitmap);
                this.subPixelBitmap = null;
            };
            this.subPixelBitmapData = new BitmapData(this.width, this.width, true, 0);
            this.subPixelBitmap = new Bitmap(this.subPixelBitmapData);
            addChild(this.subPixelBitmap);
            this.hideOriginalQrPixels();
            this.memento.reset();
            this.render();
        }

        private function onMouseUp(e:Event):void{
            this.subPixel.graphics.clear();
            this.isMouseDown = false;
            dispatchEvent(new Event(Event.CHANGE));
        }

        public function hideCustomMousePointer():void{
            stage.removeEventListener(MouseEvent.MOUSE_MOVE, this.updateCursorPosition);
            //this.cursorPen.visible = false;
            Mouse.show();
        }

        public function showCustomMousePointer():void{
            stage.addEventListener(MouseEvent.MOUSE_MOVE, this.updateCursorPosition);
            Mouse.hide();
            //this.cursorPen.visible = true;
        }

        protected function onQrMatrixChange(e:Event):void{
            var w:int;
            if (this.model.qrMatrix){
                if (this.subPixel){
                    this.subPixel.graphics.clear();
                };
                this.subPixel = new UIComponent();
                if (this.subPixelBitmap){
                    removeChild(this.subPixelBitmap);
                    this.subPixelBitmap = null;
                };
                this.subPixelBitmapData = new BitmapData(this.width, this.width, true, 0);
                this.subPixelBitmap = new Bitmap(this.subPixelBitmapData);
                addChild(this.subPixelBitmap);
                w = (this.model.pixelSize * this.model.qrMatrix.width());
                this.size0 = int((this.model.pixelSize / 2));
                this.size1 = int((this.size0 / 2));
            };
        }

        public function updatePixels():void{
            var i:int;
            while (i < this.pixelVector.length) {
                (this.pixelVector[i] as Pixel).updatePixel();
                i++;
            };
        }

        protected function onPixelTypeChange(event:Event):void{
            if (this.model.pixelType != -1){
                this.enableCustomColoring();
            } else {
                this.disableCustomColoring();
            };
        }

        protected function cornerRadiusChange(event:Event):void{
            var pixel:Pixel;
            var i:int;
            while (i < this.pixelVector.length) {
                pixel = Pixel(this.pixelVector[i]);
                pixel.pixelVO.cornerRadius = this.model.cornerRadius;
                pixel.updatePixel();
                i++;
            };
        }

        private function onMouseDown(e:Event):void{
            this.hideOriginalQrPixels();
            this.isMouseDown = true;
        }

        public function undo():void{
            trace("QrCodeDisplay.undo()");
            this.memento.undo();
        }

        protected override function keyDownHandler(e:KeyboardEvent):void{
            switch (e.keyCode){
                case Keyboard.LEFT:
                    this.memento.undo();
                    break;
                case Keyboard.RIGHT:
                    this.memento.redo();
                    break;
            };
        }

        private function changePixelMode(pixel:Pixel, hasCustomColor:Boolean, customColor:uint, active:Boolean=true):void{
            pixel.pixelVO.customColor = customColor;
            pixel.pixelVO.hasCustomColor = hasCustomColor;
            var pixelIndex:int = this.pixelVector.indexOf(pixel);
            pixel.pixelVO.active = active;
            if (pixelIndex > 1){
                (this.pixelVector[(pixelIndex - 1)] as Pixel).pixelVO.siblings[2] = active;
            };
            if ((pixelIndex + 1) < this.pixelVector.length){
                (this.pixelVector[(pixelIndex + 1)] as Pixel).pixelVO.siblings[0] = active;
            };
            if (pixelIndex > (this.model.qrMatrix.width() + 1)){
                (this.pixelVector[(pixelIndex - this.model.qrMatrix.width())] as Pixel).pixelVO.siblings[3] = active;
            };
            if (pixelIndex < ((this.model.qrMatrix.width() - 1) * this.model.qrMatrix.height())){
                (this.pixelVector[(pixelIndex + this.model.qrMatrix.width())] as Pixel).pixelVO.siblings[1] = active;
            };
            if ((pixelIndex - this.model.qrMatrix.width()) > 0){
                (this.pixelVector[((pixelIndex - this.model.qrMatrix.width()) - 1)] as Pixel).pixelVO.siblings[6] = active;
            };
            if (((!(((pixelIndex % this.model.qrMatrix.width()) == 0))) && ((((pixelIndex - this.model.qrMatrix.width()) + 1) > 0)))){
                (this.pixelVector[((pixelIndex - this.model.qrMatrix.width()) + 1)] as Pixel).pixelVO.siblings[7] = active;
            };
            if (((!((((pixelIndex - 1) % this.model.qrMatrix.width()) == 0))) && ((((pixelIndex + this.model.qrMatrix.width()) - 1) < this.pixelVector.length)))){
                (this.pixelVector[((pixelIndex + this.model.qrMatrix.width()) - 1)] as Pixel).pixelVO.siblings[5] = active;
            };
            if (((pixelIndex + this.model.qrMatrix.width()) + 1) < this.pixelVector.length){
                (this.pixelVector[((pixelIndex + this.model.qrMatrix.width()) + 1)] as Pixel).pixelVO.siblings[4] = active;
            };
        }

        private function getPixelFromMatrix(x:int, y:int):int{
            if ((((((((x >= 0)) && ((y >= 0)))) && ((x < this.model.qrMatrix.width())))) && ((y < this.model.qrMatrix.height())))){
                return (this.model.qrMatrix._get(y, x));
            };
            return (0);
        }


    }
}//package hu.carnation.qrhacker
