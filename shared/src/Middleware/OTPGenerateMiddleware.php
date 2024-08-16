<?php

namespace Shared\Middleware;

use Illuminate\Http\JsonResponse;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Response;
use Shared\Clients\OtpClient;

class OTPGenerateMiddleware {
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
        $otp = OtpClient::generateOtp();

        if (!$otp->success) {
            return self::unathorized();
        }

        $response = $next($request);
        $response->headers->set('X-OTP-Identifier', $otp->identifier);
        return $response;
    }
}
