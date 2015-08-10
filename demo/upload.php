<?php
//sleep(20);
/*if (move_uploaded_file($_FILES['file']['tmp_name'], './a.jpg')) {
	echo '{"no":"0","data":{"success":"true"}}';
} else {
	echo '{"no":"1","data":"uploaderror"}';
}*/

$file = $_FILES["file"];

$fileName = toGbk($_POST['Filename']);
$response = array(
    'errorCode' => 0,
    'data' => array(
        'message' => ''
    )
);
function toGbk($word)
{
    // 转UTF8
    $word0 = iconv('utf-8', 'gbk', $word); //假设word为gbk
    $word1 = iconv('gbk', 'utf-8', $word0);
    return ($word1 == $word) ? $word0 : $word;
}
if ($_FILES["file"]["error"] > 0) {
    $response['errorCode']= 1;
    $response['data']['message']= '上传失败，请重新上传';

} else {
 
        if(move_uploaded_file($_FILES["file"]["tmp_name"],  $fileName)){
            
            $response['errorCode']= 0;
            $response['data']['message']= '上传成功';
            
        }else{
            $response['errorCode']= 1;
            $response['data']['message']= '上传失败，请重新上传';
        }


    }

echo '{"code":200,"message":"ok","url":"\/014\/03\/25\/200x200_avatar_88.jpg","time":1404811828,"imagewidth":200,"imageheight":200,"imageframes":1,"imagetype":"JPEG","extparam":"dWlkPTE0MDMyNTg4JnVrZXk9NjU2MDdjNDYzOGFhODU3MjI1MTQ5OWYwN2NjNWMwZjM=","sign":"4939c45ccbcf0fadf7e35cc2207f2f3d"}';
?>
