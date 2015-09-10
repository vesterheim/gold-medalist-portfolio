<?php
# FileName="Connection_php_mysql.htm"
# Type="MYSQL"
# HTTP="true"
#$hostname_vnamgold_portfolio = "db26.pair.com";
#$hostname_vnamgold_portfolio = "localhost";
#$database_vnamgold_portfolio = "vnamgold_portfolio";
#$username_vnamgold_portfolio = "vnamgold";
#$password_vnamgold_portfolio = "MuVbCWAn";


$hostname_vnamgold_portfolio = "db135a.pair.com";
$database_vnamgold_portfolio = "vnam_portfolio";
$username_vnamgold_portfolio = "vnam_8";
$password_vnamgold_portfolio = "yEbrpHwV";

$vnamgold_portfolio = mysql_pconnect($hostname_vnamgold_portfolio, $username_vnamgold_portfolio, $password_vnamgold_portfolio) or trigger_error(mysql_error(),E_USER_ERROR); 
?>