<?php

namespace Shared\Pageable;

use Illuminate\Database\Eloquent\Model;

/**
 * @method static paginateFromRequest(PageableRequest $request)
 */
trait Pageable {
  /**
   * @return PageableBuilder
   */
  public static function query() {
    return parent::query();
  }

  public function newEloquentBuilder($query): PageableBuilder {
    return new PageableBuilder($query);
  }
}
