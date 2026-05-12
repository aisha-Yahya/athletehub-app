<?php
$db = new PDO('sqlite:d:/laravel/athletehub/database/database.sqlite');
$stmt = $db->query("SELECT id, email, created_at FROM users");
foreach ($stmt as $row) {
    echo $row['id'] . ' - ' . $row['email'] . " - " . $row['created_at'] . "\n";
}
