<?php

require __DIR__.'/vendor/autoload.php';
$app = require_once __DIR__.'/bootstrap/app.php';
$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();

use App\Models\User;

$rows = User::all();
echo "TOTAL USERS: ".$rows->count().PHP_EOL;
foreach ($rows as $u) {
    echo $u->id.' | '.$u->email.' | '.$u->role.PHP_EOL;
}