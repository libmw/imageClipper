package baidu.lib.serialization {

	/**
	 * JSON解析错误（注:从Adobe as3corelib 库引入并修改）
	 */
	public class JSONParseError extends Error 	{
	
		private var _location:int;
		
		private var _text:String;
	
		/**
		 * 构造函数
		 * @param message 			<String>错误信息
		 * @param location			<int>发生解析错误的位置索引
		 * @param text				<String>发生解析错误的字符串
		 */
		public function JSONParseError( message:String = "", location:int = 0, text:String = "") {
			super( message );
			_location = location;
			_text = text;
		}

		/**
		 * 发生解析错误的位置索引（只读）
		 * @return 					<String>发生解析错误的字符串索引位置
		 */
		public function get location():int {
			return _location;
		}
		
		/**
		 * 发生解析错误的字符串（只读）
		 * @return 					<String>发生解析错误的字符串
		 */
		public function get text():String {
			return _text;
		}
	}
	
}