package baidu.lib.serialization {

	internal class JSONToken {
	
		private var _type:int;
		private var _value:Object;
		
		/**
		 * Creates a new JSONToken with a specific token type and value.
		 *
		 * @param type The JSONTokenType of the token
		 * @param value The value of the token
		 */
		public function JSONToken( type:int = -1 /* JSONTokenType.UNKNOWN */, value:Object = null ) {
			_type = type;
			_value = value;
		}
		
		/**
		 * Returns the type of the token.
		 */
		public function get type():int {
			return _type;	
		}
		
		/**
		 * Sets the type of the token.
		 */
		public function set type( value:int ):void {
			_type = value;	
		}
		
		/**
		 * Gets the value of the token
		 */
		public function get value():Object {
			return _value;	
		}
		
		/**
		 * Sets the value of the token
		 */
		public function set value ( v:Object ):void {
			_value = v;	
		}

	}
	
}