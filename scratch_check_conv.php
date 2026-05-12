<?php
$db = new PDO('sqlite:d:/laravel/athletehub/database/database.sqlite');
$stmt = $db->query("SELECT count(*) as cnt FROM conversations");
foreach ($stmt as $row) {
    echo "Conversations count: " . $row['cnt'] . "\n";
}
$stmt = $db->query("SELECT count(*) as cnt FROM messages");
foreach ($stmt as $row) {
    echo "Messages count: " . $row['cnt'] . "\n";
}
