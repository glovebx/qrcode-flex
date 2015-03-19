//Created by Action Script Viewer - http://www.buraks.com/asv
package hu.carnation.transform.components{
    import flash.display.MovieClip;
    import flash.display.Sprite;
    import flash.events.Event;
    import flash.events.MouseEvent;
    
    import mx.core.FlexSprite;

    public class SaveView extends FlexSprite {

        public static const IMAGE_CLICK:String = "image";
        public static const HR_IMAGE_CLICK:String = "hrimage";
        public static const PDF_CLICK:String = "pdf";
        public static const UPGRADE_CLICK:String = "upgrade";
        public static const LOGIN_CLICK:String = "login";
        public static const CANCEL:String = "cancel";
        public static const DOWNLOAD:String = "download";
        public static const WEBSHOP_CLICK:String = "webshop";

        public var storePDF:Boolean = false;
        public var role:String;
        public var upgrade:MovieClip;//instance name
        public var pdf_cbox:MovieClip;//instance name
        public var loginButton:MovieClip;//instance name
        public var upgradeButton:MovieClip;//instance name
        public var imageButton:MovieClip;//instance name
        public var hrimageButton:MovieClip;//instance name
        public var pdfButton:MovieClip;//instance name
        public var background:MovieClip;//instance name
        public var closeButton:MovieClip;//instance name
        public var errorbg:Sprite;//instance name
        public var modifyButton:MovieClip;//instance name
        public var downloadButton:MovieClip;//instance name
        public var webshopButton:MovieClip;//instance name
        public var webshopHit:MovieClip;
        public var webshopBg:MovieClip;//instance name
        private var _error:Boolean = false;

        public function SaveView(_arg1:String=""):void{
            this.role = _arg1;
            this.addEventListener(Event.ADDED_TO_STAGE, this.init, false, 0, true);
        }

        private function init(_arg1:Event):void{
            removeEventListener(Event.ADDED_TO_STAGE, this.init);
            this.addEventListener(Event.REMOVED_FROM_STAGE, this.dispose, false, 0, true);
            this.imageButton.labelTf.text = "IMAGE";
            this.hrimageButton.labelTf.text = "HI-RES IMAGE";
            this.pdfButton.labelTf.text = "PDF";
            this.upgradeButton.labelTf.text = "UPGRADE";
            this.webshopButton.labelTf.text = "WEBSHOP";
            this.loginButton.buttonMode = true;
            this.imageButton.buttonMode = (this.pdfButton.buttonMode = (this.hrimageButton.buttonMode = (this.upgradeButton.buttonMode = true)));
            this.imageButton.mouseChildren = (this.pdfButton.mouseChildren = (this.hrimageButton.mouseChildren = (this.upgradeButton.mouseChildren = false)));
            this.closeButton.buttonMode = true;
            this.closeButton.mouseChildren = false;
            this.closeButton.addEventListener(MouseEvent.CLICK, this.onBackgroundClick, false, 0, true);
            this.imageButton.addEventListener(MouseEvent.CLICK, this.onButtonClick, false, 0, true);
            this.hrimageButton.addEventListener(MouseEvent.CLICK, this.onButtonClick, false, 0, true);
            this.pdfButton.addEventListener(MouseEvent.CLICK, this.onButtonClick, false, 0, true);
            this.upgradeButton.addEventListener(MouseEvent.CLICK, this.onButtonClick, false, 0, true);
            this.loginButton.addEventListener(MouseEvent.CLICK, this.onButtonClick, false, 0, true);
            this.imageButton.addEventListener(MouseEvent.MOUSE_OVER, this.onButtonOver, false, 0, true);
            this.hrimageButton.addEventListener(MouseEvent.MOUSE_OVER, this.onButtonOver, false, 0, true);
            this.pdfButton.addEventListener(MouseEvent.MOUSE_OVER, this.onButtonOver, false, 0, true);
            this.upgradeButton.addEventListener(MouseEvent.MOUSE_OVER, this.onButtonOver, false, 0, true);
            this.webshopButton.addEventListener(MouseEvent.MOUSE_OVER, this.onButtonOver, false, 0, true);
            this.imageButton.addEventListener(MouseEvent.MOUSE_OUT, this.onButtonOut, false, 0, true);
            this.hrimageButton.addEventListener(MouseEvent.MOUSE_OUT, this.onButtonOut, false, 0, true);
            this.pdfButton.addEventListener(MouseEvent.MOUSE_OUT, this.onButtonOut, false, 0, true);
            this.upgradeButton.addEventListener(MouseEvent.MOUSE_OUT, this.onButtonOut, false, 0, true);
            this.webshopButton.addEventListener(MouseEvent.MOUSE_OUT, this.onButtonOut, false, 0, true);
            this.background.buttonMode = true;
            this.background.addEventListener(MouseEvent.CLICK, this.onBackgroundClick, false, 0, true);
            this.modifyButton.labelTf.text = "MODIFY";
            this.downloadButton.labelTf.text = "DOWNLOAD";
            this.modifyButton.buttonMode = (this.downloadButton.buttonMode = true);
            this.modifyButton.mouseChildren = (this.downloadButton.mouseChildren = false);
            this.modifyButton.addEventListener(MouseEvent.CLICK, this.onButtonClick, false, 0, true);
            this.downloadButton.addEventListener(MouseEvent.CLICK, this.onButtonClick, false, 0, true);
            this.modifyButton.addEventListener(MouseEvent.MOUSE_OVER, this.onButtonOver, false, 0, true);
            this.modifyButton.addEventListener(MouseEvent.MOUSE_OUT, this.onButtonOut, false, 0, true);
            this.downloadButton.addEventListener(MouseEvent.MOUSE_OVER, this.onButtonOver, false, 0, true);
            this.downloadButton.addEventListener(MouseEvent.MOUSE_OUT, this.onButtonOut, false, 0, true);
            this.errorbg.visible = (this.modifyButton.visible = (this.downloadButton.visible = false));
            this.webshopButton.buttonMode = true;
            this.webshopButton.mouseChildren = false;
            this.webshopButton.addEventListener(MouseEvent.CLICK, this.onWebshopClick, false, 0, true);
            switch (this.role){
                case "FREE":
                case "REG":
                case "GUEST":
                    this.pdf_cbox.visible = false;
                    this.pdfButton.visible = false;
                    this.hrimageButton.visible = false;
                    this.upgrade.visible = true;
                    this.upgradeButton.visible = true;
                    this.loginButton.visible = true;
                    return;
                case "REGULAR":
                case "PLUS":
                case "ADMIN":
                    this.pdf_cbox.visible = false;
                    this.pdfButton.visible = true;
                    this.hrimageButton.visible = true;
                    this.upgrade.visible = false;
                    this.upgradeButton.visible = false;
                    this.loginButton.visible = false;
                    return;
            };
        }

        private function onWebshopClick(_arg1:MouseEvent):void{
            switch (_arg1.type){
                case MouseEvent.CLICK:
                    dispatchEvent(new Event(WEBSHOP_CLICK));
                    return;
                case MouseEvent.MOUSE_OVER:
                    this.webshopButton.gotoAndStop(2);
                    return;
                case MouseEvent.MOUSE_OUT:
                    this.webshopButton.gotoAndStop(1);
                    return;
            };
        }

        private function showError():void{
            this.webshopBg.visible = (this.imageButton.visible = (this.pdfButton.visible = false));
            this.errorbg.visible = (this.modifyButton.visible = (this.downloadButton.visible = true));
        }

        private function hideError():void{
            this.webshopBg.visible = (this.imageButton.visible = (this.pdfButton.visible = true));
            this.errorbg.visible = (this.modifyButton.visible = (this.downloadButton.visible = false));
        }

        private function onBackgroundClick(_arg1:MouseEvent):void{
            dispatchEvent(new Event(CANCEL));
        }

        private function onButtonClick(_arg1:MouseEvent):void{
            _arg1.stopImmediatePropagation();
            switch (_arg1.currentTarget){
                case this.imageButton:
                    dispatchEvent(new Event(IMAGE_CLICK));
                    return;
                case this.hrimageButton:
                    dispatchEvent(new Event(HR_IMAGE_CLICK));
                    return;
                case this.pdfButton:
                    dispatchEvent(new Event(PDF_CLICK));
                    return;
                case this.modifyButton:
                    dispatchEvent(new Event(CANCEL));
                    return;
                case this.downloadButton:
                    this.hideError();
                    dispatchEvent(new Event(DOWNLOAD));
                    return;
                case this.upgradeButton:
                    dispatchEvent(new Event(UPGRADE_CLICK));
                    return;
                case this.loginButton:
                    dispatchEvent(new Event(LOGIN_CLICK));
                    return;
            };
        }

        private function onButtonOver(_arg1:MouseEvent):void{
            var _local2:MovieClip = MovieClip(_arg1.currentTarget);
            _local2.gotoAndStop(2);
        }

        private function onButtonOut(_arg1:MouseEvent):void{
            var _local2:MovieClip = MovieClip(_arg1.currentTarget);
            _local2.gotoAndStop(1);
        }

        private function dispose(_arg1:Event):void{
            removeEventListener(Event.REMOVED_FROM_STAGE, this.dispose);
        }

        public function get error():Boolean{
            return (this._error);
        }

        public function set error(_arg1:Boolean):void{
            this._error = _arg1;
            if (_arg1){
                this.showError();
            };
        }


    }
}//package hu.carnation.transform.components
