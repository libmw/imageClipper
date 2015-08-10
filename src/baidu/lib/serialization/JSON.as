package baidu.lib.serialization {

	/**
	 * JSON序列化及反序列化工具（注:从Adobe as3corelib 库引入并修改）
	 */
	public class JSON {
	
		/**
		 * 生成指定对象的JSON序列化字符串
		 * @param o 				<Object>需要序列化的对象
		 * @return					<String>JSON序列化结果
		 */
		public static function encode( o:* ):String {
			
			var encoder:JSONEncoder = new JSONEncoder( o );
			return encoder.getString();
		
		}
		
		/**
		 * 将JSON序列化字符串解析成本地对象
		 * @param s 				<String>JSON序列化字符串
		 * @return					<*>解析出的本地化对象
		 * @throw JSONParseError
		 */
		public static function decode( s:String ):* {
			
			var decoder:JSONDecoder = new JSONDecoder( s );
			return decoder.getValue();
			
		}
	
	}

}