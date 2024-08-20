<?php

namespace Shared\Middleware;

use Illuminate\Http\JsonResponse;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Response;

class PrivateMiddleware {
    /**
     * Handle an incoming request.
     *
     * @param Request $request
     * @param Closure(Request): (Response|RedirectResponse) $next
     * @return Response|RedirectResponse|JsonResponse
     */
    public function handle(Request $request, \Closure $next) {
        if ($request->header('X-APP-KEY') === env('APP_KEY')) {
            return $next($request);
        }

        return response()->json(['message' => 'Not Found'], JsonResponse::HTTP_NOT_FOUND);
    }
}
