<?php
require_once('Mail.php');
require_once('Mail/mime.php');
require_once('Net/SMTP.php');
#require_once('Pheanstalk/pheanstalk_init.php');
#$pheanstalk = new Pheanstalk_Pheanstalk('127.0.0.1');
$xml = new DOMDocument( "1.0", "ISO-8859-15" );

$required = array(
		  'php-mbstring' => 'mb_check_encoding',
		  'php-gd' => 'gd_info',
		  'php-soap' => 'SoapClient',
		  'php-mcrypt' => 'mcrypt_encrypt'
		  );
foreach ($required as $yumPackage => $phpFunction) {
  if (!function_exists($phpFunction) && !class_exists($phpFunction)) {
    echo "PHP requires $yumPackage\n";
  }
}

?>
