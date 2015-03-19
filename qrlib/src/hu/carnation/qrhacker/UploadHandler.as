//Created by Action Script Viewer - http://www.buraks.com/asv
package hu.carnation.qrhacker{
    import flash.display.Bitmap;
    import flash.display.Sprite;
    import flash.events.Event;
    
    import hu.carnation.net.LocalConnectionBitmapReceiver;
    import hu.carnation.qr.event.QrCodeEvent;
    import hu.carnation.qr.model.Model;
    
    import mx.core.FlexSprite;

    public class UploadHandler extends FlexSprite {

        private var bgBitmapReceiver:LocalConnectionBitmapReceiver;
        private var model:Model;
        private var photoBitmapReceiver:LocalConnectionBitmapReceiver;
        private var fgBitmapReceiver:LocalConnectionBitmapReceiver;

        public function UploadHandler(model:Model){
            this.model = model;
            this.bgBitmapReceiver = new LocalConnectionBitmapReceiver("bgupload", "bgupload");
            this.bgBitmapReceiver.addEventListener(Event.COMPLETE, this.onBitmapReceived, false, 0, true);
            this.fgBitmapReceiver = new LocalConnectionBitmapReceiver("fgupload", "fgupload");
            this.fgBitmapReceiver.addEventListener(Event.COMPLETE, this.onBitmapReceived, false, 0, true);
            this.photoBitmapReceiver = new LocalConnectionBitmapReceiver("photoupload", "photoupload");
            this.photoBitmapReceiver.addEventListener(Event.COMPLETE, this.onBitmapReceived, false, 0, true);
        }

        protected function onBitmapReceived(e:Event):void{
            switch (e.currentTarget){
                case this.bgBitmapReceiver:
                    dispatchEvent(new QrCodeEvent(QrCodeEvent.BACKGROUNDIMAGE_CHANGED));
                    break;
                case this.fgBitmapReceiver:
                    dispatchEvent(new QrCodeEvent(QrCodeEvent.FOREGROUNDIMAGE_CHANGED));
                    break;
                case this.photoBitmapReceiver:
                    this.model.photo = this.photoBitmapReceiver.receivedBitmap;
                    break;
            };
        }

        public function get foregroundBitmap():Bitmap{
            return (this.fgBitmapReceiver.receivedBitmap);
        }

        public function get backgroundBitmap():Bitmap{
            return (this.bgBitmapReceiver.receivedBitmap);
        }


    }
}//package hu.carnation.qrhacker
