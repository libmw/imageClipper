package
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Loader;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.ContextMenuEvent;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.MouseEvent;
	import flash.events.ProgressEvent;
	import flash.events.SecurityErrorEvent;
	import flash.external.ExternalInterface;
	import flash.geom.Matrix;
	import flash.geom.Rectangle;
	import flash.net.FileFilter;
	import flash.net.FileReference;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.net.URLRequestHeader;
	import flash.net.URLRequestMethod;
	import flash.net.URLVariables;
	import flash.net.navigateToURL;
	import flash.system.LoaderContext;
	import flash.system.Security;
	import flash.system.System;
	import flash.ui.ContextMenu;
	import flash.ui.ContextMenuItem;
	import flash.utils.ByteArray;
	import flash.utils.clearInterval;
	import flash.utils.setTimeout;
	import baidu.lib.images.BMPDecoder;
	import baidu.lib.serialization.JSON;
	import baidu.local.JPGEncoderIMP;
	import baidu.local.StaticLib;
	import baidu.local.UploadPostHelper;
	
	import libs.Clipper;
	import libs.Preview;
	
	public class ImageClipper extends Sprite 
	{    
		private var _image:Bitmap = new Bitmap(); //裁剪的图片
		private var _bitmapData:BitmapData;
		private var _uploadData:ByteArray; //用于上传的bytearray
		private var _loader:Loader = new Loader();
		private var _zoom:Number; //缩放
		
		private var _clipper:Clipper;
		private var _fileURLLoader : URLLoader = new URLLoader();					//上传
		private var _errorMessage:String;
		private var _response:Object;
		
		private var _options:Object; //参数配置
		
		private var _preview:Preview; //头像预览框
		
		private var _requestVariables:Array = new Array(); //上传参数
		
		private var _fileReference:FileReference = new FileReference(); //图片选择框
		
		
		public function ImageClipper(){ 
			this.addEventListener(Event.ENTER_FRAME, checkLoaded);
		}
		
		/**
		 * 确保自身加载完成
		 */
		private function checkLoaded(evt:Event = null):void {
			if (stage.stageWidth > 0 && stage.stageHeight > 0) {
				this.removeEventListener(Event.ENTER_FRAME, checkLoaded);
				init();
			}
		}
		
		/**
		 * 加载完后开始初始化
		 */
		private function init():void {
			
			_initOptions();
			
			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.align = StageAlign.TOP_LEFT;
			System.useCodePage = true;
			flash.system.Security.allowDomain('*');
			
			StaticLib.config = {
				'topBarHeight': 48, //顶部工具条的高度
				'previewWidth': _options["isPreview"] ? (_options["previewWidth"] + 15) : 0, //预览头像区域的宽度
					'previewPaddingTop': 15, //预览头像区域的顶部padding
					'previewPaddingLeft': 15, //预览头像区域的左padding
					'urlPath': _options["resourceUrl"]
			};
			
			StaticLib.callback = {
				'on_complete' : _options['complete'] || 'on_complete',
					'on_error' : _options['error'] || 'on_error',
					'on_load' : _options['load'] || 'on_load'
			};
			
			
			_regInterface();
			_buildUI();
			_bindEvents();
			
			var menu:ContextMenu = new ContextMenu();
			var menuItem:ContextMenuItem = new ContextMenuItem("imageClipper V1.0");
			// 隐藏内建菜单
			menu.hideBuiltInItems()
			//设置右键菜单为自定义菜单
			this.contextMenu = menu;
			// 在菜单数组中添加一个选项；
			menu.customItems.push(menuItem);
			// 给菜单选项添加事件；
			// 给菜单选项添加事件；
			menuItem.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT,menuItem_click);
			function menuItem_click(event:ContextMenuEvent):void{
				navigateToURL(new URLRequest("https://github.com/libmw/imageClipper"))
			}
		}
		
		
		
		/**
		 * 获取页面传递过来的参数
		 * */
		private function _initOptions():void{
			//获取配置
			_options = this.loaderInfo.parameters;
			
			
			StaticLib.console('console.log', _options);
			
			//上传地址
			_options["uploadUrl"] = _options["uploadUrl"] || "index.php";
			
			//上传文件的字段名
			_options["file"] = _options["file"] || "file";
			
			var selfUrl:String = this.stage.loaderInfo.url; 
			//静态资源的地址，按钮图片，缩放光标图片等
			_options["resourceUrl"] = _options["resourceUrl"] || selfUrl.substring(0, selfUrl.lastIndexOf("/"));
			
			//是否有预览图
			_options["isPreview"] = _options["isPreview"] == 'false' ? false : true;
			
			//预览图尺寸
			_options["previewSize"] = _options["previewSize"] || '200*200|80*80|48*48';
			
			//默认预览图
			_options["defaultPreview"] = _options["defaultPreview"] || _options["resourceUrl"] + '/default-200.jpg';
			
			//裁剪区域宽度			
			_options["previewWidth"] = 100;
			
			if(_options["previewSize"].split('|')[0]){
				var previewSize:Array = _options["previewSize"].split('|');
				for(var i:int = 0; i < previewSize.length; i++){
					_options["previewWidth"] = Math.max(_options["previewWidth"], previewSize[i].split('*')[0]);
				}
			}
			
			
			//长宽比,为0代表不限制比例
			_options["ratio"] = parseFloat(_options["ratio"]);
			
			if(isNaN(_options["ratio"])){
				_options["ratio"] = 0;
			}
			
			//默认图片的地址
			if(_options["imgSrc"]){
				setImageSrc(_options["imgSrc"]);
			}
			
			
		}
		
		/**
		 * 注册js调用的接口
		 * */
		private function _regInterface():void{
			
			if(!ExternalInterface.available){
				StaticLib.console('log', 'MultiUploadMain._regInterface - flash没有准备好');
				setTimeout(_regInterface, 50);
				return;
			}
			
			var _interfaceList : Object = {
				'testInterface' : StaticLib.console,
					'setImageSrc' : setImageSrc, //设置裁剪图片的地址
					'submit' : submit		//提交
			};
			
			try {
				_regInterfaceHandler(_interfaceList);
				callBack(StaticLib.callback["on_load"]);
				StaticLib.console('log', 'MultiUploadMain._regInterface - 注册对外接口成功！!!!');
			}catch(e:*){
				StaticLib.console('log', 'MultiUploadMain._regInterface - flash没有准备好');
				setTimeout(_regInterface, 50);
				return;
			}
		}
		
		/**
		 * 循环注册js调用的接口
		 * */
		
		private function _regInterfaceHandler(interfaceList:Object):void{
			for(var i:String in interfaceList){
				ExternalInterface.addCallback(i, interfaceList[i]);
			}
		}
		
		private function _bindEvents():void{
			_loader.contentLoaderInfo.addEventListener(Event.COMPLETE, _imageLoaded);
			_fileURLLoader.addEventListener(Event.COMPLETE, urlUploadCompleteDataHandler); //上传成功
			_fileURLLoader.addEventListener(IOErrorEvent.IO_ERROR, _uploadError); //上传失败
			_fileURLLoader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, _uploadError); //上传失败
		}
		
		/**
		 * 渲染
		 * */
		private function _buildUI():void{
			//顶部条
			_buildTopBar();
			
			//裁剪的图片
			addChild(_image);
			
			StaticLib.console('log', getImageRect());
			
			//裁剪框
			_clipper = new Clipper(this, 10, 10, null, true, _options['ratio'], false, _options['cliperSize']);
			this.addEventListener(Event.CHANGE, function(evt:Event):void{
				StaticLib.console('log', '缩放框：');
				StaticLib.console('log', getImageRect());
				_clipper.initClipRect(getImageRect());
				_clipper.begin();
			});
			_clipper.addEventListener(Event.COMPLETE, function(evt:Event):void{
				//_previewer.clipImage(_clipper.getClipRect());
			});
			
			
			StaticLib.console('log', 'preview: ' + _options['isPreview']);
			
			//预览图
			_preview = new Preview(this, _options["previewSize"].split('|'), _options["defaultPreview"]);				
			
			
			StaticLib.console('console.log', this.width);
			
			var backImage:MovieClip = new MovieClip();
			addChild(backImage);
			
			backImage.graphics.lineStyle(0.5, 0x999999, 0.5);//边框宽度2，红色，alpha 1
			backImage.graphics.drawRoundRect(0, 0, 100, 100, 0 , 0);
			backImage.graphics.endFill();
			backImage.x = 1;
			backImage.y = StaticLib.config.topBarHeight;
			backImage.width = stage.stageWidth - StaticLib.config.previewWidth - ( _options["isPreview"] == 'false' ? 0 : 2);
			backImage.height = stage.stageHeight - StaticLib.config.topBarHeight - 1;
			
			var loader:Loader = new Loader();
			var myURL:URLRequest = new URLRequest(StaticLib.config.urlPath + '/bg.jpg?new1');//取出图片文件名
			loader.contentLoaderInfo.addEventListener(Event.COMPLETE, _imageLoaded);
			loader.load(myURL);//载入图片
			
			function _imageLoaded(evt:Event):void{
				var _bitmap:Bitmap = Bitmap(loader.content);
				var sampleSprite:Sprite = new Sprite();
				sampleSprite.graphics.beginBitmapFill(_bitmap.bitmapData, null , true , false); 				
				sampleSprite.graphics.drawRect(1, 1, 900, 900);
				sampleSprite.graphics.endFill();
				sampleSprite.width = 100;
				sampleSprite.height = 100;
				backImage.addChild(sampleSprite);
				setChildIndex(backImage,0);
			}
			
		}
		
		/**
		 * 渲染topbar
		 * */
		private function _buildTopBar():void{
			_buildUploadBtn();
			_buildRotateBtn();
		}
		
		/**
		 * 上传按钮相关
		 * */
		private function _buildUploadBtn():void{
			//渲染按钮
			var uploadBtn:Sprite = new Sprite();
			var loader:Loader = _imageLoader(StaticLib.config.urlPath + '/btn_upload.png', 7, 8);
			
			uploadBtn.buttonMode = true;
			uploadBtn.addChild(loader);
			addChild(uploadBtn);
			
			//按钮事件
			uploadBtn.addEventListener(MouseEvent.CLICK, _browseFile);
			//			_uploadBtn.addEventListener(MouseEvent.ROLL_OVER, _buttonToggle);
			//			_uploadBtn.addEventListener(MouseEvent.ROLL_OUT, _buttonToggle);
			
			//文件选择事件
			_fileReference.addEventListener(Event.SELECT, _selectFile);
			_fileReference.addEventListener(Event.CANCEL, _selectFile);
			_fileReference.addEventListener(Event.COMPLETE, _fileLoaded); //load完成后触发的事件
			//_fileReference.addEventListener(IOErrorEvent.IO_ERROR, errorHandler);  //load错误后触发的事件
		}
		
		private function _browseFile(evt : MouseEvent = null) : void {
			var _fileFilter:FileFilter = new FileFilter('图片', 'png|jpg|gif|bmp'.replace('png','*.png').replace('jpg','*.jpg;*.jpeg').replace('gif','*.gif').replace('bmp','*.bmp').replace(/\|/g,';'));
			_fileReference.browse([_fileFilter]);
			
		}
		
		private function _selectFile(evt : Event = null) : void {
			switch(evt.type) {
				case Event.SELECT:
					_fileReference.load();
					break;
				case Event.CANCEL:
					break;
			}		
		}
		
		/**
		 * _fileReference.data加载完毕
		 * */
		private function _fileLoaded(evt : Event = null):void{
			
			if(_fileReference.type.toLowerCase() == '.bmp'){
				
				var decoder:BMPDecoder = new BMPDecoder();
				/**
				 * 首先解码BMP图片为BitmapData
				 * */
				try{
					_bitmapData = decoder.decode(_fileReference.data);
					_drawPreview();
				}
				catch (err:Error){ //bmp解码失败
					_error('解码失败，请选择其他图片');
					return;
				}
			}else{
				var loader:* = new Loader(); //使用loader来改变图片大小
				loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, _fileContentError);
				loader.contentLoaderInfo.addEventListener(Event.COMPLETE, _fileContentLoaded);
				loader.loadBytes(_fileReference.data);
			}
		}
		
		/**
		 * 转换_fileReference.data为bitMap对象
		 * */
		private function _fileContentLoaded(evt : Event = null):void{
			var loader:Loader = evt.target.loader as Loader;
			(loader.content as Bitmap).smoothing = true;
			_bitmapData = (loader.content as Bitmap).bitmapData;
			_drawPreview();
		}
		
		/**
		 * _fileReference图片加载失败
		 * */
		private function _fileContentError(evt : Event = null):void{
			_error('图片加载失败，请换一张图片试试');
		}
		
		
		/**
		 * 旋转按钮相关
		 * */
		private function _buildRotateBtn():void{
			//渲染按钮
			var rotateBtn:Sprite = new Sprite();
			var loader:Loader = _imageLoader(StaticLib.config.urlPath + '/btn_rotate.png', 152, 15);
			rotateBtn.buttonMode = true;
			rotateBtn.addChild(loader);
			addChild(rotateBtn);
			
			//按钮事件
			rotateBtn.addEventListener(MouseEvent.CLICK, _rotate);
		}
		
		private function _rotate(evt:Event):void{
			
			var degree:int = 90;
			
			var matrix:Matrix = new Matrix();
			matrix.rotate(degree * Math.PI / 180);
			var bitmapData:BitmapData = new BitmapData(_bitmapData.width, _bitmapData.height, true);
			bitmapData.draw(_bitmapData);
			if(degree == 90 || degree == 270){
				_bitmapData = new BitmapData(bitmapData.height, bitmapData.width, true);
				if(degree == 90){
					matrix.translate(bitmapData.height, 0);
				}else{
					
					matrix.translate(0, bitmapData.width);
				}
			}else if(degree == 180){
				_bitmapData = new BitmapData(bitmapData.width, bitmapData.height, true);
				matrix.translate(bitmapData.width, bitmapData.height);
			}
			StaticLib.console('console.log', '旋转角度：'+degree);
			StaticLib.console('console.log', '旋转fudu：'+(degree * Math.PI / 180));
			_bitmapData.draw(bitmapData, matrix);
			_drawPreview();
		}
		
		/**
		 * 绘制图片到场景上
		 * */
		private function _drawPreview():void{
			var _previewWidth:Number,
			_previewHeight:Number;
			
			var originalWidth:Number = _bitmapData.width;
			var originalHeight:Number = _bitmapData.height;
			var originalAspectratio:Number = originalWidth / originalHeight;
			
			var clipCtnWidth:int = stage.stageWidth - StaticLib.config.previewWidth;
			var clipCtnHeight:int = stage.stageHeight - StaticLib.config.topBarHeight;
			var stageAspectratio:Number = clipCtnWidth / clipCtnHeight;
			StaticLib.console('console.log', 'topbar:'+StaticLib.config.topBarHeight+',stageHeight:'+stage.stageHeight);
			
			
			//获取缩放结果
			if(originalAspectratio > stageAspectratio){
				_previewWidth = clipCtnWidth;
				_previewHeight = clipCtnWidth / originalAspectratio;
				_zoom = _previewWidth / _bitmapData.width;
			}else{
				_previewHeight = clipCtnHeight;
				_previewWidth = clipCtnHeight * originalAspectratio;
				_zoom = _previewHeight / _bitmapData.height;
			}
			
			
			var viewBitmapData:BitmapData = new BitmapData(_previewWidth, _previewHeight);
			viewBitmapData.draw(_bitmapData, new Matrix(_zoom, 0, 0, _zoom), null, null, null, true);
			_image.bitmapData && _image.bitmapData.dispose();
			_image.bitmapData = viewBitmapData;
			
			//_bitmapData.dispose();
			
			_image.x = (clipCtnWidth - _previewWidth) / 2;
			_image.y = (clipCtnHeight - _previewHeight) / 2 + StaticLib.config.topBarHeight;
			
			
			dispatchEvent(new Event(Event.CHANGE));
		}
		
		public function zoom(times:Number):void{
			
		}
		
		public function submit():void{
			if(_bitmapData){
				_jpgEncode(_getUploadData());
			}else{
				_error('请选择头像图片');
			}
			
		}
		
		private function _getUploadData():BitmapData{
			var clipRect:Rectangle = _clipper.getClipRect();
			
			if(_options['uploadSize']){
			}
			
			
			var originalClipRect:Rectangle = new Rectangle(
				clipRect.x / _zoom,
				clipRect.y / _zoom,
				clipRect.width / _zoom,
				clipRect.height / _zoom
			);
			
			
			//原始图片裁切后的bitmapData
			var originalClipedBitmapData: BitmapData = new BitmapData(originalClipRect.width, originalClipRect.height); 
			var matrix:Matrix = new Matrix(1, 0, 0, 1, -originalClipRect.x, -originalClipRect.y); 
			originalClipedBitmapData.draw(_bitmapData, matrix);
			
			
			
			if(_options['uploadSize']){ //指定了上传尺寸，拉伸到上传尺寸
				var uploadWidth:int;
				var uploadHeight:int;
				uploadWidth = _options['uploadSize'].split('*')[0];
				uploadHeight = _options['uploadSize'].split('*')[1];
				
				var uploadBitmapData: BitmapData = new BitmapData(uploadWidth, uploadHeight);
				uploadBitmapData.draw(originalClipedBitmapData, new Matrix(uploadWidth / originalClipedBitmapData.width, 0, 0, uploadHeight / originalClipedBitmapData.height), null, null, null, true);
				return uploadBitmapData;
			}else{ //直接上传原始图片裁切后的尺寸
				return originalClipedBitmapData;
			}
			
			
			
			
		}
		
		/**
		 * 重置预览图
		 * */
		public function resetPreviewImage():void{
			var clipRect:Rectangle = _clipper.getClipRect();
			var originalClipRect:Rectangle = new Rectangle(
				clipRect.x / _zoom,
				clipRect.y / _zoom,
				clipRect.width / _zoom,
				clipRect.height / _zoom
			);
			
			var _tempBitmapData:BitmapData = new BitmapData(originalClipRect.width, originalClipRect.height);
			var matrix:Matrix = new Matrix(1, 0, 0, 1, -originalClipRect.x, -originalClipRect.y); 
			//不要使用clipRect参数来裁剪，坑爹的。它绘制的时候会在_tempBitmapData上从clipRect的x，y坐标开始绘制
			_tempBitmapData.draw(_bitmapData, matrix);
			_preview.render(_tempBitmapData);
			
		}
		
		
		/**
		 * 开始上传
		 * */
		private function _upload(uploadUrl:String):void{
			var urlRequest : URLRequest = new URLRequest(uploadUrl);
			urlRequest.method = URLRequestMethod.POST;
			
			var variables:URLVariables = new URLVariables();
			for (var pro:String in _requestVariables) {
				variables[pro] = _requestVariables[pro];
			}
			
			StaticLib.console('log', '---------------------here');
			
			StaticLib.console('log', variables);
			
			urlRequest.data = UploadPostHelper.getPostData(_getFileName() + '.jpg', _uploadData, _options["file"], variables);
			urlRequest.requestHeaders.push(new URLRequestHeader('Cache-Control', 'no-cache'));
			urlRequest.requestHeaders.push(new URLRequestHeader('Content-Type', 'multipart/form-data; boundary=' + UploadPostHelper.getBoundary()));
			
			_fileURLLoader.dataFormat = URLLoaderDataFormat.BINARY;
			_fileURLLoader.load(urlRequest);
		}
		
		
		
		private function _getFileName():String{	
			var date:Date = new Date();
			return 'img_' +  date.getTime();
		}
		
		/**
		 * 压缩完成 进行异步jpg编码
		 * */
		private function _jpgEncode(bitmapData:BitmapData):void{
			StaticLib.console('console.log','width12121212:'+bitmapData.width + ',height:'+bitmapData.height);
			var jpgEncoder:JPGEncoderIMP = new JPGEncoderIMP(90);
			jpgEncoder.addEventListener(Event.COMPLETE, _handleEncodeComplete);
			jpgEncoder.addEventListener(ProgressEvent.PROGRESS, _handleEncodeProgress);
			jpgEncoder.encodeAsync(bitmapData);
		}
		
		/**
		 * 编码完成
		 * */
		private function _handleEncodeComplete(evt:Event) : void{
			_uploadData = ((evt.target) as JPGEncoderIMP).ba;
			_upload(_options.uploadUrl);
		}
		
		/**
		 * 编码进度
		 * */
		private function _handleEncodeProgress(evt:ProgressEvent) : void{
			dispatchEvent(new ProgressEvent(ProgressEvent.PROGRESS, false, false, evt.bytesLoaded, evt.bytesTotal));
			//StaticLib.consoleB('console.log','当前进度:'+(evt.bytesLoaded/evt.bytesTotal));
			return;
		}
		
		/**
		 * 上传事件：上传完成，拿到服务端返回数据
		 */
		private function urlUploadCompleteDataHandler(evt : Event = null) : void {
			var resultString : String = _fileURLLoader.data;
			StaticLib.console('console.log', '上传完成，数据位'+resultString);
			try { 
				_response = baidu.lib.serialization.JSON.decode(resultString);
				callBack(StaticLib.callback["on_complete"]);
			}catch (err:Error) {
				_response = resultString;
				_error();
			}
		}
		
		/**
		 * 上传失败
		 * */
		private function _uploadError(evt:* = null):void{
			_error();
		}
		
		/**
		 * 错误抛出
		 * */
		private function _error(msg:String = '上传失败'):void {
			_errorMessage = msg;
			callBack(StaticLib.callback["on_error"]);
		}
		
		/**
		 * 向js抛出事件
		 * */
		private function callBack(call:String):void{
			StaticLib.console('console.log', 'call'+call);
			
			//去掉key里'-'符号，否则会报错
			var response:Object = new Object();
			for(var item:String in _response){
				response[item.replace('-', '')] = _response[item];
			}
			ExternalInterface.call(call, {response: response, errorMessage: _errorMessage});
		}
		
		
		/***
		 * 设置图片地址
		 */
		public function setImageSrc(src:String):void{
			var request:URLRequest = new URLRequest(src);
			_loader.load(request, new LoaderContext(true));
			StaticLib.console('log', 'loader执行完成');
		}
		
		/***
		 * 设置的图片加载完成
		 */
		private function _imageLoaded(evt:Event):void{
			StaticLib.console('log', 'loader已经loaded');
			_bitmapData = (evt.target.content as Bitmap).bitmapData;
			_drawPreview();
		}
		
		public function getImageRect():Rectangle{
			return new Rectangle(_image.x, _image.y, _image.width, _image.height);
		}
		
		/**
		 * 根据图片url得到loader
		 * */
		private function _imageLoader(url:String, x:int = 0, y:int = 0):Loader{
			var loader:Loader = new Loader();
			var request:URLRequest = new URLRequest(url);
			loader.load(request);
			loader.x = x;
			loader.y = y;
			return loader;
		}
	}
}
import flash.net.navigateToURL;

