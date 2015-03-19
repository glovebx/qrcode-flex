//Created by Action Script Viewer - http://www.buraks.com/asv
package hu.carnation.synchronizer{
    import flash.events.EventDispatcher;
    import flash.net.LocalConnection;
    import hu.carnation.math.MathUtils;
    import flash.events.StatusEvent;
    import flash.events.AsyncErrorEvent;
    import flash.events.Event;

    public class SynchronizeMaster extends EventDispatcher {

        public static var DEFAULT_CHANNEL:String = "default_channel";

        private var slave_id:String;
        private var default_channel:String;
        private var client;
        private var unique_connection:LocalConnection;
        private var _connected:Boolean;
        private var _lag:Number;
        private var unique_master_channel:String;
        private var unique_slave_channel:String;
        private var public_connection:LocalConnection;
        private var send_connection:LocalConnection;


        public static function generateRandomId():String{
            var character_code:int;
            var character:String;
            var id:String = "";
            var i:int;
            while (i < 20) {
                character_code = MathUtils.rangeRandom(97, 122, true);
                character = String.fromCharCode(character_code);
                id = (id + character);
                i++;
            };
            return (id);
        }


        public function send(method:String, ... rest):void{
            trace(((("[SynchronizeMaster | send()] - Calling: " + method) + ", args: ") + rest));
            if (rest.length > 0){
                this.send_connection.send(this.unique_slave_channel, method, rest);
            } else {
                this.send_connection.send(this.unique_slave_channel, method);
            };
        }

        public function get connected():Boolean{
            return (this._connected);
        }

        public function initialize(slave_id:String="default_slave_id", channel:String="", client=null):void{
            this.slave_id = slave_id;
            this.client = client;
            this.default_channel = (((channel)!="") ? channel : SynchronizeMaster.DEFAULT_CHANNEL);
            this.public_connection = new LocalConnection();
            try {
                this.public_connection.connect(this.default_channel);
            } catch(e:Error) {
                this.public_connection.close();
                throw (new Error(("cannot connect to channel: " + channel)));
            };
            this.public_connection.client = this;
            this.send_connection = new LocalConnection();
            this.send_connection.addEventListener(StatusEvent.STATUS, this.onConnectionStatus, false, 0, true);
            this.send_connection.addEventListener(AsyncErrorEvent.ASYNC_ERROR, this.onConnectionStatus, false, 0, true);
            trace(("[SynchronizeSlave | initialize()] - Construced. Initial slave id: " + slave_id));
        }

        public function get lag():Number{
            return (this._lag);
        }

        public function initiateHandshake(caller_id:String, unique_slave_channel:String):void{
            trace(((("[SynchronizeMaster | initiateHandshake()] - Handshaking with: " + caller_id) + " on channel: ") + unique_slave_channel));
            if (caller_id == this.slave_id){
                this.unique_slave_channel = unique_slave_channel;
                this.unique_master_channel = SynchronizeMaster.generateRandomId();
                this.unique_connection = new LocalConnection();
                this.unique_connection.connect(this.unique_master_channel);
                this.unique_connection.client = this;
                this.public_connection.close();
                this.public_connection = null;
                this.send_connection.send(this.unique_slave_channel, "completeHandshake", this.unique_master_channel, new Date().getTime());
            };
        }

        private function onConnectionStatus(event:StatusEvent):void{
            if (event.level == "error"){
                trace("[SynchronizeMaster | onConnectionStatus()] - No connection.");
            };
        }

        public function synchronizationComplete(lag:Number):void{
            trace(("[SynchronizeMaster | synchronizationComplete()] - Sync complete. Lag: " + lag));
            this._connected = true;
            this._lag = lag;
            this.send_connection.send(this.unique_slave_channel, "synchronizationComplete");
            this.unique_connection.client = (((this.client)!=null) ? this.client : this);
            this.dispatchEvent(new Event(Event.COMPLETE));
        }


    }
}//package hu.carnation.synchronizer
