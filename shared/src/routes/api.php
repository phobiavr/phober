<?php

use Illuminate\Support\Facades\Route;

Route::get('/instance-info', function () {
    return response()->json([
        'instance_id' => gethostname(),
    ]);
});
