//Created by Action Script Viewer - http://www.buraks.com/asv
package hu.carnation.qr{
    import __AS3__.vec.Vector;
    
    import com.google.zxing.BinaryBitmap;
    import com.google.zxing.BufferedImageLuminanceSource;
    import com.google.zxing.DecodeHintType;
    import com.google.zxing.MultiFormatReader;
    import com.google.zxing.Reader;
    import com.google.zxing.Result;
    import com.google.zxing.client.result.ParsedResult;
    import com.google.zxing.client.result.ResultParser;
    import com.google.zxing.common.ByteMatrix;
    import com.google.zxing.common.GlobalHistogramBinarizer;
    import com.google.zxing.common.flexdatatypes.HashTable;
    import com.google.zxing.qrcode.QRCodeReader;
    import com.google.zxing.qrcode.QRCodeWriter;
    
    import flash.display.Bitmap;
    import flash.display.BitmapData;
    import flash.display.Loader;
    import flash.display.LoaderInfo;
    import flash.display.Sprite;
    import flash.events.Event;
    import flash.geom.Rectangle;
    import flash.net.*;
    import flash.net.URLRequest;
    import flash.net.URLVariables;
    import flash.system.LoaderContext;
    import flash.system.Security;
    import flash.text.TextField;
    import flash.utils.ByteArray;
    
    import hu.carnation.qr.event.QrCodeEvent;
    import hu.carnation.qr.model.Model;
    
    import mx.core.UIComponent;

    public class QrCodeHandler extends UIComponent {

        private var model:Model;
        //private var qrCodeReader:QRCodeReader;
		private var qrCodeReader:Reader;
        private var hints:HashTable;
        private var qrCodeWriter:QRCodeWriter;
        private var qrGoogleLoader:Loader;
        private var dbg:TextField;

        public function QrCodeHandler(model:Model){
            this.model = model;
            this.qrCodeWriter = new QRCodeWriter();
        }

        public function decodeBitmap(bitmap:Bitmap):Object{
            var result:Object;
            var errorText:String;
            var errorPercent:Number;
            var parsedResult:ParsedResult;
            this.qrCodeReader = new MultiFormatReader();//QRCodeReader();
            result = {};
            var sourceBitmapData:BitmapData = bitmap.bitmapData;
            var luminanceSource:BufferedImageLuminanceSource = new BufferedImageLuminanceSource(sourceBitmapData);
            var binaryBitmap:BinaryBitmap = new BinaryBitmap(new GlobalHistogramBinarizer(luminanceSource));
            var qrResult:Result;
            try {
				var hints:HashTable = new HashTable();
				hints.Add(DecodeHintType.CHARACTER_SET, "GB2312");
                qrResult = this.qrCodeReader.decode(binaryBitmap, hints);
            } catch(e:Error) {
                result.errorText = e.message;
                dispatchEvent(new QrCodeEvent(QrCodeEvent.DECODE_ERROR));
                trace(("ERROR QrCodeHandler.decodeBitmap(bitmap) " + e.message));
                return (result);
            };
            if (qrResult != null){
                //errorPercent = ((qrResult.errorsNum * 100) / qrResult.totalWords);
				//TODO:
				errorPercent = ((qrResult.getResultPoints().length * 100) / qrResult.getRawBytes().length);
                parsedResult = ResultParser.parseResult(qrResult);
                result.text = parsedResult.getDisplayResult();
                result.error = errorPercent;
                dispatchEvent(new QrCodeEvent(QrCodeEvent.DECODE_COMPLETE));
            } else {
                result.errorText = errorText;
                dispatchEvent(new QrCodeEvent(QrCodeEvent.DECODE_ERROR));
            };
            return (result);
        }

        public function generateQrCode(str:String):void{
            var result:ByteMatrix;
            var urlVars:URLVariables = new URLVariables();
            var req:URLRequest = new URLRequest();
            urlVars.cht = "qr";
            urlVars.chs = "300x300";
            urlVars.chl = str;
            urlVars.chld = "H|0";
            req.url = "http://chart.apis.google.com/chart";
            req.data = urlVars;
            var loaderContext:LoaderContext = new LoaderContext();
            if (Security.sandboxType == Security.LOCAL_TRUSTED){
                loaderContext.checkPolicyFile = true;
				//loaderContext.allowCodeImport = true;
                this.qrGoogleLoader = new Loader();
                this.qrGoogleLoader.contentLoaderInfo.addEventListener(Event.COMPLETE, this.onQrGoogleLoaded, false, 0, true);
                this.qrGoogleLoader.load(req, loaderContext);
            } else {
                loaderContext.checkPolicyFile = false;
				//loaderContext.allowCodeImport = true;
                this.qrGoogleLoader = new Loader();
                this.qrGoogleLoader.contentLoaderInfo.addEventListener(Event.COMPLETE, this.onQrGoogleInfoLoaded, false, 0, true);
                this.qrGoogleLoader.load(req, loaderContext);
            };
        }

        protected function onQrGoogleInfoLoaded(e:Event):void{
            var lInfo:LoaderInfo = LoaderInfo(e.target);
            var ba:ByteArray = lInfo.bytes;
            this.loadQrGoogleByteArray(ba);
        }

        private function loadQrGoogleByteArray(ba:ByteArray):void{
            var baLoader:Loader = new Loader();
			var loaderContext:LoaderContext = new LoaderContext();
			loaderContext.allowCodeImport = true;
            baLoader.loadBytes(ba, loaderContext);
            baLoader.contentLoaderInfo.addEventListener(Event.COMPLETE, this.onQrGoogleByteArrayLoaded, false, 0, true);
        }

        protected function onQrGoogleByteArrayLoaded(e:Event):void{
            var imageInfo:LoaderInfo = LoaderInfo(e.target);
            var bmd:BitmapData = new BitmapData(imageInfo.width, imageInfo.height, true, 0);
            bmd.draw(imageInfo.loader);
            this.convertBitmapToByteMatrix(bmd);
        }

        private function onQrGoogleLoaded(e:Event):void{
            var qrCodeBitmap:Bitmap = (this.qrGoogleLoader.content as Bitmap);
            var qrBmd:BitmapData = qrCodeBitmap.bitmapData;
            this.convertBitmapToByteMatrix(qrBmd);
        }

        private function convertBitmapToByteMatrix(qrBmd:BitmapData):void{
            var pixelColor:uint;
            var i:int;
            var w:int;
            var h:int;
            var j:int;
            while (j < qrBmd.width) {
                pixelColor = qrBmd.getPixel(w, h);
				//16777215就是16进制的FFFFFF，白色
				//0表示碰到黑色了，标准二维码里面黑色表示数据
                if (pixelColor == 0) break;
                w++;
                h++;
                j++;
            };
            var pixelSize:int = this.getQrPixelSize(qrBmd, w, h);
            var matrixWidth:int = ((300 - (2 * w)) / pixelSize);
            var byteMatrix:ByteMatrix = new ByteMatrix(matrixWidth, matrixWidth);
            var k:int;
            while (k < matrixWidth) {
                i = 0;
                while (i < matrixWidth) {
                    if (qrBmd.getPixel(((k * pixelSize) + w), ((i * pixelSize) + h)) == 0){
                        byteMatrix._set(k, i, 1);
                    } else {
                        byteMatrix._set(k, i, 0);
                    };
                    i++;
                };
                k++;
            };
            this.model.qrMatrix = byteMatrix;
            dispatchEvent(new QrCodeEvent(QrCodeEvent.ENCODE_COMPLETE));
        }

        private function getQrPixelSize(bmp:BitmapData, w:int, h:int):int{
            var vec1:Vector.<uint> = bmp.getVector(new Rectangle(w, h, bmp.width, 1));
            var blackPixels:int;
            var i:int;
            while (i < vec1.length) {
                if (vec1[i] == 0xFF000000){
                    blackPixels++;
                } else {
                    break;
                };
                i++;
            };
			//为何要除以7？
			//二维码左上角的定位四方形，宽度是84，其上方的黑色横线，是由7个正方形黑块组成，所以除以7？
            return ((blackPixels / 7));
        }


    }
}//package hu.carnation.qr
