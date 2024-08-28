<?php

namespace Shared;

use Illuminate\Contracts\Auth\Guard;
use Illuminate\Contracts\Auth\UserProvider;
use Illuminate\Http\Request;

class JsonGuard implements Guard {
    protected $request;
    protected $provider;
    protected $user;

    /**
     * Create a new authentication guard.
     */
    public function __construct(UserProvider $provider, Request $request) {
        $this->request = $request;
        $this->provider = $provider;
        $this->user = NULL;
    }

    /**
     * Determine if the current user is authenticated.
     */
    public function check(): bool {
        return !is_null($this->user());
    }

    /**
     * Determine if the current user is a guest.
     */
    public function guest(): bool {
        return !$this->check();
    }

    /**
     * Get the currently authenticated user.
     */
    public function user() {
        if (!is_null($this->user)) {
            return $this->user;
        }
    }

    /**
     * Get the JSON params from the current request
     */
    public function getJsonParams() {
//    $jsondata = $this->request->query('jsondata');
//
//    return (!empty($jsondata) ? json_decode($jsondata, TRUE) : NULL);
    }

    /**
     * Get the ID for the currently authenticated user.
     */
    public function id() {
        return $this->user()['id'] ?? null;

    }

    /**
     * Validate a user's credentials.
     */
    public function validate(array $credentials = []) {
//    if (empty($credentials['username']) || empty($credentials['password'])) {
//      if (!$credentials = $this->getJsonParams()) {
//        return false;
//      }
//    }
//
//    $user = $this->provider->retrieveByCredentials($credentials);
//
//    if (!is_null($user) && $this->provider->validateCredentials($user, $credentials)) {
//      $this->setUser($user);
//
//      return true;
//    } else {
//      return false;
//    }
    }

    /**
     * Set the current user.
     */
    public function setUser($user) {
        $this->user = $user;

        return $this;
    }

    /**
     * Determine if the guard has a user instance.
     */
    public function hasUser() {
    }
}
