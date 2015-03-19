//Created by Action Script Viewer - http://www.buraks.com/asv
package hu.carnation.qrhacker{
    import flash.display.Bitmap;
    import flash.display.BitmapData;
    import flash.display.Sprite;
    import flash.events.Event;
    import flash.geom.Matrix;
    import flash.geom.Rectangle;
    
    import co.moodshare.pdf.MSPDF;
    
    import hu.carnation.qr.event.QrCodeEvent;
    import hu.carnation.qr.model.Model;
    import hu.carnation.transform.QrTransformItemManager;
    
    public class PhotoView extends BasicView {

        private var transformManager:QrTransformItemManager;
        private var mainRef:IMain;
		
        public function PhotoView(model:Model, uploadHandler:UploadHandler, mainRef:IMain){
            super(model, uploadHandler);
            this.mainRef = mainRef;
            this.addEventListener(Event.ADDED_TO_STAGE, this.init, false, 0, true);
            model.addEventListener(QrCodeEvent.PHOTO_UPLOADED, this.onPhotoUploaded, false, 0, true);
            model.addEventListener(QrCodeEvent.PHOTOURL_CHANGED, this.onPhotoURLChanged, false, 0, true);
        }

        public function get hasSelectedItem():Boolean{
            return (this.transformManager.hasSelectedItem);
        }

        public function enable():void{
            this.transformManager.enable();
            this.transformManager.mouseEnabled = true;
        }

        public function getBitmap():Bitmap{
            var scaleMatrix:Matrix;
			var rect:Rectangle = mainRef.getQrDisplayRegion();
            var bitmapData:BitmapData = new BitmapData((3 * rect.width), (3 * rect.height), true, 0);
            var result:Bitmap = new Bitmap(bitmapData, "auto", true);
            if (this.hasContent){
                scaleMatrix = new Matrix();
                scaleMatrix.scale(3, 3);			
                bitmapData.draw(this, scaleMatrix);
            };
            return (result);
        }

		public function getBitmap2():Bitmap{
			var scaleMatrix:Matrix;
			var rect:Rectangle = mainRef.getQrDisplayRegion();
			var bitmapData:BitmapData = new BitmapData(rect.width, rect.height, true, 0);
			var result:Bitmap = new Bitmap(bitmapData, "auto", true);
			if (this.hasContent){	
				bitmapData.draw(this);
			};
			return (result);
		}
		
		
        override public function get hasContent():Boolean{
            return (this.transformManager.hasItem);
        }

        override protected function onImageLoaded(_bitmap:Bitmap):void{
            var photoSprite:Sprite = new Sprite();
            var photoBitmap:Bitmap = _bitmap;
            photoBitmap.smoothing = true;
            photoSprite.addChild(photoBitmap);
			//该photoBitmap的父容器photoSprite的坐标是在它的父容器PhotoView的中心点，
			//所以为了把photoBitmap图片显示到外围容器PhotoView的中心，就需要负偏移图片本身尺寸的一半
			//注意，在flash里面，sprite在舞台上相当于一个没有宽高的点而已
            photoBitmap.x = (-(photoBitmap.width) / 2);
            photoBitmap.y = (-(photoBitmap.height) / 2);
//            photoSprite.x = (stage.stageWidth / 2);
//            photoSprite.y = (stage.stageHeight / 2);
			//x、y是PhotoView的中心点
			photoSprite.x = (mainRef.getQrDisplayRegion().width / 2);
			photoSprite.y = (mainRef.getQrDisplayRegion().height / 2);			
            this.transformManager.addItem(photoSprite);
            this.mainRef.checkQR();
            //this.mainRef.closeHtmlPopups();
        }

        override public function updatePDF(pdf:MSPDF):void{
            var photoBitmapData:BitmapData;
            if (this.hasContent){
//				var item:TransformItem = this.transformManager.exportableTransformItem;
//                photoBitmapData = new BitmapData(item.width, item.height, true, 0);
//				
//				var scaleMatrix:Matrix = new Matrix();
//				scaleMatrix.scale(item.scaleX, item.scaleY);
//				//item.targetObject是photoSprite
//				var photoBitmap:Bitmap = Bitmap(Sprite(item.targetObject).getChildAt(0));
//                photoBitmapData.draw(photoBitmap, scaleMatrix);
//				//注意图片生成到PDF里的时候，边缘有空白的空间
//				var rect:Rectangle = new Rectangle(photoBitmap.x, photoBitmap.y, photoBitmap.width, photoBitmap.height);
//				
//                //pdf.addBitmapData(photoBitmapData, null, item.x + photoBitmap.x + rect.left, item.y + photoBitmap.y + rect.top);
//				pdf.addBitmapData(photoBitmapData, null, item.x + photoBitmap.x + 34.35, item.y + photoBitmap.y + 34.35);
				
				
				var rect:Rectangle = mainRef.getQrDisplayRegion();
                photoBitmapData = new BitmapData(rect.width, rect.height, true, 0);
                photoBitmapData.draw(this);
				
                pdf.addBitmapData(photoBitmapData, null, 0, 0);
            };
        }

        protected function onPhotoUploaded(e:Event):void{
            var photoSprite:Sprite;
            var photoBitmap:Bitmap;
            if (model.photo){
                photoSprite = new Sprite();
								
                photoBitmap = model.photo;
                photoBitmap.smoothing = true;
                photoSprite.addChild(photoBitmap);
                photoBitmap.x = (-(photoBitmap.width) / 2);
                photoBitmap.y = (-(photoBitmap.height) / 2);
//                photoSprite.x = (stage.stageWidth / 2);
//                photoSprite.y = (stage.stageHeight / 2);
				photoSprite.x = (mainRef.getQrDisplayRegion().width / 2);
				photoSprite.y = (mainRef.getQrDisplayRegion().height / 2);
				
                this.transformManager.addItem(photoSprite);
                model.photo = null;
                this.mainRef.checkQR();
//                this.mainRef.setTool("fg", "att", true);
//                this.mainRef.closeHtmlPopups();
            };
        }

        public function disable():void{
            this.transformManager.disable();
            this.transformManager.mouseEnabled = false;
        }

        private function init(e:Event=null):void{
            removeEventListener(Event.ADDED_TO_STAGE, this.init);		
			var rect:Rectangle = mainRef.getQrDisplayRegion();
            this.transformManager = new QrTransformItemManager(rect.width, rect.height, model, mainRef);
            this.transformManager.addEventListener(QrTransformItemManager.SELECTION_CHANGE, this.onTransformManagerChange, false, 0, true);
            this.transformManager.addEventListener(QrTransformItemManager.FINISH_TRANSFORM, this.onTransformManagerChange, false, 0, true);
            this.addChild(this.transformManager);
            this.transformManager.init();
        }

        protected function onTransformManagerChange(e:Event):void{
            this.mainRef.checkQR();
            if (!this.transformManager.hasItem){
                trace("PhotoView.onTransformManagerChange(e) Setttol, fg, att, false");
//                this.mainRef.setTool("fg", "att", false);
            };
        }

        protected function onPhotoURLChanged(e:Event):void{
            loadImageFromURL(model.photoURL);
        }

        public function deselectAllItem():void{
            if (((this.transformManager) && (this.hasSelectedItem))){
                this.transformManager.deselectAllItem();
            };
        }

        override public function dispose():void{
            this.deselectAllItem();
            this.transformManager.dispose();
        }


    }
}//package hu.carnation.qrhacker
