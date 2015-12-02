# imageClipper

本组件是 [HeadImageCliper](https://github.com/libmw/headImageCliper)组件的升级版本，HeadImageCliper将不再进行更新。

javascript图片裁剪上传组件，利用flash在本地进行裁剪后再上传。

支持固定尺寸预览。

支持自定义上传图片的尺寸。

支持按比例裁剪和完全自由变换尺寸裁剪。

支持自定义上传按钮样式。

支持png、jpg、bmp、gif图片上传。

支持自定义默认预览图。

项目使用flashbuilder开发，可以用flashbuilder直接导入此项目。

![demo](http://libmw.github.io/resource/2015/headimagecliper/demo.png)


## 使用方法

1.把/bin-debug/imageClipper.swf放到你的网站目录

2./demo文件夹下的所有图片和js放到你的网站目录。图片是swf文件需要使用的按钮、光标等，imageClipper.js是与flash交互的组件ImageClipper。

3.使用如下代码调用裁剪组件：

```javascript
window.imageClipper = new ImageClipper({
    container: container, //上传界面的容器，原生dom
    width: container.clientWidth, //flash的宽度
    height: container.clientHeight, //flash的高度
    ratio: 1, //长宽比。默认为1。若为浮点数则会根据此比例裁剪图片。若不需要按比例裁剪，请设置为0
    flashUrl: '../bin-debug/imageClipper.swf?v=0728', //上传flash的地址
    resourceUrl: './', //flash包含的按钮、光标等静态文件的放置路径
    uploadUrl: './upload.php', //上传路径
    uploadSize: '200*160', //上传到服务器的图片的尺寸，若不指定，将直接上传裁剪后的图片区域
    file: 'file', //上传的字段名，默认为file
    isPreview: true, //是否显示预览图
    previewSize: '200*160|300*80', //显示哪些尺寸的预览图
    defaultPreview: './img_1438242362849.jpg' //默认显示的预览图
});

imageClipper.bind('complete',function(evt, response){
    alert('上传成功');
    console.log('上传成功，服务器返回内容：', response);
});

imageClipper.bind('error',function(evt, response){
    console.log(response); //错误信息有多重，可能是上传失败，可能是未选择图片等
});

//设置被裁剪的图片地址
//imageClipper.setImageSrc('http://127.0.0.1/imageClipper/demo/img_1432626207571.jpg');
```

完整示例请[查看demo](http://libmw.github.io/2015/08/10/image-clipper.html)

有任何问题，mailto：libmw@163.com


