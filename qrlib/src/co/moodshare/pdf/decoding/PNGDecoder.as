package co.moodshare.pdf.decoding
{
	import flash.display.BitmapData;
	import flash.display.BitmapDataChannel;
	import flash.geom.Point;
	import flash.utils.ByteArray;

	/**
	 * 
	 * description
	 *
	 * @langversion ActionScript 3
	 * @playerversion Flash 9.0.0
	 *
	 * @author jamesrobb
	 * @since Jun 8, 2011
	 * 
	 */
	public class PNGDecoder extends Object 
	{
		
		public static const HEADER	: int = 0x8950;
		
		
		
		public static function isPNG( bytes:ByteArray ):Boolean
		{
			bytes.position = 0;
			
			return ( bytes.readUnsignedShort() == HEADER );
		}
		
		
		public static function getWidth( bytes:ByteArray ):int
		{
			if( !isPNG( bytes ) ) return -1;
			
			bytes.position = 16;
			
			return bytes.readInt();
		}
		
		
		public static function getHeight( bytes:ByteArray ):int
		{
			if( !isPNG( bytes ) ) return -1;
			
			bytes.position = 20;
			
			return bytes.readInt();
		}
		
		
		public static function getBitsPerComponent( bytes:ByteArray ):int
		{
			if( !isPNG( bytes ) ) return -1;
			
			bytes.position = 24;
			
			return bytes.readByte();
		}
		
		
		public static function getColorType( bytes:ByteArray ):int
		{
			if( !isPNG( bytes ) ) return -1;
			
			bytes.position = 25;
			
			return bytes.readByte();
		}
		
		/**
		 * @param bytes A ByteArray instance that represents a PNG
		 * @return A BitmapData instance representation of the decoded PNG IDAt data
		 */
		public static function decode( bytes:ByteArray ):BitmapData
		{
			if( !isPNG( bytes ) ) return null;
			if( getColorType( bytes ) == 3 ) return null;
			
			var trans : Boolean = ( getColorType( bytes ) == 6 );
			
			var bmd : BitmapData = new BitmapData( getWidth( bytes ),
												   getHeight( bytes ),
												   trans,
												   trans ? 0x00000000 : 4.294967295E9 );
												   
			var idatBytes : ByteArray = new ByteArray();
			var n : int;
			var type : uint;
			
			bytes.position = 33;
			
			do 
			{	
				n = bytes.readInt();
				type = bytes.readUnsignedInt();
				
				if( type == 0x504C5445 )
				{
					bytes.position += n + 4;
					
				}else if( type == 0x49444154 )
				{	
					bytes.readBytes( idatBytes, 0, n );
					bytes.position += 4;
					
					idatBytes.uncompress();
					idatBytes.position = 0;
					
					var row : int = bmd.width * 4;//width * pixel component bytes
					
					var pxls : ByteArray = new ByteArray();
					var count : int = 0;
					
					/*
					 * remove filter bytes from start of each scanline
					 */
					while( idatBytes.bytesAvailable )
					{
						idatBytes.position += 1;
						idatBytes.readBytes( pxls, row * count, row );
						count++;
					}
					
					/*
					 * If transparent re-order pixels from RGBA to ARGB 
					 */
					if( trans )
					{
						pxls.position = 0;
						idatBytes.clear();
						
						var p : uint;
						
						while( pxls.bytesAvailable )
						{
							p = pxls.readUnsignedInt();
							idatBytes.writeUnsignedInt( ( p >>> 8 )|( p << 24 ) );
						}
						
					}else{
						
						idatBytes = pxls;
					}
					
					break;	
				}
				
			} while ( n > 0 );
			
			idatBytes.position = 0;
			
			bmd.setPixels( bmd.rect, idatBytes );
			
			return bmd;
		}
		
		

		public function PNGDecoder()
		{
			super();
		}
		
	}
	
}
