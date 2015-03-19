//Created by Action Script Viewer - http://www.buraks.com/asv
package hu.carnation.synchronizer{
    import flash.events.EventDispatcher;
    import flash.net.LocalConnection;
    import flash.utils.Timer;
    import flash.events.StatusEvent;
    import flash.events.AsyncErrorEvent;
    import flash.events.TimerEvent;
    import flash.events.Event;

    public class SynchronizeSlave extends EventDispatcher {

        private var slave_id:String;
        private var default_channel:String;
        private var client;
        private var unique_connection:LocalConnection;
        private var _connected:Boolean;
        private var _lag:Number;
        private var unique_master_channel:String;
        private var unique_slave_channel:String;
        private var connect_timer:Timer;
        private var send_connection:LocalConnection;


        public function send(method:String, ... rest):void{
            if (rest.length > 0){
                this.send_connection.send(this.unique_master_channel, method, rest);
            } else {
                this.send_connection.send(this.unique_master_channel, method);
            };
        }

        public function get connected():Boolean{
            return (this._connected);
        }

        public function initialize(slave_id:String="default_slave_id", channel:String="", client=null):void{
            this.slave_id = slave_id;
            this.client = client;
            this.default_channel = (((channel)!="") ? channel : SynchronizeMaster.DEFAULT_CHANNEL);
            this.unique_slave_channel = SynchronizeMaster.generateRandomId();
            this.unique_connection = new LocalConnection();
            this.unique_connection.client = this;
            this.unique_connection.connect(this.unique_slave_channel);
            this.send_connection = new LocalConnection();
            this.send_connection.addEventListener(StatusEvent.STATUS, this.onConnectionStatus, false, 0, true);
            this.send_connection.addEventListener(AsyncErrorEvent.ASYNC_ERROR, this.onConnectionStatus, false, 0, true);
            this.connect_timer = new Timer(500, 0);
            this.connect_timer.addEventListener(TimerEvent.TIMER, this.connect, false, 0, true);
            this.connect_timer.start();
        }

        public function get lag():Number{
            return (this._lag);
        }

        private function onConnectionStatus(event:StatusEvent):void{
            if (event.level != "error"){
                if (event.level == "status"){
                    if (((this.connect_timer) && (this.connect_timer.running))){
                        this.connect_timer.stop();
                    };
                };
            };
        }

        private function connect(event:TimerEvent):void{
            this.send_connection.send(this.default_channel, "initiateHandshake", this.slave_id, this.unique_slave_channel);
        }

        public function synchronizationComplete():void{
            this._connected = true;
            this.connect_timer.stop();
            this.connect_timer.removeEventListener(TimerEvent.TIMER, this.connect);
            this.connect_timer = null;
            this.unique_connection.client = (((this.client)!=null) ? this.client : this);
            this.dispatchEvent(new Event(Event.COMPLETE));
        }

        public function completeHandshake(master_channel:String, master_time:Number):void{
            this.unique_master_channel = master_channel;
            this._lag = (new Date().getTime() - master_time);
            this.send_connection.send(this.unique_master_channel, "synchronizationComplete", this._lag);
        }


    }
}//package hu.carnation.synchronizer
