<?php

use App\Models\Pod;
use Illuminate\Support\Facades\Broadcast;
use Illuminate\Support\Facades\Gate;

Broadcast::channel('App.Models.User.{id}', function ($user, $id) {
    return $user->id === $id;
});

Broadcast::channel('pod.{podId}', function ($user, string $podId) {
    $pod = Pod::find($podId);

    return $pod && Gate::forUser($user)->allows('view', $pod);
});
