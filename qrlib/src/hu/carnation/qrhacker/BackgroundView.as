//Created by Action Script Viewer - http://www.buraks.com/asv
package hu.carnation.qrhacker{
    import co.moodshare.pdf.MSPDF;
    
    import flash.display.Bitmap;
    import flash.display.BitmapData;
    import flash.display.Sprite;
    import flash.events.Event;
    import flash.events.MouseEvent;
    import flash.geom.ColorTransform;
    import flash.geom.Matrix;
    import flash.geom.Point;
    import flash.geom.Rectangle;
    
    import hu.carnation.qr.event.QrCodeEvent;
    import hu.carnation.qr.model.Model;
    
    import org.alivepdf.colors.RGBColor;
    import org.alivepdf.images.ImageFormat;
    
    import spark.core.SpriteVisualElement;

    public class BackgroundView extends BasicView {

        protected var colorSprite:Sprite;
//		protected var colorSprite:SpriteVisualElement;
        private var bgOrigPos:Point;
        private var originalBackground:Bitmap;
        private var mouseDown:Boolean = false;
        private var mouseOrigPos:Point;
        private var scaleFactor:Number;
        private var mainRef:IMain;
        private var backgroundBitmap:Bitmap;

        public function BackgroundView(model:Model, uploadHandler:UploadHandler, mainRef:IMain){
            super(model, uploadHandler);
            this.mainRef = mainRef;
            model.addEventListener(QrCodeEvent.BACKGROUNDCOLOR_CHANGED, this.colorChanged, false, 0, true);
            model.addEventListener(QrCodeEvent.BACKGROUNDURL_CHANGED, this.urlChanged, false, 0, true);
            model.addEventListener(QrCodeEvent.BACKGROUNDALPHA_CHANGED, this.alphaChanged, false, 0, true);
            uploadHandler.addEventListener(QrCodeEvent.BACKGROUNDIMAGE_CHANGED, this.imageUploaded, false, 0, true);
            this.addEventListener(Event.ADDED_TO_STAGE, this.init, false, 0, true);
        }

        //private function fitBitmapToStage(bm:Bitmap):Bitmap{
		private function fitBitmapToContainer(bm:Bitmap):Bitmap{
//            var ratioWidth:Number = (stage.stageWidth / bm.width);
//            var ratioHeight:Number = (stage.stageHeight / bm.height);
			var rect:Rectangle = mainRef.getQrDisplayRegion();
            var ratioWidth:Number = (rect.width / bm.width);
            var ratioHeight:Number = (rect.height / bm.height);	
			
            var matrix:Matrix = new Matrix();
            this.scaleFactor = Math.max(ratioWidth, ratioHeight);
            matrix.scale(this.scaleFactor, this.scaleFactor);
            var bmd:BitmapData = new BitmapData((bm.width * this.scaleFactor), (bm.height * this.scaleFactor), true, 0);
            var result:Bitmap = new Bitmap(bmd);
            result.smoothing = true;
            bmd.draw(bm, matrix, null, null, null, true);
            if (this.scaleFactor > 1){
                bm = result;
            };
            return (result);
        }

        protected function urlChanged(e:Event):void{
            if (model.backgroundURL){
                loadImageFromURL(model.backgroundURL);
            };
        }

        protected function colorChanged(e:Event):void{
            if (model.backgroundColor){
                this.updateColorSprite(model.backgroundColor);
            };
        }

        private function init(e:Event=null):void{
            removeEventListener(Event.ADDED_TO_STAGE, this.init);
            this.colorSprite = new Sprite();
//			this.colorSprite = new SpriteVisualElement();
            addChild(this.colorSprite);
//			addElement(this.colorSprite);
            this.colorSprite.graphics.beginFill(model.backgroundColor);
//            this.colorSprite.graphics.drawRect(0, 0, stage.stageWidth, stage.stageHeight);
			var rect:Rectangle = mainRef.getQrDisplayRegion();
			this.colorSprite.graphics.drawRect(0, 0, rect.width, rect.width);
			
            this.colorSprite.graphics.endFill();
        }

        protected function imageChanged(bm:Bitmap):void{
//            this.mainRef.closeHtmlPopups();
            this.resetBitmap();
            if (bm){
                this.originalBackground = bm;
                //this.backgroundBitmap = this.fitBitmapToStage(this.originalBackground);
				this.backgroundBitmap = this.fitBitmapToContainer(this.originalBackground);
                this.addChild(this.backgroundBitmap);
                hasContent = true;
                this.mainRef.checkQR();
                this.enableMove();
            };
        }

        private function toRad(a:Number):Number{
            return (((a * Math.PI) / 180));
        }

        protected function imageUploaded(e:Event):void{
            this.imageChanged(Bitmap(uploadHandler.backgroundBitmap));
//            this.mainRef.setTool("bg", "photo", true);
        }

        public function resetBitmap():void{
            if (this.backgroundBitmap){
                this.disableMove();
                if (contains(this.backgroundBitmap)){
                    removeChild(this.backgroundBitmap);
                };
                this.backgroundBitmap = null;
                this.originalBackground = null;
                hasContent = false;
                this.mainRef.checkQR();
            };
        }

        public function disableMove():void{
            this.removeEventListener(Event.ENTER_FRAME, this.updateBackgroundPosition);
            this.removeEventListener(MouseEvent.MOUSE_DOWN, this.backgroundMouseDownHandler);
            stage.removeEventListener(MouseEvent.MOUSE_DOWN, this.backgroundMouseDownHandler);
            stage.removeEventListener(Event.MOUSE_LEAVE, this.backgroundMouseDownHandler);
        }

        override protected function onImageLoaded(bitmap:Bitmap):void{
            this.imageChanged(bitmap);
        }

        public function getBitmap():Bitmap{
            var result:Bitmap;
            var bitmapData:BitmapData;
            var colorMatrix:Matrix;
            var bitmapSize:Number;
            var bitmapMatrix:Matrix;
            var ctransform:ColorTransform;
			var rect:Rectangle = mainRef.getQrDisplayRegion();
            bitmapData = new BitmapData((3 * rect.width), (3 * rect.height), true, 0xFFFFFF);
            if (this.colorSprite){
                colorMatrix = new Matrix();
                colorMatrix.scale(3, 3);
                bitmapData.draw(this.colorSprite, colorMatrix);
            };
            if (this.backgroundBitmap){
                bitmapSize = Math.min(this.originalBackground.width, this.originalBackground.height);
                bitmapMatrix = new Matrix();
                ctransform = new ColorTransform();
                ctransform.alphaMultiplier = this.backgroundBitmap.alpha;
                bitmapMatrix.scale((this.scaleFactor * 3), (this.scaleFactor * 3));
                if (this.backgroundBitmap.width > rect.width){
                    bitmapMatrix.translate(((3 * this.backgroundBitmap.x) * this.scaleFactor), 0);
                } else {
                    if (this.backgroundBitmap.height > rect.height){
                        bitmapMatrix.translate(0, ((3 * this.backgroundBitmap.x) * this.scaleFactor));
                    };
                };
                bitmapData.draw(this.originalBackground, bitmapMatrix, ctransform, null, null, true);
            };
            result = new Bitmap(bitmapData, "auto", true);
            return (result);
        }

        override public function dispose():void{
            if (this.backgroundBitmap){
                this.disableMove();
                if (contains(this.backgroundBitmap)){
                    removeChild(this.backgroundBitmap);
                };
                this.backgroundBitmap = null;
                this.originalBackground = null;
                hasContent = false;
            };
        }

        override public function updatePDF(pdf:MSPDF):void{
            var bitmapSize:Number;
            var matrix:Matrix;
            var colorMatrix:Matrix;
            var ctransform:ColorTransform;
            var bgBitmapData:BitmapData;
            var bgBitmap:Bitmap;
			var rect:Rectangle = mainRef.getQrDisplayRegion();
            var padding:Number = pdf.getX();
            pdf.beginFill(new RGBColor(model.backgroundColor));
            pdf.drawRect(new Rectangle(padding, padding, (rect.width * model.pdfScale), (rect.height * model.pdfScale)));
            pdf.end();
            if (this.backgroundBitmap){
                bitmapSize = Math.min(this.originalBackground.width, this.originalBackground.height);
                matrix = new Matrix();
                if (this.backgroundBitmap.width > rect.width){
                    matrix.translate((this.backgroundBitmap.x * (1 / this.scaleFactor)), 0);
                } else {
                    if (this.backgroundBitmap.height > rect.height){
                        matrix.translate(0, (this.backgroundBitmap.x * (1 / this.scaleFactor)));
                    };
                };
                this.originalBackground.alpha = this.backgroundBitmap.alpha;
                colorMatrix = new Matrix();
                colorMatrix.scale((1 / this.scaleFactor), (1 / this.scaleFactor));
                ctransform = new ColorTransform();
                ctransform.alphaMultiplier = this.backgroundBitmap.alpha;
                bgBitmapData = new BitmapData(bitmapSize, bitmapSize, true, 0xFFFFFF);
                bgBitmapData.draw(this.colorSprite, colorMatrix);
                bgBitmapData.draw(this.originalBackground, matrix, ctransform, null, null, true);
                bgBitmap = new Bitmap(bgBitmapData, "auto", true);
                pdf.addImage(bgBitmap, null, 0, 0, rect.width, rect.height, 0, 1, true, ImageFormat.PNG, 100);
                pdf.setAlpha(1);
            };
        }

        protected function updateBackgroundPosition(e:Event):void{
			var rect:Rectangle = mainRef.getQrDisplayRegion();
            if ((((((((mouseX < 0)) || ((mouseX > rect.width)))) || ((mouseY < 0)))) || ((mouseY > rect.height)))){
                stage.dispatchEvent(new Event(Event.MOUSE_LEAVE));
            };
            var difx:Number = (mouseX - this.mouseOrigPos.x);
            var dify:Number = (mouseY - this.mouseOrigPos.y);
            if (this.backgroundBitmap.width > rect.width){
                if (((((this.bgOrigPos.x + difx) > (rect.width - this.backgroundBitmap.width))) && (((this.bgOrigPos.x + difx) <= 0)))){
                    this.backgroundBitmap.x = (this.bgOrigPos.x + difx);
                } else {
                    if (difx > 0){
                        this.backgroundBitmap.x = 0;
                    } else {
                        if (difx < 0){
                            this.backgroundBitmap.x = (rect.width - this.backgroundBitmap.width);
                        };
                    };
                };
            } else {
                if (this.backgroundBitmap.height > rect.height){
                    if (((((this.backgroundBitmap.y + dify) <= 0)) && (((this.backgroundBitmap.y + dify) > (rect.height - this.backgroundBitmap.height))))){
                        this.backgroundBitmap.y = (this.bgOrigPos.y + dify);
                    };
                    if (this.backgroundBitmap.y > 0){
                        this.backgroundBitmap.y = 0;
                    };
                };
            };
        }

        protected function backgroundMouseDownHandler(e:Event):void{
            if (e.type == MouseEvent.MOUSE_DOWN){
                this.mouseOrigPos = new Point(mouseX, mouseY);
                this.bgOrigPos = new Point(this.backgroundBitmap.x, this.backgroundBitmap.y);
                this.addEventListener(Event.ENTER_FRAME, this.updateBackgroundPosition, false, 0, true);
            } else {
                if ((((e.type == MouseEvent.MOUSE_UP)) || ((e.type == Event.MOUSE_LEAVE)))){
                    this.removeEventListener(Event.ENTER_FRAME, this.updateBackgroundPosition);
                };
            };
        }

        protected function alphaChanged(e:Event):void{
            if (this.backgroundBitmap){
                this.backgroundBitmap.alpha = model.backgroundAlpha;
                this.originalBackground.alpha = model.backgroundAlpha;
                this.mainRef.checkQR();
            };
        }

        public function enableMove():void{
            if (this.backgroundBitmap){
                this.addEventListener(MouseEvent.MOUSE_DOWN, this.backgroundMouseDownHandler, false, 0, true);
                stage.addEventListener(MouseEvent.MOUSE_UP, this.backgroundMouseDownHandler, false, 0, true);
                stage.addEventListener(Event.MOUSE_LEAVE, this.backgroundMouseDownHandler, false, 0, true);
            };
        }

        protected function updateColorSprite(color:uint):void{
            this.colorSprite.graphics.beginFill(color);
            //this.colorSprite.graphics.drawRect(0, 0, stage.stageWidth, stage.stageHeight);
			var rect:Rectangle = mainRef.getQrDisplayRegion();
			this.colorSprite.graphics.drawRect(0, 0, rect.width, rect.height);
            this.colorSprite.graphics.endFill();
            this.mainRef.checkQR();
        }


    }
}//package hu.carnation.qrhacker
