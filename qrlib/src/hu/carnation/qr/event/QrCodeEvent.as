//Created by Action Script Viewer - http://www.buraks.com/asv
package hu.carnation.qr.event{
    import flash.events.Event;

    public class QrCodeEvent extends Event {

        public static const DECODE_ERROR:String = "onDecodeError";
        public static const DECODE_COMPLETE:String = "onDecodeComplete";
        public static const ENCODE_ERROR:String = "onEncodeError";
        public static const ENCODE_COMPLETE:String = "onEncodeComplete";
        public static const QRMATRIX_CHANGE:String = "onQrMatrixChanged";
        public static const CORNERRADIUS_CHANGED:String = "onCornerRadiusChanged";
        public static const PIXELSIZE_CHANGE:String = "onPixelSizeChange";
        public static const PIXELTYPE_CHANGE:String = "onPixelTypeChange";
        public static const BACKGROUNDCOLOR_CHANGED:String = "onBackgroundColorChanged";
        public static const BACKGROUNDALPHA_CHANGED:String = "onBackgroundAlphaChanged";
        public static const BACKGROUNDIMAGE_CHANGED:String = "onBackgroundImageChanged";
        public static const BACKGROUNDURL_CHANGED:String = "onBackgroundURLChanged";
        public static const FOREGROUNDIMAGE_CHANGED:String = "onForegroundImageChanged";
        public static const FOREGROUNDURL_CHANGED:String = "onForegroundURLChanged";
        public static const FOREGROUNDALPHA_CHANGED:String = "onForegroundAlphaChanged";
        public static const FOREGROUNDCOLOR_CHANGED:String = "onForegroundColorChanged";
        public static const PIXELCOLOR_CHANGED:String = "onPixelColorChanged";
        public static const ADVANCED_PIXELCOLOR_CHANGED:String = "onAdvancedPixelColorChanged";
        public static const PHOTOURL_CHANGED:String = "onPhotoUrlChanged";
        public static const PHOTO_UPLOADED:String = "onPhotoUploaded";

        public function QrCodeEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false){
            super(type, bubbles, cancelable);
        }

    }
}//package hu.carnation.qr.event
