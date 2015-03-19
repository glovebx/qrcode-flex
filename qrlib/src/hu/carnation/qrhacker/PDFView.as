//Created by Action Script Viewer - http://www.buraks.com/asv
package hu.carnation.qrhacker{
    import flash.display.Sprite;
    import co.moodshare.pdf.MSPDF;
    import flash.events.Event;
    import flash.net.FileReference;
    import org.alivepdf.saving.Method;
    import flash.utils.ByteArray;
    import flash.events.MouseEvent;

    public class PDFView extends Sprite {

        public static const PDF_SAVED:String = "onPDFSaved";
        public static const PDF_CANCEL:String = "onPDFCanceled";

        private var overlay:Sprite;
        private var _pdf:MSPDF;

        public function PDFView(pdf:MSPDF):void{
            this.pdf = pdf;
            this.overlay = new Sprite();
            addChild(this.overlay);
            this.addEventListener(Event.ADDED_TO_STAGE, this.init, false, 0, true);
        }

        public function set pdf(value:MSPDF):void{
            this._pdf = value;
        }

        protected function onPdfSaveCancel(event:Event):void{
            trace("PDFView.onPdfSaveCancel(event)");
            dispatchEvent(new Event(PDF_CANCEL));
        }

        public function get pdf():MSPDF{
            return (this._pdf);
        }

        protected function onPdfSaved(event:Event):void{
            trace("PDFView.onPdfSaved(event)");
            dispatchEvent(new Event(PDF_SAVED));
        }

        private function savePDF():void{
            var file:FileReference = new FileReference();
            var pdfbytes:ByteArray = this.pdf.save(Method.LOCAL);
            file.save(pdfbytes, "qrHackerTest.pdf");
            file.addEventListener(Event.COMPLETE, this.onPdfSaved, false, 0, true);
            file.addEventListener(Event.CANCEL, this.onPdfSaveCancel, false, 0, true);
        }

        protected function onOverlayClicked(event:MouseEvent):void{
            if (this.pdf){
                this.savePDF();
            };
        }

        private function init(e:Event=null):void{
            removeEventListener(Event.ADDED_TO_STAGE, this.init);
            this.overlay.graphics.clear();
            this.overlay.graphics.beginFill(0xFF0000, 0.5);
            this.overlay.graphics.drawRect(10, 10, (stage.stageWidth - 20), (stage.stageHeight - 20));
            this.overlay.graphics.endFill();
            this.overlay.buttonMode = true;
            this.overlay.addEventListener(MouseEvent.CLICK, this.onOverlayClicked, false, 0, true);
        }


    }
}//package hu.carnation.qrhacker
