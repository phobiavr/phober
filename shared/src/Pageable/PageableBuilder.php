<?php

namespace Shared\Pageable;

use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Illuminate\Database\Eloquent\Builder;

class PageableBuilder extends Builder {
  public function paginateFromRequest(PageableRequest $request): LengthAwarePaginator {
    extract($request->pagination());

    return $this->paginate($perPage, $columns, $pageName, $page);
  }
}
