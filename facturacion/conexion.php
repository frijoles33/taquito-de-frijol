<?php

$host='localhost';
$username='id21968030_facturacion';
$password='';
$db='id21968030_facturacion';

$conection=@mysqli_connect($host,$username,$password,$db);

if(!$conection) {
     echo"Error en la conexion";
}
?>