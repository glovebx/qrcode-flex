/*
_________________            __________________________
___    |__  /__(_)__   _________  __ \__  __ \__  ____/
__  /| |_  /__  /__ | / /  _ \_  /_/ /_  / / /_  /_    
_  ___ |  / _  / __ |/ //  __/  ____/_  /_/ /_  __/
/_/  |_/_/  /_/  _____/ \___//_/     /_____/ /_/  

* Copyright (c) 2007 Thibault Imbert
*
* This program is distributed under the terms of the MIT License as found 
* in a file called LICENSE. If it is not present, the license
* is always available at http://www.opensource.org/licenses/mit-license.php.
*
* This program is distributed in the hope that it will be useful, but
* without any waranty; without even the implied warranty of merchantability
* or fitness for a particular purpose. See the MIT License for full details.
*/

/**
 * This library lets you generate PDF files with the Adobe Flash Player 9 and 10.
 * AlivePDF contains some code from the FPDF PHP library by Olivier Plathey (http://www.fpdf.org/)
 * Core Team : Thibault Imbert, Mark Lynch, Alexandre Pires, Marc Hugues
 * @version 0.1.5 RC current release
 * @url http://alivepdf.bytearray.org
 */

package org.alivepdf.pdf
{
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.Shape;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.net.URLRequest;
	import flash.net.URLRequestHeader;
	import flash.net.URLRequestMethod;
	import flash.net.navigateToURL;
	import flash.system.Capabilities;
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;
	import flash.utils.Endian;
	import flash.utils.getTimer;
	
	import org.alivepdf.annotations.Annotation;
	import org.alivepdf.annotations.MovieAnnotation;
	import org.alivepdf.annotations.TextAnnotation;
	import org.alivepdf.cells.CellVO;
	import org.alivepdf.codabar.CodaBar;
	import org.alivepdf.colors.CMYKColor;
	import org.alivepdf.colors.GrayColor;
	import org.alivepdf.colors.IColor;
	import org.alivepdf.colors.RGBColor;
	import org.alivepdf.colors.RGBColorCache;
	import org.alivepdf.colors.SpotColor;
	import org.alivepdf.decoding.Filter;
	import org.alivepdf.display.Display;
	import org.alivepdf.display.PageMode;
	import org.alivepdf.drawing.DashedLine;
	import org.alivepdf.drawing.SectorDrawingCommand;
	import org.alivepdf.drawing.WindingRule;
	import org.alivepdf.encoding.Base64;
	import org.alivepdf.encoding.JPEGEncoder;
	import org.alivepdf.encoding.PNGEncoder;
	import org.alivepdf.encoding.TIFFEncoder;
	import org.alivepdf.events.PageEvent;
	import org.alivepdf.events.ProcessingEvent;
	import org.alivepdf.fonts.CoreFont;
	import org.alivepdf.fonts.CoreFontCache;
	import org.alivepdf.fonts.EmbeddedFont;
	import org.alivepdf.fonts.FontCollections;
	import org.alivepdf.fonts.FontDescription;
	import org.alivepdf.fonts.FontFamily;
	import org.alivepdf.fonts.FontMetrics;
	import org.alivepdf.fonts.FontType;
	import org.alivepdf.fonts.IFont;
	import org.alivepdf.fonts.Style;
	import org.alivepdf.gradients.ShadingType;
	import org.alivepdf.grid.Grid;
	import org.alivepdf.grid.GridCell;
	import org.alivepdf.grid.GridRowType;
	import org.alivepdf.html.FONTTagAttributes;
	import org.alivepdf.html.HTMLTag;
	import org.alivepdf.images.ColorSpace;
	import org.alivepdf.images.DoJPEGImage;
	import org.alivepdf.images.DoPNGImage;
	import org.alivepdf.images.DoTIFFImage;
	import org.alivepdf.images.GIFImage;
	import org.alivepdf.images.ImageFormat;
	import org.alivepdf.images.JPEGImage;
	import org.alivepdf.images.PDFImage;
	import org.alivepdf.images.PNGImage;
	import org.alivepdf.images.TIFFImage;
	import org.alivepdf.images.gif.player.GIFPlayer;
	import org.alivepdf.layout.Align;
	import org.alivepdf.layout.Border;
	import org.alivepdf.layout.HorizontalAlign;
	import org.alivepdf.layout.Layout;
	import org.alivepdf.layout.Mode;
	import org.alivepdf.layout.Position;
	import org.alivepdf.layout.Resize;
	import org.alivepdf.layout.Size;
	import org.alivepdf.layout.Unit;
	import org.alivepdf.links.HTTPLink;
	import org.alivepdf.links.ILink;
	import org.alivepdf.links.InternalLink;
	import org.alivepdf.links.Outline;
	import org.alivepdf.operators.Drawing;
	import org.alivepdf.pages.Page;
	import org.alivepdf.saving.Method;
	import org.alivepdf.text.Cell;
	import org.alivepdf.tools.sprintf;
	import org.alivepdf.visibility.Visibility;
	
	/**
	 * Dispatched when a page has been added to the PDF. The addPage() method generate this event
	 *
	 * @eventType org.alivepdf.events.PageEvent.ADDED
	 *
	 * * @example
	 * This example shows how to listen for such an event :
	 * <div class="listing">
	 * <pre>
	 *
	 * myPDF.addEventListener ( PageEvent.ADDED, pageAdded );
	 * </pre>
	 * </div>
	 */
	[Event(name='added', type='org.alivepdf.events.PageEvent')]
	
	/**
	 * Dispatched when PDF has been generated and available. The save() method generate this event
	 *
	 * @eventType org.alivepdf.events.ProcessingEvent.COMPLETE
	 *
	 * * @example
	 * This example shows how to listen for such an event :
	 * <div class="listing">
	 * <pre>
	 *
	 * myPDF.addEventListener ( ProcessingEvent.COMPLETE, generationComplete );
	 * </pre>
	 * </div>
	 */
	[Event(name='complete', type='org.alivepdf.events.ProcessingEvent')]
	
	/**
	 * Dispatched when the PDF page tree has been generated. The save() method generate this event
	 *
	 * @eventType org.alivepdf.events.ProcessingEvent.PAGE_TREE
	 *
	 * * @example
	 * This example shows how to listen for such an event :
	 * <div class="listing">
	 * <pre>
	 *
	 * myPDF.addEventListener ( ProcessingEvent.PAGE_TREE, pageTreeAdded );
	 * </pre>
	 * </div>
	 */
	[Event(name='pageTree', type='org.alivepdf.events.ProcessingEvent')]
	
	/**
	 * Dispatched when the required resources (fonts, images, etc.) haven been written into the PDF. The save() method generate this event
	 *
	 * @eventType org.alivepdf.events.ProcessingEvent.RESOURCES
	 *
	 * * @example
	 * This example shows how to listen for such an event :
	 * <div class="listing">
	 * <pre>
	 *
	 * myPDF.addEventListener ( ProcessingEvent.RESOURCES, resourcesAdded );
	 * </pre>
	 * </div>
	 */
	[Event(name='resources', type='org.alivepdf.events.ProcessingEvent')]
	
	/**
	 * Dispatched when the PDF generation has been initiated. The save() method generate this event
	 *
	 * @eventType org.alivepdf.events.ProcessingEvent.STARTED
	 *
	 * * @example
	 * This example shows how to listen for such an event :
	 * <div class="listing">
	 * <pre>
	 *
	 * myPDF.addEventListener ( ProcessingEvent.STARTED, generationStarted );
	 * </pre>
	 * </div>
	 */
	[Event(name='started', type='org.alivepdf.events.ProcessingEvent')]
	
	/**
	 * The PDF class represents a PDF document.
	 * 
	 * @author Thibault Imbert
	 * 
	 * @example
	 * This example shows how to create a PDF document :
	 * <div class="listing">
	 * <pre>
	 * 
	 * var myPDF:PDF = new PDF( Orientation.LANDSCAPE, Unit.MM, Size.A4 );
	 * </pre>
	 * </div>
	 * 
	 * This example shows how to listen for events during PDF creation :
	 * <div class="listing">
	 * <pre>
	 *
	 * myPDF.addEventListener( ProcessingEvent.STARTED, generationStarted );
	 * myPDF.addEventListener( ProcessingEvent.PAGE_TREE, pageTreeGeneration );
	 * myPDF.addEventListener( ProcessingEvent.RESOURCES, resourcesEmbedding );
	 * myPDF.addEventListener( ProcessingEvent.COMPLETE, generationComplete );
	 * </pre>
	 * </div>
	 * 
	 * This example shows how to listen for an event when a page is added to the PDF :
	 * <div class="listing">
	 * <pre>
	 *
	 * myPDF.addEventListener( PageEvent.ADDED, pageAdded );
	 * </pre>
	 * </div>
	 */	
	public class PDF implements IEventDispatcher
	{
		
		protected static const PDF_VERSION:String = '1.3';
		protected static const ALIVEPDF_VERSION:String = '0.1.5 RC';
		protected const I1000:int = 1000;
		
		protected static const STATE_0:int = 0;
		protected static const STATE_1:int = 1;
		protected static const STATE_2:int = 2;
		protected static const STATE_3:int = 3;
		
		protected var format:Array;
		protected var size:Size;
		protected var margin:Number;
		protected var nbPages:int;
		protected var n:int;                 
		protected var offsets:Array;     
		protected var state:int;      
		protected var defaultOrientation:String;
		protected var defaultSize:Size;
		protected var defaultRotation:int;
		protected var defaultUnit:String;
		protected var currentOrientation:String;
		protected var orientationChanges:Array;
		protected var strokeColor:IColor;
		protected var fillColor:IColor;
		protected var strokeStyle:String;
		protected var strokeAlpha:Number;
		protected var strokeFlatness:Number;
		protected var strokeBlendMode:String;
		protected var strokeDash:DashedLine;
		protected var strokeCaps:String;
		protected var strokeJoints:String;
		protected var strokeMiter:Number;
		protected var textAlpha:Number;
		protected var textLeading:Number;
		protected var textColor:IColor;
		protected var textScale:Number;
		protected var textSpace:Number;
		protected var textWordSpace:Number;
		protected var k:Number;             
		protected var leftMargin:Number;
    protected var leftMarginPt:Number;
		protected var topMargin:Number;
    protected var topMarginPt:Number;
		protected var rightMargin:Number;
    protected var rightMarginPt:Number;
		protected var bottomMargin:Number;
    protected var bottomMarginPt:Number;
		protected var currentMargin:Number;            
		protected var currentX:Number;
		protected var currentY:Number;
		protected var currentMatrix:Matrix;
		protected var lasth:Number;       
		protected var strokeThickness:Number;  
		protected var fonts:Array;
		protected var differences:Array;                   
		protected var fontFamily:String;     
		protected var fontStyle:String;       
		protected var underline:Boolean;       
		protected var fontSizePt:Number;      
		protected var windingRule:String;            
		protected var addTextColor:String;       
		protected var colorFlag:Boolean;     
		protected var ws:Number;
		protected var helvetica:IFont;
		protected var autoPageBreak:Boolean;
		protected var pageBreakTrigger:Number;
		protected var inHeader:Boolean;    
		protected var inFooter:Boolean;    
		protected var zoomMode:*;     
		protected var zoomFactor:Number;     
		protected var layoutMode:String;         
		protected var pageMode:String;
		protected var isLinux:Boolean;
		protected var documentTitle:String;            
		protected var documentSubject:String;       
		protected var documentAuthor:String;      
		protected var documentKeywords:String;    
		protected var documentCreator:String;     
		protected var aliasNbPages:String;   
		protected var version:String;
		protected var buffer:ByteArray;
		protected var streamDictionary:Dictionary;
		protected var compressedPages:ByteArray;
		protected var image:PDFImage;
		protected var fontSize:Number;
		protected var name:String;
		protected var type:String;
		protected var desc:String;
		protected var underlinePosition:Number;
		protected var underlineThickness:Number;
		protected var charactersWidth:Object;
		protected var d:Number;
		protected var nb:int;
		protected var size1:Number;
		protected var size2:Number;
		protected var currentFont:IFont;
		protected var defaultFont:IFont;
		protected var b2:String;
		protected var filter:String;
		protected var filled:Boolean
		protected var dispatcher:EventDispatcher;
		protected var arrayPages:Array;
		protected var arrayNotes:Array;
		protected var graphicStates:Array;
		protected var currentPage:Page;
		protected var outlines:Array;
		protected var outlineRoot:int;
		protected var textRendering:int;
		protected var viewerPreferences:String;
		protected var reference:String;
		protected var pagesReferences:Array;
		protected var nameDictionary:String;
		protected var displayObjectbounds:Rectangle;
		protected var coreFontMetrics:FontMetrics;
		protected var columnNames:Array;
		protected var columns:Array;
		protected var currentGrid:Grid;
		protected var isEven:int;
		protected var matrix:Matrix;
		protected var pushedFontName:String;
		protected var fontUnderline:Boolean;
		protected var jsResource:int;
		protected var js:String;
		protected var widths:*;
		protected var aligns:Array = new Array();
		protected var spotColors:Array = new Array();
		protected var drawColor:String;
		protected var bitmapFilled:Boolean;
		protected var bitmapFillBuffer:Shape = new Shape();
		protected var visibility:String = Visibility.ALL;
		protected var nOCGPrint:int;
		protected var nOCGView:int;
		protected var startingPageIndex:uint;
		protected var nextPageY:Number = 10;
		protected var nextPageX:Number = 10;
		protected var gradients:Array = new Array();
		protected var isWrapRow : Boolean;
		protected var row : Array;
		protected var column : Array;
		protected var rowX : Number;
		protected var rowY : Number;
		protected var maxY : Number;
		protected var angle:Number = 0;
		protected var _footer:String;
		protected var _header:String;
		private var stroking:Boolean;
		
		/**
		 * The PDF class represents a PDF document.
		 *
		 * @example
		 * This example shows how to create a valid PDF document :
		 * <div class="listing">
		 * <pre>
		 *
		 * var myPDF:PDF = new PDF ( Orientation.PORTRAIT, Unit.MM, Size.A4 );
		 * </pre>
		 * </div>
		 */
		public function PDF ( orientation:String='Portrait', unit:String='Mm', autoPageBreak:Boolean=true, pageSize:Size=null, rotation:int=0 )
		{
			init ( orientation, unit, autoPageBreak, pageSize, rotation );
		}
		
		/**
		 * Lets you specify the left, top, and right margins.
		 *
		 * @param left Left margin
		 * @param top Right number
		 * @param right Top number
		 * @param bottom Bottom number
		 * @example
		 * This example shows how to set margins for the PDF document :
		 * <div class="listing">
		 * <pre>
		 *
		 * myPDF.setMargins ( 10, 10, 10, 10 );
		 * </pre>
		 * </div>
		 */
		public function setMargins ( left:Number, top:Number, right:Number=-1, bottom:Number=20 ):void
		{
			leftMargin = left;
      leftMarginPt = leftMargin*k;
      
			topMargin = top;
      topMarginPt = topMargin*k;
      
			bottomMargin = bottom;
      bottomMarginPt = bottomMargin*k;
      
      if( right == -1 ) 
        right = left;
      
			rightMargin = right;
      rightMarginPt = rightMargin*k;
		}
		
		/**
		 * Lets you reset the margins dimensions.
		 *
		 * @return
		 * @example
		 * This example shows how to reset the margins dimensions :
		 * <div class="listing">
		 * <pre>
		 *
		 * myPDF.resetMargins ();
		 * </pre>
		 * </div>
		 */	
		public function resetMargins ():void
		{
			var margin:Number = 28.35/k;
			setMargins ( margin, margin );
		}
		
		/**
		 * Lets you retrieve the margins dimensions.
		 *
		 * @return Rectangle
		 * @example
		 * This example shows how to get the margins dimensions :
		 * <div class="listing">
		 * <pre>
		 *
		 * var marginsDimensions:Rectangle = myPDF.getMargins ();
		 * // output : (x=10.00, y=10.0012, w=575.27, h=811.88)
		 * trace( marginsDimensions )
		 * </pre>
		 * </div>
		 */
		public function getMargins ():Rectangle
		{
			return new Rectangle( leftMargin, topMargin, getCurrentPage().w - rightMargin - leftMargin, getCurrentPage().h - bottomMargin - topMargin );
		}
		
		/**
		 * Lets you specify the left margin.
		 *
		 * @param margin Left margin
		 * @example
		 * This example shows how set left margin for the PDF document :
		 * <div class="listing">
		 * <pre>
		 *
		 * myPDF.setLeftMargin ( 10 );
		 * </pre>
		 * </div>
		 */
		public function setLeftMargin (margin:Number):void
		{
			leftMargin = margin;
      leftMarginPt = leftMargin*k;
      
			if( nbPages > 0 && currentX < margin ) 
				currentX = margin;
		}
		
		/**
		 * Lets you specify the top margin.
		 *
		 * @param margin Top margin
		 * @example
		 * This example shows how set top margin for the PDF document :
		 * <div class="listing">
		 * <pre>
		 *
		 * myPDF.setTopMargin ( 10 );
		 * </pre>
		 * </div>
		 */
		public function setTopMargin (margin:Number):void
		{
			topMargin = margin;
      topMarginPt = topMargin*k;
		}
		
		/**
		 * Lets you specify the bottom margin
		 *
		 * @param margin Bottom margin
		 * @example
		 * This example shows how set bottom margin for the PDF document :
		 * <div class="listing">
		 * <pre>
		 *
		 * myPDF.setBottomMargin ( 10 );
		 * </pre>
		 * </div>
		 */
		public function setBottomMargin (margin:Number):void
		{
			bottomMargin = margin;
      bottomMarginPt = bottomMargin*k;
		}
		
		/**
		 * Lets you specify the right margin.
		 *
		 * @param margin Right margin
		 * @example
		 * This example shows how set right margin for the PDF document :
		 * <div class="listing">
		 * <pre>
		 *
		 * myPDF.setRightMargin ( 10 );
		 * </pre>
		 * </div>
		 */
		public function setRightMargin (margin:Number):void
		{
			rightMargin = margin;
      rightMarginPt  = rightMargin*k;
		}
		
		/**
		 * Lets you enable or disable auto page break mode and triggering margin.
		 * 
		 * @param auto Page break mode
		 * @param margin Bottom margin
		 * 
		 */		
		public function setAutoPageBreak ( auto:Boolean, margin:Number ):void
		{
			autoPageBreak = auto;
			bottomMargin = margin;
			if ( currentPage != null ) 
				pageBreakTrigger = currentPage.h-margin;
		}
		
		/**
		 * Lets you set a specific display mode, the DisplayMode takes care of the general layout of the PDF in the PDF reader
		 *
		 * @param zoom Zoom mode, can be Display.FULL_PAGE, Display.FULL_WIDTH, Display.REAL, Display.DEFAULT
		 * @param layout Layout of the PDF document, can be Layout.SINGLE_PAGE, Layout.ONE_COLUMN, Layout.TWO_COLUMN_LEFT, Layout.TWO_COLUMN_RIGHT
		 * @param mode PageMode can be pageMode.USE_NONE, PageMode.USE_OUTLINES, PageMode.USE_THUMBS, PageMode.FULL_SCREEN
		 * @param zoomValue Zoom factor to be used when the PDF is opened, a value of 1.5 would open the PDF with a 150% zoom
		 * @example
		 * This example creates a PDF which opens at full page scaling, one page at a time :
		 * <div class="listing">
		 * <pre>
		 *
		 * myPDF.setDisplayMode ( Display.FULL_PAGE, Layout.SINGLE_PAGE );
		 * </pre>
		 * </div>
		 * To create a full screen PDF you would write :
		 * <div class="listing">
		 * <pre>
		 * 
		 * myPDF.setDisplayMode( Display.FULL_PAGE, Layout.SINGLE_PAGE, PageMode.FULLSCREEN );
		 * </pre>
		 * </div>
		 * 
		 * To create a PDF which will open with a 150% zoom, you would write :
		 * <div class="listing">
		 * <pre>
		 * 
		 * myPDF.setDisplayMode( Display.REAL, Layout.SINGLE_PAGE, PageMode.USE_NONE, 1.5 );
		 * </pre>
		 * </div>
		 */
		public function setDisplayMode ( zoom:String='FullWidth', layout:String='SinglePage', mode:String='UseNone', zoomValue:Number=1 ):void
		{
			zoomMode = zoom;
			zoomFactor = zoomValue;
			layoutMode = layout;
			pageMode = mode;
		}
		
		/**
		 * Lets you set specify the timing (in seconds) a page is shown when the PDF is shown in fullscreen mode.
		 *
		 * @param title The title
		 * @example
		 * This example shows how to set a specific advance timing (5 seconds) for the current page :
		 * <div class="listing">
		 * <pre>
		 *
		 * myPDF.setAdvanceTiming ( 5 );
		 * </pre>
		 * </div>
		 * 
		 * You can also specify this on the Page object :
		 * <div class="listing">
		 * <pre>
		 *
		 * var page:Page = new Page ( Orientation.PORTRAIT, Unit.MM );
		 * page.setAdvanceTiming ( 5 );
		 * myPDF.addPage ( page );
		 * </pre>
		 * </div>
		 */
		public function setAdvanceTiming ( timing:int ):void
		{
			currentPage.advanceTiming = timing;
		}
		
		/**
		 * Lets you set a title for the PDF.
		 *
		 * @param title The title
		 * @example
		 * This example shows how to set a specific title to the PDF tags :
		 * <div class="listing">
		 * <pre>
		 *
		 * myPDF.setTitle ( "AlivePDF !" );
		 * </pre>
		 * </div>
		 */
		public function setTitle ( title:String ):void
		{
			documentTitle = title;
		}
		
		/**
		 * Lets you set a subject for the PDF.
		 *
		 * @param subject The subject
		 * @example
		 *  This example shows how to set a specific subject to the PDF tags :
		 * <div class="listing">
		 * <pre>
		 *
		 * myPDF.setSubject ( "Any topic" );
		 * </pre>
		 * </div>
		 */
		public function setSubject ( subject:String ):void
		{
			documentSubject = subject;
		}
		
		/**
		 * Sets the specified author for the PDF.
		 *
		 * @param author The author
		 * @example
		 * This example shows how to add a specific author to the PDF tags :
		 * <div class="listing">
		 * <pre>
		 *
		 * myPDF.setAuthor ( "Bob" );
		 * </pre>
		 * </div>
		 */
		public function setAuthor ( author:String ):void
		{
			documentAuthor = author;
		}
		
		/**
		 * Sets the specified keywords for the PDF.
		 *
		 * @param keywords The keywords
		 * @example
		 * This example shows how to add some keywords to the PDF tags :
		 * <div class="listing">
		 * <pre>
		 *
		 * myPDF.setKeywords ( "Design, Agency, Communication, etc." );
		 * </pre>
		 * </div>
		 */
		public function setKeywords ( keywords:String ):void
		{
			documentKeywords = keywords;
		}
		
		/**
		 * Sets the specified creator for the PDF.
		 *
		 * @param creator Name of the PDF creator
		 * @example
		 * This example shows how to set a creator name to the PDF tags :
		 * <div class="listing">
		 * <pre>
		 *
		 * myPDF.setCreator ( "My Application 1.0" );
		 * </pre>
		 * </div>
		 */
		public function setCreator ( creator:String ):void
		{
			documentCreator = creator;
		}
		
		/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		/*
		* AlivePDF paging API
		*/
		/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		
		/**
		 * Lets you specify an alias for the total number of pages.
		 *
		 * @param alias Alias to use
		 * @example
		 * This example shows how to show the total number of pages :
		 * <div class="listing">
		 * <pre>
		 *
		 * myPDF.setAliasNbPages ( "[nb]" );
		 * myPDF.textStyle( new RGBColor (0,0,0), 1 );
		 * myPDF.setFont( FontFamily.HELVETICA, Style.NORMAL, 18 );
		 * // then use the alias when needed
		 * myPDF.addText ("There are [nb] pages in the PDF !", 150, 50);
		 * </pre>
		 * </div>
		 */
		public function setAliasNbPages ( alias:String='{nb}' ):void
		{
			aliasNbPages = alias;
		}
		
		/**
		 * Lets you rotate a specific page (between 1 and n-1).
		 *
		 * @param number Page number
		 * @param rotation Page rotation (must be a multiple of 90)
		 * @throws RangeError
		 * @example
		 * This example shows how to rotate the first page 90 clock wise :
		 * <div class="listing">
		 * <pre>
		 *
		 * myPDF.rotatePage ( 1, 90 );
		 * </pre>
		 * </div>
		 * 
		 * This example shows how to rotate the first page 90 counter clock wise :
		 * <div class="listing">
		 * <pre>
		 *
		 * myPDF.rotatePage ( 1, -90 );
		 * </pre>
		 * </div>
		 */
		public function rotatePage ( number:int, rotation:Number ):void
		{
			if ( number > 0 && number <= arrayPages.length ) 
				arrayPages[int(number-1)].rotate ( rotation );
			else throw new RangeError ("No page available, please select a page from 1 to " + arrayPages.length);
		}

		/**
		 * Lets you add a page to the current PDF.
		 *  
		 * @param page
		 * @returns page
		 * @example
		 * 
		 * This example shows how to add an A4 page with a landscape orientation :
		 * <div class="listing">
		 * <pre>
		 *
		 * var page:Page = new Page ( Orientation.LANDSCAPE, Unit.MM, Size.A4 );
		 * myPDF.addPage( page );
		 * </pre>
		 * </div>
		 * This example shows how to add a page with a custom size :
		 * <div class="listing">
		 * <pre>
		 *
		 * var customSize:Size = new Size ( [420.94, 595.28], "CustomSize", [5.8,  8.3], [148, 210] );
		 * var page:Page = new Page ( Orientation.PORTRAIT, Unit.MM, customSize );
		 * myPDF.addPage ( page );
		 * </pre>
		 * </div>
		 * 
		 */		
		public function addPage (page:Page=null):Page
		{
			if ( page == null ) 
				page = new Page ( defaultOrientation, defaultUnit, defaultSize, defaultRotation );
			
			pagesReferences.push ( (3+(arrayPages.length<<1))+' 0 R' );
			
			arrayPages.push ( page );
			
			page.number = pagesReferences.length;
			
			if ( state == PDF.STATE_0 ) 
				open();
			
			if( nbPages > 0 )
			{
				inFooter = true;
				footer();
				inFooter = false;
				finishPage();
			}
      
      currentPage = page;
      
      setUnit(currentPage.unit);
			
			startPage ( page != null ? page.orientation : defaultOrientation );
			
			/*
			if ( strokeColor != null ) 
				lineStyle ( strokeColor, strokeThickness, strokeFlatness, strokeAlpha, windingRule, strokeBlendMode, strokeDash, strokeCaps, strokeJoints, strokeMiter );
			
			if ( fillColor != null ) 
				beginFill( fillColor );*/
			
			if ( textColor != null ) 
				textStyle ( textColor, textAlpha, textRendering, textSpace, textSpace, textScale, textLeading );
			
			if ( currentFont != null ) 
				setFont ( currentFont, fontSizePt );
			else setFont( CoreFontCache.getFont ( FontFamily.HELVETICA ), 9);
			
			inHeader = true;
			header();
			inHeader = false;
			
			dispatcher.dispatchEvent( new PageEvent ( PageEvent.ADDED, currentPage ) );
			
			return page;
		}
		
		/**
		 * Lets you retrieve a Page object.
		 *
		 * @param page page number, from 1 to total numbers of pages
		 * @return Page
		 * @example
		 * This example shows how to retrieve the first page :
		 * <div class="listing">
		 * <pre>
		 *
		 * var page:Page = myPDF.getPage ( 1 );
		 * </pre>
		 * </div>
		 */
		public function getPage ( index:int ):Page
		{
			var lng:int = arrayPages.length;
			if ( index > 0 && index <= lng ) 
				return arrayPages [int(index-1)];
			else throw new RangeError ("Can't retrieve page " + index + ". "+lng+" page(s) available.");
		}
		
		/**
		 * Lets you retrieve all the PDF pages.
		 *
		 * @return Array
		 * @example
		 * This example shows how to retrieve all the PDF pages :
		 * <div class="listing">
		 * <pre>
		 *
		 * var pdfPages:Array = myPDF.getPages ();
		 *
		 * for each ( var p:Page in pdfPages ) trace( p );
		 * 
		 * outputs :
		 * 
		 * [Page orientation=Portrait width=210 height=297]
		 * [Page orientation=Landscape width=297 height=210]
		 * 
		 * </pre>
		 * </div>
		 */
		public function getPages ():Array
		{
			if ( arrayPages.length ) 
				return arrayPages;
			else throw new RangeError ("No pages available.");
		}
		
		/**
		 * Lets you move to a Page in the PDF.
		 *
		 * @param page page number, from 1 to total numbers of pages
		 * @example
		 * This example shows how to move to the first page :
		 * <div class="listing">
		 * <pre>
		 *
		 * myPDF.gotoPage ( 1 );
		 * // draw on the first page
		 * myPDF.lineStyle( new RGBColor(0xFF0000), 2, 0 );
		 * myPDF.drawRect( 60, 60, 40, 40 ); 
		 * </pre>
		 * </div>
		 */
		public function gotoPage ( index:int ):void
		{
			var lng:int = arrayPages.length;
			if ( index > 0 && index <= lng ) 
				currentPage = arrayPages[index-1];	
			else throw new RangeError ("Can't find page " + index + ". "+lng+" page(s) available.");
		}
		
		/**
		 * Lets you remove a Page from the PDF.
		 *
		 * @param page page number, from 1 to total numbers of pages
		 * @return Page
		 * @example
		 * This example shows how to remove the first page :
		 * <div class="listing">
		 * <pre>
		 * myPDF.removePage ( 1 );
		 * </pre>
		 * </div>
		 * 
		 * If you want to remove pages each by each, you can combine removePage with getPageCount:
		 * <div class="listing">
		 * <pre>
		 * myPDF.removePage ( myPDFEncoder.getPageCount() );
		 * </pre>
		 * </div>
		 */
		public function removePage ( index:int ):Page
		{
			if ( index > 0 && index <= arrayPages.length ) 
				return arrayPages.splice ( index-1, 1 )[0];
			else throw new RangeError ("Cannot remove page " + index + ".");
		}
		
		/**
		 * Lets you remove all the pages from the PDF.
		 *
		 * @example
		 * This example shows how to remove all the pages :
		 * <div class="listing">
		 * <pre>
		 * myPDF.removeAllPages();
		 * </pre>
		 * </div>
		 */
		public function removeAllPages ():void 
		{	
			arrayPages = new Array();
			pagesReferences = new Array();
		}
		
		/**
		 * Lets you retrieve the current Page.
		 *
		 * @return Page A Page object
		 * @example
		 * This example shows how to retrieve the current page :
		 * <div class="listing">
		 * <pre>
		 *
		 * var page:Page = myPDF.getCurrentPage ();
		 * </pre>
		 * </div>
		 */
		public function getCurrentPage ():Page
		{
			if ( arrayPages.length > 0 ) 
				return currentPage;
			else throw new RangeError ("Can't retrieve the current page, " + arrayPages.length + " pages available.");
		}
		
		/**
		 * Lets you retrieve the number of pages in the PDF document.
		 *
		 * @return int Number of pages in the PDF
		 * @example
		 * This example shows how to retrieve the number of pages :
		 * <div class="listing">
		 * <pre>
		 *
		 * var totalPages:int = myPDF.totalPages;
		 * </pre>
		 * </div>
		 */
		public function get totalPages():int
		{
			return arrayPages.length;
		}
		
		/**
		 * Lets you insert a line break for text.
		 *
		 * @param height Line break height
		 * @example
		 * This example shows how to add a line break :
		 * <div class="listing">
		 * <pre>
		 *
		 * myPDF.newLine ( 10 );
		 * </pre>
		 * </div>
		 */
		public function newLine ( height:*='' ):void
		{
			currentX = leftMargin;
			currentY += (height is String) ? lasth : height;
		}
		
		/**
		 * Lets you retrieve the X position for the current page.
		 *
		 * @return Number the X position
		 */
		public function getX ():Number
		{
			return currentX;
		}
		
		/**
		 * Lets you retrieve the Y position for the current page.
		 *
		 * @return Number the Y position
		 */
		public function getY ():Number
		{
			return currentY;
		}
		
		/**
		 * Lets you specify the X position for the current page.
		 *
		 * @param x The X position
		 */
		public function setX ( x:Number ):void
		{
			if (acceptPageBreak()) 
				currentX = ( x >= 0 ) ? x : currentPage.w + x;	
			else currentX = x;
		}
		
		/**
		 * Lets you specify the Y position for the current page.
		 *
		 * @param y The Y position
		 */
		public function setY ( y:Number ):void
		{
			if (acceptPageBreak()) 
			{
				currentX = leftMargin;
				currentY = ( y >= 0 ) ? y : currentPage.h + y;
			} else currentY = y;
		}
		
		/**
		 * Lets you specify the X and Y position for the current page.
		 *
		 * @param x The X position
		 * @param y The Y position
		 */
		public function setXY ( x:Number, y:Number ):void
		{
			setY( y );
			setX( x );
		}
		
		/**
		 * Returns the default PDF Size.
		 * 
		 * @return Size
		 * 
		 */		
		public function getDefaultSize ():Size
		{
			return defaultSize;	
		}
		
		/**
		 * Returns the default PDF orientation.
		 * 
		 * @return String
		 * 
		 */		
		public function getDefaultOrientation ():String 
		{
			return defaultOrientation;	
		}
		
		/**
		 * Returns the default PDF unit unit.
		 * 
		 * @return String
		 * 
		 */		
		public function getDefaultUnit ():String 
		{
			return defaultUnit;
		}
		
		/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		/*
		* AlivePDF transform API
		*
		* skew()
		* rotate()
		*
		*/
		/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		
		/**
		 * Allows you to skew any content drawn after the skew() call  
		 * @param ax X skew angle
		 * @param ay Y skew angle
		 * @param x X position
		 * @param y Y position
		 * 
		 */		
		public function skew(ax:Number, ay:Number, x:Number=-1, y:Number=-1):void
		{
			if(x == -1)
				x = getX();
			
			if(y == -1)
				y = getY();
			
			if(ax == 90 || ay == 90)
				throw new RangeError("Please use values between -90° and 90° for skewing.");
			
			x *= k;
			y = (currentPage.h - y) * k;
			ax *= Math.PI / 180;
			ay *= Math.PI / 180;
			matrix.identity();
			matrix.a = 1;
			matrix.b = Math.tan(ay);
			matrix.c = Math.tan(ax);
			matrix.d = 1;
			getMatrixTransformPoint(x, y);
			transform(matrix);
		}
		
		/**
		 * Allows you to rotate any content drawn after the rotate() call  
		 * @param angle Rotation angle
		 * @param x X position
		 * @param y Y position
		 * 
		 */	
		/*
		public function rotate(angle:Number, x:Number=-1, y:Number=-1, relative:Boolean=true):void
		{
			if(x == -1)
				x = getX();
			
			if(y == -1)
				y = getY();
			
			if ( this.angle != 0 )
				write('Q');
			
			this.angle = angle;
			
			if ( this.angle != 0 )
			{
				angle *= Math.PI / 180;
				x *= k;
				y = (currentPage.h - y) * k;
				matrix.identity();
				matrix.rotate(-angle);
				getMatrixTransformPoint(x, y);
				transform(matrix);
			}
			
			if (!relative)
				write('Q');
		}*/
		
		public function rotate(angle:Number, x:Number=-1, y:Number=-1):void
		{
			if(x == -1)
				x = getX();
			
			if(y == -1)
				y = getY();
			
			angle *= Math.PI / 180;
			x *= k;
			y = (currentPage.h - y) * k;
			matrix.identity();
			matrix.rotate(-angle);
			getMatrixTransformPoint(x, y);
			transform(matrix);
		}
		
		/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		/*
		* AlivePDF Header and Footer API
		*
		* header()
		* footer()
		*/
		/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		
		public function header(headerText:String=''):void
		{
			
/*			//to be overriden by subclassing (uncomment for a demo )
			var newFont:CoreFont = CoreFontCache.getFont ( FontFamily.HELVETICA );
			this.setFont(newFont, 12);
			this.textStyle( new RGBColor (0x000000) );
			this.addCell(80);
			this.addCell(30,10,headerText,1,0, Align.CENTER);
			this.newLine(20);*/
		}
		
		public  function footer(footerText:String='', showPageNumber:Boolean=false,position:String="left"):void
		{
			
/*			//to be overriden by subclassing (uncomment for a demo )
			
			switch(position){
				case "left":
									this.setXY (15, -15);
									break;
				case "center":
									this.setXY(100,-15);
									break;
				case "right":
									this.setXY(this.getMargins().width * 0.5,-15);
									break;
			}
			//this.setXY (15, -15);
			var newFont:CoreFont = CoreFontCache.getFont ( FontFamily.HELVETICA );
			this.setFont(newFont, 8);
			this.textStyle( new RGBColor (0x000000) );
			if(showPageNumber){
			this.addCell(0,10, footerText+(totalPages-1),0,0,'C');
			}else{
				this.addCell(0,10, footerText,0,0, Align.CENTER);
			}
			this.newLine(20);*/
		}
		
		/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		/*
		* AlivePDF Drawing API
		*
		* moveTo()
		* lineTo()
		* drawLine()
		* end()
		* curveTo()
		* lineStyle()
		* beginFill()
		* beginBitmapFill()
		* endFill()
		* drawRect()
		* drawRoundRect()
		* drawComplexRoundRect()
		* drawCircle()
		* drawEllipse()
		* drawPolygone()
		* drawRegularPolygone()
		* drawPath()
		*/
		/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		
		/**
		 * Lets you specify the opacity for the next drawing operations, from 0 (100% transparent) to 1 (100% opaque).
		 *
		 * @param alpha Opacity
		 * @param blendMode Blend mode, can be Blend.DIFFERENCE, BLEND.HARDLIGHT, etc.
		 * @example
		 * This example shows how to set the transparency to 50% for any following drawing, image or text operation :
		 * <div class="listing">
		 * <pre>
		 *
		 * myPDF.setAlpha ( .5 );
		 * </pre>
		 * </div>
		 */	
		public function setAlpha ( alpha:Number, blendMode:String='Normal' ):void
		{
			var graphicState:int = addExtGState( { 'ca' : alpha, 'SA' : true, 'CA' : alpha, 'BM' : '/' + blendMode } );
			setExtGState ( graphicState );
		}
		
		/**
		 * Lets you move the current drawing point to the specified destination.
		 *
		 * @param x X position
		 * @param y Y position
		 * @example
		 * This example shows how to move the pen to 120,200 :
		 * <div class="listing">
		 * <pre>
		 *
		 * myPDF.moveTo ( 120, 200 );
		 * </pre>
		 * </div>
		 */
		public function moveTo ( x:Number, y:Number ):void
		{
			write ( x*k + " " + (currentPage.h-y)*k + " m");
		}
		
		/**
		 * Lets you draw a stroke from the current point to the new point.
		 *
		 * @param x X position
		 * @param y Y position
		 * @example
		 * This example shows how to draw some dashed lines in the current page with specific caps style and joint style :
		 * <br><b>Important : Always call the end() method when you're done</b>
		 * <div class="listing">
		 * <pre>
		 *
		 * myPDF.lineStyle( new RGBColor ( 0x990000 ), 1, 1 );
		 * myPDF.moveTo ( 10, 20 );
		 * myPDF.lineTo ( 40, 20 );
		 * myPDF.lineTo ( 40, 40 );
		 * myPDF.lineTo ( 10, 40 );
		 * myPDF.lineTo ( 10, 20 );
		 * myPDF.end();
		 * </pre>
		 * </div>
		 */
		public function lineTo ( x:Number, y:Number ):void
		{
			write ( x*k + " " + (currentPage.h-y)*k+ " l");
		}
		
		/**
		 * The end method closes the stroke.
		 *
		 * @example
		 * This example shows how to draw some dashed lines in the current page with specific caps style and joint style :
		 * <br><b>Important : Always call the end() method when you're done</b>
		 * <div class="listing">
		 * <pre>
		 * 
		 * myPDF.lineStyle( new RGBColor ( 0x990000 ), 1, 1 );
		 * myPDF.moveTo ( 10, 20 );
		 * myPDF.lineTo ( 40, 20 );
		 * myPDF.lineTo ( 40, 40 );
		 * myPDF.lineTo ( 10, 40 );
		 * myPDF.lineTo ( 10, 20 );
		 * // end the stroke
		 * myPDF.end();
		 * </pre>
		 * </div>
		 */
		public function end (closePath:Boolean=true):void
		{
			if ( !filled )
			{
				if (closePath)
					write ("s");
				else write ("S");
			}

			else if ( !stroking )
				write (windingRule == WindingRule.NON_ZERO ? "f" : "f*");
			else write (windingRule == WindingRule.NON_ZERO ? "b" : "b*");
			
			if ( stroking )
				stroking = false;
		}
		
		/**
		 * 
		 * 
		 * 
		 */
		public function drawLine(x1:Number, y1:Number, x2:Number, y2:Number):void
		{
			write(sprintf('%.2F %.2F m %.2F %.2F l S',x1*k,(currentPage.h-y1)*k,x2*k,(currentPage.h-y2)*k));
		}
		
		/**
		 * The curveTo method draws a cubic bezier curve.
		 * 
		 * @param controlX1
		 * @param controlY1
		 * @param controlX2
		 * @param controlY2
		 * @param finalX3
		 * @param finalY3
		 * @example
		 * This example shows how to draw some curves lines in the current page :
		 * <br><b>Important : Always call the end() method when you're done</b>
		 * <div class="listing">
		 * <pre>
		 *
		 * myPDF.lineStyle ( new RGBColor ( 0x990000 ), 1, 1, null, CapsStyle.NONE, JointStyle.MITER );
		 * myPDF.moveTo ( 10, 200 );
		 * myPDF.curveTo ( 120, 210, 196, 280, 139, 195 );
		 * myPDF.curveTo ( 190, 110, 206, 190, 179, 205 );
		 * myPDF.end();
		 * </pre>
		 * </div>
		 */	
		public function curveTo ( controlX1:Number, controlY1:Number, controlX2:Number, controlY2:Number, finalX3:Number, finalY3:Number ):void
		{
			write (controlX1*k + " " + (currentPage.h-controlY1)*k + " " + controlX2*k + " " + (currentPage.h-controlY2)*k+ " " + finalX3*k + " " + (currentPage.h-finalY3)*k + " c");
		}
		
		/**
		 * Sets the stroke style.
		 * 
		 * @param color
		 * @param thickness
		 * @param flatness
		 * @param alpha
		 * @param rule
		 * @param blendMode
		 * @param style
		 * @param caps
		 * @param joints
		 * @param miterLimit
		 * @example
		 * This example shows how to draw a star with an "even odd" rule :
		 * <div class="listing">
		 * <pre>
		 *
		 * myPDF.lineStyle( new RGBColor ( 0x990000 ), 1, 0, 1, Rule.EVEN_ODD, null, null, Caps.NONE, Joint.MITER );
		 * 
		 * myPDF.beginFill( new RGBColor ( 0x009900 ) );
		 * myPDF.moveTo ( 66, 10 );
		 * myPDF.lineTo ( 23, 127 );
		 * myPDF.lineTo ( 122, 50 );
		 * myPDF.lineTo ( 10, 49 );
		 * myPDF.lineTo ( 109, 127 );
		 * myPDF.end();
		 * 
		 * </pre>
		 * </div>
		 * This example shows how to draw a star with an "non-zero" winding rule :
		 * <div class="listing">
		 * <pre>
		 *
		 * myPDF.lineStyle( new RGBColor ( 0x990000 ), 1, 0, 1, Rule.NON_ZERO_WINDING, null, null, Caps.NONE, Joint.MITER );
		 * 
		 * myPDF.beginFill( new RGBColor ( 0x009900 ) );
		 * myPDF.moveTo ( 66, 10 );
		 * myPDF.lineTo ( 23, 127 );
		 * myPDF.lineTo ( 122, 50 );
		 * myPDF.lineTo ( 10, 49 );
		 * myPDF.lineTo ( 109, 127 );
		 * myPDF.end();
		 * 
		 * </pre>
		 * </div>
		 * 
		 */	
		public function lineStyle ( color:IColor, thickness:Number=1, flatness:Number=0, alpha:Number=1, rule:String="NonZeroWinding", blendMode:String="Normal", style:DashedLine=null, caps:String=null, joints:String=null, miterLimit:Number=3 ):void
		{
			stroking = true;
			setStrokeColor ( strokeColor = color );
			strokeThickness = thickness;
			strokeAlpha = alpha;
			strokeFlatness = flatness;
			windingRule = rule;
			strokeBlendMode = blendMode;
			strokeDash = style;
			strokeCaps = caps;
			strokeJoints = joints;
			strokeMiter = miterLimit;
			setAlpha ( alpha, blendMode );
			if ( nbPages > 0 ) 
				write ( sprintf ('%.2f w', thickness*k) );
			write ( flatness + " i ");
			write ( style != null ? style.pattern : '[] 0 d' );
			if ( caps != null ) 
				write ( caps );
			if ( joints != null ) 
				write ( joints );
			write ( miterLimit + " M" );
		}
		
		/**
		 * Sets the stroke color for different color spaces CMYK, RGB or DEVICEGRAY.
		 */
		protected function setStrokeColor ( color:IColor, tint:Number=100 ):void
		{
			var op:String;
			
			if ( color is RGBColor )
			{
				op = "RG";
				var r:Number = (color as RGBColor).r/255;
				var g:Number = (color as RGBColor).g/255;
				var b:Number = (color as RGBColor).b/255;
				write ( r + " " + g + " " + b + " " + op );
				
			} else if ( color is CMYKColor )
			{	
				op = "K";
				var c:Number = (color as CMYKColor).cyan*.01;
				var m:Number = (color as CMYKColor).magenta*.01;
				var y:Number = (color as CMYKColor).yellow*.01;
				var k:Number = (color as CMYKColor).black*.01;
				write ( c + " " + m + " " + y + " " + k + " " + op );
				
			} else if ( color is SpotColor )
			{
				if ( spotColors.indexOf (color) == -1 ) 
					spotColors.push ( color );
				write (sprintf('/CS%d CS %.3F SCN', (color as SpotColor).i, tint*.01));
				
			} else 
			{
				op = "G";
				var gray:Number = (color as GrayColor).gray*.01;
				write ( gray + " " + op );
			}
		}
		
		/**
		 * Sets the text color for different color spaces CMYK, RGB, or DEVICEGRAY.
		 * @param
		 */
		protected function setTextColor ( color:IColor, tint:Number=100 ):void
		{
			var op:String;
			
			if ( color is RGBColor )
			{
				op = !textRendering ? "rg" : "RG"
				var r:Number = (color as RGBColor).r/255;
				var g:Number = (color as RGBColor).g/255;
				var b:Number = (color as RGBColor).b/255;
				addTextColor = r + " " + g + " " + b + " " + op;
				
			} else if ( color is CMYKColor )
			{
				op = !textRendering ? "k" : "K"
				var c:Number = (color as CMYKColor).cyan*.01;
				var m:Number = (color as CMYKColor).magenta*.01;
				var y:Number = (color as CMYKColor).yellow*.01;
				var k:Number = (color as CMYKColor).black*.01;
				addTextColor = c + " " + m + " " + y + " " + k + " " + op;
				
			} else if ( color is SpotColor )
			{
				if ( spotColors.indexOf (color) == -1 ) 
					spotColors.push ( color );
				addTextColor = sprintf('/CS%d cs %.3F scn', (color as SpotColor).i, tint*.01);
				colorFlag = (fillColor != textColor);
				
			} else
			{
				op = !textRendering ? "g" : "G"
				var gray:Number = (color as GrayColor).gray*.01;
				addTextColor = gray + " " + op;
			}
		}
		
		/**
		 * Sets the filling color for different color spaces CMYK, RGB or DEVICEGRAY.
		 *
		 * @param color Color object, can be CMYKColor, GrayColor, or RGBColor
		 * @example
		 * This example shows how to create a red rectangle in the current page :
		 * <div class="listing">
		 * <pre>
		 *
		 * myPDF.beginFill ( new RGBColor ( 0x990000 ) );
		 * myPDF.drawRect ( new Rectangle ( 10, 26, 50, 25 ) );
		 * </pre>
		 * </div>
		 */
		public function beginFill ( color:IColor, tint:Number=100 ):void
		{
			filled = true;
			fillColor = color;
			
			var op:String;
			
			if ( color is RGBColor )
			{
				op = "rg";
				var r:Number = (color as RGBColor).r/255;
				var g:Number = (color as RGBColor).g/255;
				var b:Number = (color as RGBColor).b/255;
				write ( r + " " + g + " " + b + " " + op );
				
			} else if ( color is CMYKColor )
			{
				op = "k";
				var c:Number = (color as CMYKColor).cyan*.01;
				var m:Number = (color as CMYKColor).magenta*.01;
				var y:Number = (color as CMYKColor).yellow*.01;
				var k:Number = (color as CMYKColor).black*.01;
				write ( c + " " + m + " " + y + " " + k + " " + op );
				
			} else if ( color is SpotColor )
			{
				if ( spotColors.indexOf (color) == -1 ) 
					spotColors.push ( color );
				write (sprintf('/CS%d cs %.3F scn', (color as SpotColor).i, tint*.01));
				colorFlag = (fillColor != textColor);
				
			} else
			{
				op = "g";
				var gray:Number = (color as GrayColor).gray*.01;
				write ( gray + " " + op );
			}
		}
		
		/**
		 * The beginBitmapFill method fills a surface with a bitmap as a texture.
		 * 
		 * @param bitmap A flash.display.BitmapData object
		 * @param matrix A flash.geom.Matrix object
		 * 
		 * @example
		 * This example shows how to create a 100*100 rectangle filled with a bitmap texture :
		 * <div class="listing">
		 * <pre>
		 *
		 * var texture:BitmapData = new CustomBitmapData (0,0);
		 * 
		 * myPDF.beginBitmapFill( texture );
		 * myPDF.drawRect ( new Rectangle ( 0, 0, 100, 100 ) );
		 * </pre>
		 * </div>
		 * 
		 */
		public function beginBitmapFill ( bitmap:BitmapData, matrix:Matrix=null ):void
		{
			bitmapFilled = true;
			bitmapFillBuffer = new Shape();
			bitmapFillBuffer.graphics.beginBitmapFill( bitmap, matrix );
		}
		
		/**
		 * Ends all previous filling.
		 *
		 * @example
		 * This example shows how to create a red rectangle in the current page :
		 * <div class="listing">
		 * <pre>
		 *
		 * myPDF.beginFill ( new RGBColor ( 0x990000 ) );
		 * myPDF.moveTo ( 10, 10 );
		 * myPDF.lineTo ( 20, 90 );
		 * myPDF.lineTo ( 90, 50);
		 * myPDF.end()
		 * myPDF.endFill();
		 * </pre>
		 * </div>
		 */
		public function endFill ():void
		{
			if ( !bitmapFilled ) 
				filled = false;
			else bitmapFilled = false;
		}
		
		/**
		 * The drawRect method draws a rectangle shape.
		 * 
		 * @param rect A flash.geom.Rectange object
		 * @example
		 * This example shows how to create a blue rectangle in the current page :
		 * <div class="listing">
		 * <pre>
		 *
		 * myPDF.lineStyle ( new RGBColor ( 0x990000 ), 1, .3, null, CapsStyle.ROUND, JointStyle.MITER );
		 * myPDF.beginFill ( new RGBColor ( 0x009900 ) );
		 * myPDF.drawRect ( new Rectangle ( 20, 46, 100, 45 ) );
		 * </pre>
		 * </div>
		 */
		public function drawRect ( rect:Rectangle ):void
		{
			if ( !bitmapFilled ) 
			{
				var style:String = getCurrentStyle(style);
				write (sprintf('%.2f %.2f %.2f %.2f re %s', (rect.x)*k, (currentPage.h-(rect.y))*k, rect.width*k, -rect.height*k, style));
				if ( stroking )
					stroking = false;
			} else 
			{
				bitmapFillBuffer.graphics.drawRect ( rect.x, rect.y, rect.width, rect.height );
				addImage(bitmapFillBuffer, null, rect.x, rect.y, rect.width, rect.height);
			}
		}
		
		/**
		 * The drawRoundedRect method draws a rounded rectangle shape.
		 * 
		 * @param rect A flash.geom.Rectange object
		 * @param ellipseWidth Angle radius
		 * @example
		 * This example shows how to create a rounded green rectangle in the current page :
		 * <div class="listing">
		 * <pre>
		 *
		 * myPDF.lineStyle ( new RGBColor ( 0x00FF00 ), 1, 0, .3, BlendMode.NORMAL, null, CapsStyle.ROUND, JointStyle.MITER );
		 * myPDF.beginFill ( new RGBColor ( 0x009900 ) );
		 * myPDF.drawRoundRect ( new Rectangle ( 20, 46, 100, 45 ), 20 );
		 * </pre>
		 * </div>
		 */
		public function drawRoundRect ( rect:Rectangle, ellipseWidth:Number ):void
		{	
			if ( !bitmapFilled )
			{
				drawRoundRectComplex ( rect, ellipseWidth, ellipseWidth, ellipseWidth, ellipseWidth );
				if ( stroking )
					stroking = false;
			} else
			{
				bitmapFillBuffer.graphics.drawRoundRect( rect.x, rect.y, rect.width, rect.height, ellipseWidth, ellipseWidth );
				addImage(bitmapFillBuffer, null, rect.x, rect.y);	
			}
		}
		
		/**
		 * The drawComplexRoundRect method draws a rounded rectangle shape.
		 * 
		 * @param rect A flash.geom.Rectange object
		 * @param topLeftEllipseWidth Angle radius
		 * @param bottomLeftEllipseWidth Angle radius
		 * @param topRightEllipseWidth Angle radius
		 * @param bottomRightEllipseWidth Angle radius
		 * 
		 * @example
		 * This example shows how to create a complex rounded green rectangle (different angles radius) in the current page :
		 * <div class="listing">
		 * <pre>
		 *
		 * myPDF.lineStyle ( new RGBColor ( 0x00FF00 ), 1, 0, .3 );
		 * myPDF.beginFill ( new RGBColor ( 0x007700 ) );
		 * myPDF.drawComplexRoundRect( new Rectangle ( 5, 5, 40, 40 ), 16, 16, 8, 8 );
		 * </pre>
		 * </div>
		 * 
		 */		
		public function drawRoundRectComplex ( rect:Rectangle, topLeftEllipseWidth:Number, topRightEllipseWidth:Number, bottomLeftEllipseWidth:Number, bottomRightEllipseWidth:Number ):void
		{	
			if ( !bitmapFilled )
			{
				var k:Number = k;
				var hp:Number = currentPage.h;
				var MyArc:Number = 4/3 * (Math.sqrt(2) - 1);
				write(sprintf('%.2f %.2f m',(rect.x+topLeftEllipseWidth)*k,(hp-rect.y)*k ));
				var xc:Number = rect.x+rect.width-topRightEllipseWidth;
				var yc:Number = rect.y+topRightEllipseWidth;
				write(sprintf('%.2f %.2f l', xc*k,(hp-rect.y)*k ));
				curve(xc + topRightEllipseWidth*MyArc, yc - topRightEllipseWidth, xc + topRightEllipseWidth, yc - topRightEllipseWidth*MyArc, xc + topRightEllipseWidth, yc);
				xc = rect.x+rect.width-bottomRightEllipseWidth ;
				yc = rect.y+rect.height-bottomRightEllipseWidth;
				write(sprintf('%.2f %.2f l',(rect.x+rect.width)*k,(hp-yc)*k));
				curve(xc + bottomRightEllipseWidth, yc + bottomRightEllipseWidth*MyArc, xc + bottomRightEllipseWidth*MyArc, yc + bottomRightEllipseWidth, xc, yc + bottomRightEllipseWidth);
				xc = rect.x+bottomLeftEllipseWidth;
				yc = rect.y+rect.height-bottomLeftEllipseWidth;
				write(sprintf('%.2f %.2f l',xc*k,(hp-(rect.y+rect.height))*k));
				curve(xc - bottomLeftEllipseWidth*MyArc, yc + bottomLeftEllipseWidth, xc - bottomLeftEllipseWidth, yc + bottomLeftEllipseWidth*MyArc, xc - bottomLeftEllipseWidth, yc);
				xc = rect.x+topLeftEllipseWidth;
				yc = rect.y+topLeftEllipseWidth;
				write(sprintf('%.2f %.2f l',(rect.x)*k,(hp-yc)*k ));
				curve(xc - topLeftEllipseWidth, yc - topLeftEllipseWidth*MyArc, xc - topLeftEllipseWidth*MyArc, yc - topLeftEllipseWidth, xc, yc - topLeftEllipseWidth);
				var style:String = getCurrentStyle(style);
				write(style);
				if ( stroking )
					stroking = false;
			} else 
			{
				bitmapFillBuffer.graphics.drawRoundRectComplex( rect.x, rect.y, rect.width, rect.height, topLeftEllipseWidth, topRightEllipseWidth, bottomLeftEllipseWidth, bottomRightEllipseWidth );
				addImage(bitmapFillBuffer, null, rect.x, rect.y);	
			}
		}
		
		/**
		 * The drawEllipse method draws an ellipse.
		 * 
		 * @param x X Position
		 * @param y Y Position
		 * @param radiusX X Radius
		 * @param radiusY Y Radius
		 * @example
		 * This example shows how to create a rounded red ellipse in the current page :
		 * <div class="listing">
		 * <pre>
		 *
		 * myPDF.lineStyle ( new RGBColor ( 0x990000 ), 1, .3, new DashedLine ([0, 1, 2, 6]), CapsStyle.NONE, JointStyle.ROUND );
		 * myPDF.beginFill ( new RGBColor ( 0x990000 ) );
		 * myPDF.drawEllipse( 45, 275, 40, 15 );
		 * </pre>
		 * </div>
		 */
		public function drawEllipse ( x:Number, y:Number, radiusX:Number, radiusY:Number ):void
		{
			if ( !bitmapFilled )
			{
				var style:String = getCurrentStyle(style);
				
				var lx:Number = 4/3*(1.41421356237309504880-1)*radiusX;
				var ly:Number = 4/3*(1.41421356237309504880-1)*radiusY;
				var k:Number = k;
				var h:Number = currentPage.h;
				
				write(sprintf('%.2f %.2f m %.2f %.2f %.2f %.2f %.2f %.2f c',
					(x+radiusX)*k,(h-y)*k,
					(x+radiusX)*k,(h-(y-ly))*k,
					(x+lx)*k,(h-(y-radiusY))*k,
					x*k,(h-(y-radiusY))*k));
				write(sprintf('%.2f %.2f %.2f %.2f %.2f %.2f c',
					(x-lx)*k,(h-(y-radiusY))*k,
					(x-radiusX)*k,(h-(y-ly))*k,
					(x-radiusX)*k,(h-y)*k));
				write(sprintf('%.2f %.2f %.2f %.2f %.2f %.2f c',
					(x-radiusX)*k,(h-(y+ly))*k,
					(x-lx)*k,(h-(y+radiusY))*k,
					x*k,(h-(y+radiusY))*k));
				write(sprintf('%.2f %.2f %.2f %.2f %.2f %.2f c %s',
					(x+lx)*k,(h-(y+radiusY))*k,
					(x+radiusX)*k,(h-(y+ly))*k,
					(x+radiusX)*k,(h-y)*k,
					style));
				if ( stroking )
					stroking = false;
			} else
			{
				bitmapFillBuffer.graphics.drawEllipse( x, y, radiusX, radiusY );
				addImage(bitmapFillBuffer, null, x, y);	
			}
		}
		
		/**
		 * The drawCircle method draws a circle.
		 * 
		 * @param x X Position
		 * @param y Y Position
		 * @param radius Circle Radius
		 * @example
		 * This example shows how to create a rounded red ellipse in the current page :
		 * <div class="listing">
		 * <pre>
		 *
		 * myPDF.beginFill ( new RGBColor ( 0x990000 ) );
		 * myPDF.drawCircle ( 30, 180, 20 );
		 * </pre>
		 * </div>
		 */
		public function drawCircle( x:Number, y:Number, radius:Number ):void
		{
			drawEllipse ( x, y, radius, radius );
		}
		
		/**
		 * The drawPolygone method draws a polygone.
		 * 
		 * @param points Array of points
		 * @example
		 * This example shows how to create a polygone with a few points :
		 * <div class="listing">
		 * <pre>
		 *
		 * myPDF.beginFill ( new RGBColor ( 0x990000 ) );
		 * myPDF.drawPolygone ( [89, 40, 20, 90, 40, 50, 10, 60, 70, 90] );
		 * </pre>
		 * </div>
		 */
		public function drawPolygone ( points:Array ):void
		{
			var lng:int = points.length;
			var i:int = 0;
			var pos:int;
			
			while ( i < lng )
			{
				pos = int(i+1);
				i == 0 ? moveTo ( points[i], points[pos] ) : lineTo ( points[i], points[pos] );
				i+=2;
			}
			
			end();
		}
		
		/**
		 * The drawSector method draws a sector, which allows you to draw a pie chart.
		 * 
		 * @param xCenter
		 * @param yCenter
		 * @param radius
		 * @param a
		 * @param b
		 * @param style
		 * @param clockWise
		 * @param angleOrigin
		 * @example
		 * This example shows how to create a nice pie chart :
		 * <div class="listing">
		 * <pre>
		 *
		 * var xc:int = 105;
		 * var yc:int = 60;
		 * var radius:int = 40;
		 * 
		 * myPDF.lineStyle( new RGBColor ( 0x000000 ), .1 );
		 * myPDF.beginFill( new RGBColor ( 0x0099CC ) );
		 * myPDF.drawSector(xc, yc, radius, 20, 120);
		 * myPDF.beginFill( new RGBColor ( 0x336699 ) );
		 * myPDF.drawSector(xc, yc, radius, 120, 250);
		 * myPDF.beginFill( new RGBColor ( 0x6598FF ) );
		 * myPDF.drawSector(xc, yc, radius, 250, 20);
		 * </pre>
		 * </div>
		 */		
		public function drawSector(xCenter:Number, yCenter:Number, radius:Number, a:Number, b:Number, style:String='FD', clockWise:Boolean=true, angleOrigin:Number=90):void
		{
			var d0:Number = a - b;
			var d:Number;
			var b:Number;
			var a:Number;
			var op:String;
			
			if(clockWise)
			{
				d = b;
				b = angleOrigin - a;
				a = angleOrigin - d;
			}else
			{
				b += angleOrigin;
				a += angleOrigin;
			}
			
			while(a<0)
				a += 360;
			while(a>360)
				a -= 360;
			while(b<0)
				b += 360;
			while(b>360)
				b -= 360;
			
			if (a > b)
				b += 360;
			
			b = b/360*2*Math.PI;
			a = a/360*2*Math.PI;;
			d = b - a;
			
			if (d == 0 && d0 != 0)
				d = 2*Math.PI;
			
			var hp:Number = currentPage.h;
			var myArc:Number;
			
			if (Math.sin(d/2))
				myArc = 4/3*(1-Math.cos(d/2))/Math.sin(d/2)*radius;
			else
				myArc = 0;
			
			//first put the center
			write(sprintf('%.2F %.2F m',(xCenter)*k,(hp-yCenter)*k));
			//put the first point
			write(sprintf('%.2F %.2F l',(xCenter+radius*Math.cos(a))*k,((hp-(yCenter-radius*Math.sin(a)))*k)));
			
			//draw the arc
			if (d < Math.PI/2)
			{
				arc(xCenter+radius*Math.cos(a)+myArc*Math.cos(Math.PI/2+a),
					yCenter-radius*Math.sin(a)-myArc*Math.sin(Math.PI/2+a),
					xCenter+radius*Math.cos(b)+myArc*Math.cos(b-Math.PI/2),
					yCenter-radius*Math.sin(b)-myArc*Math.sin(b-Math.PI/2),
					xCenter+radius*Math.cos(b),
					yCenter-radius*Math.sin(b)
				);
			}else
			{
				b = a + d/4;
				myArc = 4/3*(1-Math.cos(d/8))/Math.sin(d/8)*radius;
				arc(xCenter+radius*Math.cos(a)+myArc*Math.cos(Math.PI/2+a),
					yCenter-radius*Math.sin(a)-myArc*Math.sin(Math.PI/2+a),
					xCenter+radius*Math.cos(b)+myArc*Math.cos(b-Math.PI/2),
					yCenter-radius*Math.sin(b)-myArc*Math.sin(b-Math.PI/2),
					xCenter+radius*Math.cos(b),
					yCenter-radius*Math.sin(b)
				);
				a = b;
				b = a + d/4;
				arc(xCenter+radius*Math.cos(a)+myArc*Math.cos(Math.PI/2+a),
					yCenter-radius*Math.sin(a)-myArc*Math.sin(Math.PI/2+a),
					xCenter+radius*Math.cos(b)+myArc*Math.cos(b-Math.PI/2),
					yCenter-radius*Math.sin(b)-myArc*Math.sin(b-Math.PI/2),
					xCenter+radius*Math.cos(b),
					yCenter-radius*Math.sin(b)
				);
				a = b;
				b = a + d/4;
				arc(xCenter+radius*Math.cos(a)+myArc*Math.cos(Math.PI/2+a),
					yCenter-radius*Math.sin(a)-myArc*Math.sin(Math.PI/2+a),
					xCenter+radius*Math.cos(b)+myArc*Math.cos(b-Math.PI/2),
					yCenter-radius*Math.sin(b)-myArc*Math.sin(b-Math.PI/2),
					xCenter+radius*Math.cos(b),
					yCenter-radius*Math.sin(b)
				);
				a = b;
				b = a + d/4;
				arc(xCenter+radius*Math.cos(a)+myArc*Math.cos(Math.PI/2+a),
					yCenter-radius*Math.sin(a)-myArc*Math.sin(Math.PI/2+a),
					xCenter+radius*Math.cos(b)+myArc*Math.cos(b-Math.PI/2),
					yCenter-radius*Math.sin(b)-myArc*Math.sin(b-Math.PI/2),
					xCenter+radius*Math.cos(b),
					yCenter-radius*Math.sin(b)
				);
			}
			
			//terminate drawing
			if(style == SectorDrawingCommand.FILL)
				op = 'f';
			else if(style == SectorDrawingCommand.FILL_DRAW || style == SectorDrawingCommand.DRAW_FILL)
				op = 'b';
			else op = 's';
			
			write(op);
		}
		
		/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		/*
		* AlivePDF Gradient API
		* linearGradient()
		* radialGradient()
		*
		*/
		/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		
		public function linearGradient(x:Number, y:Number, width:Number, height:Number, col1:Array, col2:Array,coordinates:Array):void
		{
			clip(x,y,width,height);
			gradient(2,col1,col2,coordinates);
		}
		
		public function radialGradient(x:Number, y:Number, width:Number, height:Number, col1:Array, col2:Array, coordinates:Array):void
		{
			clip(x,y,width,height);
			gradient(3,col1,col2,coordinates);
		}
		
		public function clip(x:Number,y:Number,width:Number,height:Number):void
		{
			var s:String = 'q';
			s += sprintf(' %.2F %.2F %.2F %.2F re W n', x*k, (currentPage.h-y)*k, width*k, -height*k);
			s += sprintf(' %.3F 0 0 %.3F %.3F %.3F cm', width*k, height*k, x*k, (currentPage.h-(y+height))*k);
			write(s);
		}
		
		protected function gradient(gradientType:int, col1:Array, col2:Array, coords:Array):void
		{
			var n:int = gradients.length+1;
			if(col1[1] == null)
				col1[1] = col1[2] = col1[0];
			var colBuffer1:String = sprintf('%.3F %.3F %.3F',(col1[0]/255),(col1[1]/255),(col1[2]/255));
			if(col2[1] == null) 
				col2[1] = col2[2] = col2[0];
			var colBuffer2:String = sprintf('%.3F %.3F %.3F',(col2[0]/255),(col2[1]/255),(col2[2]/255));
			var gradient:ShadingType = gradients[n] = new ShadingType ( gradientType, coords, colBuffer1, colBuffer2 );
			write('/Sh'+n+' sh');
			write('Q');
		}
		
		protected function insertShaders():void
		{
			var coords:Array;
			var f1:int;
			
			for each (var grad:ShadingType in gradients)
			{  
				coords = grad.coords;
				
				if (grad.type == ShadingType.TYPE2 || grad.type == ShadingType.TYPE3)
				{
					newObj();
					write('<<');
					write('/FunctionType 2');
					write('/Domain [0.0 1.0]');
					write('/C0 ['+grad.col1+']');
					write('/C1 ['+grad.col2+']');
					write('/N 1');
					write('>>');
					write('endobj');
					f1 = n;
				}
				
				newObj();
				write('<<');
				write('/ShadingType '+grad.type);
				write('/ColorSpace /DeviceRGB');
				
				if( grad.type == ShadingType.TYPE2 )
				{
					write(sprintf('/Coords [%.3F %.3F %.3F %.3F]', coords[0], coords[1], coords[2], coords[3]));
					write('/Function '+f1+' 0 R');
					write('/Extend [true true] ');
					write('>>');
				}
				else if( grad.type == ShadingType.TYPE3 )
				{
					write(sprintf('/Coords [%.3F %.3F 0 %.3F %.3F %.3F]', coords[0], coords[1], coords[2], coords[3], coords[4]));
					write('/Function '+f1+' 0 R');
					write('/Extend [true true] ');
					write('>>');
				}
				else if( grad.type == ShadingType.TYPE6 )
				{
					write('/BitsPerCoordinate 16');
					write('/BitsPerComponent 8');
					write('/Decode[0 1 0 1 0 1 0 1 0 1]');
					write('/BitsPerFlag 8');
					write('/Length '+grad.stream.length);
					write('>>');
					buffer.writeBytes(grad.stream);
				}
				write('endobj');
				grad.id = n;
			}
		}
		
		/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		/*
		* AlivePDF clipping API
		*
		* clippingText()
		* clippingRect()
		* clippingRoundedRect()
		* clippingEllipse()
		* clippingCircle()
		* clippingPolygon()
		*
		*/
		/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		
		public function clippingText(x:Number, y:Number, text:String, outline:Boolean=false):void
		{
			var op:int = outline ? 5 : 7;
			write(sprintf('q BT %.2F %.2F Td %d Tr (%s) Tj ET',
				x*k,
				(currentPage.h-y)*k,
				op,
				escapeIt(text)));
		}
		
		public function clippingRect(x:Number, y:Number, width:Number, height:Number, outline:Boolean=false):void
		{
			var op:String = outline ? 'S' : 'n';
			write(sprintf('q %.2F %.2F %.2F %.2F re W %s',
				currentX*k,
				(currentPage.h-y)*k,
				width*k,-currentPage.h*k,
				op));
		}
		
		protected function arc(x1:Number, y1:Number, x2:Number, y2:Number, x3:Number, y3:Number):void
		{
			var h:Number = currentPage.h;
			write(sprintf('%.2F %.2F %.2F %.2F %.2F %.2F c ', x1*k, (h-y1)*k,
				x2*k, (h-y2)*k, x3*k, (h-y3)*k));
		}
		
		public function clippingRoundedRect(x:Number, y:Number, width:Number, height:Number, radius:Number, outline:Boolean=false):void
		{
			var hp:Number = currentPage.h;
			var op:String = outline ? 'S' : 'n';
			
			var myArc:Number = 4/3 * (Math.sqrt(2) - 1);
			
			write(sprintf('q %.2F %.2F m',(x+radius)*k,(hp-y)*k ));
			var xc:Number = x+width-radius;
			var yc:Number = y+radius;
			write(sprintf('%.2F %.2F l', xc*k,(hp-y)*k ));
			arc(xc + radius*myArc, yc - radius, xc + radius, yc - radius*myArc, xc + radius, yc);
			xc = x+width-radius ;
			yc = y+height-radius;
			write(sprintf('%.2F %.2F l',(x+width)*k,(hp-yc)*k));
			arc(xc + radius, yc + radius*myArc, xc + radius*myArc, yc + radius, xc, yc + radius);
			xc = x+radius ;
			yc = y+height-radius;
			write(sprintf('%.2F %.2F l',xc*k,(hp-(y+height))*k));
			arc(xc - radius*myArc, yc + radius, xc - radius, yc + radius*myArc, xc - radius, yc);
			xc = x+radius ;
			yc = y+radius;
			write(sprintf('%.2F %.2F l',(x)*k,(hp-yc)*k ));
			arc(xc - radius, yc - radius*myArc, xc - radius*myArc, yc - radius, xc, yc - radius);
			write(' W '+op);
		}
		
		public function clippingEllipse(x:Number, y:Number, ty:Number, ry:Number, outline:Boolean=false):void
		{
			var op:String = outline ? 'S' : 'n';
			var lx:Number = 4/3*(1.41421356237309504880-1)*ty;
			var ly:Number = 4/3*(1.41421356237309504880-1)*ry;
			var k:Number = k;
			var h:Number = currentPage.h;
			
			write(sprintf('q %.2F %.2F m %.2F %.2F %.2F %.2F %.2F %.2F c',
				(x+ty)*k,(h-y)*k,
				(x+ty)*k,(h-(y-ly))*k,
				(x+lx)*k,(h-(y-ry))*k,
				x*k,(h-(y-ry))*k));
			write(sprintf('%.2F %.2F %.2F %.2F %.2F %.2F c',
				(x-lx)*k,(h-(y-ry))*k,
				(x-ty)*k,(h-(y-ly))*k,
				(x-ty)*k,(h-y)*k));
			write(sprintf('%.2F %.2F %.2F %.2F %.2F %.2F c',
				(x-ty)*k,(h-(y+ly))*k,
				(x-lx)*k,(h-(y+ry))*k,
				x*k,(h-(y+ry))*k));
			write(sprintf('%.2F %.2F %.2F %.2F %.2F %.2F c W %s',
				(x+lx)*k,(h-(y+ry))*k,
				(x+ty)*k,(h-(y+ly))*k,
				(x+ty)*k,(h-y)*k,
				op));
		}
		
		public function clippingCircle(x:Number, y:Number, radius:Number, outline:Boolean=false):void
		{
			clippingEllipse(x, y, radius, radius, outline);
		}
		
		public function clippingPolygon(points:Array, outline:Boolean=false):void
		{
			var op:String = outline ? 'S' : 'n';
			var h:Number = currentPage.h;
			var k:Number = k;
			var points_string:String = '';
			
			for(var i:int = 0; i<points.length; i+=2)
			{
				points_string += sprintf('%.2F %.2F', points[i]*k, (h-points[int(i+1)])*k);
				if(i==0)
					points_string += ' m ';
				else
					points_string += ' l ';
			}
			
			write('q '+points_string+'h W '+op);
		}
		
		public function unsetClipping():void
		{
			write('Q');
		}
		
		public function clippedCell(width:Number, height:Number=0, text:String='', border:*=0, ln:Number=0, align:String='', fill:Number=0, link:ILink=null):void
		{
			if(border || fill || currentY+height>pageBreakTrigger)
			{
				addCell(width,height,'',border,0,'',fill);
				currentX -= width;
			}
			clippingRect(currentX,currentY,width,height);
			addCell(width,height,text,'',ln,align,fill,link);
			unsetClipping();
		}
		
		/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		/*
		* AlivePDF BarCodde API
		*
		* addCodaBar()
		*
		*/
		/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		
		/**
		 * Allows you to add a CodaBar (Monarch) to the current page at any position.
		 * @param codaBar
		 
		 * This example shows how to add a CodaBar to the current page at position of 20, 20 :
		 * <div class="listing">
		 * <pre>
		 * 
		 * var barCode:CodaBar = new CodaBar ( 20, 20, "0123456789" );
		 * myPDF.addCodaBar( barCode );
		 * </pre>
		 * </div>
		 */		
		public function addCodaBar( codaBar:CodaBar ):void
		{	
			setFont( CoreFontCache.getFont ( FontFamily.ARIAL ) );
			addText(codaBar.code, codaBar.x, codaBar.y+codaBar.height + 4);
			lineStyle ( RGBColorCache.getColor ( "0x000000"), 0, 0, 1 );
			beginFill( RGBColorCache.getColor ( "0x000000" ) );
			
			var code:String = (codaBar.start+codaBar.code+codaBar.end).toUpperCase();
			var char:String;
			var seq:Array;
			var barChar:Dictionary;
			var lineWidth:Number = 0;
			var lng:int = 0x7;
			var lngCode:int = code.length;
			var rect:Rectangle = new Rectangle(codaBar.x, codaBar.y, lineWidth, codaBar.height);
			
			for(var i:int=0; i<lngCode; i++)
			{
				barChar = codaBar.barChar;
				char = code.charAt(i);
				
				if(barChar[char] == null )
					throw new Error('Invalid character in barcode: '+char);
				
				seq = barChar[char];
				
				for(var j:int=0; j<lng; j++)
				{
					lineWidth = codaBar.baseWidth*seq[j]/6.5;
					
					if( (j & 1) == 0 )
					{
						rect.width = lineWidth;
						rect.x = codaBar.x;
						drawRect( rect );
					}
					codaBar.x += lineWidth;
				}
				codaBar.x += codaBar.baseWidth*10.4/6.5;
			}
		}
		
		/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		/*
		* AlivePDF Visibility API
		*
		* setVisible()
		*
		*/
		/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		
		public function setVisible (visible:String):void
		{
			if ( visibility != Visibility.ALL )
				write('EMC');
			if ( visible == Visibility.PRINT )
				write('/OC /OC1 BDC');
			else if( visible == Visibility.SCREEN )
				write('/OC /OC2 BDC');
			else if ( visible != Visibility.ALL )
				throw new Error('Incorrect visibility: '+visible);
			visibility = visible;
		}
		
		/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		/*
		* AlivePDF Interactive API
		*
		* addAnnotation()
		* addTransition()
		* addBookmark()
		* addLink()
		*
		*/
		/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		
		/**
		 * Lets you add an annotation to the current page
		 * @param annotation
		 * 
		 * This example shows how to add an annotation for the current page :
		 * <div class="listing">
		 * <pre>
		 * 
		 * var annotation:Annotation = new TextAnnotation ( AnnotationType.TEXT, "This is a text annotation!", 20, 20, 100, 100 );
		 * myPDF.addAnnotation( annotation );
		 * </pre>
		 * </div>
		 */		
		public function addAnnotation ( annotation:Annotation ):void
		{
			var rectangle:String = annotation.x*k + ' ' + (((currentPage.h-annotation.y)*k) - (annotation.height*k)) + ' ' + ((annotation.x*k) + (annotation.width*k)) + ' ' + (currentPage.h-annotation.y)*k;
			
			if ( annotation is TextAnnotation )
			{
				var textAnnotation:TextAnnotation = annotation as TextAnnotation;
				currentPage.annotations += ( '<</Type /Annot /Border [0 0 1] /Subtype /'+textAnnotation.type+' /Contents '+escapeString(textAnnotation.text)+' /Rect [ '+rectangle+' ]>>' );	
			} else if ( annotation is MovieAnnotation )
			{
				var movieAnnotation:MovieAnnotation = annotation as MovieAnnotation;
				currentPage.annotations += ( '<</Type /Annot /Border [0 0 1] /Subtype /'+movieAnnotation.type+' /Contents '+escapeString(movieAnnotation.text)+' /Rect [ '+rectangle+' ]>>' );	
			}
		}
		
		/**
		 * Lets you add a bookmark.
		 * Note : Multiple calls will create a nice table.
		 *
		 * @param text Text appearing in the outline panel
		 * @param level Specify the bookmark's level
		 * @param y Position in the current page to go
		 * @param color RGBColor object
		 * @example
		 * This example shows how to add a bookmark for the current page just added :
		 * <div class="listing">
		 * <pre>
		 *
		 * myPDF.addPage();
		 * myPDF.addBookmark("A page bookmark");
		 * </pre>
		 * </div>
		 * 
		 * This example shows how to add a bookmark with a specific color (red) for the current page just added :
		 * <div class="listing">
		 * <pre>
		 *
		 * myPDF.addPage();
		 * myPDF.addBookmark("A page bookmark", 0, 0, new RGBColor ( 0x990000 ) );
		 * </pre>
		 * </div>
		 * 
		 * You can also add sublevel bookmarks with the following code, using the level parameter :
		 * <div class="listing">
		 * <pre>
		 *
		 * myPDF.addPage();
		 * myPDF.addBookmark("Page 1", 0, 0, new RGBColor ( 0x990000 ) );
		 * myPDF.addBookmark("Page 1 sublink", 1, 0, new RGBColor ( 0x990000 ) );
		 * </pre>
		 * </div>
		 */
		public function addBookmark ( text:String, level:int=0, y:Number=-1, color:RGBColor=null ):void
		{
			if ( color == null ) 
				color = RGBColorCache.getColor ( "0x000000" );
			if( y == -1 ) 
				y = getY();
			outlines.push ( new Outline ( text, level, nbPages, y, color.r, color.g, color.b ) );
		}
		
		/**
		 * Lets you add clickable link to a specific position
		 * Link can be internal (document level navigation) or external (HTTP).
		 *
		 * @param x Page Format, can be Size.A3, Size.A4, Size.A5, Size.LETTER or Size.LEGAL
		 * @param y
		 * @param width
		 * @param height
		 * @param link
		 * @param highlight
		 * @example
		 * This example shows how to add an invisible clickable HTTP link in the current page :
		 * <div class="listing">
		 * <pre>
		 *
		 * myPDF.addLink ( 70, 4, 60, 16, new HTTPLink ("http://www.alivepdf.org") );
		 * </pre>
		 * </div>
		 * 
		 * This example shows how to add an invisible clickable internal link (document level navigation) in the current page :
		 * <div class="listing">
		 * <pre>
		 *
		 * myPDF.addLink ( 70, 4, 60, 16, new InternalLink (2, 10) );
		 * </pre>
		 * </div>
		 * 
		 * By default, the link highlight mode (when the mouse is pressed over the link) is inverted.
		 * This example shows how change the visual state of the link when pressed :
		 * <div class="listing">
		 * <pre>
		 *
		 * myPDF.addLink ( 70, 4, 60, 16, new InternalLink (2, 10), Highlight.OUTLINE );
		 * </pre>
		 * </div>
		 * 
		 * To make the link invisible even when clicked, just pass Highlight.NONE as below :
		 * <div class="listing">
		 * <pre>
		 *
		 * myPDF.addLink ( 70, 4, 60, 16, new InternalLink (2, 10), Highlight.NONE );
		 * </pre>
		 * </div>
		 */
		public function addLink ( x:Number, y:Number, width:Number, height:Number, link:ILink, highlight:String="I" ):void
		{
			var rectangle:String = x*k + ' ' + (currentPage.h-y-height)*k + ' ' + (x+width)*k + ' ' + (currentPage.h-y)*k;
			
			currentPage.annotations += "<</Type /Annot /Subtype /Link /Rect ["+rectangle+"] /Border [0 0 0] /H /"+highlight+" ";
			
			if ( link is HTTPLink ) 
				currentPage.annotations += "/A <</S /URI /URI "+escapeString((link as HTTPLink).link)+">>>>";
			else 
			{
				var currentLink:InternalLink = link as InternalLink;
				var h:Number = orientationChanges[currentLink.page] != null ? currentPage.wPt : currentPage.hPt;
				
				if ( currentLink.rectangle != null ) 
					currentPage.annotations += sprintf('/Dest [%d 0 R /FitR %.2f %.2f %.2f %.2f]>>',1+2*currentLink.page, currentLink.rectangle.x*k, (currentPage.h-currentLink.rectangle.y-currentLink.rectangle.height)*k, (currentLink.rectangle.x+currentLink.rectangle.width)*k, (currentPage.h-currentLink.rectangle.y)*k );
				else if ( !currentLink.fit ) 
					currentPage.annotations += sprintf('/Dest [%d 0 R /XYZ 0 %.2f null]>>',1+2*currentLink.page,(currentPage.h-currentLink.y)*k);
				else if ( currentLink.fit ) currentPage.annotations += sprintf('/Dest [%d 0 R /Fit]>>',1+2*currentLink.page);
			}
		}
		
		/**
		 * Returns an InternalLink object linked to the current page at the current Y in the page.
		 * 
		 * @return InternalLink
		 * @example
		 * This example shows how to add an internal link using the getInternalLink method :
		 * <div class="listing">
		 * <pre>
		 *
		 * var link:InternalLink = myPDF.getCurrentInternalLink();
		 * myPDF.gotoPage(3);	
		 * myPDF.addCell(40, 8, "Here is a link to another page", 0, 0, "", 0, link);		
		 * </pre>
		 * </div>
		 */		
		public function getCurrentInternalLink ():InternalLink
		{	
			return new InternalLink( totalPages, currentY );
		}
		
		/**
		 * Lets you add a transition between each PDF page
		 * Note : PDF must be shown in fullscreen to see the transitions, use the setDisplayMode method with the PageMode.FULL_SCREEN parameter.
		 * 
		 * @param style Transition style, can be Transition.SPLIT, Transition.BLINDS, BLINDS.BOX, Transition.WIPE, etc.
		 * @param duration The transition duration
		 * @param dimension The dimension in which the the specified transition effect occurs
		 * @param motionDirection The motion's direction for the specified transition effect
		 * @param transitionDirection The direction in which the specified transition effect moves
		 * @example
		 * This example shows how to add a 4 seconds "Wipe" transition between the first and second page :
		 * <div class="listing">
		 * <pre> 
		 * myPDF.addPage();  
		 * myPDF.addTransition (Transition.WIPE, 4, Dimension.VERTICAL);
		 * </pre>
		 * </div>
		 */
		public function addTransition ( style:String='R', duration:Number=1, dimension:String='H', motionDirection:String='I', transitionDirection:int=0 ):void
		{
			currentPage.addTransition ( style, duration, dimension, motionDirection, transitionDirection );
		}
		
		/**
		 * Lets you control the way the document is to be presented on the screen or in print.
		 * Note : Very useful to hide any window when the PDF is opened.
		 *
		 * @param toolbar Toolbar behavior
		 * @param menubar Menubar behavior
		 * @param windowUI WindowUI behavior
		 * @param fitWindow Specify whether to resize the document's window to fit the size of the first displayed page.
		 * @param centeredWindow Specify whether to position the document's window in the center of the screen.
		 * @param displayTitle Specify whether the window's title bar should display the document title taken from the value passed to the setTitle method
		 * @example
		 * This example shows how to present the document centered on the screen with no toolbars :
		 * <div class="listing">
		 * <pre>
		 *
		 * myPDF.setViewerPreferences (ToolBar.HIDE, MenuBar.HIDE, WindowUI.HIDE, FitWindow.DEFAULT, CenterWindow.CENTERED);
		 * </pre>
		 * </div>
		 */
		public function setViewerPreferences ( toolbar:String='false', menubar:String='false', windowUI:String='false', fitWindow:String='false', centeredWindow:String='false', displayTitle:String='false' ):void
		{
			viewerPreferences = '<< /HideToolbar '+toolbar+' /HideMenubar '+menubar+' /HideWindowUI '+windowUI+' /FitWindow '+fitWindow+' /CenterWindow '+centeredWindow+' /DisplayDocTitle '+displayTitle+' >>';
		}
		
		/**
		 * Lets you specify which page should be viewed by default when the document is opened.
		 * Note : This method must be called once all the pages have been created and added through addPage().
		 *
		 * @param index Page number
		 * @example
		 * This example shows how to sepcify the second page to be viewed by default :
		 * <div class="listing">
		 * <pre>
		 *
		 * myPDF.setStartingPage (2);
		 * </pre>
		 * </div>
		 */
		public function setStartingPage ( index:int ):void
		{
			var lng:int = arrayPages.length;
			if ( index > 0 && index <=  lng ) 
				startingPageIndex = index-1;
			else throw new RangeError ("Can't set page " + index + ". "+lng+ " page(s) available.")
		}
		
		/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		/*
		* AlivePDF printing API
		*
		*/
		/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		
		private function insertSpotColors():void
		{
			for each( var color:SpotColor in spotColors )
			{
				newObj();
				write('[/Separation /'+findAndReplace(' ', '#20', color.name));
				write('/DeviceCMYK <<');
				write('/Range [0 1 0 1 0 1 0 1] /C0 [0 0 0 0] ');
				write(sprintf('/C1 [%.3F %.3F %.3F %.3F] ', color.color.cyan*.01, color.color.magenta*.01, color.color.yellow*.01, color.color.black*.01));
				write('/FunctionType 2 /Domain [0 1] /N 1>>]');
				write('endobj');
				color.n = n;
			}
		}
		
		/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		/*
		* AlivePDF font API
		*
		* addFont()
		* removeFont()
		* setFont()
		* setFontSize()
		* getTotalFonts()
		* totalFonts
		*
		*/
		/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		
		protected function addFont ( font:IFont ):IFont
		{
			pushedFontName = font.name;
			
			if ( !fonts.some(findFont) ) 
				fonts.push ( font );
			
			font.id = fonts.length;
			
			fontFamily = font.name;
			
			var addedFont:EmbeddedFont;
			
			if ( font is EmbeddedFont )
			{
				addedFont = font as EmbeddedFont;	
				
				if ( addedFont.differences != null )
				{
					d = -1;
					nb = differences.length;
					for ( var j:int = 0; j < nb ; j++ )
					{
						if(differences[j] == addedFont.differences)
						{
							d = j;
							break;
						}
					}
					
					if( d == -1 )
					{
						d = nb;
						differences[d = nb] = addedFont.differences;
					}
					
					fonts[fonts.length-1].differences = d;
				}		
			}
			return font;
		}
		
		protected function findFont ( element:IFont, index:int, arr:Array ):Boolean
		{	
			return element.name == pushedFontName;	
		}
		
		/**
		 * Lets you set a specific font.
		 * Note : Since release 0.1.5, you do not need to call the addFont method anymore. It will be called automatically internally if needed.
		 *
		 * @param A font, can be a core font (org.alivepdf.fonts.CoreFont), or an embedded font (org.alivepdf.fonts.EmbeddedFont)
		 * @param size Any font size
		 * @param underlined if text should be underlined
		 * @example
		 * This example shows how to set the Helvetica font, with a bold style :
		 * <div class="listing">
		 * <pre>
		 *
		 * var font:CoreFont = CoreFontCache.getFont ( FontFamily.HELVETICA_BOLD );
		 * myPDF.setFont( font );
		 * </pre>
		 * </div>
		 */
		public function setFont ( font:IFont, size:int=12, underlined:Boolean=false ):void
		{	
			pushedFontName = font.name;
			
			var result:Array = fonts.filter(findFont);
			currentFont = result.length > 0 ? result[0] : addFont( font );	
			
			underline = underlined;
			fontFamily = currentFont.name;
			fontSizePt = size;
			fontSize = size/k;
			
			if ( nbPages > 0 ) 
				write (sprintf('BT /F%d %.2f Tf ET', currentFont.id, fontSizePt));
		}
		
		/**
		 * Lets you set a new size for the current font.
		 *
		 * @param size Font size
		 * @example
		 * This example shows how to se the current font to 18 :
		 * <div class="listing">
		 * <pre>
		 *
		 * myPDF.setFontSize( 18 );
		 * </pre>
		 * </div>
		 */
		public function setFontSize ( size:int ):void
		{	
			if( fontSizePt == size ) 
				return;
			fontSizePt = size;
			fontSize = size/k;
			if( nbPages > 0 ) 
				write (sprintf('BT /F%d %.2f Tf ET', currentFont.id, fontSizePt));	
		}
		
		/**
		 * Lets you remove an embedded font from the PDF.
		 *
		 * @param font The embedded font
		 * @example
		 * This example shows how to remove an embedded font :
		 * <div class="listing">
		 * <pre>
		 *
		 * myPDF.removeFont( myEmbeddedFont );
		 * </pre>
		 * </div>
		 */
		public function removeFont ( font:IFont ):void
		{
			if ( !(font.type is EmbeddedFont) ) 
				throw new Error('The font you have passed is a Core font. Core fonts cannot be removed as they are not embedded in the PDF.');
			var position:int = fonts.indexOf(font);
			if ( position != -1 ) 
				fonts.splice(position, 1);
			else throw new Error ("Font cannot be found.");	
		}
		
		/**
		 * Lets you retrieve the total number of fonts used in the PDF document.
		 *
		 * @return int Number of fonts (embedded or not) used in the PDF
		 * @example
		 * This example shows how to retrieve the number of fonts used in the PDF document :
		 * <div class="listing">
		 * <pre>
		 *
		 * var totalFonts:int = myPDF.totalFonts;
		 * </pre>
		 * </div>
		 */
		public function get totalFonts():int
		{
			return fonts.length;	
		}
		
		/**
		 * Lets you retrieve the fonts used in the PDF document.
		 *
		 * @return Array An Array of fonts objects (CoreFont, EmbeddedFont)
		 * @example
		 * This example shows how to retrieve the fonts :
		 * <div class="listing">
		 * <pre>
		 *
		 * var fonts:Array = myPDF.getFonts();
		 * </pre>
		 * </div>
		 */
		public function getFonts():Array
		{
			return fonts;	
		}
		
		/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		/*
		* AlivePDF text API
		*
		* addText()
		* textStyle()
		* addCell()
		* addCellFitScale()
		* addCellFitScaleForce()
		* addCellFitSpace()
		* addCellFitSpaceForce()
		* addMultiCell()
		* writeText()
		*
		*/
		/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		
		/**
		 * Lets you set some text to any position on the page.
		 * Note : addText is a low level method which does not handle line returns and paragraph requirements. Use writeText for that or writeFlashHtmlText if you need HTML on top of that.
		 *
		 * @param text The text to add
		 * @param x X position
		 * @param y Y position
		 * @example
		 * This example shows how to set some text to a specific place :
		 * <div class="listing">
		 * <pre>
		 *
		 * myPDF.addText ('Some simple text added !', 14, 110);
		 * </pre>
		 * </div>
		 */
		public function addText ( text:String, x:Number=0, y:Number=0 ):void	
		{
			var s:String = sprintf('BT %.2f %.2f Td (%s) Tj ET',x*k, (currentPage.h-y)*k, escapeIt(text));
			if (underline && text !='') 
				s += ' '+doUnderline(x,y,text);
			if (colorFlag) 
				s = 'q ' + addTextColor + ' ' + s +' Q';
			write(s);
		}
		
		/**
		 * Sets the text style with an appropriate color, alpha etc.
		 *
		 * @param color Color object, can be CMYKColor, GrayColor, or RGBColor
		 * @param alpha Text opacity
		 * @param rendering pRendering Specify the text rendering mode
		 * @param wordSpace Spaces between each words
		 * @param characterSpace Spaces between each characters
		 * @param scale Text scaling
		 * @param leading Text leading
		 * @example
		 * This example shows how to set a specific black text style with full opacity :
		 * <div class="listing">
		 * <pre>
		 *
		 * myPDF.textStyle ( new RGBColor ( 0x000000 ), 1 ); 
		 * </pre>
		 * </div>
		 */
		public function textStyle ( color:IColor, alpha:Number=1, rendering:int=0, wordSpace:Number=0, characterSpace:Number=0, scale:Number=100, leading:Number=0 ):void
		{	
			textColor = color;
			textAlpha = alpha;
			textWordSpace = wordSpace;
			textSpace = characterSpace;
			textScale = scale;
			textLeading = leading;
			
			write ( sprintf ( '%d Tr', textRendering = rendering ) );
			setTextColor ( color );
			setAlpha ( alpha );
			write ( wordSpace + ' Tw ' + characterSpace + ' Tc ' + scale + ' Tz ' + leading + ' TL ' );
			colorFlag = ( fillColor != addTextColor );
		}
		
		/**
		 * Add a cell with some text to the current page.
		 *
		 * @param width Cell width
		 * @param height Cell height
		 * @param text Text to add into the cell
		 * @param ln Sets the new position after cell is drawn, default value is 0
		 * @param align Lets you center or align the text into the cell
		 * @param fill Lets you specify if the cell is colored (1) or transparent (0)
		 * @param link Link can be internal to do document level navigation (InternalLink) or external (HTTPLink)
		 * @return Page
		 * @example
		 * This example shows how to write some text within a cell :
		 * <div class="listing">
		 * <pre>
		 *
		 * var font:CoreFont = CoreFontCache.getFont ( FontFamily.HELVETICA_BOLD );
		 * myPDF.setFont( font );
		 * myPDF.textStyle ( new RGBColor ( 0x990000 ) );
		 * myPDF.addCell(50, 10, 'Some text into a cell !', 1, 1);
		 * </pre>
		 * </div>
		 * 
		 * This example shows how to write some clickable text within a cell :
		 * <div class="listing">
		 * <pre>
		 *
		 * var font:CoreFont = CoreFontCache.getFont ( FontFamily.HELVETICA_BOLD );
		 * myPDF.setFont( font );
		 * myPDF.textStyle ( new RGBColor ( 0x990000 ) );
		 * myPDF.addCell(50, 10, 'A clickable cell !', 1, 1, null, 0, new HTTPLink ("http://www.alivepdf.org") );
		 * </pre>
		 * </div>
		 */
		public function addCell ( width:Number=0, height:Number=0, text:String='', border:*=0, ln:Number=0, align:String='', fill:Number=0, link:ILink=null ):void
		{
			if( currentY + height > pageBreakTrigger && !inHeader && !inFooter && acceptPageBreak() )
			{
				var x:Number = currentX;
				
				if( ws > 0 )
				{
					ws = 0;
					write('0 Tw');
				}
				
				addPage( new Page ( currentOrientation, defaultUnit, defaultSize , currentPage.rotation ) );
				currentX = x;
				
				if( ws > 0 ) 
					write(sprintf('%.3f Tw', ws*k));
			}
			
			if ( currentPage.w == 0 ) 
				currentPage.w = currentPage.w-rightMargin-currentX;
			
			var s:String = new String();
			var op:String;
			
			if( fill == 1 || border == 1 )
			{
				if ( fill == 1 ) 
					op = ( border == 1 ) ? Drawing.FILL_AND_STROKE : Drawing.FILL;
				else op = Drawing.STROKE;
				
				s = sprintf('%.2f %.2f %.2f %.2f re %s ', currentX*k, (currentPage.h-currentY)*k, width*k, -height*k, op);
				endFill();
			}
			
			if ( border is String )
			{
				var borderBuffer:String = String ( border );
				var currentPageHeight:Number = currentPage.h;
				if( borderBuffer.indexOf (Border.LEFT) != -1 ) 
					s+=sprintf('%.2f %.2f m %.2f %.2f l S ', currentX*k,(currentPageHeight-currentY)*k,currentX*k,(currentPageHeight-(currentY+height))*k);
				if( borderBuffer.indexOf (Border.TOP) != -1) 
					s+=sprintf('%.2f %.2f m %.2f %.2f l S ', currentX*k,(currentPageHeight-currentY)*k,(currentX+width)*k,(currentPageHeight-currentY)*k);
				if( borderBuffer.indexOf (Border.RIGHT) != -1) 
					s+=sprintf('%.2f %.2f m %.2f %.2f l S ', (currentX+width)*k,(currentPageHeight-currentY)*k,(currentX+width)*k,(currentPageHeight-(currentY+height))*k);
				if( borderBuffer.indexOf (Border.BOTTOM) != -1 ) 
					s+=sprintf('%.2f %.2f m %.2f %.2f l S ', currentX*k,(currentPageHeight-(currentY+height))*k,(currentX+width)*k,(currentPageHeight-(currentY+height))*k);
			}
			
			if ( text !== '' )
			{
				var dx:Number;
				
				if ( align == HorizontalAlign.RIGHT ) 
					dx = width-currentMargin-getStringWidth(text);
				else if ( align == HorizontalAlign.CENTER ) 
					dx = (width-getStringWidth(text))*.5;
				else dx = currentMargin;
				
				if (colorFlag) 
					s += 'q '+addTextColor+' ';
				
				var txt2:String = escapeIt(text);
				s += sprintf('BT %.2f %.2f Td (%s) Tj ET',(currentX+dx)*k,(currentPage.h-(currentY+.5*height+.3*fontSize))*k,txt2);
				
				if (underline) 
					s += ' ' + doUnderline(currentX+dx,currentY+.5*height+.3*fontSize,text);
				if (colorFlag) 
					s += ' Q';
				
				if ( link != null ) 
					addLink (currentX+dx,currentY+.5*height-.5*fontSize,getStringWidth(text),fontSize, link);
			}
			
			if ( s != '' ) 
				write(s);
			
			lasth = currentPage.h;
			
			if ( ln > 0 )
			{
				currentY += height;
				if ( ln == 1 ) 
					currentX = leftMargin;
				
			} else currentX += width;
		}
		
		protected function addCellFit(width:Number, height:Number=0, text:String='', border:*=0, ln:Number=0, align:String='', fill:Number=0, link:ILink=null, scale:Boolean=false, force:Boolean=true):void
		{
			var stringWidth:Number = getStringWidth(text);
			
			if(width==0)
				width = currentPage.w-rightMargin-currentX;
			
			var ratio:Number = (width-currentMargin*2)/stringWidth;
			var fit:Boolean = (ratio < 1 || (ratio > 1 && force));
			
			if (fit)
			{
				if (scale)
				{
					var horizScale:Number = ratio*100.0;
					write(sprintf('BT %.2F Tz ET',horizScale));
				}
				else
				{
					var charSpace:Number = (width-currentMargin*2-stringWidth)/Math.max(getStringLength(text)-1,1)*k
					write(sprintf('BT %.2F Tc ET',charSpace));
				}
				var align:String = '';
			}
			
			addCell(width,height,text,border,ln,align,fill,link);
			
			if (fit)
				write('BT '+(scale ? '100 Tz' : '0 Tc')+' ET');
		}
		
		/**
		 * Adds a cell with horizontal scaling only if necessary
		 * @param width
		 * @param height
		 * @param text
		 * @param border
		 * @param ln
		 * @param align
		 * @param fill
		 * @param link
		 * 
		 */		
		public function addCellFitScale(width:Number, height:Number=0, text:String='', border:*=0, ln:Number=0, align:String='', fill:Number=0, link:ILink=null):void
		{
			addCellFit(width,height,text,border,ln,align,fill,link,true,false);
		}
		
		/**
		 * Adds a cell with horizontal scaling always
		 * @param width
		 * @param height
		 * @param text
		 * @param border
		 * @param ln
		 * @param align
		 * @param fill
		 * @param link
		 * 
		 */		
		public function addCellFitScaleForce(width:Number, height:Number=0, text:String='', border:*=0, ln:Number=0, align:String='', fill:Number=0, link:ILink=null):void
		{
			addCellFit(width,height,text,border,ln,align,fill,link,true,true);
		}
		
		/**
		 * Adds a cell with character spacing only if necessary
		 * @param width
		 * @param height
		 * @param text
		 * @param border
		 * @param ln
		 * @param align
		 * @param fill
		 * @param link
		 * 
		 */		
		public function addCellFitSpace(width:Number, height:Number=0, text:String='', border:*=0, ln:Number=0, align:String='', fill:Number=0, link:ILink=null):void
		{
			addCellFit(width,height,text,border,ln,align,fill,link,false,false);
		}
		
		/**
		 * Adds a cell with character spacing always
		 * @param width
		 * @param height
		 * @param text
		 * @param border
		 * @param ln
		 * @param align
		 * @param fill
		 * @param link
		 * 
		 */		
		public function addCellFitSpaceForce(width:Number, height:Number=0, text:String='', border:*=0, ln:Number=0, align:String='', fill:Number=0, link:ILink=null):void
		{
			addCellFit(width,height,text,border,ln,align,fill,link,false,true);
		}
		
		/**
		 * Add a multicell with some text to the current page.
		 *
		 * @param width Cell width
		 * @param height Cell height
		 * @param text Text to add into the cell
		 * @param border Lets you specify if a border should be drawn around the cell
		 * @param align Lets you center or align the text into the cell, values can be L (left align), C (centered), R (right align), J (justified) default value
		 * @param filled Lets you specify if the cell is colored (1) or transparent (0)
		 * @return Page
		 * @example
		 * This example shows how to write a table made of text cells :
		 * <div class="listing">
		 * <pre>
		 *
		 * myPDF.setFont( FontFamily.COURIER, Style.BOLD, 14 );
		 * myPDF.textStyle ( new RGBColor ( 0x990000 ) );
		 * myPDF.addMultiCell ( 70, 24, "A multicell :)", 1);
		 * myPDF.addMultiCell ( 70, 24, "A multicell :)", 1);
		 * </pre>
		 * </div>
		 */
		public function addMultiCell ( width:Number, height:Number, text:String, border:*=0, align:String='J', filled:int=0):void
		{
			charactersWidth = currentFont.charactersWidth;
			
			if ( width == 0 ) 
				width = currentPage.w - rightMargin - currentX;
			
			var wmax:Number = (width-2*currentMargin)*I1000/fontSize;
			var s:String = findAndReplace ("\r",'',text);
			var nb:int = s.length;
			
			if( nb > 0 && s.charAt(nb-1) == "\n" ) 
				nb--;
			
			var b:* = 0;
			
			if( border )
			{
				if( border == 1 )
				{
					border = 'LTRB';
					b = 'LRT';
					b2 = 'LR';
				}
				else
				{
					b2 = '';
					if (border.indexOf(Border.LEFT)!= -1) 
						b2+= Border.LEFT;
					if (border.indexOf(Border.RIGHT)!= -1) 
						b2+= Border.RIGHT;
					b = (border.indexOf(Border.TOP)!= -1) ? 
						b2+Border.TOP : b2;
				}
			}
			
			var sep:int = -1;
			var i:int = 0;
			var j:int = 0;
			var l:int = 0;
			var ns:int = 0;
			var nl:int = 1;
			var c:String;
			var cell:Cell;
			
			var cwAux:int = 0;
			
			while (i<nb)
			{			
				c = s.charAt(i);
				
				if (c=="\n")
				{
					if (ws>0)
					{
						ws=0;
						write('0 Tw');
					}
					
					addCell(width, height, s.substr(j,i-j), b, 2, align, filled);
					
					i++;
					sep = -1;
					j = i;
					l = 0;
					ns = 0;
					nl++;
					
					if (border && nl==2) 
						b = b2;
					continue;			
				}
				
				if(c==' ')
				{
					sep = i;
					var ls:int = l;
					ns++;
				}
				
				cwAux = charactersWidth[c] as int;
				
				if (cwAux == 0) 
					cwAux = FontMetrics.DEFAULT_WIDTH;
				
				l += cwAux;
				
				if (l>wmax)
				{
					if (sep==-1)
					{
						if (i==j) 
							i++;
						if (ws>0)
						{
							ws=0;
							write('0 Tw');
						}
						
						addCell(width,height,s.substr(j,i-j),b,2,align, filled);
					}
					else
					{
						if (align == Align.JUSTIFIED)
						{
							ws = (ns>1) ? ((wmax-ls)*.001)*fontSize/(ns-1) : 0;
							write(sprintf('%.3f Tw',ws*k));
						}
						
						addCell(width,height,s.substr(j,sep-j),b,2,align,filled);
						
						i=sep+1;
					}
					
					sep = -1;
					j = i;
					l = 0;
					ns = 0;
					nl++;
					
					if ( border && nl == 2 ) 
						b = b2;
				}
				else i++;
			}
			
			if ( ws>0 )
			{
				ws = 0;
				write('0 Tw');
			}
			
			if ( border && border.indexOf ('B')!= -1 ) 
				b += 'B';
			
			addCell ( width, height, s.substr(j,i-j), b, 2, align, filled );
			
			currentX = leftMargin;
		}
		
		/**
		 * Lets you write some text in the current page.
		 * Note : writeText takes care of line return and paragraphs requirements. If you need HTML in top of that, use writeFlashHtmlText.
		 *
		 * @param lineHeight Line height, lets you specify height between each lines
		 * @param text Text to write, to put a line break just add a \n in the text string
		 * @param link Any link, like http://www.mylink.com, will open te browser when clicked
		 * @example
		 * This example shows how to add some text to the current page :
		 * <div class="listing">
		 * <pre>
		 *
		 * myPDF.writeText ( 5, "Lorem ipsum dolor sit amet, consectetuer adipiscing elit.", "http://www.google.fr");
		 * </pre>
		 * </div>
		 * This example shows how to add some text with a clickable link :
		 * <div class="listing">
		 * <pre>
		 *
		 * myPDF.writeText ( 5, "Lorem ipsum dolor sit amet, consectetuer adipiscing elit.", "http://www.google.fr");
		 * </pre>
		 * </div>
		 */
		public function writeText ( lineHeight:Number, text:String, link:ILink=null ):void
		{
			var cw:Object = currentFont.charactersWidth;
			var w:Number = currentPage.w-rightMargin-currentX;
			var wmax:Number = (w-2*currentMargin)*I1000/fontSize;
			
			var s:String = findAndReplace ("\r",'', text);
			var nb:int = s.length;
			var sep:int = -1;
			var i:int = 0;
			var j:int = 0;
			var l:int = 0;
			var nl:int = 1;
			var c:String;
			var cwAux:int
			
			while( i<nb )
			{
				c = s.charAt(i);
				
				if( c == "\n" )
				{
					addCell (w,lineHeight,s.substr(j,i-j),0,2,'',0,link);
					i++;
					sep = -1;
					j = i;
					l = 0;
					if (nl==1)
					{
						currentX = leftMargin;
						w = currentPage.w-rightMargin-currentX;
						wmax= (w-2*currentMargin)*I1000/fontSize;
					}
					nl++;
					continue;
				}
				
				if(c == ' ') 
					sep=i;
				
				cwAux = cw[c] as int;
				
				if (cwAux == 0) 
					cwAux = FontMetrics.DEFAULT_WIDTH;
				
				l += cwAux;
				
				if( l > wmax )
				{
					//Automatic line break
					if( sep==-1 )
					{
						if(currentX>leftMargin)
						{
							//Move to next line
							currentX = leftMargin;
							currentY += currentPage.h;
							w = currentPage.w-rightMargin-currentX;
							wmax = (w-2*currentMargin)*I1000/fontSize;
							i++;
							nl++;
							continue;
						}
						if ( i==j ) 
							i++;
						addCell (w,lineHeight,s.substr(j,i-j),0,2,'',0,link);
					}
					else
					{
						addCell (w,lineHeight,s.substr(j,sep-j),0,2,'',0,link);
						i = sep+1;
					}
					sep = -1;
					j = i;
					l = 0;
					if( nl==1 )
					{
						currentX = leftMargin;
						w = currentPage.w-rightMargin-currentX;
						wmax = (w-2*currentMargin)*I1000/fontSize;
					}
					nl++;
				}
				else i++;
			}
			if ( i != j ) 
				addCell ((l*.001)*fontSize,lineHeight,s.substr(j),0,0,'',0,link);
		}
		
		/**
		 * Lets you write some text with basic HTML type formatting.
		 *
		 * @param pHeight Line height, lets you specify height between each lines
		 * @param pText Text to write, to put a line break just add a \n in the text string
		 * @param pLink Any link, like http://www.mylink.com, will open te browser when clicked
     * @param pHeightInFontSizePercentage If not NaN, override the pHeight with the given per FontSize percentage
		 * @example
		 * 
		 * Only a limited subset of tags are currently supported
		 *  <b> </b>
		 *  <i> </i>
		 *  <br />  used to create a new line
		 * 
		 * This example shows how to add some text to the current page :
		 * <div class="listing">
		 * <pre>
		 *
		 * myPDF.writeFlashHtmlText ( 5, "Lorem ipsum <b>dolor</b> sit amet, consectetuer<br /> adipiscing elit.");
		 * </pre>
		 * </div>
     * 
		 * This example shows how to add some text with a clickable link :
		 * <div class="listing">
		 * <pre>
		 *
		 * myPDF.writeFlashHtmlText ( 5, "Lorem ipsum dolor sit amet, consectetuer adipiscing elit.", "http://www.google.com");
		 * </pre>
		 * </div>
     * 
     * This example shows how to add some text using a pHeight of 120% of the fontSize :
		 * <div class="listing">
		 * <pre>
		 *
		 * myPDF.writeFlashHtmlText ( 5, "Lorem ipsum dolor sit amet, consectetuer adipiscing elit.", null, 120);
		 * </pre>
		 * </div>
		 */
		public function writeFlashHtmlText ( pHeight:Number, pText:String, pLink:ILink=null, pHeightInFontSizePercentage:Number=NaN ):void
		{
      //Output text in flowing mode
			var cw    : Object     = currentFont.charactersWidth;
			var w     : Number     = currentPage.w-rightMargin-currentX;
			var wmax  : Number     = (w-2*currentMargin)*I1000/fontSize;
			var s     : String     = findAndReplace ("\r",'',pText);
			
			// Strip all \n's as we don't use them - use <br /> tag for returns
			s = findAndReplace("\n",'', s);  
			
			var nb      : int;        // Count of number of characters in section
			var sep     : int = -1;   // Stores the position of the last seperator
			var lenAtSep: Number = 0; // Store the length at the last seprator 
			var i       : int = 0;    // Counter for looping through each string
			var j       : int = 0;    // Counter which is updated with character count to be actually output (taking auto line breaking into account)
			var l       : int = 0;    // Length of the the current character string
			var k       : int = 0;    // Counter for looping through each item in the parsed XML array  
			var ns      : int = 0;    // number of space character
			
			//XML whitespace is important for this text parsing - so save prev value so we can restore it.
			var prevWhiteSpace    : Boolean = XML.ignoreWhitespace;
			XML.ignoreWhitespace = false;
			
      
      var aTaggedString     : Vector.<HTMLTag>;
      
      // We want to now if the HTML is comming from a conversion from
      // some TLF format.
      // This could be done with
      // String(TextConverter.export(this.richEditableText.textFlow, TextConverter.TEXT_FIELD_HTML_FORMAT, ConversionType.STRING_TYPE));
      // And the result will looks like:
      // <HTML><BODY><TEXTFORMAT><P> ..</P><P> ..</P></TEXTFORMAT></BODY></HTML>
      //
      // Or 
      //
      // if the string comming from the htmlText property of some MX component
      // For example this.richTextEditor.htmlText
      // The result will looks like:
      // <TEXTFORMAT><P> ..</P></TEXTFORMAT><TEXTFORMAT><P> ..</P></TEXTFORMAT>
      //
      // This flag is mainly use to change the behavior depending of the HTML
      // source.
      // For example when comingFromTLF == true, the lists are as follow:
      // <UL><LI><TEXFORMAT><P><FONT>first</FONT></P></TEXFORMAT></LI><LI><TEXFORMAT><P><FONT>second</FONT></P></TEXFORMAT></LI></UL>
      //
      // when comingFromTLF == true, the lists are as follow:
      // <TEXFORMAT><LI><FONT>first</FONT></LI></TEXFORMAT><TEXFORMAT><LI><FONT>second</FONT></LI></TEXFORMAT>
      
      var comingFromTLF:Boolean;
      var insideULList:Boolean;
      
      // If comming from TLF there is already an <HTML> tag
      if ( s.substr(0, 6) == "<HTML>" ) {
        comingFromTLF = true;
        aTaggedString = parseTags ( new XML ( s ) );
      } else {
        comingFromTLF = false;
        aTaggedString = parseTags ( new XML( "<HTML>"+s+"</HTML>" ) );
      }
      
			XML.ignoreWhitespace = prevWhiteSpace;
			
			//Stores the cell snippets for the current line
			var currentLine      : Array = new Array(); 
			var cellVO           : CellVO;
			
			//Variables to track the state of the current text
      var newFont          : IFont;
      var fontTagAttr      : FONTTagAttributes; // hold the value of the last <FONT> tag attributes
			var fontBold         : Boolean = false; 
			var fontItalic       : Boolean = false;
			fontUnderline     = false;
      
			var textAlign        : String = '';  // '' or 'C' or 'R' or 'J' 
			var attr             : XML;
      
			var cwAux            : int;
      
      // Sometime <FONT> nodes are nested such as in
      // <FONT><FONT>foo</FONT>bar</FONT>
      // this looks to be related to colors (not sure)
      // So we need to have a stack of FontParams to handle the above situation
      var fontTagAttrStack:Vector.<FONTTagAttributes> = new Vector.<FONTTagAttributes>();
      
      // begin with default font attributes
      fontTagAttr = new FONTTagAttributes();
      setFontSize( fontTagAttr.size );
      if ( ! isNaN(pHeightInFontSizePercentage) )
        pHeight = pHeightInFontSizePercentage/100*fontTagAttr.size/this.k;
      
      var listLevelDepth:int;
      
      var lastParagraphX:Number;
      var lastParagraphY:Number;
			
			// total number of HTML tags
			var lng:int = aTaggedString.length;
			
			//Loop through each item in array
			for ( k=0; k < lng; k++ )
			{            	
				//Handle any tags and if unknown then handle as text    
				switch ( aTaggedString[k].tag.toUpperCase() )
				{	
					//Process Tags
					case "<TEXTFORMAT>":
            break;
					case "</TEXTFORMAT>":
						break;
					case "<P>":
            lastParagraphX = currentX;
            lastParagraphY = currentY;
            
						for each ( attr in aTaggedString[k].attr )
  					{	
  						switch ( String ( attr.name() ).toUpperCase() )
  						{	
  							case "ALIGN": 
  								textAlign = String ( attr ).toUpperCase().charAt(0);
  								break;
  							default:
  								break;
  						}
  					}
						break;
					case "</P>":
						
            if ( ! insideULList ) {
              
              renderLine(currentLine,textAlign);
              currentLine     = new Array();
              currentX   		  = leftMargin;
              textAlign       = '';
              ns              = 0;
              
              if ( currentX == lastParagraphX && currentY == lastParagraphY ) {
                // means we write nothing in that P tag
                // we interpret that as a line break
                lineBreak( pHeight );
              }
              
            }
						
						break;
					case "<FONT>":
            
            // A <FONT> could override only some attributes, so we default
            // all the attributes with the actual fontParams
            if ( fontTagAttr ) {
              fontTagAttr = fontTagAttr.clone();
            } else {
              // we use the default attribute if not specified just after
              fontTagAttr = new FONTTagAttributes(); 
            }           
            
						for each ( attr in aTaggedString[k].attr )
  					{
  						switch ( String ( attr.name() ).toUpperCase() )
  						{	
  							case "FACE":
  								// TODO: Add Font Face Support
                  fontTagAttr.face = String ( attr );
  								break;
  							case "SIZE":
                  fontTagAttr.size = parseInt( String ( attr ) );
                  setFontSize( fontTagAttr.size );
                  if ( ! isNaN(pHeightInFontSizePercentage) )
                    pHeight = pHeightInFontSizePercentage/100*fontTagAttr.size/this.k;
  								break;
  							case "COLOR":
                  fontTagAttr.color = RGBColorCache.getColor( String ( attr ) );
  								break;
  							case "LETTERSPACING":
                  fontTagAttr.letterspacing = parseInt( String ( attr ) );
  								break;
  							case "KERNING":
  								// TODO
                  fontTagAttr.kerning = parseInt( String ( attr ) );
  								break;
  							default:
  								break;
  						}
  					}
            
            fontTagAttrStack.push(fontTagAttr);
            
						break;
					case "</FONT>":
            
            fontTagAttrStack.pop();
            
            if ( fontTagAttrStack.length > 0 ) {
              fontTagAttr = fontTagAttrStack[fontTagAttrStack.length - 1];
            } else {
              // get the default
              fontTagAttr = new FONTTagAttributes();
              
              if ( textColor is RGBColor ) {
                fontTagAttr.color = RGBColor(textColor);
              }
              
            }
            
            setFontSize( fontTagAttr.size );
            if ( ! isNaN(pHeightInFontSizePercentage) )
              pHeight = pHeightInFontSizePercentage/100*fontTagAttr.size/this.k;
            
						break;
          case "<A>":
            for each ( attr in aTaggedString[k].attr )
            {
            switch ( String ( attr.name() ).toUpperCase() )
              {	
              case "HREF":
                pLink = new HTTPLink( String ( attr ) );
                break;
              default:
                break;
              }
            }
            
            break;
          case "</A>":
            pLink = null;
            break;
					case "<B>":
						fontBold = true;
						break;
					case "</B>":
						fontBold = false;
						break;
					case "<I>":
						fontItalic = true;
						break;
					case "</I>":
						fontItalic = false;
						break;
					case "<U>":
						fontUnderline = true;
						break;
					case "</U>":
						fontUnderline = false;
						break;
          break;
          case "<UL>":
            listLevelDepth++;
            insideULList = true;
            break;
          case "</UL>":
            listLevelDepth--;
            if ( listLevelDepth == 0 )
              insideULList = false;
            break;
					case "<BR>":
						// Both cases will set line break to true.  It is typically entered as <br /> 
						// but the parser converts this to a start and end tag
						lineBreak ( pHeight );
					case "</BR>":
						if (currentLine.length > 0 )
						{
							renderLine(currentLine,textAlign);
							currentX  = leftMargin;
							currentLine = new Array();
						}
						break;
          case "<LI>":
            
            if ( ! comingFromTLF ) {
              // MX flash html does not use <UL> tag so we assume a depth of 1
              listLevelDepth = 1;
              insideULList = true;
            }
            
            //Create an CellVO to make the indentation
            cellVO            = new CellVO();
            cellVO.text       = "";
            
            // indentation
            for (var listPrefixCounter:int = 0; listPrefixCounter < listLevelDepth; listPrefixCounter++){
              cellVO.text += "    ";
            }
            
            cellVO.text       += "\u2022 "; // bullet char
            cellVO.x          = currentX;
            cellVO.y          = currentY;
            cellVO.width      = getStringWidth(cellVO.text);
            cellVO.height     = pHeight;
            cellVO.fontSizePt = fontSizePt;
            cellVO.color      = RGBColorCache.getColor( "0x000000" );
            cellVO.underlined = fontUnderline;
            
            //Set the font for calculation of character widths
            newFont = CoreFontCache.getFont ( getFontStyleString(fontBold, fontItalic, fontFamily) );
            setFont ( newFont, cellVO.fontSizePt );
            cellVO.font = newFont;
            
            currentLine.push ( cellVO );
            currentX += cellVO.width;
            
            break;
          case "</LI>":
            
            if ( ! comingFromTLF ) {
              // MX flash html does not use <UL> tag so we must clean up things
              listLevelDepth = 0;
              insideULList = false;
            }
            
            // new line
            renderLine(currentLine,textAlign);
            currentLine     = new Array();
            currentX        = leftMargin;
            ns              = 0;
            
            break;
          default:
            // do nothing for unsuported nodes ...
            break;
          case "NONE":
						//Process text                    
						
						//Create a blank CellVO for this part
						cellVO            = new CellVO();	
						cellVO.link       = pLink;
						cellVO.fontSizePt = fontSizePt;
						cellVO.color      = fontTagAttr.color;
						cellVO.underlined = fontUnderline;
						
						if ( currentFont is EmbeddedFont )
						{
							var style:String = Style.NORMAL;
							
							if(fontBold && fontItalic)
							{
								style = Style.BOLD_ITALIC;
							}
							else if(fontBold)
							{
								style = Style.BOLD;
							}
							else if(fontItalic)
							{
								style = Style.ITALIC;
							}
							
							newFont = FontCollections.lookup(currentFont.name, style);
						}
						else 
							newFont = CoreFontCache.getFont ( getFontStyleString(fontBold, fontItalic, fontFamily) );

						setFont ( newFont, cellVO.fontSizePt );
						cellVO.font = newFont;
						
						//Font character width lookup table
						cw      = currentFont.charactersWidth; 
						
						//Current remaining space per line
						w       = currentPage.w-rightMargin-currentX;
						
						//Size of a full line of text
						wmax    = (w-2*currentMargin)*I1000/fontSize;  
						
						//get text from string
						s   = aTaggedString[k].value; 
						
						//Length of string
						nb  = s.length;
						
						i   =  0;
						j   =  0;
						sep = -1;
						l   =  0;
						
						while( i < nb )
						{
							//Get next character
							var c : String = s.charAt(i);
							
							//Found a seperator
							if ( c == ' ' )
							{ 
								sep      = i;    //Save seperator index
								lenAtSep = l;    //Save seperator length
								ns++;
							}
							
							//Add the character width to the length;
							cwAux = cw[c] as int;
							
							if ( cwAux == 0 ) 
								cwAux = FontMetrics.DEFAULT_WIDTH;
							
							l += cwAux;
							
							//Are we Over the char width limit?
							if ( l > wmax )
							{	
								//Automatic line break
								if ( sep == -1 )
								{
									// No seperator to force at character									
									if(currentX>leftMargin)
									{	
										//Move to next line
										currentX  = leftMargin;
										currentY += pHeight;
										
										w    = currentPage.w-rightMargin-currentX;
										wmax = (w-2*currentMargin)*I1000/fontSize;
										
										i++;
										continue;
									}
									
									if ( i == j ) 
										i++;
									
									//Set the length to the size before it was greater than wmax
									l -= cwAux;
									
									//Add the cell to the current line
									cellVO.x     = currentX;
									cellVO.y     = currentY;
									cellVO.width = (l*.001)*fontSize;
									cellVO.height= pHeight;
									cellVO.text  = s.substr(j,i-j);
									
									currentLine.push ( cellVO );
									
									//Just done a line break so render the line
									renderLine ( currentLine, textAlign );
									currentLine = new Array();
									
									//Update x and y positions            
									currentX = leftMargin;
									
								} else 
								{	
									//Split at last seperator	
									//Add the cell to the current line								
									cellVO.x      = currentX;
									cellVO.y      = currentY;
									cellVO.width  = (lenAtSep*.001)*fontSize;
									cellVO.height = pHeight;
									cellVO.text   = s.substr ( j, sep-j );
									
									currentLine.push ( cellVO );
									
									if ( textAlign == Align.JUSTIFIED )
									{
										ws = (ns>1) ? (wmax-lenAtSep)/I1000*fontSize/(ns-1) : 0;
                    
                    // the "this." is important to no use the "k" loop counter (this one was tricky ... :-)
										write(sprintf('%.3f Tw',ws*this.k));
									}
									
									//Just done a line break so render the line
									renderLine(currentLine,textAlign);
									currentLine = new Array();
									
									//Update x and y positions            
									currentX = leftMargin;
									
									w = currentPage.w - 2 * currentMargin;
									i = sep + 1;
								}
								
								sep= -1;
								j  = i;
								l  = 0;
								ns = 0;
								
								currentX = leftMargin;
								
								w   = currentPage.w - rightMargin - currentX;
								wmax = ( w-2 * currentMargin )*I1000/fontSize;
								
							} else 
								i++;
						} // while( i < nb )
						
						//Last chunk 
						if ( i != j )
						{	
							//If any remaining chars then print them out                            
							//Add the cell to the current line
							cellVO.x = currentX;
							cellVO.y = currentY;
							cellVO.width = (l*.001)*fontSize;
							cellVO.height = pHeight;
							cellVO.text = s.substr(j);
							
							//Last chunk
							if ( ws>0 )
							{
								ws=0;
								write('0 Tw');
							}                
							
							currentLine.push ( cellVO );
							
							//Update X positions
							currentX += cellVO.width;
						} 
            
						break;  
          
				} // switch on tag
        
				//Is there a finished line     
				// or last line and there is something to display
				if ( k == aTaggedString.length && currentLine.length > 0 )
				{
					renderLine(currentLine,textAlign);	
					lineBreak(pHeight);
					currentLine = new Array();
				}	
			} // loop k
			
			//Is there anything left to render before we exit?
			if ( currentLine.length > 0 ) 
			{	
				renderLine ( currentLine, textAlign );
				lineBreak ( pHeight );
				currentLine = new Array();
			}            
			
			//Set current y off the page to force new page.
			currentY += currentPage.h;
		}
		
		protected function lineBreak ( pHeight : Number ):void
		{	
			currentX  = leftMargin;
			currentY += pHeight;
		}
		
		protected function getFontStyleString (  bold : Boolean, italic : Boolean, family: String ):String
		{
			var font:String = family;
			var position:int;
			
			if ( (position = font.indexOf("-")) != -1 )
				font = font.substr(0, position);
			
			if ( bold && italic )
				if(family == "Times-Roman")
					font += "-BoldItalic";
				else
					font += "-BoldOblique";
				else if ( bold )
					font += "-Bold";
				else if ( italic )
					if(family == "Times-Roman")
						font += "-Italic";
					else
						font += "-Oblique";
					else if(font == "Times")
						font = "Times-Roman";
			
			return font;
		}
		
		protected function renderLine ( lineArray : Array, align : String = '' ):void
		{	
			var cellVO    : CellVO;
			var availWidth: Number = currentPage.w - leftMargin - rightMargin;
			var lineLength: Number = 0;
			var offsetX   : Number = 0; 
			var offsetY   : Number = 0; 
			var i         : int;
			
			var firstCell : CellVO = CellVO(lineArray[0]);
			
			if ( firstCell == null )
				return;
      
      // Since we later set the font for drawing each cell, save the current
      var savedFont:IFont = currentFont;
      var savedFontSizePt:Number = fontSizePt;
      var savedUnderline:Boolean = underline;
			
			//Check if we need a new page for this line
			if ( firstCell.y + firstCell.height > pageBreakTrigger )
			{	
				addPage ();
				//Use offsetY to push already specified coord for this line back up to top of page
				offsetY = currentY - firstCell.y;
			}
			
			var lng:int = lineArray.length;
			
			//Calculate offset if we are aligning center or right
			for(i = 0; i < lng; i++)
				lineLength += (lineArray[i] as CellVO).width;
			
			//Adjust offset based on alignment
			if ( align == Align.CENTER ) 
				offsetX = (availWidth - lineLength)*.5;
			else if ( align == Align.RIGHT )
				offsetX = availWidth - lineLength;
			
			// Loop through the cells in the line and draw
			var pages:int = 0;
			var tmpCellY:Number;
			var tmpCellHeight:Number;
			for(i = 0; i < lng; i++)
			{	
				cellVO = CellVO ( lineArray[int(i)] );
				
				currentX = cellVO.x + offsetX;
				
				if (i == 0)
				{
					currentY = cellVO.y + offsetY;
				}
				else
				{
					if (Math.round(cellVO.y) > Math.round(tmpCellY))
						currentY += tmpCellHeight;
					else
						currentY -= tmpCellHeight;
				}
				
				tmpCellHeight = cellVO.height;
				tmpCellY = cellVO.y;
				
				setFont ( cellVO.font, cellVO.fontSizePt, cellVO.underlined );
				
				if ( cellVO.color != null ) 
					setTextColor ( cellVO.color );
				
				colorFlag = ( fillColor != addTextColor );
				
				addCell ( cellVO.width, cellVO.height, cellVO.text, cellVO.border, 2, null, cellVO.fill, cellVO.link );
			}
      
      // finally we restore the "old" curent font
      setFont(savedFont, savedFontSizePt, savedUnderline);
		}
		
		protected function parseTags ( myXML:XML ):Vector.<HTMLTag>
		{	
			var aTags:Vector.<HTMLTag> = new Vector.<HTMLTag>;
			var children:XMLList = myXML.children();
			var returnedTags:Vector.<HTMLTag>;
			var lng:int = children.length();
			var subLng:int;
			
			for( var i : int=0; i < lng; i++ )
			{	
				if ( children[i].name() != null )
				{	
					aTags.push( new HTMLTag ('<'+children[i].name()+'>', children[i].attributes(), "") );
					
					returnedTags = parseTags ( children[i] );
					subLng = returnedTags.length;
					
					for ( var j : int = 0; j < subLng; j++ )
						aTags.push( returnedTags[j] );
					
					aTags.push( new HTMLTag ('</'+children[i].name()+'>', children[i].attributes(), "") );
					
				} else 
					
					aTags.push( new HTMLTag ("none", new XMLList(), children[i] ) );
			}
			return aTags;
		}
		
		/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		/*
		* AlivePDF templates API
		*
		* importTemplate()
		* getTemplate()
		*
		*/
		/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		
		protected function importTemplate ( template:XML ):void
		{
			// TBD
		}
		
		protected function getTemplate ( template:XML ):XML
		{
			// TBD
			return null;
		}
		
		/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		/*
		* AlivePDF data API
		*
		* addGrid()
		*
		*/
		/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		
		/**
		 * Adds a dynamic table to the current page. This can be useful if you need to render large amount of data coming from an existing DataGrid or any data collection.
		 * 
		 * @param grid
		 * @param x
		 * @param y
		 * @param repeatHeader
		 * 
		 * This example shows how to add such a grid to the current page :
		 * <div class="listing">
		 * <pre>
		 * 
		 * // create columns to specify the column order
		 * var gridColumnAge:GridColumn = new GridColumn("City", "city", 20, Align.LEFT, Align.LEFT);
		 * var gridColumnEmail:GridColumn = new GridColumn("E-Mail", "email", 20, Align.LEFT, Align.LEFT);
		 * var gridColumnFirstName:GridColumn = new GridColumn("First Name", "firstName", 40, Align.LEFT, Align.LEFT);
		 * var gridColumnLastName:GridColumn = new GridColumn("Last Name", "lastName", 45, Align.LEFT, Align.LEFT);
		 * 
		 * // create a columns Array
		 * // it determines the order shown in the PDF
		 * var columns:Array = new Array ( gridColumnAge, gridColumnEmail, gridColumnFirstName, gridColumnLastName );
		 * 
		 * // create a Grid object as usual
		 * var grid:Grid = new Grid( dp.toArray(), 200, 120, new RGBColor ( 0xCCCCCC ), new RGBColor (0xCCCCCC), true, new RGBColor(0x887711), .1, null, columns );
		 * 
		 * p.addGrid( grid );
		 * </pre>
		 * </div>
		 */	
		public function addGrid ( grid:Grid, x:Number=0, y:Number=0, repeatHeader:Boolean=true ):void
		{	
			if ( textColor == null ) 
				throw new Error("Please call the setFont and textStyle method before adding a Grid.");
			
			currentGrid = grid;
			currentGrid.x = x;
			currentGrid.y = y;
			var i:int = 0;
			var j:int = 0;
			
			currentGrid.generateColumns(false);
			columns = currentGrid.columns;
			
			var row:Array;
			columnNames = new Array();
			var lngColumns:int = columns.length;	
			var item:*;
			
			for (i = 0; i< lngColumns; i++)
				columnNames.push ( new GridCell(columns[i].headerText, currentGrid.headerColor ) );
			
			var rect:Rectangle = getRect ( columnNames, currentGrid.headerHeight );
			if ( checkPageBreak(rect.height) )
				addPage();
			

			setXY (x +currentGrid.x, y+getY() );
			addRow( columnNames,'', rect);
			endFill();

			setXY ( x+getX(), y+getY() );
			addRow( columnNames, GridRowType.HEADER, rect );

			if (grid.cells == null)
				grid.generateCells();
			
			var buffer:Array = grid.cells;
			var lngRows:int = buffer.length;

			for (i = 0; i< lngRows; i++)
			{

				item = buffer[i];
				row = new Array();
				for (j = 0; j< lngColumns; j++)
				{
					row.push (item[columns[j].dataField] != null ? item[columns[j].dataField] : "");
					nb = Math.min(nb,nbLines(columns[j].width,row[j]));
				}

				row = buffer[i];

				
				rect = getRect ( row, currentGrid.rowHeight );
				setX ( x + getX());
				
				if ( checkPageBreak(rect.height) )
				{
					addPage();
					setXY ( x+getX(),nextPageY );
					//setXY ( x+getX(),y+getY() ); hacked to allow user to set the next Page Y of Grid
					if ( repeatHeader ) 
					{
						addRow (columnNames, GridRowType.HEADER, getRect(columnNames, currentGrid.headerHeight) ); // header
						setX ( x + getX() );
					}
				}
				
				if ( grid.useAlternativeRowColor && Boolean(isEven = i&1) )
					addRow( row, GridRowType.ALTERNATIVE, rect );
				else addRow( row, GridRowType.NORMAL, rect );
			}
		}
		

		/**
		 * This method is used to add grid when used in auto mode for big chunck of data into other pages.
		 * This may be helpful when you just want to set x,y of grid.
		 * You may set using setY after addGrid method, but is 2x slow than this simple method.
		 * 
		 * @param x
		 * @param y
		 * 
		 * @return void
		 * @langversion 3.0
		 * 
		 * This example shows how to add such a grid to the current page  :
		 * <div class="listing">
		 * <pre>
		 * 
		 * // create columns to specify the column order
		 * var gridColumnAge:GridColumn = new GridColumn("City", "city", 20, Align.LEFT, Align.LEFT);
		 * var gridColumnEmail:GridColumn = new GridColumn("E-Mail", "email", 20, Align.LEFT, Align.LEFT);
		 * var gridColumnFirstName:GridColumn = new GridColumn("First Name", "firstName", 40, Align.LEFT, Align.LEFT);
		 * var gridColumnLastName:GridColumn = new GridColumn("Last Name", "lastName", 45, Align.LEFT, Align.LEFT);
		 * 
		 * // create a columns Array
		 * // it determines the order shown in the PDF
		 * var columns:Array = new Array ( gridColumnAge, gridColumnEmail, gridColumnFirstName, gridColumnLastName );
		 * 
		 * // create a Grid object as usual
		 * var grid:Grid = new Grid( dp.toArray(), 200, 120, new RGBColor ( 0xCCCCCC ), new RGBColor (0xCCCCCC), true, new RGBColor(0x887711), .1, null, columns );
		 * 
		 * p.addGrid( grid );
		 * p.setsetGridPositionOnNextPages(); // default values are 10,10
		 * </pre>
		 * </div>
		 * */
		public function setGridPositionOnNextPages(xvalue:Number=10,yvalue:Number=10):void{
			nextPageX = yvalue;
			nextPageY = xvalue;
			
		}

		protected function getRect ( rows:Array, rowHeight:int=5 ):Rectangle

		{
			var nb:int = 0;
			var nbL:int;
			var lng:int = rows.length;
			var cell:GridCell;
			
			for(var i:int=0;i<lng;i++){
				cell = rows[i] as GridCell;
				if ( (nbL = nbLines(columns[i].width, cell.text)) > nb ) 
					nb = nbL;
			}
			
			var ph:int = rowHeight;
			var h:Number = (ph*nb > rowHeight) ? ph*nb : rowHeight;
			
			return new Rectangle(0, 0, 0, h);
		}
		
		protected function addRow(data:Array, style:String, rect:Rectangle):void
		{		    
			var a:String;
			var x:Number = 0;
			var y:Number = 0;
			var w:Number = 0;
			var h:int = rect.height;
			var lng:int = data.length;
			
			for(var i:int = 0; i<lng; i++)
			{
				var cell:GridCell = data[i] as GridCell;
				
				beginFill( cell.backgroundColor );
					
				a = (style != GridRowType.HEADER) ? columns[i].cellAlign : columns[i].headerAlign;
				rect.x = x = getX();
				rect.y = y = getY();
				rect.width = w = columns[i].width;
				lineStyle ( currentGrid.borderColor, 0, 0, currentGrid.borderAlpha );
				drawRect( rect );
				setAlpha ( 1 );
				addMultiCell(w,currentGrid.rowHeight,cell.text,0,a);
				setXY(x+w,y);
				
				endFill();
			}
			newLine(h);
		}
		
		protected function checkPageBreak(height:Number):Boolean
		{
			return getY()+height>pageBreakTrigger;
		}
		
		protected function nbLines(width:int,text:String):int
		{
			var cw:Object = currentFont.charactersWidth;
			
			if (width == 0) 
				width = currentPage.w-rightMargin-leftMargin;
			
			var wmax:int = (width-2*currentMargin)*I1000/fontSize;
			var s:String = findAndReplace("\r",'',text);
			var nb:int = s.length;
			
			if(nb>0 && s.charAt(nb-1) == "\n") 
				nb--;
			
			var sep:Number = -1;
			var i:int = 0;
			var j:int = 0;
			var l:int = 0;
			var nl:int = 1;
			var c:String;
			var cwAux:int;
			
			while(i<nb)
			{
				c = s.charAt(i);
				
				if( c == "\n" )
				{
					i++;
					sep = -1;
					j = i;
					l = 0;
					nl++;
					continue;
				}
				
				if(c==' ') 
					sep = i;
				
				cwAux = cw[c] as int;
				
				if ( cwAux == 0 ) 
					cwAux = FontMetrics.DEFAULT_WIDTH;
				
				l += cwAux;
				
				if (l>wmax)
				{
					if(sep==-1)
					{
						if(i==j)
							i++;
					} else i = sep+1;
					
					sep = -1;
					j = i;
					l = 0;
					nl++;
				}
				else
					i++;
			}
			return nl;
		}
		
		/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		/*
		* AlivePDF saving API
		*
		* save()
		* textStyle()
		* addCell()
		* addMultiCell()
		* writeText()
		*
		*/
		/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		
		/**
		 * Allows you to save the PDF locally (Flash Player 10 minmum required) or remotely through a server-side script.
		 *
		 * @param method Can be se to Method.LOCAL, the savePDF will return the PDF ByteArray. When Method.REMOTE is passed, just specify the path to the create.php file
		 * @param url The url of the create.php file
		 * @param downloadMethod Lets you specify the way the PDF is going to be available. Use Download.INLINE if you want the PDF to be opened in the browser, use Download.ATTACHMENT if you want to make it available with a save-as dialog box
		 * @param fileName The name of the PDF, only available when Method.REMOTE is used
		 * @param frame The frame where the window whould be opened
		 * @return The ByteArray PDF when Method.LOCAL is used, otherwise the method returns null
		 * @example
		 * This example shows how to save the PDF on the desktop with the AIR runtime :
		 * <div class="listing">
		 * <pre>
		 *
		 * var f:FileStream = new FileStream();
		 * file = File.desktopDirectory.resolvePath("generate.pdf");
		 * f.open( file, FileMode.WRITE);
		 * var bytes:ByteArray = myPDF.save( Method.LOCAL );
		 * f.writeBytes(bytes);
		 * f.close(); 
		 * </pre>
		 * </div>
		 * 
		 * This example shows how to save the PDF through a download dialog-box with Flash or Flex :
		 * <div class="listing">
		 * <pre>
		 *
		 * myPDF.save( Method.REMOTE, "http://localhost/save.php", Download.ATTACHMENT );
		 * </pre>
		 * </div>
		 * 
		 * This example shows how to view the PDF in the browser with Flash or Flex :
		 * <div class="listing">
		 * <pre>
		 *
		 * myPDF.save( Method.REMOTE, "http://localhost/save.php", Download.INLINE );
		 * </pre>
		 * </div>
		 * 
		 * This example shows how to save the PDF through a download dialog-box with Flash or Flex with any server involved (Flash Player 10 required) :
		 * <div class="listing">
		 * <pre>
		 *
		 * var file:FileReference = new FileReference();
		 * var bytes:ByteArray = myPDF.save( Method.LOCAL );
		 * file.save( bytes, "generated.pdf" );
		 * </pre>
		 * </div>
		 * 
		 */
		public function save ( method:String, url:String='', downloadMethod:String='inline', fileName:String='generated.pdf', frame:String="_blank" ):*
		{
			dispatcher.dispatchEvent( new ProcessingEvent ( ProcessingEvent.STARTED ) );
			var started:Number = getTimer();
			finish();
			dispatcher.dispatchEvent ( new ProcessingEvent ( ProcessingEvent.COMPLETE, getTimer() - started ) );
			buffer.position = 0;
			var output:* = null;
			
			switch (method)
			{
				case Method.LOCAL : 
					output = buffer;
					break;	
				
				case Method.BASE_64 : 
					output = Base64.encode64 ( buffer );
					break;
				
				case Method.REMOTE :
					var header:URLRequestHeader = new URLRequestHeader ("Content-type","application/octet-stream");
					var myRequest:URLRequest = new URLRequest (url+'?name='+fileName+'&method='+downloadMethod );
					myRequest.requestHeaders.push (header);
					myRequest.method = URLRequestMethod.POST;
					myRequest.data = buffer;
					navigateToURL ( myRequest, frame );
					break;
				
				default:
					throw new Error("Unknown Method \"" + method + "\"");
			}
			return output;
		}
		
		/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		/*
		* AlivePDF SWF API
		*
		* addSWF()
		*
		*/
		/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		
		private function addSWF ( swf:ByteArray ):void
		{
			// coming soon
		}
		
		/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		/*
		* AlivePDF JavaScript API
		*
		* addJavaScript()
		*
		*/
		/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		
		/**
		 * The addJavaScript allows you to inject JavaScript code to be executed when the PDF document is opened.
		 * 
		 * @param script
		 * @example
		 * This example shows how to open the print dialog when the PDF document is opened :
		 * <div class="listing">
		 * <pre>
		 *
		 * myPDF.addJavaScript ("print(true);");
		 * </pre>
		 * </div>
		 */	 
		public function addJavaScript ( script:String ):void
		{
			js = script;
		}
		
		/**
		 * The addEPSImage method takes an incoming EPS (.eps) file or Adobe® Illustrator® file (.ai) and render it on the current page.
		 * Note : Only EPS below or equal to version 8 are handled.
		 * 
		 * @param stream
		 * @param resizeMode 
		 * @param x
		 * @param y
		 * @param width
		 * @param height
		 * @param alpha
		 * @param blendMode
		 * @param link
		 * @example
		 * This example shows how to add an EPS file stream on the current page :
		 * <div class="listing">
		 * <pre>
		 *
		 * myPDF.addEPSImage ( myEPSStream );
		 * </pre>
		 * </div>
		 */	
		public function addEPSImage( stream:ByteArray, x:Number=0, y:Number=0, w:Number=0, h:Number=0, useBoundingBox:Boolean=true ):void
		{
			stream.position = 0;
			var source:String = stream.readUTFBytes(stream.bytesAvailable);
			
			var regs:Array = source.match(/%%Creator:([^\r\n]+)/);
			
			if (regs.length > 1)
			{
				var version:String = regs[1];
				
				if ( version.indexOf("Adobe Illustrator") != -1 )
				{
					var buffVersion:Array = version.split(" ");
					var numVersion:int = buffVersion.pop();
					
					if ( numVersion > 8 )
						throw new Error ("Wrong version, only 1.x, 3.x or 8.x AI files are supported for now.");
				} else throw new Error("This EPS file was not created with Adobe® Illustrator®");
			}
			
			var start:int = source.indexOf('%!PS-Adobe');
			
			if (start != -1) 
				source = source.substr(start);
			
			regs = source.match(/%%BoundingBox:([^\r\n]+)/);
			
			var x1:Number;
			var y1:Number;
			var x2:Number;
			var y2:Number;
			var buffer:Array;
			
			if (regs.length > 1)
			{
				buffer = String(regs[1]).substr(1).split(" ");
				
				x1 = buffer[0];
				y1 = buffer[1];
				x2 = buffer[2];
				y2 = buffer[3];
				
				start = source.indexOf('%%EndSetup');
				
				if ( start == -1 ) 
					start = source.indexOf('%%EndProlog');
				if ( start == -1 ) 
					start = source.indexOf('%%BoundingBox');
				
				source = source.substr(start);
				
				var end:int = source.indexOf('%%PageTrailer');
				
				if ( end == -1) 
					end = source.indexOf('showpage');
				if ( end ) 
					source = source.substr(0, end);
				
				write('q');
				
				var k:Number = k;
				var dx:Number;
				var dy:Number;
				
				if (useBoundingBox)
				{
					dx = x*k-x1;
					dy = y*k-y1;
				}else
				{
					dx = x*k;
					dy = y*k;
				}
				
				write(sprintf('%.3F %.3F %.3F %.3F %.3F %.3F cm', 1,0,0,1,dx,dy+(currentPage.hPt - 2*y*k - (y2-y1))));
				
				var scaleX:Number;
				var scaleY:Number;
				
				if (w>0)
				{
					scaleX = w/((x2-x1)/k);
					if (h>0)
					{
						scaleY = h/((y2-y1)/k);
					}else
					{
						scaleY = scaleX;
						h = (y2-y1)/k * scaleY;
					}
				}else
				{
					if (h>0)
					{
						scaleY = h/((y2-y1)/k);
						scaleX = scaleY;
						w = (x2-x1)/k * scaleX;
					}else
					{
						w = (x2-x1)/k;
						h = (y2-y1)/k;
					}
				}
				
				if (!isNaN(scaleX))
					write(sprintf('%.3F %.3F %.3F %.3F %.3F %.3F cm', scaleX, 0, 0, scaleY, x1*(1-scaleX), y2*(1-scaleY)));
				
				var lines:Array = source.split(/\r\n|[\r\n]/);
				
				var u:Number = 0;
				var cnt:int = lines.length;
				var line:String;
				var length:int;
				var chunks:Array;
				var c:String;
				var m:String;
				var ty:String;
				var tk:String;
				var cmd:String;
				
				var r:String;
				var g:String;
				var b:String;
				
				for ( var i:int=0; i<cnt; i++)
				{
					line = lines[i];
					if (line == '' || line.charAt(0) == '%') 
						continue;
					length = line.length;
					chunks = line.split(' ');
					cmd = chunks.pop();
					
					if (cmd =='Xa' || cmd =='XA')
					{
						b = chunks.pop(); 
						g = chunks.pop();
						r = chunks.pop();
						write(r+" "+g+" "+b+ " " + (cmd == 'Xa' ? 'rg' : 'RG'));
						continue;
					}
					
					switch (cmd)
					{
						case 'm':
						case 'l':
						case 'y':
						case 'c':
							
						case 'k':
						case 'K':
						case 'g':
						case 'G':
							
						case 's':
						case 'S':
							
						case 'J':
						case 'j':
						case 'w':
						case 'M':
						case 'd':
						case 'n':
						case 'v': // NO P
							write(line);
							break;
						
						case 'x':
							c = chunks[0];
							m = chunks[1];
							ty = chunks[2];
							tk = chunks[3];
							write(c+" "+m+" "+ty+" "+tk+" k");
							break;
						
						case 'X':
							c = chunks[0];
							m = chunks[1];
							ty = chunks[2];
							tk = chunks[3];
							write(c+" "+m+" "+ty+" "+tk+" K");
							break;
						
						case 'Y':
						case 'N':
						case 'V':
						case 'L':
						case 'C':
							write(line.toLowerCase());
							break;
						
						case 'b':
						case 'B':
							write(cmd + '*');
							break;
						
						case 'f':
						case 'F':
							if (u>0)
							{
								var isU:Boolean = false;
								var max:Number = i+5 < cnt ? i+5 : cnt;
								var j:int = i+1;
								for ( ; j<max; j++)
									isU = (isU || (lines[j]=='U' || lines[j]=='*U'));
								if (isU) write("f*");
							}else
								write("f*");
							break;
						
						case '*u':
							u++;
							break;
						
						case '*U':
							u--;
							break;
					}
				}
				
				write('Q');
				
			} else throw new Error("No bounding box found in the current EPS file");
		}
		
		/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		/*
		* AlivePDF image API
		*
		* addImage()
		* addImageStream()
		*
		*/
		/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		
		/**
		 * The addImageStream method takes an incoming image as a ByteArray. This method can be used to embed high-quality images (300 dpi) to the PDF.
		 * You must specify the image color space, if you don't know, there is a lot of chance the color space will be ColorSpace.DEVICE_RGB.
		 * 
		 * @param imageBytes The image stream (PNG, JPEG, GIF)
		 * @param colorSpace The image colorspace
		 * @param resizeMode A resizing behavior, like : new Resize ( Mode.FIT_TO_PAGE, Position.CENTERED ) to center the image in the page
		 * @param x The x position
		 * @param y The y position
		 * @param width The width of the image
		 * @param height The height of the image
		 * @param rotation The rotation of the image
		 * @param alpha The image alpha
		 * @param blendMode The blend mode to use if multiple images are overlapping
		 * @param keepTransformation Do you want the image current transformation (scaled, rotated) to be preserved
		 * @param link The link to associate the image with when clicked
		 * @example
		 * This example shows how to add an RGB image as a ByteArray into the current page :
		 * <div class="listing">
		 * <pre>
		 *
		 * myPDF.addImageStream( bytes, ColorSpace.DEVICE_RGB );
		 * </pre>
		 * </div>
		 * 
		 * This example shows how to add a CMYK image as a ByteArray into the current page, the image will take the whole page :
		 * <div class="listing">
		 * <pre>
		 * var resize:Resize = new Resize ( Mode.FULL_PAGE, Position.CENTERED ); 
		 * myPDF.addImageStream( bytes, ColorSpace.DEVICE_RGB, resize );
		 * </pre>
		 * </div>
		 * 
		 * This example shows how to add a CMYK image as a ByteArray into the current page, the image will take the whole page but white margins will be preserved :
		 * <div class="listing">
		 * <pre>
		 * var resize:Resize = new Resize ( Mode.RESIZE_PAGE, Position.CENTERED ); 
		 * myPDF.addImageStream( bytes, ColorSpace.DEVICE_CMYK, resize );
		 * </pre>
		 * </div>
		 */	 
		public function addImageStream ( imageBytes:ByteArray, colorSpace:String, resizeMode:Resize=null, x:Number=0, y:Number=0, width:Number=0, height:Number=0, rotation:Number=0, alpha:Number=1, blendMode:String="Normal", link:ILink=null ):void
		{
			if ( streamDictionary[imageBytes] == null )
			{
				imageBytes.position = 0;
				
				var id:int = getTotalProperties ( streamDictionary )+1;
				
				if ( imageBytes.readUnsignedShort() == JPEGImage.HEADER ) 
					image = new JPEGImage ( imageBytes, colorSpace, id );
				else if ( !(imageBytes.position = 0) && imageBytes.readUnsignedShort() == PNGImage.HEADER ) 
					image = new PNGImage ( imageBytes, colorSpace, id );
				else if ( !(imageBytes.position = 0) && imageBytes.readUTFBytes(3) == GIFImage.HEADER ) 
				{
					imageBytes.position = 0;
					var decoder:GIFPlayer = new GIFPlayer(false);
					var capture:BitmapData = decoder.loadBytes( imageBytes );
					var bytes:ByteArray = PNGEncoder.encode ( capture );
					image = new DoPNGImage ( capture, bytes, id );
				} else if ( !(imageBytes.position = 0) && (imageBytes.endian = Endian.LITTLE_ENDIAN) && imageBytes.readByte() == 73 )
				{
					image = new TIFFImage ( imageBytes, colorSpace, id );
					
				} else throw new Error ("Image format not supported for now.");
				
				streamDictionary[imageBytes] = image;
				
			} else image = streamDictionary[imageBytes];
			
			setAlpha ( alpha, blendMode );
			placeImage( x, y, width, height, rotation, resizeMode, link );
		}
		
		/**
		 * The addImage method takes an incoming DisplayObject. A JPG or PNG (non-transparent) snapshot is done and included in the PDF document.
		 * 
		 * @param displayObject The DisplayObject to embed as a bitmap in the PDF
		 * @param resizeMode A resizing behavior, like : new Resize ( Mode.FIT_TO_PAGE, Position.CENTERED ) to center the image in the page
		 * @param x The x position
		 * @param y The y position
		 * @param width The width of the image
		 * @param height The height of the image
		 * @param rotation The rotation of the image
		 * @param alpha The image alpha
		 * @param keepTransformation Do you want the image current transformation (scaled, rotated) to be preserved
		 * @param imageFormat The compression to use for the image (PNG or JPG)
		 * @param quality The compression quality if JPG is used
		 * @param blendMode The blend mode to use if multiple images are overlapping
		 * @param link The link to associate the image with when clicked
		 * @example
		 * This example shows how to add a 100% compression quality JPG image centerd on the page :
		 * <div class="listing">
		 * <pre>
		 *
		 * myPDF.addImage( displayObject, new Resize ( Mode.FIT_TO_PAGE, Position.CENTERED ) );
		 * </pre>
		 * </div>
		 * 
		 * This example shows how to add a 100% compression quality JPG image with no resizing behavior positioned at 20, 20 on the page:
		 * <div class="listing">
		 * <pre>
		 *
		 * myPDF.addImage( displayObject, null, 20, 20 );
		 * </pre>
		 * </div>
		 * 
		 */	 
		public function addImage ( displayObject:DisplayObject, resizeMode:Resize=null, x:Number=0, y:Number=0, width:Number=0, height:Number=0, rotation:Number=0, alpha:Number=1, keepTransformation:Boolean=true, imageFormat:String="PNG", quality:Number=100, blendMode:String="Normal", link:ILink=null ):void
		{			
			if ( streamDictionary[displayObject] == null )
			{	
				var bytes:ByteArray;				
				var bitmapDataBuffer:BitmapData;
				var transformMatrix:Matrix;
				
				displayObjectbounds = displayObject.getBounds( displayObject );
				
				if ( keepTransformation )
				{
					bitmapDataBuffer = new BitmapData ( displayObject.width, displayObject.height, false );
					transformMatrix = displayObject.transform.matrix;
					transformMatrix.tx = transformMatrix.ty = 0;
					transformMatrix.translate( -(displayObjectbounds.x*displayObject.scaleX), -(displayObjectbounds.y*displayObject.scaleY) );
					
				} else 
				{	
					bitmapDataBuffer = new BitmapData ( displayObject.width, displayObject.height, false );
					transformMatrix = new Matrix();
					transformMatrix.translate( -displayObjectbounds.x, -displayObjectbounds.y );
				}
				
				bitmapDataBuffer.draw ( displayObject, transformMatrix );
				
				var id:int = getTotalProperties ( streamDictionary )+1;
				
				if ( imageFormat == ImageFormat.JPG ) 
				{
					var encoder:JPEGEncoder = new JPEGEncoder ( quality );
					bytes = encoder.encode ( bitmapDataBuffer );
					image = new DoJPEGImage ( bitmapDataBuffer, bytes, id );
					
				} else if ( imageFormat == ImageFormat.PNG )
				{
					bytes = PNGEncoder.encode ( bitmapDataBuffer );
					image = new DoPNGImage ( bitmapDataBuffer, bytes, id );
					
				} else
				{
					bytes = TIFFEncoder.encode ( bitmapDataBuffer );
					image = new DoTIFFImage ( bitmapDataBuffer, bytes, id );
				}
				
				streamDictionary[displayObject] = image;
				
			} else image = streamDictionary[displayObject];
			
			setAlpha( alpha, blendMode );
			placeImage( x, y, width, height, rotation, resizeMode, link );
		}
		
		private function addTransparentImage ( displayObject:DisplayObject ):void
		{
			// TBD
		}
		
		protected function placeImage ( x:Number, y:Number, width:Number, height:Number, rotation:Number, resizeMode:Resize, link:ILink ):void
		{
			if ( width == 0 && height == 0 )
			{
				width = image.width/k;
				height = image.height/k;
			}
			
			if ( width == 0 ) 
				width = height*image.width/image.height;
			if ( height == 0 ) 
				height = width*image.height/image.width;
			
      
      var availableWidth:Number = currentPage.w-(leftMargin+rightMargin);
      var availableHeight:Number = currentPage.h-(bottomMargin+topMargin);
			
			if ( resizeMode == null )
				resizeMode = new Resize ( Mode.NONE, Position.LEFT );
			
			if ( resizeMode.mode == Mode.RESIZE_PAGE )
      {
				currentPage.resize( image.width+(leftMargin+rightMargin)*k, image.height+(bottomMargin+topMargin)*k, k );
        
        availableWidth = currentPage.w-(leftMargin+rightMargin);
        availableHeight = currentPage.h-(bottomMargin+topMargin);
        
      } else if ( resizeMode.mode == Mode.FIT_TO_PAGE )
			{			
				var ratio:Number = Math.min ( availableWidth*k/image.width, availableHeight*k/image.height );
				
				if ( ratio < 1 )
				{
					width *= ratio;
					height *= ratio;
				}
			}
				
			if ( resizeMode.position == Position.CENTERED )
			{	
				x = (availableWidth - width)*.5;
				y = (availableHeight - height)*.5;
        
        x += leftMargin;
        y += topMargin; 
        
			} else if ( resizeMode.position == Position.RIGHT )
      {
				x = availableWidth - width;
        y += topMargin;
      } else if ( resizeMode.position == Position.LEFT )
      {
			  x += leftMargin;
        y += topMargin; 
      }
      
			if ( rotation != 0)
				rotate(rotation);
			write (sprintf('q %.2f 0 0 %.2f %.2f %.2f cm', width*k, height*k, x*k, (currentPage.h - y - height)*k));
			write (sprintf('/I%d Do Q', image.resourceId));
			
			if ( link != null ) 
        addLink( x, y, width, height, link );
		}
		
		public function toString ():String
		{	
			return "[PDF totalPages="+totalPages+" nbImages="+getTotalProperties(streamDictionary)+" totalFonts="+totalFonts+" PDFVersion="+version+" AlivePDFVersion="+PDF.ALIVEPDF_VERSION+"]";	
		} 
		
		/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		/*
		* protected members
		*/
		/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		
		protected function init ( orientation:String='Portrait', unit:String='Mm', autoPageBreak:Boolean=true, pageSize:Size=null, rotation:int=0 ):void
		{
			size = ( pageSize != null ) ? Size.getSize(pageSize).clone() : Size.A4.clone();
			
			if ( size == null  ) 
				throw new RangeError ('Unknown page format : ' + pageSize +', please use a org.alivepdf.layout.' + 
					'Size object or any of those strings : Size.A3, Size.A4, Size.A5, Size.Letter, Size.Legal, Size.Tabloid');
			
			dispatcher = new EventDispatcher ( this );
			
			viewerPreferences = new String();
			outlines = new Array();
			arrayPages = new Array();
			arrayNotes = new Array();
			graphicStates = new Array();
			orientationChanges = new Array();
			nbPages = arrayPages.length;
			buffer = new ByteArray();
			offsets = new Array();
			fonts = new Array();
			differences = new Array();
			streamDictionary = new Dictionary();
			inHeader = inFooter = false;
			fontFamily = new String();
			fontStyle = new String();
			underline = false;
			
			colorFlag = false;
			matrix = new Matrix();
			
			pagesReferences = new Array();
			compressedPages = new ByteArray();
			coreFontMetrics = new FontMetrics();
			
			defaultUnit = setUnit ( unit );
			defaultSize = size;
			defaultOrientation = orientation;
			defaultRotation = rotation;
			
			n = 2;
			state = PDF.STATE_0;
			lasth = 0;
			fontSizePt = 12;
			ws = 0;
			margin = 28.35/k;
			
			setMargins ( margin, margin );
			currentMargin = margin/10;
			strokeThickness = .567/k;
			setAutoPageBreak ( autoPageBreak, margin * 2 );			
			setDisplayMode( Display.FULL_WIDTH );
			
			isLinux = Capabilities.version.indexOf ("LNX") != -1;
			version = PDF.PDF_VERSION;
		}
		
		protected function getCurrentStyle(style:String):String
		{			
			var style:String;
			
			if ( filled && stroking )
				style = Drawing.CLOSE_AND_FILL_AND_STROKE;
			else if ( filled )
				style = Drawing.FILL;
			else if ( stroking )
				style = Drawing.CLOSE_AND_STROKE;
			else style = Drawing.CLOSE_AND_STROKE;
			
			return style;
		}
		
		protected function getStringLength(string:String):int
		{
			if(currentFont.type == FontType.TYPE0)
			{
				var len:int = 0;
				var nbbytes:int = string.length;
				for (var i:int = 0; i < nbbytes; i++)
				{
					if ( string[i].charCodeAt(0) < 128 )
						len++;
					else
					{
						len++;
						i++;
					}
				}
				return len;
			}
			else
				return string.length;
		}
		
		protected function transform(tm:Matrix):void
		{
			
			write(sprintf('%.3f %.3f %.3f %.3f %.3f %.3f cm', tm.a, tm.b, tm.c, tm.d, tm.tx, tm.ty));
		}
		
		protected function getMatrixTransformPoint(px:Number, py:Number):void
		{
			var position:Point = new Point(px, py);
			var deltaPoint:Point = matrix.deltaTransformPoint(position);
			matrix.tx = px - deltaPoint.x;
			matrix.ty = py - deltaPoint.y;
		}
		
		protected function startTransform():void
		{
			write('q');
		}
		
		protected function stopTransform():void
		{
			write('Q');
		}
		
		protected function finish():void
		{
			close();
		}
		
		protected function setUnit ( unit:String ):String
		{	
			if ( unit == Unit.POINT ) 
				k = 1;
			else if ( unit == Unit.MM ) 
				k = 72/25.4;
			else if ( unit == Unit.CM ) 
				k = 72/2.54;
			else if ( unit == Unit.INCHES ) 
				k = 72;
			else throw new RangeError ('Incorrect unit: ' + unit);
      
      // We recompute the size for the current unit of all unit dependent stuff
      leftMargin = leftMarginPt/k;
      topMargin = topMarginPt/k;
      bottomMargin = bottomMarginPt/k;
      rightMargin = rightMarginPt/k;
      
			return unit;	
		}
		
		protected function acceptPageBreak():Boolean
		{
			return autoPageBreak;
		}
		
		protected function curve ( x1:Number, y1:Number, x2:Number, y2:Number, x3:Number, y3:Number ):void
		{
			var h:Number = currentPage.h;
			write(sprintf('%.2f %.2f %.2f %.2f %.2f %.2f c ', x1*k, (h-y1)*k, x2*k, (h-y2)*k, x3*k, (h-y3)*k));
		}
		
		protected function getStringWidth( content:String ):Number
		{
			charactersWidth = currentFont.charactersWidth;
			var w:Number = 0;
			var l:int = content.length;
			
			var cwAux:int = 0;
			var cw:int = 0;
			
			while (l--) 
			{	
				cw = charactersWidth[content.charAt(l)] as int;
				
				if ( cw == 0 ) 
					cw = FontMetrics.DEFAULT_WIDTH;
				
				cwAux += cw;
			}
			
			w = cwAux;
			return w*fontSize*.001;
		}
		
		protected function open():void
		{
			state = PDF.STATE_1;
		}
		
		protected function close ():void
		{
			if( arrayPages.length == 0 ) 
				addPage();
			inFooter = true;
			footer();
			inFooter = false;
			finishPage();
			finishDocument();	
		}
		
		protected function addExtGState( graphicState:Object ):int
		{
			graphicStates.push ( graphicState );
			return graphicStates.length-1;
		}
	
		protected function saveGraphicsState():void
		{
			write('q');
		}
		
		protected function restoreGraphicsState():void
		{
			write('Q');
		}
		
		protected function setExtGState( graphicState:int ):void
		{	
			write(sprintf('/GS%d gs', graphicState));	
		}
		
		protected function insertExtGState():void
		{
			var lng:int = graphicStates.length;
			
			for ( var i:int = 0; i < lng; i++)
			{
				newObj();
				graphicStates[i].n = n;
				write('<</Type /ExtGState');
				for (var k:String in graphicStates[i]) 
					write('/'+k+' '+graphicStates[i][k]);
				write('>>');
				write('endobj');
			}
		}
		
		protected function getChannels ( color:Number ):String
		{
			var r:Number = (color & 0xFF0000) >> 16;
			var g:Number = (color & 0x00FF00) >> 8;
			var b:Number = (color & 0x0000FF);
			return (r / 0xFF) + " " + (g / 0xFF) + " " + (b / 0xFF);
		}
    
    private function leftPad(stringToPad:String, desiredLength:int = 2, paddingChar:String = " "):String
    {
      if ( stringToPad == null )
        return null;
      
      if ( stringToPad.length >= desiredLength )
        return stringToPad;
      
      var paddedString:String = stringToPad;
      while ( paddedString.length < desiredLength ){
        paddedString = paddingChar + paddedString;
      }
      
      return paddedString;
    }
		
		protected function formatDate (myDate:Date):String
		{
			var year:String = String(myDate.fullYear);
			var month:String = leftPad(String(myDate.month+1), 2, "0");
			var day:String = leftPad(String(myDate.date), 2, "0");
			var hours:String = leftPad(String(myDate.hours), 2, "0");
      var min:String = leftPad(String(myDate.minutes), 2, "0");
      var sec:String = leftPad(String(myDate.seconds), 2, "0");
      
      var offSet:String = "";
      if ( myDate.timezoneOffset > 0 ) {
        offSet += "-";
      } else {
        offSet += "+";
      }
      // hours
      offSet += leftPad(String(int(Math.abs(myDate.timezoneOffset)/60)), 2, "0")+"'";
      //minutes
      offSet += leftPad(String(Math.abs(myDate.timezoneOffset)%60), 2, "0")+"'";
      
			var formatedDate:String = year+''+month+''+day+''+hours+''+min+''+sec+''+offSet;
      
			return formatedDate;
		}
		
		protected function findAndReplace ( search:String, replace:String, source:String ):String
		{
			return source.split(search).join(replace);
		}
		
		protected function createPageTree():void
		{
			compressedPages = new ByteArray();
			
			nb = arrayPages.length;
			
			if( aliasNbPages != null )
				for( var i:int = 0; i<nb; i++ ) 
					arrayPages[i].content = findAndReplace ( aliasNbPages, ( nb.toString() ), arrayPages[i].content );
			
			filter = new String();
			
			offsets[1] = buffer.length;
			write('1 0 obj');
			write('<</Type /Pages');
			write('/Kids ['+pagesReferences.join(" ")+']');
			write('/Count '+nb+'>>');
			write('endobj');
			
			var p:String;
			
			for each ( var page:Page in arrayPages )	
			{
				newObj();
				write('<</Type /Page');
				write('/Parent 1 0 R');
				write (sprintf ('/MediaBox [0 0 %.2f %.2f]', page.width, page.height) );
				write ('/Resources 2 0 R');
				if ( page.annotations != '' ) 
					write ('/Annots [' + page.annotations + ']');
				write ('/Rotate ' + page.rotation);
				if ( page.advanceTiming != 0 ) 
					write ('/Dur ' + page.advanceTiming);
				if ( page.transitions.length > 0 ) 
					write ( page.transitions );
				write ('/Contents '+(n+1)+' 0 R>>');
				write ('endobj');
				newObj();
				write('<<'+filter+'/Length '+page.content.length+'>>');
				writeStream(page.content.substr(0, page.content.length-1));
				write('endobj');
			}
		}
		
		protected function writeXObjectDictionary():void
		{
			for each ( var image:PDFImage in streamDictionary ) 
				write('/I'+image.resourceId+' '+image.n+' 0 R');
		}
		
		protected function writeResourcesDictionary():void
		{
			write('/ProcSet [/PDF /Text /ImageB /ImageC /ImageI]');
			write('/Font <<');
			for each( var font:IFont in fonts ) 
			write('/F'+font.id+' '+font.resourceId+' 0 R');
			write('>>');
			write('/XObject <<');
			writeXObjectDictionary();
			write('>>');
			write('/ExtGState <<');
			for (var k:String in graphicStates) 
				write('/GS'+k+' '+graphicStates[k].n +' 0 R');
			write('>>');
			write('/ColorSpace <<');
			for each( var color:SpotColor in spotColors)
			write('/CS'+color.i+' '+color.n+' 0 R');
			write('>>');
			write('/Properties <</OC1 '+nOCGPrint+' 0 R /OC2 '+nOCGView+' 0 R>>');
			write('/Shading <<');
			for (var i:String in gradients)
				write('/Sh'+i+' '+gradients[i].id+' 0 R');
			write('>>');
		}
		
		protected function insertImages ():void
		{
			var filter:String = new String();
			var stream:ByteArray;
			
			for each ( var image:PDFImage in streamDictionary )
			{
				newObj();
				image.n = n;
				write('<</Type /XObject');
				write('/Subtype /Image');
				write('/Width '+image.width);
				write('/Height '+image.height);
				
				if ( image.masked )
					write('/SMask '+(n-1)+' 0 R');
				
				if( image.colorSpace == ColorSpace.INDEXED ) 
					write ('/ColorSpace [/'+ColorSpace.INDEXED+' /'+ColorSpace.DEVICE_RGB+' '+((image as PNGImage).pal.length/3-1)+' '+(n+1)+' 0 R]');
				else
				{
					write('/ColorSpace /'+image.colorSpace);
					if( image.colorSpace == ColorSpace.DEVICE_CMYK ) 
						write ('/Decode [1 0 1 0 1 0 1 0]');
				}
				
				write ('/BitsPerComponent '+image.bitsPerComponent);
				
				if (image.filter != null ) 
					write ('/Filter /'+image.filter);
				
				if ( image is PNGImage || image is GIFImage )
				{
					if ( image.parameters != null ) 
						write (image.parameters);
					
					if ( image.transparency != null && image.transparency is Array )
					{
						var trns:String = '';
						var lng:int = image.transparency.length;
						for (var i:int=0;i<lng;i++) 
							trns += image.transparency[i]+' '+image.transparency[i]+' ';
						write('/Mask ['+trns+']');	
					}
				}
				
				stream = image.bytes;
				write('/Length '+stream.length+'>>');
				write('stream');
				buffer.writeBytes (stream);
				buffer.writeUTFBytes ("\n");
				write("endstream");
				write('endobj');
				
				if( image.colorSpace == ColorSpace.INDEXED )
				{
					newObj();
					var pal:String = (image as PNGImage).pal;
					write('<<'+filter+'/Length '+pal.length+'>>');
					writeStream(pal);
					write('endobj');
				}
			}
		}
		
		protected function insertFonts ():void
		{
			var nf:int = n;
			
			for each(var diff:String in differences)
			{
				newObj();
				write('<</Type /Encoding /BaseEncoding /WinAnsiEncoding /Differences ['+diff+']>>');
				write('endobj');
			}
			
			var font:IFont;
			var embeddedFont:EmbeddedFont;
			var fontDescription:FontDescription;
			var type:String;
			var name:String;
			var charactersWidth:Object;
			var s:String;
			var lng:int;
			
			for each ( font in fonts )
			{
				if ( font is EmbeddedFont )
				{
					if ( font.type == FontType.TRUE_TYPE )
					{
						embeddedFont = font as EmbeddedFont;
						fontDescription = embeddedFont.description;
						newObj();
						write ('<</Length '+embeddedFont.stream.length);
						write ('/Filter /'+Filter.FLATE_DECODE);
						write ('/Length1 '+embeddedFont.originalSize+'>>');
						write('stream');
						buffer.writeBytes (embeddedFont.stream);
						buffer.writeByte(0x0A);
						write("endstream");
						write('endobj');	
					}			
				}
				
				font.resourceId = n+1;
				type = font.type;
				name = font.name;
				
				if( !(font is EmbeddedFont) )
				{
					newObj();
					write('<</Type /Font');
					write('/BaseFont /'+name);
					write('/Subtype /Type1');
					if( name != FontFamily.SYMBOL && name != FontFamily.ZAPFDINGBATS ) 
						write ('/Encoding /WinAnsiEncoding');
					write('>>');
					write('endobj');
				}
				else if ( font is EmbeddedFont )
				{						
					newObj();
					write('<</Type /Font');
					write('/BaseFont /'+name);
					write('/Subtype /'+type);
					write('/FirstChar 32');
					write('/LastChar 255');
					write('/Widths '+(n+1)+' 0 R');
					write('/FontDescriptor '+(n+2)+' 0 R');
					if( embeddedFont.encoding != null )
					{
						if( embeddedFont.differences != null ) 
							write ('/Encoding '+(int(nf)+int(embeddedFont.differences)+1)+' 0 R');
						else write ('/Encoding /WinAnsiEncoding');
					}
					write('>>');
					write('endobj');
					newObj();
					s = '[ ';
					for(var i:int=32; i<=0xFF; ++i) 
						s += (embeddedFont.widths[String.fromCharCode(i)])+' ';
					write(s+']');
					write('endobj');
					newObj();
					write('<</Type /FontDescriptor');
					write('/FontName /'+name); 
					write('/FontWeight /'+fontDescription.fontWeight);
					write('/Descent '+fontDescription.descent);
					write('/Ascent '+fontDescription.ascent);
					write('/AvgWidth '+fontDescription.averageWidth);
					write('/Flags '+fontDescription.flags);
					write('/FontBBox ['+fontDescription.boundingBox[0]+' '+fontDescription.boundingBox[1]+' '+fontDescription.boundingBox[2]+' '+fontDescription.boundingBox[3]+']');
					write('/ItalicAngle '+ fontDescription.italicAngle);
					write('/StemV '+fontDescription.stemV);
					write('/MissingWidth '+fontDescription.missingWidth);
					write('/CapHeight '+fontDescription.capHeight);
					write('/FontFile'+(type=='Type1' ? '' : '2')+' '+(embeddedFont.resourceId-1)+' 0 R');
					write('>>');
					write('endobj');
					
				} else throw new Error("Unsupported font type: " + type + "\nMake sure you used the UnicodePDF class if you used the ArialUnicodeMS font class" );
			}
		}
		protected function insertSWF():void
		{
				/// TO BE DONE on next release	
		}
		
		protected function insertJS():void
		{
			newObj();
			jsResource = n;
			write('<<');
			write('/Names [(EmbeddedJS) '+(n+1)+' 0 R]');
			write('>>');
			write('endobj');
			newObj();
			write('<<');
			write('/S /JavaScript');
			write('/JS '+escapeString(js));
			write('>>');
			write('endobj');	
		}
		
		protected function writeResources():void
		{
			insertShaders();
			insertOCG();
			insertSpotColors();
			insertExtGState();
			insertFonts();
			insertImages();
			if ( js != null ) 
				insertJS();
			offsets[2] = buffer.length;
			write('2 0 obj');
			write('<<');
			writeResourcesDictionary();
			write('>>');
			write('endobj');
			insertBookmarks();
		}
		
		protected function insertOCG():void
		{
			newObj();
			nOCGPrint = n;
			write('<</Type /OCG /Name (print)');
			write('/Usage <</Print <</PrintState /ON>> /View <</ViewState /OFF>>>>>>');
			write('endobj');
			newObj();
			nOCGView = n;
			write('<</Type /OCG /Name (view)');
			write('/Usage <</Print <</PrintState /OFF>> /View <</ViewState /ON>>>>>>');
			write('endobj');
		}
		
		protected function insertBookmarks ():void
		{	
			var nb:int = outlines.length;
			if ( nb == 0 ) return;
			
			var lru:Array = new Array();
			var level:Number = 0;
			var o:Outline;
			
			for ( var i:String in outlines )
			{
				o = outlines[i];
				
				if(o.level > 0)
				{
					var parent:* = lru[int(o.level-1)];
					//Set parent and last pointers
					outlines[i].parent = parent;
					outlines[parent].last = i;
					if(o.level > level)
					{
						//Level increasing: set first pointer
						outlines[parent].first=i;
					}
				}
				else outlines[i].parent=nb;
				
				if(o.level<=level && int(i)>0)
				{
					//Set prev and next pointers
					var prev:int = lru[o.level];
					outlines[prev].next = i;
					outlines[i].prev=prev;
				}
				lru[o.level] = i;
				level=o.level;
			}
			
			//Outline items
			var n:int = n+1;
			
			for each ( var p:Outline in outlines )
			{
				newObj();
				write('<</Title '+escapeString(p.text));
				write('/Parent '+(n+int(p.parent))+' 0 R');
				if(p.prev != null ) 
					write('/Prev '+(n+int(p.prev))+' 0 R');
				if(p.next != null ) 
					write('/Next '+(n+int(p.next))+' 0 R');
				if(p.first != null ) 
					write('/First '+(n+int(p.first))+' 0 R');
				if(p.last != null ) 
					write('/Last '+(n+int(p.last))+' 0 R');
				write ('/C ['+p.redMultiplier+' '+p.greenMultiplier+' '+p.blueMultiplier+']');
				write(sprintf('/Dest [%d 0 R /XYZ 0 %.2f null]',1+2*p.pages,(currentPage.h-p.y)*k));
				write('/Count 0>>');
				write('endobj');
			}
			
			//Outline root
			newObj();
			outlineRoot = this.n;
			write('<</Type /Outlines /First '+n+' 0 R');
			write('/Last '+(this.n-1)+' 0 R>>');
			write('endobj');
		}
		
		protected function insertInfos():void
		{
			write ('/Producer '+escapeString('AlivePDF '+PDF.ALIVEPDF_VERSION));
			if ((documentTitle != null)) 
				write('/Title '+escapeString(documentTitle));
			if ((documentSubject != null)) 
				write('/Subject '+escapeString(documentSubject));
			if ((documentAuthor != null)) 
				write('/Author '+escapeString(documentAuthor));
			if ((documentKeywords != null)) 
				write('/Keywords '+escapeString(documentKeywords));
			if ((documentCreator != null)) 
				write('/Creator '+escapeString(documentCreator));
			write('/CreationDate '+escapeString('D:'+ formatDate(new Date()) ));
      write('/ModDate '+escapeString('D:'+ formatDate(new Date()) ));
		}
		
		protected function createCatalog ():void
		{
			write('/Type /Catalog');
			write('/Pages 1 0 R');
			
			var startingPage:String = pagesReferences[startingPageIndex];
			
			if ( zoomMode == Display.FULL_PAGE ) 
				write('/OpenAction ['+startingPage+' /Fit]');
			else if ( zoomMode == Display.FULL_WIDTH ) 
				write('/OpenAction ['+startingPage+' /FitH null]');
			else if ( zoomMode == Display.REAL ) 
				write('/OpenAction ['+startingPage+' /XYZ null null '+zoomFactor+']');
			else if ( !(zoomMode is String) ) 
				write('/OpenAction ['+startingPage+' /XYZ null null '+(zoomMode*.01)+']');
			
			write('/PageLayout /'+layoutMode);
			
			if ( viewerPreferences.length ) 
				write ( '/ViewerPreferences '+ viewerPreferences );
			
			if ( outlines.length )
			{
				write('/Outlines '+outlineRoot+' 0 R');
				write('/PageMode /UseOutlines');
			} else write('/PageMode /'+pageMode);
			
			if ( js != null )
				write('/Names <</JavaScript '+(jsResource)+' 0 R>>');
			
			var p:String = nOCGPrint+' 0 R';
			var v:String = nOCGView+' 0 R';
			var ast:String = "<</Event /Print /OCGs ["+p+" "+v+"] /Category [/Print]>> <</Event /View /OCGs ["+p+" "+v+"] /Category [/View]>>";
			write("/OCProperties <</OCGs ["+p+" "+v+"] /D <</ON ["+p+"] /OFF ["+v+"] /AS ["+ast+"]>>>>");
		}
		
		protected function createHeader():void
		{
			write('%PDF-'+version);
		}
		
		protected function createTrailer():void
		{
			write('/Size '+(n+1));
			write('/Root '+n+' 0 R');
			write('/Info '+(n-1)+' 0 R');
		}
		
		protected function finishDocument():void
		{	
			if ( pageMode == PageMode.USE_ATTACHMENTS ) 
				version = "1.6";
			else if ( layoutMode == Layout.TWO_PAGE_LEFT || layoutMode == Layout.TWO_PAGE_RIGHT || visibility != null ) 
				version = "1.5";
			else if ( graphicStates.length && version < "1.4" ) 
				version = "1.4";
			else if ( outlines.length ) 
				version = "1.4";
			//Resources
			createHeader();
			var started:Number;
			started = getTimer();
			createPageTree();
			dispatcher.dispatchEvent ( new ProcessingEvent ( ProcessingEvent.PAGE_TREE, getTimer() - started ) );
			started = getTimer();
			writeResources();
			dispatcher.dispatchEvent ( new ProcessingEvent ( ProcessingEvent.RESOURCES, getTimer() - started ) );
			//Info
			newObj();
			write('<<');
			insertInfos();
			write('>>');
			write('endobj');
			//Catalog
			insertSWF();
			newObj();
			write('<<');
			createCatalog();
			write('>>');
			write('endobj');
			//Cross-ref
			var o:int = buffer.length;
			write('xref');
			write('0 '+(n+1));
			write('0000000000 65535 f ');
			for( var i:int=1; i<=n; i++) 
				write(sprintf('%010d 00000 n ', offsets[i]));
			//Trailer
			write('trailer');
			write('<<');
			createTrailer();
			write('>>');
			write('startxref');
			write(o.toString());
			write('%%EOF');
			state = PDF.STATE_3;
		}
		
		protected function startPage ( newOrientation:String ):void
		{
			nbPages = arrayPages.length;
			state = PDF.STATE_2;
			
			setXY(leftMargin, topMargin);
			
			if ( newOrientation == '' ) 
				newOrientation = defaultOrientation;
			else if ( newOrientation != defaultOrientation ) 
				orientationChanges[nbPages] = true;
			
			pageBreakTrigger = arrayPages[nbPages-1].h-bottomMargin;
			currentOrientation = newOrientation;
		}
		
		protected function finishPage():void
		{
			setVisible(Visibility.ALL);
			state = PDF.STATE_1;	
		}
		
		protected function newObj():void
		{
			offsets[int(++n)] = buffer.length;
			write (n+' 0 obj');
		}
		
		protected function doUnderline( x:Number, y:Number, content:String ):String
		{
			underlinePosition = currentFont.underlinePosition;
			underlineThickness = currentFont.underlineThickness;
			var w:Number = getStringWidth(content)+ws*substrCount(content, ' ');
			return sprintf('%.2f %.2f %.2f %.2f re f',x*k,(currentPage.h-(y-(underlinePosition*.001)*fontSize))*k,w*k,(-underlineThickness*.001)*fontSizePt);
		}
		
		protected function substrCount ( content:String, search:String ):int
		{
			return content.split (search).length;			
		}
		
		protected function getTotalProperties ( object:Object ):int
		{
			var num:int = 0;
			for (var p:String in object) 
				num++;
			return num;
		}
		
		protected function escapeString(content:String):String
		{
			return '('+escapeIt(content)+')';
		}
		
		protected function escapeIt(content:String):String
		{
			content = findAndReplace('\n', "\\n",content);
			content = findAndReplace('\r', "\\r",content);
			content = findAndReplace('\t', "\\t",content);
			content = findAndReplace('\b', "\\b",content);
			content = findAndReplace('\f', "\\f",content);
			return findAndReplace(')','\\)',findAndReplace('(','\\(',findAndReplace('\\','\\\\',content)));
		} 
		
		protected function writeStream(stream:String):void
		{
			write('stream');
			write(stream);
			write('endstream');
		}
		
		protected function write( content:String ):void
		{
			if ( currentPage == null ) 
				throw new Error ("No pages available, please call the addPage method first.");
			if ( state == PDF.STATE_2 ) 
				currentPage.content += content+"\n";
			else 
			{
				if ( !isLinux )
				{
					if(content.indexOf("\xFE\xFF") > 0)
					{
						var chunks:Array = content.split("\xFE\xFF");
						var chunk:String;
						var len:int = chunks.length;
					
						for(var i:int =0;i<len;i++)
						{
							chunk = chunks[i] as String;
							buffer.writeMultiByte(chunk, "windows-1252");
							if(i == len-1 && chunk != "") continue;
							buffer.writeByte(0);
						}
						buffer.writeByte(0x0A);
					}
					else buffer.writeMultiByte( content+"\n", "windows-1252" );
				}
				else 
				{
					var contentTxt:String = content.toString();
					var lng:int = contentTxt.length;
					for(i=0; i<lng; ++i)
							buffer.writeByte(contentTxt.charCodeAt(i));
					buffer.writeByte(0x0A);
				}
			}
		}
		
		//--
		//-- IEventDispatcher
		//--
		
		public function addEventListener( type:String, listener:Function, useCapture:Boolean = false, priority:int = 0, useWeakReference:Boolean = false ):void
		{
			dispatcher.addEventListener( type, listener, useCapture, priority, useWeakReference );
		}
		
		public function dispatchEvent( event:Event ):Boolean
		{
			return dispatcher.dispatchEvent( event );
		}
		
		public function hasEventListener( type:String ):Boolean
		{
			return dispatcher.hasEventListener( type );
		}
		
		public function removeEventListener( type:String, listener:Function, useCapture:Boolean = false ):void
		{
			dispatcher.removeEventListener( type, listener, useCapture );
		}
		
		public function willTrigger( type:String ):Boolean
		{
			return dispatcher.willTrigger( type );
		}
	}	
}