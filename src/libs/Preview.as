package libs
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Loader;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.geom.Matrix;
	import flash.net.URLRequest;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;
	
	import baidu.local.StaticLib;
	
	/**
	 * 头像预览类
	 * */
	public class Preview extends Sprite{
		
		private var sizeList:Array = new Array(); //所有预览头像的尺寸列表
		private var imageList:Array = new Array(); //所有预览头像的列表
		
		private var _parent:Sprite; //父容器
		private var _previewWidth:int; //预览区域的宽度
		private var _previewHeight:int; //预览区域的高度
		
		private var _previewX:int; //预览区域的x坐标
		private var _previewY:int; //预览区域的y坐标
		
		private var _previewPaddingLeft:int; //预览区域的左padding
		
		private var _currentTop:int; //当前布局的top值
		
		public function Preview(parent:Sprite, imageSizeList:Array, defaultPreview:String){
			_parent = parent;
			
			_previewWidth = StaticLib.config.previewWidth;
			_previewX = _parent.stage.stageWidth - _previewWidth;
			
			_previewY = StaticLib.config.topBarHeight;
			_previewHeight = _parent.stage.stageHeight - _previewY;
			
			_previewPaddingLeft = StaticLib.config.previewPaddingLeft;
			
			_currentTop = StaticLib.config.previewPaddingTop;
			
			sizeList = imageSizeList;
			_buildUI(imageSizeList, defaultPreview);
			
			this.x = _previewX;
			this.y = _previewY;
			
			with(this.graphics){
				beginFill(0xffffff, 1);
				drawRect(0, 0, _previewWidth, _previewHeight);
				endFill();
			}
			parent.addChild(this);
			
		}
		
		/**
		 * 创建各个尺寸的预览图片
		 * */
		private function _buildUI(sizeList : Array, defaultPreview:String):void{
			for(var i:int = 0; i < sizeList.length; i++){
				_buildPreview(sizeList[i]);
			}
			//_buildPreview(100);
			
			//_buildPreview(100);
			var loader:Loader = new Loader();
			var myURL:URLRequest = new URLRequest(defaultPreview);//取出图片文件名
			loader.contentLoaderInfo.addEventListener(Event.COMPLETE, _imageLoaded);
			loader.load(myURL);//载入图片
			
		}
		/***
		 * 设置的图片加载完成
		 */
		private function _imageLoaded(evt:Event):void{
			StaticLib.console('log', 'loader已经loaded');
			var _bitmapData:BitmapData = (evt.target.content as Bitmap).bitmapData;
			this.render( _bitmapData );
		}
		
		/**
		 * 创建一个预览图片框框
		 * */
		private function _buildPreview(size:String):void{
			var w:int = size.split('*')[0];
			var h:int = size.split('*')[1];
			var item:Sprite = new Sprite();
			var image:Bitmap = new Bitmap();
			image.x = _previewPaddingLeft;
			image.y = _currentTop;
			imageList.push(image);
			this.addChild(image);
			
			var text:TextField = new TextField();
			text.x = _previewPaddingLeft;
			text.y = _currentTop + h + 5;
			text.width = w;
			text.autoSize = TextFieldAutoSize.CENTER;
			
			var newFormat:TextFormat = new TextFormat();
			newFormat.color = 0x999999;
			newFormat.size = 14;
			text.defaultTextFormat = newFormat;
			text.appendText(w + 'x' + h);
			this.addChild(text);
			
			
			StaticLib.console('log', 'imagex:' + image.x + 'imagey:' + image.y);
			
			_currentTop += h + 35; //间隔为5
			
		}
		
		/**
		 * 渲染预览图
		 * */
		public function render(bitmapData:BitmapData):void{
			
			for(var i:int = 0; i < sizeList.length; i++){
				var _image:Bitmap = imageList[i];
				var size:String = sizeList[i];
				
				var imageWidth:int = size.split('*')[0];
				var imageHeight:int = size.split('*')[1];
				var viewBitmapData:BitmapData = new BitmapData(imageWidth, imageHeight);
				viewBitmapData.draw(bitmapData, new Matrix(imageWidth / bitmapData.width, 0, 0, imageHeight / bitmapData.height), null, null, null, true);
				
				
				
				
				_image.bitmapData && _image.bitmapData.dispose();
				_image.bitmapData = viewBitmapData;
			}
			
			
		}
	}
}