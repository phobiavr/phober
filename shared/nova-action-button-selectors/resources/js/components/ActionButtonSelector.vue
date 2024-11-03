<template>
    <div v-if="hasDropdownItems" class="flex">
        <div :dusk="`${resource.id.value}-inline-actions`" class="flex gap-4 py-0" :class="{ 'mr-4': shouldShowDropdown }">
            <template v-for="action in actions">
                <button
                    v-if="action.showAsButton"
                    :key="action.uriKey"
                    :dusk="`${resource.id.value}-inline-action-${action.uriKey}`"
                    :title="action.name"
                    :destructive="action.destructive"
                    class="bg-primary-500 hover:bg-primary-400 ring-primary-200 relative inline-flex h-9 cursor-pointer items-center justify-center rounded px-3 text-sm font-bold text-white shadow focus:outline-none focus:ring dark:text-gray-900 dark:ring-gray-600"
                    @click="() => handleActionClick(action.uriKey)"
                >
                    {{ action.name }}
                </button>
            </template>
        </div>

        <Dropdown v-if="shouldShowDropdown">
            <template #default>
                <span>
                    <span class="sr-only">{{ __('Resource Row Dropdown') }}</span>
                    <Button variant="action" icon="ellipsis-horizontal" :dusk="`${resource.id.value}-control-selector`" />
                </span>
            </template>

            <template #menu>
                <DropdownMenu width="auto" class="px-1">
                    <ScrollWrap :height="250" class="divide-y divide-solid divide-gray-100 dark:divide-gray-800">
                        <div v-if="canModifyResource" class="py-1">
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

                            <DropdownMenuItem
                                v-if="resource.authorizedToDelete && !resource.softDeleted"
                                data-testid="open-delete-modal"
                                dusk="open-delete-modal-button"
                                :destructive="true"
                                @click.prevent="openDeleteModal"
                            >
                                {{ __('Delete Resource') }}
                            </DropdownMenuItem>

                            <DropdownMenuItem
                                v-if="resource.authorizedToRestore && resource.softDeleted"
                                as="button"
                                class="block w-full px-3 py-1 text-left text-sm font-semibold text-red-400 ring-inset hover:text-red-300 focus:text-red-600 focus:outline-none focus:ring"
                                data-testid="open-restore-modal"
                                dusk="open-restore-modal-button"
                                @click.prevent="openRestoreModal"
                            >
                                {{ __('Restore Resource') }}
                            </DropdownMenuItem>

                            <DropdownMenuItem
                                v-if="resource.authorizedToForceDelete"
                                as="button"
                                class="block w-full px-3 py-1 text-left text-sm font-semibold text-red-400 ring-inset hover:text-red-300 focus:text-red-600 focus:outline-none focus:ring"
                                data-testid="open-force-delete-modal"
                                dusk="open-force-delete-modal-button"
                                :destructive="true"
                                @click.prevent="openForceDeleteModal"
                            >
                                {{ __('Force Delete Resource') }}
                            </DropdownMenuItem>
                        </div>

                        <div
                            v-if="actions.filter((action) => action.showAsButton !== true).length > 0"
                            :dusk="`${resource.id.value}-inline-actions`"
                            class="py-1"
                        >
                            <template v-for="action in actions">
                                <!-- User Actions -->
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

        <DeleteResourceModal :show="deleteModalOpen" mode="delete" @close="closeDeleteModal" @confirm="confirmDelete" />

        <RestoreResourceModal :show="restoreModalOpen" @close="closeRestoreModal" @confirm="confirmRestore" />

        <DeleteResourceModal
            :show="forceDeleteModalOpen"
            mode="force delete"
            @close="closeForceDeleteModal"
            @confirm="confirmForceDelete"
        />
    </div>
</template>

<script>
import { mapActions, mapGetters } from 'vuex';
import { Button } from 'laravel-nova-ui';

import { Deletable, HandlesActions, InteractsWithResourceInformation } from '@/mixins';

