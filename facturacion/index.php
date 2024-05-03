<?php

$alert='';
session_start();
if(!empty($_SESSION['active']))
{
    header('location: sistema/');
}else{

if(!empty($_POST))
{
  if(empty($_POST['usuario']) || empty($_POST['clave']))
  {
    $alert='Ingrese su usuario y su clave';
  }else{
      
      require_once "conexion.php";
      
      $user= mysqli_real_escape_string($conection,$_POST['usuario']);
      $pass= md5(mysqli_real_escape_string($conection,$_POST['clave']));
      
      $query= @mysqli_query($conection,"SELECT * FROM usuario WHERE usuario='$user' AND clave='$pass'");
      $result=mysqli_num_rows($query);
      
      if($result>0)
      {
          $data=mysqli_fetch_array($query);
          
          $_SESSION['active']=true;
          $_SESSION['idUser']=$data['idusuario'];
          $_SESSION['nombre']=$data['nombre'];
          $_SESSION['email']=$data['email'];
          $_SESSION['user']=$data['usuario'];
          $_SESSION['rol']=$data['rol'];
          
          header('location: sistema/');
      }else{
          $alert='El usuario o la clave son incorrectos';
           session_destroy();
      }
      
      
  }
}
}



?>

<!DOCTYPE html>
<html lang="en">
<head>
        <meta name="viewport" content="width-device-width, initial-scale=1.0" >
<meta charset="UTF-8">
<title>Login | Sistema Facturacion</title>
<link rel="stylesheet" type="text/css" href="css/style2.css">

</head>
<body>
<section id="container">
    
   <form action="" method="post">
   
   <h3>Iniciar sesion</h3>
   <img src="img/pingui.jpg" alt="login">
   <br>
   <input type="text" name="usuario" placeholder="Usuario">
   <input type="password" name="clave" placeholder="Contraseña">
<div class="alert"><?php echo isset($alert) ? $alert : ''; ?></div>
   <input type="submit" value="INGRESAR">
   
   </form>

 </section>
</body>
</html>