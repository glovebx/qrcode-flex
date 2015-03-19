//Created by Action Script Viewer - http://www.buraks.com/asv
package hu.carnation.net{
    import flash.display.Sprite;
    import hu.carnation.synchronizer.SynchronizeSlave;
    import flash.utils.ByteArray;
    import flash.display.Bitmap;
    import flash.display.Loader;
    import flash.events.Event;
    import flash.display.BitmapData;
    import flash.geom.Rectangle;
    import flash.display.LoaderInfo;

    public class LocalConnectionBitmapReceiver extends Sprite {

        private static const LC_BYTE_LIMIT:uint = 40000;

        private var synchronizer_slave:SynchronizeSlave;
        private var byte_holder:ByteArray;
        private var _receivedBitmap:Bitmap;
        private var bitmapLoader:Loader;
        private var _connectionName:String;
        private var old_sequence_number:uint = 0;
        private var _connectionId:String;

        public function LocalConnectionBitmapReceiver(connectionName:String, connectionId:String):void{
            this.connectionName = connectionName;
            this.connectionId = connectionId;
            this.synchronizer_slave = new SynchronizeSlave();
            this.synchronizer_slave.addEventListener(Event.COMPLETE, this.onSynchronized, false, 0, true);
            this.synchronizer_slave.initialize(connectionId, connectionName, this);
        }

        public function get connectionName():String{
            return (this._connectionName);
        }

        public function set connectionName(value:String):void{
            this._connectionName = value;
        }

        private function onSynchronized(e:Event):void{
        }

        public function receivedBitmapPacket(sequence_number:uint, bytes:Object, bytesLength:Number, width:Number, height:Number):void{
            var bmd:BitmapData;
            var bm:Bitmap;
            var old_clip:*;
            var byteArray:ByteArray = (bytes as ByteArray);
            if ((((this.byte_holder == null)) || (!((this.old_sequence_number == sequence_number))))){
                this.byte_holder = new ByteArray();
                this.byte_holder.length = bytesLength;
                this.byte_holder.position = 0;
                this.old_sequence_number = sequence_number;
            };
            this.byte_holder.writeBytes(byteArray);
            if (this.byte_holder.bytesAvailable == 0){
                bmd = new BitmapData(width, height);
                this.byte_holder.position = 0;
                bmd.setPixels(new Rectangle(0, 0, width, height), this.byte_holder);
                bm = new Bitmap(bmd);
                old_clip = getChildByName("sent_bitmap");
                if (old_clip){
                    removeChild(old_clip);
                };
                bm.name = "sent_bitmap";
                this.receivedBitmap = bm;
                this.byte_holder = null;
            };
        }

        public function get connectionId():String{
            return (this._connectionId);
        }

        public function set receivedBitmap(value:Bitmap):void{
            this._receivedBitmap = value;
        }

        public function set connectionId(value:String):void{
            this._connectionId = value;
        }

        public function get receivedBitmap():Bitmap{
            return (this._receivedBitmap);
        }

        protected function onBitmapLoaderComplete(event:Event):void{
            var bitmapData:BitmapData = Bitmap(LoaderInfo(event.target).content).bitmapData;
            this.receivedBitmap = new Bitmap(bitmapData);
            dispatchEvent(new Event(Event.COMPLETE));
        }

        public function receivedByteArrayPacket(sequence_number:uint, bytes:Object, bytesLength:Number):void{
            var byteArray:ByteArray = (bytes as ByteArray);
            if ((((this.byte_holder == null)) || (!((this.old_sequence_number == sequence_number))))){
                this.byte_holder = new ByteArray();
                this.byte_holder.length = bytesLength;
                this.byte_holder.position = 0;
                this.old_sequence_number = sequence_number;
            };
            this.byte_holder.writeBytes(byteArray);
            if (this.byte_holder.bytesAvailable == 0){
                this.byte_holder.position = 0;
                this.bitmapLoader = new Loader();
                this.bitmapLoader.contentLoaderInfo.addEventListener(Event.COMPLETE, this.onBitmapLoaderComplete);
                this.bitmapLoader.loadBytes(this.byte_holder);
                this.byte_holder = null;
            };
        }


    }
}//package hu.carnation.net