export default {
    components: {
        Button,
    },
    mixins: [Deletable, HandlesActions, InteractsWithResourceInformation],

    inheritAttrs: false,

    props: {
        resource: { type: Object },
        resourceName: String,
        actions: { type: Array },
        viaManyToMany: { type: Boolean },
        viaResource: { type: String, default: '' },
        viaResourceId: { type: String, default: '' },
        viaRelationship: { type: String, default: '' },
    },
    emits: ['resource-deleted', 'resource-restored'],

    data: () => {
        return {
            showActionResponseModal: false,
            actionResponseData: {},
            deleteModalOpen: false,
            restoreModalOpen: false,
            forceDeleteModalOpen: false,
        };
    },

    methods: {
        ...mapActions(['startImpersonating']),

        openPreviewModal() {
            this.previewModalOpen = true;
        },

        closePreviewModal() {
            this.previewModalOpen = false;
        },

        /**
         * Show the confirmation modal for deleting or detaching a resource
         */
        async confirmDelete() {
            this.deleteResources([this.resource], (response) => {
                Nova.success(
                    this.__('The :resource was deleted!', {
                        resource: this.resourceInformation.singularLabel.toLowerCase(),
                    })
                );

                if (response && response.data && response.data.redirect) {
                    Nova.visit(response.data.redirect);
                    return;
                }

                if (!this.resource.softDeletes) {
                    Nova.visit(`/resources/${this.resourceName}`);
                    return;
                }

                this.closeDeleteModal();
                this.$emit('resource-deleted');
            });
        },

        /**
         * Open the delete modal
         */
        openDeleteModal() {
            this.deleteModalOpen = true;
        },

        /**
         * Close the delete modal
         */
        closeDeleteModal() {
            this.deleteModalOpen = false;
        },

        /**
         * Show the confirmation modal for restoring a resource
         */
        async confirmRestore() {
            this.restoreResources([this.resource], () => {
                Nova.success(
                    this.__('The :resource was restored!', {
                        resource: this.resourceInformation.singularLabel.toLowerCase(),
                    })
                );

                this.closeRestoreModal();
                this.$emit('resource-restored');
            });
        },

        /**
         * Open the restore modal
         */
        openRestoreModal() {
            this.restoreModalOpen = true;
        },

        /**
         * Close the restore modal
         */
        closeRestoreModal() {
            this.restoreModalOpen = false;
        },

        /**
         * Show the confirmation modal for force deleting
         */
        async confirmForceDelete() {
            this.forceDeleteResources([this.resource], (response) => {
                Nova.success(
                    this.__('The :resource was deleted!', {
                        resource: this.resourceInformation.singularLabel.toLowerCase(),
                    })
                );

                if (response && response.data && response.data.redirect) {
                    Nova.visit(response.data.redirect);
                    return;
                }

                Nova.visit(`/resources/${this.resourceName}`);
            });
        },

        /**
         * Open the force delete modal
         */
        openForceDeleteModal() {
            this.forceDeleteModalOpen = true;
        },

        /**
         * Close the force delete modal
         */
        closeForceDeleteModal() {
            this.forceDeleteModalOpen = false;
        },
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

        hasDropdownItems() {
            return this.actions.length > 0 || this.canModifyResource;
        },

        canModifyResource() {
            return (
                this.resource.authorizedToReplicate ||
                this.canBeImpersonated ||
                (this.resource.authorizedToDelete && !this.resource.softDeleted) ||
                (this.resource.authorizedToRestore && this.resource.softDeleted) ||
                this.resource.authorizedToForceDelete
            );
        },

        canBeImpersonated() {
            return this.currentUser.canImpersonate && this.resource.authorizedToImpersonate;
        },

        selectedResources() {
            return [this.resource.id.value];
        },

        shouldShowDropdown() {
            const showInDropdownList = this.actions.filter((action) => !(action.showAsButton === true));

            return (showInDropdownList.length > 0 || this.userHasAnyOptions);
        },
    },
};
</script>
