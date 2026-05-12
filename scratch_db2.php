<?php
$db = new SQLite3('d:/laravel/athletehub/database/database.sqlite');
$r = $db->query('PRAGMA table_info(conversations)');
echo "=== Conversations Table Schema ===" . PHP_EOL;
while($row = $r->fetchArray(SQLITE3_ASSOC)) {
    echo $row['name'] . ' (' . $row['type'] . ')' . PHP_EOL;
}

// Add an upcoming event
echo "=== Creating Upcoming Event ===" . PHP_EOL;
$title = "بطولة السباحة الحرة";
$desc = "بطولة للهواة والمحترفين";
$date = date('Y-m-d H:i:s', strtotime('+5 days')); // Upcoming!
$db->exec("INSERT INTO events (conversation_id, title, description, event_date, created_by, status, created_at, updated_at) VALUES (2, '$title', '$desc', '$date', 3, 'upcoming', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)");

$eventId = $db->lastInsertRowID();
echo "Created event ID: $eventId" . PHP_EOL;

$db->exec("INSERT INTO event_user (event_id, user_id, status) VALUES ($eventId, 1, 'attending')");
$db->exec("INSERT INTO event_user (event_id, user_id, status) VALUES ($eventId, 2, 'attending')");
echo "Added RSVPs" . PHP_EOL;

