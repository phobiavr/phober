<?php

namespace Shared\Middleware;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\App;

class TranslationMiddleware
{
    /**
     * Handle an incoming request.
     *
     * @param \Illuminate\Http\Request $request
     * @param \Closure(\Illuminate\Http\Request): (\Illuminate\Http\Response|\Illuminate\Http\RedirectResponse) $next
     * @return \Illuminate\Http\Response|\Illuminate\Http\RedirectResponse
     */
    public function handle(Request $request, \Closure $next) {
        $locale = $request->header('Accept-Language', 'en');

        App::setLocale($locale);

        return $next($request);
    }
}
