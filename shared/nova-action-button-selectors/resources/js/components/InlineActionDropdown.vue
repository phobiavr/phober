<template>
    <div class="flex">
        <div v-if="actions.length > 0" :dusk="`${resource.id.value}-inline-actions`" class="mr-4 flex gap-4">
            <!-- User Actions -->
            <template v-for="action in actions">
                <button
                    v-if="action.showAsButton"
                    :key="action.uriKey"
                    as="button"
                    :dusk="`${resource.id.value}-inline-action-${action.uriKey}`"
                    :title="action.name"
                    :destructive="action.destructive"
                    class="bg-primary-500 hover:bg-primary-400 ring-primary-200 h-9 cursor-pointer items-center justify-center rounded px-3 text-sm font-bold text-white shadow focus:outline-none focus:ring dark:text-gray-900 dark:ring-gray-600"
                    @click.stop="() => handleActionClick(action.uriKey)"
                >
                    {{ action.name }}
                </button>
            </template>
        </div>

        <Dropdown v-if="shouldShowDropdown">
            <template #default>
                <div>
                    <span class="sr-only">{{ __('Resource Row Dropdown') }}</span>
                    <Button variant="action" icon="ellipsis-horizontal" :dusk="`${resource.id.value}-control-selector`" />
                </div>
            </template>

            <template #menu>
                <DropdownMenu v-if="shouldShowDropdown" width="auto" class="px-1">
                    <ScrollWrap :height="250" class="divide-y divide-solid divide-gray-100 dark:divide-gray-800">
                        <div v-if="userHasAnyOptions" class="py-1">
                            <!-- Preview Resource Link -->
                            <DropdownMenuItem
                                v-if="shouldShowPreviewLink"
                                :data-testid="`${resource.id.value}-preview-button`"
                                :dusk="`${resource.id.value}-preview-button`"
                                as="button"
                                :title="__('Preview')"
                                @click.prevent="$emit('show-preview')"
                            >
                                {{ __('Preview') }}
                            </DropdownMenuItem>

                            <!-- Replicate Resource Link -->
                            <DropdownMenuItem
                                v-if="resource.authorizedToReplicate"
                                :dusk="`${resource.id.value}-replicate-button`"
                                :href="
                                    $url(`/resources/${resourceName}/${resource.id.value}/replicate`, {
                                        viaResource,
                                        viaResourceId,
                                        viaRelationship,
                                    })
                                "
                                :title="__('Replicate')"
                            >
                                {{ __('Replicate') }}
                            </DropdownMenuItem>

                            <!-- Impersonate Resource Button -->
                            <DropdownMenuItem
                                v-if="canBeImpersonated"
                                as="button"
                                :dusk="`${resource.id.value}-impersonate-button`"
                                :title="__('Impersonate')"
                                @click.prevent="
                                    startImpersonating({
                                        resource: resourceName,
                                        resourceId: resource.id.value,
                                    })
                                "
                            >
                                {{ __('Impersonate') }}
                            </DropdownMenuItem>
                        </div>

                        <div v-if="amountDropdownActions > 0" :dusk="`${resource.id.value}-inline-actions`" class="py-1">
                            <!-- User Actions -->
                            <template v-for="action in actions">
                                <DropdownMenuItem
                                    v-if="!action.showAsButton"
                                    :key="action.uriKey"
                                    as="button"
                                    :dusk="`${resource.id.value}-inline-action-${action.uriKey}`"
                                    :title="action.name"
                                    :destructive="action.destructive"
                                    @click="() => handleActionClick(action.uriKey)"
                                >
                                    {{ action.name }}
                                </DropdownMenuItem>
                            </template>
                        </div>
                    </ScrollWrap>
                </DropdownMenu>
            </template>
        </Dropdown>

        <!-- Action Confirmation Modal -->
        <component
            :is="selectedAction.component"
            v-if="confirmActionModalOpened"
            :show="confirmActionModalOpened"
            :working="working"
            :selected-resources="selectedResources"
            :resource-name="resourceName"
            :action="selectedAction"
            :endpoint="endpoint"
            :errors="errors"
            @confirm="executeAction"
            @close="closeConfirmationModal"
        />

        <!-- Action Response Modal -->
        <component
            :is="actionResponseData.modal"
            v-if="selectedAction"
            :show="showActionResponseModal"
            :data="actionResponseData"
            @close="closeActionResponseModal"
        />
    </div>
</template>

<script>
import { HandlesActions, mapProps } from '@/mixins';
import { mapActions, mapGetters } from 'vuex';
import { Button } from 'laravel-nova-ui';

export default {
    components: {
        Button,
    },
    mixins: [HandlesActions],

    props: {
        resource: { type: Object },
        actions: { type: Array },
        viaManyToMany: { type: Boolean },

        ...mapProps(['resourceName', 'viaResource', 'viaResourceId', 'viaRelationship']),
    },

    emits: ['show-preview'],

    data: () => {
        return {
            showActionResponseModal: false,
            actionResponseData: {},
        };
    },

    computed: {
        ...mapGetters(['currentUser']),

        currentSearch() {
            return '';
        },

        encodedFilters() {
            return '';
        },

        currentTrashed() {
            return '';
        },

        shouldShowDropdown() {
            return this.amountDropdownActions > 0 || this.userHasAnyOptions;
        },

        amountButtonActions() {
            return this.actions.filter((action) => action.showAsButton == true).length;
        },

        amountDropdownActions() {
            return this.actions.filter((action) => !(action.showAsButton == true)).length;
        },

        shouldShowPreviewLink() {
            return this.resource.authorizedToView && this.resource.previewHasFields;
        },

        userHasAnyOptions() {
            return this.resource.authorizedToReplicate || this.shouldShowPreviewLink || this.canBeImpersonated;
        },

        canBeImpersonated() {
            return this.currentUser.canImpersonate && this.resource.authorizedToImpersonate;
        },

        selectedResources() {
            return [this.resource.id.value];
        },
    },

    methods: mapActions(['startImpersonating']),
};
</script>
