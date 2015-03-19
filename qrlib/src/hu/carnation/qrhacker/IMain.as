package hu.carnation.qrhacker
{
	import flash.geom.Rectangle;

	public interface IMain
	{

		function checkQR():void;
		
		//function getQrSize():Number;
		
		//function getQrGenerateRegion():Rectangle;
		
		function getQrDisplayRegion():Rectangle;
	}
}