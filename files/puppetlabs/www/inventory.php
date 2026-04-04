<?php
$uploaddir = '/home/inventory_data/';
$uploadfile = $uploaddir . basename($_FILES['userfile']['name']);

echo '<pre>';
if (move_uploaded_file($_FILES['userfile']['tmp_name'], $uploadfile)){
echo "File is valid, sucessfully uploaded.\n";
} else {
echo "illegal content\n";
}

print_r($_FILES);

print "</pre>";
?>
