<?php
# FileName="Connection_php_mysql.htm"
# Type="MYSQL"
# HTTP="true"
$hostname_Vesterheim_Remote = "db26.pair.com";
$database_Vesterheim_Remote = "vnamgold_portfolio";
$username_Vesterheim_Remote = "vnamgold";
$password_Vesterheim_Remote = "MuVbCWAn";
$Vesterheim_Remote = mysql_pconnect($hostname_Vesterheim_Remote, $username_Vesterheim_Remote, $password_Vesterheim_Remote) or trigger_error(mysql_error(),E_USER_ERROR); 
?>