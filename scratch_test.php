<?php
require 'd:/laravel/athletehub/vendor/autoload.php';
$app = require_once 'd:/laravel/athletehub/bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

$user = \App\Models\User::find(1);

// Skills
echo "=== Skills ===" . PHP_EOL;
$skills = $user->skills;
foreach($skills as $s) echo $s->name . " | ";
echo PHP_EOL;

// Events
echo "=== Events ===" . PHP_EOL;
$conversationIds = $user->conversations()->pluck('conversations.id');
echo "Conversation IDs: " . json_encode($conversationIds) . PHP_EOL;

$events = \App\Models\Event::whereIn('conversation_id', $conversationIds)
            ->with(['creator:id,name,avatar', 'attendees:id,name,avatar', 'conversation:id,name,type'])
            ->orderBy('event_date', 'desc')
            ->get();
            
echo "Events found: " . $events->count() . PHP_EOL;
foreach($events as $e) {
    echo "Event: " . $e->title . " Date: " . $e->event_date . " Conv: " . $e->conversation_id . PHP_EOL;
}
