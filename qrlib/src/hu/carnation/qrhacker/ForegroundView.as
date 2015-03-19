//Created by Action Script Viewer - http://www.buraks.com/asv
package hu.carnation.qrhacker {
    import co.moodshare.pdf.MSPDF;
    
    import flash.display.Bitmap;
    import flash.display.BitmapData;
    import flash.events.Event;
    import flash.geom.ColorTransform;
    import flash.geom.Matrix;
    import flash.geom.Point;
    import flash.geom.Rectangle;
    
    import hu.carnation.qr.event.QrCodeEvent;
    import hu.carnation.qr.model.Model;

    public class ForegroundView extends BasicView {

        private var originalForeground:Bitmap;
        private var foregroundBitmap:Bitmap;
        private var mainRef:IMain;
        private var maskedBitmap:Bitmap;
        private var _qrCodeDisplay:QrCodeDisplay;
        private var scaleFactor:Number;

        public function ForegroundView(model:Model, uploadHandler:UploadHandler, mainRef:IMain){
            super(model, uploadHandler);
            this.mainRef = mainRef;
            model.addEventListener(QrCodeEvent.FOREGROUNDURL_CHANGED, this.urlChanged, false, 0, true);
            model.addEventListener(QrCodeEvent.FOREGROUNDALPHA_CHANGED, this.alphaChanged, false, 0, true);
            model.addEventListener(QrCodeEvent.CORNERRADIUS_CHANGED, this.updateMask, false, 0, true);
            uploadHandler.addEventListener(QrCodeEvent.FOREGROUNDIMAGE_CHANGED, this.imageUploaded, false, 0, true);
        }

//        private function fitBitmapToStage(bm:Bitmap):Bitmap{
		private function fitBitmapToContainer(bm:Bitmap):Bitmap{		
//            var bmd:BitmapData = new BitmapData(mainRef.getQrSize(), mainRef.getQrSize(), true, 0);
			var rect:Rectangle = mainRef.getQrDisplayRegion();
			var bmd:BitmapData = new BitmapData(rect.width, rect.height, true, 0);
			var ratioWidth:Number = (rect.width / bm.width);
			var ratioHeight:Number = (rect.height / bm.height);	
			
            var result:Bitmap = new Bitmap(bmd);
            //var ratioWidth:Number = (stage.stageWidth / bm.width);
            //var ratioHeight:Number = (stage.stageHeight / bm.height);
            var matrix:Matrix = new Matrix();
            this.scaleFactor = Math.max(ratioWidth, ratioHeight);
            matrix.scale(this.scaleFactor, this.scaleFactor);
            bmd.draw(bm, matrix, null, null, null, true);
            if (this.scaleFactor > 1){
                bm = result;
            };
            return (result);
        }

        protected function urlChanged(e:Event):void{
            if (model.foregroundURL){
                loadImageFromURL(model.foregroundURL);
            };
        }

        public function updateMask(e:Event=null):void{
            var qrCodeBmd:BitmapData;
            var qrCodeBitmap:Bitmap;
            var qrTransMatrix:Matrix;
            var maskBmd:BitmapData;
            if (this.qrCodeDisplay){
                this.qrCodeDisplay.disableCustomColoring();
                if (this.foregroundBitmap){
					var rect:Rectangle = mainRef.getQrDisplayRegion();
					
                    qrCodeBmd = new BitmapData(rect.width, rect.height, true, 0);
                    qrCodeBitmap = new Bitmap(qrCodeBmd);
                    qrTransMatrix = new Matrix();
                    qrTransMatrix.translate(this.qrCodeDisplay.x, this.qrCodeDisplay.y);
                    qrCodeBmd.draw(this.qrCodeDisplay, qrTransMatrix, null, null, null, true);
                    maskBmd = new BitmapData(rect.width, rect.height, true, 0);
                    maskBmd.copyPixels(this.foregroundBitmap.bitmapData, maskBmd.rect, new Point(), qrCodeBmd, new Point(), true);
                    if (this.maskedBitmap){
                        removeChild(this.maskedBitmap);
                        this.maskedBitmap = null;
                    };
                    this.maskedBitmap = new Bitmap(maskBmd);
                    this.maskedBitmap.alpha = model.foregroundAlpha;
                    this.maskedBitmap.smoothing = true;
                    addChild(this.maskedBitmap);
                    hasContent = true;
                    this.mainRef.checkQR();
                };
            };
        }

        protected function imageChanged(bm:Bitmap):void{
//            this.mainRef.closeHtmlPopups();
            this.resetBitmap();
            if (bm){
                this.originalForeground = bm;
                //this.foregroundBitmap = this.fitBitmapToStage(this.originalForeground);
				this.foregroundBitmap = this.fitBitmapToContainer(this.originalForeground);
                hasContent = true;
                this.updateMask();
            };
        }

        protected function imageUploaded(e:Event):void{
            this.imageChanged(Bitmap(uploadHandler.foregroundBitmap));
//            this.mainRef.setTool("fg", "photo", true);
        }

        public function resetBitmap():void{
            if (this.foregroundBitmap){
                if (contains(this.maskedBitmap)){
                    removeChild(this.maskedBitmap);
                };
                this.maskedBitmap = null;
                this.foregroundBitmap = null;
                this.originalForeground = null;
                hasContent = false;
                this.mainRef.checkQR();
            };
        }

        override public function dispose():void{
            if (this.foregroundBitmap){
                if (contains(this.maskedBitmap)){
                    removeChild(this.maskedBitmap);
                };
                this.maskedBitmap = null;
                this.foregroundBitmap = null;
                this.originalForeground = null;
                hasContent = false;
            };
        }

        override protected function onImageLoaded(bitmap:Bitmap):void{
            this.imageChanged(bitmap);
        }

        public function getBitmap():Bitmap{
            var qrCodeBmd:BitmapData;
            var qrCodeBitmap:Bitmap;
            var qrTransMatrix:Matrix;
            var maskBmd:BitmapData;
            var resizeMatrix:Matrix;
            var ctransform:ColorTransform;
            var resizedForegroundBitmapData:BitmapData;
            var result:Bitmap = new Bitmap();
            if (this.foregroundBitmap){
				var rect:Rectangle = mainRef.getQrDisplayRegion();
                qrCodeBmd = new BitmapData((3 * rect.width), (3 * rect.height), true, 0);
                qrCodeBitmap = new Bitmap(qrCodeBmd);
                qrTransMatrix = new Matrix();
                qrTransMatrix.translate(this.qrCodeDisplay.x, this.qrCodeDisplay.y);
                qrTransMatrix.scale(3, 3);
                qrCodeBmd.draw(this.qrCodeDisplay, qrTransMatrix, null, null, null, true);
                maskBmd = new BitmapData((3 * rect.width), (3 * rect.height), true, 0);
                resizeMatrix = new Matrix();
                ctransform = new ColorTransform();
                ctransform.alphaMultiplier = this.foregroundBitmap.alpha;
                resizeMatrix.scale((3 * this.scaleFactor), (3 * this.scaleFactor));
                resizedForegroundBitmapData = new BitmapData((3 * rect.width), (3 * rect.height), true, 0);
                resizedForegroundBitmapData.draw(this.originalForeground, resizeMatrix);
                maskBmd.copyPixels(resizedForegroundBitmapData, maskBmd.rect, new Point(), qrCodeBmd, new Point(), true);
                result.bitmapData = maskBmd;
                result.alpha = model.foregroundAlpha;
            };
            return (result);
        }

        override public function updatePDF(pdf:MSPDF):void{
            var maskedFgBmd:BitmapData;
            if (this.foregroundBitmap){
                maskedFgBmd = new BitmapData(this.width, this.height, true, 0);
                maskedFgBmd.draw(this, null, null, null, null, true);
				var rect:Rectangle = mainRef.getQrDisplayRegion();
                pdf.addBitmapData(maskedFgBmd, null, 0, 0, rect.width, rect.height, 0, 1);
            };
        }

        public function set qrCodeDisplay(value:QrCodeDisplay):void{
            this._qrCodeDisplay = value;
            value.disableCustomColoring();
            this.updateMask();
        }

        protected function alphaChanged(e:Event):void{
            if (this.maskedBitmap){
                this.maskedBitmap.alpha = model.foregroundAlpha;
                this.mainRef.checkQR();
            };
        }

        public function get qrCodeDisplay():QrCodeDisplay{
            return (this._qrCodeDisplay);
        }


    }
}//package hu.carnation.qrhacker
