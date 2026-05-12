<?php
$db = new SQLite3('d:/laravel/athletehub/database/database.sqlite');

// Add skills for user 1 (aisha) - كرة القدم (1), السباحة (3), الجري (4)
$db->exec("INSERT OR IGNORE INTO skill_user (user_id, skill_id) VALUES (1, 1)");
$db->exec("INSERT OR IGNORE INTO skill_user (user_id, skill_id) VALUES (1, 3)");
$db->exec("INSERT OR IGNORE INTO skill_user (user_id, skill_id) VALUES (1, 4)");

echo "Skills added for user 1!" . PHP_EOL;

// Verify
$r = $db->query('SELECT su.user_id, su.skill_id, s.name FROM skill_user su JOIN skills s ON su.skill_id = s.id WHERE su.user_id = 1');
while($row = $r->fetchArray(SQLITE3_ASSOC)) {
    echo "User:" . $row['user_id'] . " | Skill:" . $row['name'] . PHP_EOL;
}
