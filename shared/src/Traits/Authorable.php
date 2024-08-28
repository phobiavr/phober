<?php

namespace Shared\Traits;

use Illuminate\Database\Eloquent\Relations\MorphOne;
use Illuminate\Support\Facades\Auth;
use Shared\Author;

trait Authorable {
    public function getMorphClass() {
        return static::$authorableType ?? get_class();
    }

    protected static function bootAuthorable(): void {
        static::created(function ($model) {
            if (Auth::check()) $model->author()->create(['created_by' => Auth::id(), 'last_updated_by' => Auth::id()]);
        });

        static::updated(function ($model) {
            if (Auth::check()) $model->author()->update(['last_updated_by' => Auth::id()]);
        });
    }

    public function author(): MorphOne {
        return $this->setConnection('db_shared')->morphOne(Author::class, 'authorable');
    }
}
