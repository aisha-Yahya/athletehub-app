<?php
$db = new SQLite3('d:/laravel/athletehub/database/database.sqlite');
$r = $db->query('SELECT * FROM personal_access_tokens WHERE tokenable_id = 1');
while($row = $r->fetchArray(SQLITE3_ASSOC)) {
    echo "Token ID: " . $row['id'] . " Name: " . $row['name'] . " Token: " . $row['token'] . PHP_EOL;
}
