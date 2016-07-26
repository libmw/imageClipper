/**
 * options.width [Int] flash的宽度
 * options.height [Int] flash的高度
 * options.flashUrl [String] swf文件的完整地址
 * options.resourceUrl [String] flash包含的按钮、光标等静态文件的放置路径
 * options.ratio [Float] 长宽比。默认为1。若为浮点数则会根据此比例裁剪图片。若不需要按比例裁剪，请设置为0
 * options.uploadUrl [String] 上传地址，注意，如果上传地址跨域，则需要设置crossdomain.xml(http://www.adobe.com/devnet/adobe-media-server/articles/cross-domain-xml-for-streaming.html)
 * options.uploadSize [String] 上传到服务器的图片的尺寸，格式为200*180。如果指定此值，会将裁剪后的图片拉伸为此尺寸再上传到服务器。若不指定，将直接上传裁剪后的图片区域。
 * options.file [String] 上传的字段名，默认为file
 * options.isPreview [Boolean] 是否显示预览图
 * options.previewSize [String] 显示哪些尺寸的预览图。'200*180|100*80'代表显示200*180*80的预览图。注意预览图的尺寸如果过大，可能会超出flash的可视范围，此时应该设置不显示预览图或者增大flash的宽高度
 * options.defaultPreview [String] 默认显示的预览图。如果预览图跨域，则需设置crossdomain.xml
 * */
function ImageClipper(options){
    this._container = options.container;
    this._width = options.width || 200;
    this._height = options.height || 50;
    this._uploadUrl = options.uploadUrl || '';
    this._file = options.file || 'file';
    this._isPreview = typeof options.isPreview == 'undefined' ? true : options.isPreview;
    this._previewSize = options.previewSize || '200*200|80*80|48*48';
    this._defaultPreview = options.defaultPreview || '';
    this._ratio = options.ratio === 0 ? 0 : (options.ratio || 1);
    this._uploadSize = options.uploadSize || '';
    this._resourceUrl = options.resourceUrl || '';
    this._flashUrl = options.flashUrl;
    this._token = (new Date).getTime();
    this._flashVars = '';
    this._events = [
        'complete',
        'error',
        'load'
    ];
    this._init();
}

/**
 * 提交裁切好的图片到服务器
 * */
ImageClipper.prototype.submit = function(){
    this._flash.submit();
};

/**
 * 设置默认裁切的图片地址，如果图片跨域，需要设置crossdomain.xml
 * */
ImageClipper.prototype.setImageSrc = function(url){
    if(this._flash.setImageSrc){
        this._flash.setImageSrc(url);
    }else{
        var _this = this;
        this.bind('load', function(){
            _this._flash.setImageSrc(url);
        });
    }

};

/**
 * 绑定事件
 * */
ImageClipper.prototype.bind = function(evt, func){
    if(!this._events[evt]){
        this._events[evt] = [];
    }
    this._events[evt].push(func);
};

/**
 * 取消绑定事件
 * */
ImageClipper.prototype.unbind = function(evt, func){
    if(this._events[evt]){
        var events = this._events[evt];
        for(var i = 0; i < events.length; i ++){
            if(func == events[i]){
                events[i].splice(i, 1);
            }
        }
    }
};

/**
 * 触发事件
 * */
ImageClipper.prototype.trigger = function(evt, data){
    if(this._events[evt]){
        var events = this._events[evt];
        for(var i = 0; i < events.length; i ++){
            events[i].call(this, evt, data);
        }
    }
};

ImageClipper.prototype._init = function(){
    this._initFlashvars();
    this._generateCallBack();
    this._initUI();
};

ImageClipper.prototype._initFlashvars = function(){
    var varArr = [
        'uploadUrl=' + encodeURIComponent(this._uploadUrl),
        'file=' + encodeURIComponent(this._file),
        'isPreview=' + this._isPreview,
        'previewSize=' + encodeURIComponent(this._previewSize),
        'defaultPreview=' + encodeURIComponent(this._defaultPreview),
        'ratio=' + encodeURIComponent(this._ratio),
        'uploadSize=' + encodeURIComponent(this._uploadSize),
        'resourceUrl=' + this._resourceUrl
    ];
    this._flashVars = varArr.join('&');
};

ImageClipper.prototype._initUI = function(){
    var id = 'flashUploader' + this._token;
    var url = this._flashUrl;
    var ie = '<object id="'+ id +'" onfocus="return false;"  name="#" classid="clsid:d27cdb6e-ae6d-11cf-96b8-444553540000" codebase="https://download.macromedia.com/pub/shockwave/cabs/flash/swflash.cab#version=9,0,0,0" width="'+ this._width +'" height="'+ this._height +'"><param name="allowScriptAccess" value="always" /><param value="transparent" name="wmode"><param name="flashvars" value="'+ this._flashVars +'" /><param name=play value=false> <param name="allowFullScreen" value="false" /><param name="movie" value="'+ url +'" /></object>',
        w3c = '<object id="'+ id +'" type="application/x-shockwave-flash" data="'+ url +'" width="'+ this._width +'" height="'+ this._height +'"><param name="allowScriptAccess" value="always" /><param value="transparent" name="wmode"><param name="flashvars" value="'+ this._flashVars +'" /></object>';

    if('ActiveXObject' in window){
        try{new ActiveXObject('ShockwaveFlash.ShockwaveFlash');}catch(e){
            w3c = ie = '检测到你的浏览器没有FlashPlayer，请<a href="https://admdownload.adobe.com/bin/live/flashplayer22ax_ra_install.exe">点此安装</a>';
        }
    }
    
    if (navigator.appName.indexOf("Microsoft") != -1) {
        this._container.innerHTML = ie;
    } else {
        this._container.innerHTML = w3c;
    }

    this._flash =  document[id] || window[id];

};


ImageClipper.prototype._generateCallBack = function(){
    var token = this._token;
    var _this = this;
    var events = this._events;
    for(var i = 0; i < events.length; i++){
        var evt = events[i]
            ,callBack = evt + token;
        window[callBack] = (function(evt){
            return function(data){
                _this.trigger(evt, data);
            }
        })(evt);
        this._flashVars += '&' + this._decodeCamel(evt) + '=' + callBack;
    }
};

ImageClipper.prototype._decodeCamel = function(camel){
    return camel.replace(/([A-Z])/g, function(all, $1){return '_' + $1.toLowerCase();});
};

