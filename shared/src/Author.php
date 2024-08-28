<?php

namespace Shared;

use App\Models\User;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\MorphTo;

class Author extends Model {
    protected $fillable = ["created_by", "last_updated_by", "updated_at"];

    public function authorable(): MorphTo {
        return $this->morphTo();
    }

    public function createdBy(): BelongsTo {
        return $this->belongsTo(User::class, "created_by");
    }

    public function updatedBy(): BelongsTo {
        return $this->belongsTo(User::class, "last_updated_by");
    }
}
