package scan
{
	import mx.core.UIComponent;
	
	public final class ScanArea extends UIComponent
	{
		public function ScanArea()
		{
			super();
		}
		
		protected override function updateDisplayList(w:Number, h:Number):void
		{
			super.updateDisplayList(w, h);
			graphics.clear();
			if(!w || !h)
				return;
			graphics.lineStyle(1, 0xFF0000);
			graphics.drawRect(0, 0, w, h);
		}
	}
}