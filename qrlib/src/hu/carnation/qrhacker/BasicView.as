//Created by Action Script Viewer - http://www.buraks.com/asv
package hu.carnation.qrhacker{
    import co.moodshare.pdf.MSPDF;
    
    import flash.display.Bitmap;
    import flash.display.BitmapData;
    import flash.display.Loader;
    import flash.display.LoaderInfo;
    import flash.display.Sprite;
    import flash.events.Event;
    import flash.events.IOErrorEvent;
    import flash.net.URLRequest;
    import flash.system.LoaderContext;
    import flash.utils.ByteArray;
    
    import hu.carnation.qr.model.Model;
    
    import mx.core.FlexSprite;
    import mx.core.UIComponent;
    
    import spark.components.SkinnableContainer;

    public class BasicView extends UIComponent {

        protected var uploadHandler:UploadHandler;
        protected var imageLoader:Loader;
        private var imageURLRequest:URLRequest;
        private var _hasContent:Boolean = false;
        protected var model:Model;
        private var _pdf:MSPDF;

        public function BasicView(model:Model, uploadHandler:UploadHandler){
            this.model = model;
            this.uploadHandler = uploadHandler;
        }

        protected function loadImageFromURL(url:String):void{
            var loaderContext:LoaderContext = new LoaderContext();
            loaderContext.checkPolicyFile = false;
            this.imageURLRequest = new URLRequest(url);
            this.imageLoader = new Loader();
            this.imageLoader.contentLoaderInfo.addEventListener(Event.COMPLETE, this.onImageInfoLoaded, false, 0, true);
            this.imageLoader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, this.onImageLoaderError, false, 0, true);
            this.imageLoader.load(this.imageURLRequest, loaderContext);
        }

        protected function loadImage(bitmap:Bitmap):void{
        }

        protected function onImageLoaderError(e:IOErrorEvent):void{
            trace("BasicView.onImageLoaderError(event) URL not found");
        }

        private function loadImageByteArray(ba:ByteArray):void{
            var baLoader:Loader = new Loader();
            baLoader.loadBytes(ba);
            baLoader.contentLoaderInfo.addEventListener(Event.COMPLETE, this.onImageByteArrayLoaded, false, 0, true);
        }

        protected function updateView(e:Event):void{
        }

        public function dispose():void{
        }

        protected function onImageLoaded(bitmap:Bitmap):void{
        }

        protected function onImageInfoLoaded(e:Event):void{
            var lInfo:LoaderInfo = LoaderInfo(e.target);
            var ba:ByteArray = lInfo.bytes;
            this.loadImageByteArray(ba);
        }

        public function updatePDF(pdf:MSPDF):void{
        }

        protected function onImageByteArrayLoaded(e:Event):void{
            var imageInfo:LoaderInfo = LoaderInfo(e.target);
            var bmd:BitmapData = new BitmapData(imageInfo.width, imageInfo.height, true, 0);
            bmd.draw(imageInfo.loader);
            var resultBitmap:Bitmap = new Bitmap(bmd);
            this.onImageLoaded(resultBitmap);
        }

        public function set hasContent(value:Boolean):void{
            this._hasContent = value;
        }

        public function get hasContent():Boolean{
            return (this._hasContent);
        }


    }
}//package hu.carnation.qrhacker
