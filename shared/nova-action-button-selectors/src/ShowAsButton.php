<?php

namespace Lednerb\ActionButtonSelector;

trait ShowAsButton
{
    /**
     * ShowAsButton constructor.
     */
    public function __construct(...$parameters)
    {
        if (method_exists(parent::class, '__construct')) {
            parent::__construct(...$parameters);
        }

        return $this->showAsButton();
    }

    public function showAsButton($show = true)
    {
        return $this->withMeta(['showAsButton' => $show]);
    }
}
