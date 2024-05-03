<header>
        <div class="header">
            
            <h1>Sistema Facturacion</h1>
            <div class="optionsBar">
                <p>Mexico,  <?php echo fechaC(); ?></p>
                <span>|</span>
                <span class="user"><?php echo $_SESSION['user']; ?></span>
                <img class="photouser" src="img/bingo.jpeg" alt="Usuario">
                <a href="salir.php"><img  class="close" src="img/boton.jpeg" alt="Salir del sistema" title="Salir"></a>
            </div>
        </div>
       <?php include "nav.php"; ?>
    </header>