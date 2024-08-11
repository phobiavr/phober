<?php

namespace Shared\Middleware;

use Illuminate\Http\JsonResponse;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Response;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Http;

class AuthServerMiddleware
{
    /**
     * Handle an incoming request.
     *
     * @param Request $request
     * @param Closure(Request): (Response|RedirectResponse)  $next
     * @return Response|RedirectResponse|JsonResponse
     */
    public function handle(Request $request, \Closure $next) {
        $url = env('AUTH_SERVER', 'http://auth-server');

        $response = Http::accept('application/json')->withHeaders([
            'Authorization' => 'Bearer ' . request()->bearerToken()
        ])->get($url . '/valid');

        if ($response->status() === Response::HTTP_OK) {
            Auth::guard('server')->setUser($response['user']);

            return $next($request);
        }

        return response()->json(['message' => 'Credentials error'], 401);
    }
}
