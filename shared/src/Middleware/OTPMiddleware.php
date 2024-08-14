<?php

namespace Shared\Middleware;

use Illuminate\Http\JsonResponse;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Response;
use Shared\Clients\OtpClient;

class OTPMiddleware {
    private static function unathorized(): JsonResponse {
        return response()->json(['error' => 'Unauthorized'], 401);
    }

    /**
     * Handle an incoming request.
     *
     * @param Request $request
     * @param Closure(Request): (Response|RedirectResponse) $next
     * @return Response|RedirectResponse|JsonResponse
     */
    public function handle(Request $request, \Closure $next) {
        $identifier = $request->header('X-OTP-Identifier') ?? null;
        $code = $request->header('X-OTP-Code') ?? null;

        if (!$identifier) {
            return self::unathorized();
        }

        return OtpClient::validate($identifier, $code) ? $next($request) : self::unathorized();
    }
}
