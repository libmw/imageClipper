package baidu.local
{
	import flash.external.ExternalInterface;
	public class StaticLib
	{
		public static var callback:Object = {
			
		}; //回调
		public static var myInterface:Object = {
			
		} ; //接口
		public static var config:Object = {
			
		} ; //接口
		public function StaticLib(){
		}
		public static function console(type:String, msg:*):void
		{
			ExternalInterface.call('console.log', msg);
		}
		
	}
}